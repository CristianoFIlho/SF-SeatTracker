import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createReservation from '@salesforce/apex/ReservationController.createReservation';

export default class ConfirmationModal extends LightningElement {
    @api showtimeId;
    @api movieName;
    @api theaterName;
    @api sessionDateTime;
    @api seatNumbers;
    @api totalAmount;
    @api selectedSeatIds = [];
    
    @track customerName = '';
    @track customerEmail = '';
    @track customerPhone = '';
    @track agreeToTerms = false;
    @track isLoading = false;

    get isFormValid() {
        return this.customerName && 
               this.customerEmail && 
               this.agreeToTerms &&
               this.selectedSeatIds.length > 0;
    }

    handleNameChange(event) {
        this.customerName = event.target.value;
    }

    handleEmailChange(event) {
        this.customerEmail = event.target.value;
    }

    handlePhoneChange(event) {
        this.customerPhone = event.target.value;
    }

    handleTermsChange(event) {
        this.agreeToTerms = event.target.checked;
    }

    handleConfirm() {
        if (!this.isFormValid) {
            this.showToast('Error', 'Please fill in all required fields and agree to terms', 'error');
            return;
        }

        this.isLoading = true;

        const customerInfo = JSON.stringify({
            name: this.customerName,
            email: this.customerEmail,
            phone: this.customerPhone
        });

        createReservation({ 
            showtimeId: this.showtimeId,
            seatIds: this.selectedSeatIds,
            customerInfo: customerInfo
        })
        .then(result => {
            this.isLoading = false;
            this.showToast(
                'Success!', 
                `Reservation confirmed! Your confirmation code is: ${result.Confirmation_Code__c}`, 
                'success'
            );
            
            // Fire success event
            this.dispatchEvent(new CustomEvent('reservationsuccess', {
                detail: { reservation: result }
            }));
            
            // Close modal
            this.handleClose();
        })
        .catch(error => {
            this.isLoading = false;
            this.showToast(
                'Error', 
                'Error creating reservation: ' + (error.body?.message || error.message),
                'error'
            );
        });
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
            mode: variant === 'success' ? 'sticky' : 'dismissable'
        });
        this.dispatchEvent(event);
    }
}

