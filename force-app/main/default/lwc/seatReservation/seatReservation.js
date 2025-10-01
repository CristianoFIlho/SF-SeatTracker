import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getSeatsForShowtime from '@salesforce/apex/ReservationController.getSeatsForShowtime';

export default class SeatReservation extends LightningElement {
    _showtimeId;
    @api ticketPrice = 0;
    
    @api
    set showtimeId(value) {
        console.log('=== SEAT RESERVATION DEBUG ===');
        console.log('seatReservation received showtimeId:', value);
        console.log('Previous showtimeId:', this._showtimeId);
        this._showtimeId = value;
        console.log('New showtimeId set to:', this._showtimeId);
        
        // Fallback: If wire fails, try imperative call after a delay
        if (value && value !== this._showtimeId) {
            setTimeout(() => {
                this.loadSeatsImperatively();
            }, 1000);
        }
        
        console.log('=== END SEAT RESERVATION SETTER DEBUG ===');
    }
    
    get showtimeId() {
        return this._showtimeId;
    }
    
    @track seats = [];
    @track selectedSeats = [];
    @track isLoading = false;
    @track error;
    
    MAX_SEATS = 10;
    subscription = null;

    connectedCallback() {
        console.log('SeatReservation connectedCallback - showtimeId:', this.showtimeId);
        console.log('SeatReservation connectedCallback - ticketPrice:', this.ticketPrice);
        
        // Subscribe to Platform Events for real-time seat updates
        this.subscribeToSeatUpdates();
        
        // Register error listener
        onError((error) => {
            console.error('Platform Event subscription error:', error);
        });
    }
    
    disconnectedCallback() {
        // Unsubscribe from Platform Events
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    renderedCallback() {
        console.log('SeatReservation renderedCallback - showtimeId:', this.showtimeId);
    }

    @wire(getSeatsForShowtime, { showtimeId: '$showtimeId' })
    wiredSeats({ error, data }) {
        console.log('=== WIRE ADAPTER DEBUG ===');
        console.log('Seat wire adapter triggered with showtimeId:', this.showtimeId);
        console.log('Wire adapter params:', { showtimeId: this.showtimeId });
        
        // Add timeout protection
        if (!this.showtimeId) {
            console.log('No showtimeId provided, skipping wire call');
            return;
        }
        
        if (data) {
            console.log('Seat wire adapter SUCCESS. Data received:', JSON.stringify(data));
            console.log('Number of seats received:', data.length);
            console.log('First few seats:', data.slice(0, 3));
            
            this.seats = data.map(seat => ({
                ...seat,
                isSelected: false,
                cssClass: this.getSeatClass(seat)
            }));
            this.error = undefined;
            
            console.log('Processed seats array length:', this.seats.length);
            console.log('=== END WIRE ADAPTER SUCCESS ===');
        } else if (error) {
            console.error('Seat wire adapter FAILED. Error received:', JSON.stringify(error));
            console.error('Error details:', error);
            console.error('Error body:', error.body);
            console.error('Error message:', error.body?.message);
            
            this.error = error;
            const errorMessage = error.body ? error.body.message : JSON.stringify(error);
            this.showToast('Error', 'Error loading seats: ' + errorMessage, 'error');
            console.log('=== END WIRE ADAPTER ERROR ===');
        } else {
            console.log('Seat wire called but no data or error yet - this is normal during initialization');
            console.log('=== END WIRE ADAPTER PENDING ===');
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
    
    /**
     * Fallback method to load seats imperatively if wire fails
     */
    loadSeatsImperatively() {
        console.log('=== IMPERATIVE FALLBACK DEBUG ===');
        console.log('Attempting imperative call for showtimeId:', this.showtimeId);
        
        if (!this.showtimeId) {
            console.log('No showtimeId for imperative call');
            return;
        }
        
        this.isLoading = true;
        
        getSeatsForShowtime({ showtimeId: this.showtimeId })
            .then(result => {
                console.log('Imperative call SUCCESS:', JSON.stringify(result));
                console.log('Number of seats from imperative call:', result.length);
                
                this.seats = result.map(seat => ({
                    ...seat,
                    isSelected: false,
                    cssClass: this.getSeatClass(seat)
                }));
                this.error = undefined;
                this.isLoading = false;
                
                console.log('=== END IMPERATIVE FALLBACK SUCCESS ===');
            })
            .catch(error => {
                console.error('Imperative call FAILED:', JSON.stringify(error));
                console.error('Imperative error details:', error);
                
                this.error = error;
                this.isLoading = false;
                const errorMessage = error.body ? error.body.message : JSON.stringify(error);
                this.showToast('Error', 'Error loading seats (imperative): ' + errorMessage, 'error');
                
                console.log('=== END IMPERATIVE FALLBACK ERROR ===');
            });
    }
    
    /**
     * Subscribe to Platform Events for real-time seat updates
     */
    subscribeToSeatUpdates() {
        if (!this.showtimeId) {
            return;
        }
        
        const channel = '/event/Seat_Status_Change__e';
        const replayId = -1;
        
        subscribe(channel, replayId, (response) => {
            console.log('Received Platform Event:', response);
            
            const eventData = response.data.payload;
            
            // Only process events for the current showtime
            if (eventData.Showtime_Id__c === this.showtimeId) {
                this.updateSeatStatus(eventData.Seat_Id__c, eventData.New_Status__c);
            }
        }).then(response => {
            console.log('Successfully subscribed to Platform Event:', response);
            this.subscription = response;
        }).catch(error => {
            console.error('Error subscribing to Platform Event:', error);
        });
    }
    
    /**
     * Update seat status in real-time
     * @param {string} seatId - The seat ID to update
     * @param {string} newStatus - The new status
     */
    updateSeatStatus(seatId, newStatus) {
        const seatIndex = this.seats.findIndex(seat => seat.Id === seatId);
        
        if (seatIndex !== -1) {
            // Update the seat status
            this.seats[seatIndex].Status__c = newStatus;
            this.seats[seatIndex].cssClass = this.getSeatClass(this.seats[seatIndex]);
            
            // If the seat was selected and is no longer available, remove it from selection
            if (newStatus !== 'Available' && this.selectedSeats.includes(seatId)) {
                const selectedIndex = this.selectedSeats.indexOf(seatId);
                this.selectedSeats.splice(selectedIndex, 1);
                this.seats[seatIndex].isSelected = false;
                
                this.showToast('Seat Unavailable', 
                    `Seat ${this.seats[seatIndex].Row__c}-${this.seats[seatIndex].Number__c} is no longer available`, 
                    'warning');
            }
            
            // Trigger re-render
            this.seats = [...this.seats];
            this.selectedSeats = [...this.selectedSeats];
            
            // Fire event to parent with updated selection
            this.dispatchEvent(new CustomEvent('seatselection', {
                detail: {
                    selectedSeats: this.selectedSeats,
                    totalPrice: this.totalPrice
                }
            }));
        }
    }
}

