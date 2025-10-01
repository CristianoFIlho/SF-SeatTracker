import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getReservationByCode from '@salesforce/apex/ReservationController.getReservationByCode';
import cancelReservation from '@salesforce/apex/ReservationController.cancelReservation';

export default class ReservationCancellation extends NavigationMixin(LightningElement) {
    @track confirmationCode = '';
    @track reservation = null;
    @track isLoading = false;
    @track showCancelForm = false;
    
    get hasReservation() {
        return this.reservation !== null;
    }
    
    get isSearchButtonDisabled() {
        return this.isLoading || !this.confirmationCode.trim();
    }
    
    get canCancel() {
        return this.reservation && 
               this.reservation.Status__c !== 'Cancelled' && 
               this.reservation.Status__c !== 'Completed';
    }
    
    get formattedShowtime() {
        if (!this.reservation || !this.reservation.Showtime__r) return '';
        return this.reservation.Showtime__r.Session_DateTime__c ? 
               this.reservation.Showtime__r.Session_DateTime__c.format() : '';
    }
    
    get formattedAmount() {
        return this.reservation ? `$${this.reservation.Total_Amount__c.toFixed(2)}` : '';
    }
    
    get cancellationMessage() {
        if (!this.reservation) return '';
        
        const showtimeStart = this.reservation.Showtime__r?.Session_DateTime__c;
        if (!showtimeStart) return '';
        
        const now = new Date();
        const showtimeDate = new Date(showtimeStart);
        const hoursDiff = (showtimeDate.getTime() - now.getTime()) / (1000 * 60 * 60);
        
        if (hoursDiff < 2) {
            return 'Cancellation is not allowed within 2 hours of showtime.';
        }
        
        return 'You can cancel this reservation up to 2 hours before showtime.';
    }
    
    handleCodeChange(event) {
        this.confirmationCode = event.target.value;
        this.reservation = null;
        this.showCancelForm = false;
    }
    
    async handleSearchReservation() {
        if (!this.confirmationCode.trim()) {
            this.showToast('Error', 'Please enter a confirmation code', 'error');
            return;
        }
        
        this.isLoading = true;
        
        try {
            this.reservation = await getReservationByCode({ 
                confirmationCode: this.confirmationCode.trim() 
            });
            
            if (this.reservation) {
                this.showCancelForm = true;
                this.showToast('Success', 'Reservation found', 'success');
            } else {
                this.showToast('Not Found', 'No reservation found with this confirmation code', 'warning');
            }
            
        } catch (error) {
            console.error('Error searching reservation:', error);
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleCancelReservation() {
        if (!this.reservation) return;
        
        this.isLoading = true;
        
        try {
            const result = await cancelReservation({ 
                reservationId: this.reservation.Id 
            });
            
            if (result) {
                this.showToast('Success', 'Reservation cancelled successfully', 'success');
                this.reservation = null;
                this.confirmationCode = '';
                this.showCancelForm = false;
            }
            
        } catch (error) {
            console.error('Error cancelling reservation:', error);
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    handleReset() {
        this.reservation = null;
        this.confirmationCode = '';
        this.showCancelForm = false;
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}
