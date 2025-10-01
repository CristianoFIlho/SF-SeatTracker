import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSeatsForShowtime from '@salesforce/apex/ReservationController.getSeatsForShowtime';

export default class SeatReservation extends LightningElement {
    @api showtimeId;
    @api ticketPrice = 0;
    
    @track seats = [];
    @track selectedSeats = [];
    @track isLoading = false;
    @track error;
    
    MAX_SEATS = 10;

    @wire(getSeatsForShowtime, { showtimeId: '$showtimeId' })
    wiredSeats({ error, data }) {
        console.log('Seat wire called with showtimeId:', this.showtimeId);
        if (data) {
            console.log('Seats loaded:', data.length, 'seats');
            this.seats = data.map(seat => ({
                ...seat,
                isSelected: false,
                cssClass: this.getSeatClass(seat)
            }));
            this.error = undefined;
        } else if (error) {
            console.error('Error loading seats:', error);
            this.error = error;
            const errorMessage = error.body ? error.body.message : JSON.stringify(error);
            this.showToast('Error', 'Error loading seats: ' + errorMessage, 'error');
        }
    }

    get seatRows() {
        const rows = {};
        this.seats.forEach(seat => {
            if (!rows[seat.Row__c]) {
                rows[seat.Row__c] = [];
            }
            rows[seat.Row__c].push(seat);
        });
        
        return Object.keys(rows).sort().map(rowKey => ({
            key: rowKey,
            label: `Row ${rowKey}`,
            seats: rows[rowKey].sort((a, b) => a.Number__c - b.Number__c)
        }));
    }

    get selectedCount() {
        return this.selectedSeats.length;
    }

    get totalPrice() {
        return (this.selectedSeats.length * this.ticketPrice).toFixed(2);
    }

    get canAddMore() {
        return this.selectedSeats.length < this.MAX_SEATS;
    }

    get selectedSeatNumbers() {
        return this.selectedSeats
            .map(seatId => {
                const seat = this.seats.find(s => s.Id === seatId);
                return seat ? `${seat.Row__c}-${seat.Number__c}` : '';
            })
            .filter(s => s)
            .join(', ');
    }

    handleSeatClick(event) {
        const seatId = event.currentTarget.dataset.id;
        const seat = this.seats.find(s => s.Id === seatId);

        if (!seat || seat.Status__c !== 'Available') {
            this.showToast('Unavailable', 'This seat is not available', 'warning');
            return;
        }

        const index = this.selectedSeats.indexOf(seatId);
        
        if (index > -1) {
            // Deselect
            this.selectedSeats.splice(index, 1);
            seat.isSelected = false;
        } else {
            // Select
            if (this.selectedSeats.length >= this.MAX_SEATS) {
                this.showToast('Maximum Reached', `You can select up to ${this.MAX_SEATS} seats`, 'warning');
                return;
            }
            this.selectedSeats.push(seatId);
            seat.isSelected = true;
        }

        // Update CSS class
        seat.cssClass = this.getSeatClass(seat);
        
        // Trigger re-render
        this.seats = [...this.seats];
        this.selectedSeats = [...this.selectedSeats];

        // Fire event to parent
        this.dispatchEvent(new CustomEvent('seatselection', {
            detail: {
                selectedSeats: this.selectedSeats,
                totalPrice: this.totalPrice
            }
        }));
    }

    getSeatClass(seat) {
        const baseClass = 'seat';
        
        if (seat.isSelected) {
            return `${baseClass} selected`;
        }
        
        switch (seat.Status__c) {
            case 'Available':
                return `${baseClass} available ${seat.Seat_Type__c ? seat.Seat_Type__c.toLowerCase() : ''}`;
            case 'Reserved':
                return `${baseClass} reserved`;
            case 'Occupied':
                return `${baseClass} occupied`;
            case 'Blocked':
                return `${baseClass} blocked`;
            default:
                return baseClass;
        }
    }

    handleClearSelection() {
        this.selectedSeats = [];
        this.seats = this.seats.map(seat => ({
            ...seat,
            isSelected: false,
            cssClass: this.getSeatClass(seat)
        }));
        
        this.dispatchEvent(new CustomEvent('seatselection', {
            detail: {
                selectedSeats: [],
                totalPrice: 0
            }
        }));
    }

    @api
    getSelectedSeats() {
        return this.selectedSeats;
    }

    @api
    clearSelection() {
        this.handleClearSelection();
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    get hasSeats() {
        return this.seats && this.seats.length > 0;
    }
}

