import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createReservationWithPayment from '@salesforce/apex/ReservationController.createReservationWithPayment';

export default class PaymentProcessor extends LightningElement {
    @api showtimeId;
    @api seatIds = [];
    @api customerInfo = {};
    @api totalAmount = 0;

    @track isLoading = false;
    @track paymentMethod = 'card';
    @track cardNumber = '';
    @track expiryDate = '';
    @track cvv = '';
    @track cardholderName = '';

    get formattedAmount() {
        return `$${this.totalAmount.toFixed(2)}`;
    }

    get isButtonDisabled() {
        return this.isLoading || !this.isValidPayment;
    }

    get isValidPayment() {
        return this.cardNumber && this.expiryDate && this.cvv && this.cardholderName;
    }

    handleCardNumberChange(event) {
        this.cardNumber = event.target.value.replace(/\D/g, '').replace(/(.{4})/g, '$1 ').trim();
    }

    handleExpiryChange(event) {
        let value = event.target.value.replace(/\D/g, '');
        if (value.length >= 2) {
            value = value.substring(0, 2) + '/' + value.substring(2, 4);
        }
        this.expiryDate = value;
    }

    handleCvvChange(event) {
        this.cvv = event.target.value.replace(/\D/g, '');
    }

    handleCardholderChange(event) {
        this.cardholderName = event.target.value;
    }

    async handlePayment() {
        if (!this.isValidPayment) {
            this.showToast('Pagamento Inválido',
                'Por favor, preencha todos os campos de pagamento',
                'error');
            return;
        }

        this.isLoading = true;

        try {
            // Create payment method ID (simulated)
            const paymentMethodId = 'pm_' + Date.now();

            console.log('🔄 Processing payment...');
            console.log('  - Showtime ID:', this.showtimeId);
            console.log('  - Seat IDs:', this.seatIds);
            console.log('  - Total Amount:', this.totalAmount);

            const reservation = await createReservationWithPayment({
                showtimeId: this.showtimeId,
                seatIds: this.seatIds,
                customerInfo: JSON.stringify(this.customerInfo),
                paymentMethodId: paymentMethodId
            });

            console.log('✅ Payment successful:', reservation);

            this.showToast('Pagamento Confirmado!',
                `Código de confirmação: ${reservation.Confirmation_Code__c}`,
                'success');

            // Dispatch success event
            this.dispatchEvent(new CustomEvent('paymentsuccess', {
                detail: { reservation }
            }));

        } catch (error) {
            console.error('❌ Payment error:', error);
            console.error('  - Error body:', error.body);
            console.error('  - Error message:', error.body?.message);

            const errorMessage = error.body?.message ||
                error.message ||
                'Ocorreu um erro ao processar o pagamento.';

            this.showToast('Falha no Pagamento', errorMessage, 'error');

            // Dispatch error event
            this.dispatchEvent(new CustomEvent('paymenterror', {
                detail: { error: errorMessage }
            }));
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('paymentcancel'));
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
