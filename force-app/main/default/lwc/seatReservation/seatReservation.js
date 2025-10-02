import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getSeatsForShowtime from '@salesforce/apex/ReservationController.getSeatsForShowtime';

export default class SeatReservation extends LightningElement {
    _showtimeId;
    @api ticketPrice = 0;

    @api
    set showtimeId(value) {
        console.log('=== SEAT RESERVATION SETTER DEBUG ===');
        console.log('seatReservation received showtimeId:', value);
        console.log('Type of value:', typeof value);
        console.log('Previous showtimeId:', this._showtimeId);

        // Only update if value is different and valid
        if (value && value !== this._showtimeId) {
            this._showtimeId = value;
            console.log('✅ showtimeId updated to:', this._showtimeId);

            // Clear previous state
            this.seats = [];
            this.selectedSeats = [];
            this.error = undefined;
            this.isLoading = true;

            // Use ONLY imperative call (skip wire to avoid async issues)
            console.log('🔄 Loading seats imperatively for showtimeId:', this._showtimeId);
            this.loadSeatsImperatively();
        } else {
            console.log('❌ showtimeId NOT updated - value:', value, 'same as previous or null');
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
        console.log('✅ SeatReservation connectedCallback');
        console.log('   - showtimeId:', this.showtimeId);
        console.log('   - ticketPrice:', this.ticketPrice);

        // Subscribe to Platform Events for real-time seat updates
        this.subscribeToSeatUpdates();

        // Register error listener
        onError((error) => {
            console.error('❌ Platform Event subscription error:', error);
        });
    }

    disconnectedCallback() {
        console.log('🔌 SeatReservation disconnectedCallback');
        // Unsubscribe from Platform Events
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    renderedCallback() {
        const seatElements = this.template.querySelectorAll('.seat');
        console.log(`🎨 SeatReservation rendered - ${seatElements.length} seat elements in DOM`);
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

    showToast(title, message, variant, mode = 'dismissible') {
        console.log(`📢 Toast: [${variant}] ${title} - ${message}`);

        const event = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        });
        this.dispatchEvent(event);
    }

    get hasSeats() {
        return this.seats && this.seats.length > 0;
    }

    /**
     * Load seats imperatively (primary method, not fallback)
     */
    loadSeatsImperatively() {
        console.log('=== IMPERATIVE LOAD START ===');
        console.log('📡 Calling Apex for showtimeId:', this._showtimeId);

        if (!this._showtimeId) {
            console.log('❌ No showtimeId provided');
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        this.error = undefined;

        getSeatsForShowtime({ showtimeId: this._showtimeId })
            .then(result => {
                console.log('✅ Apex call SUCCESS');
                console.log(`   - Received ${result?.length || 0} seats`);

                if (result && Array.isArray(result) && result.length > 0) {
                    console.log('   - Sample seat:', JSON.stringify(result[0]));

                    this.seats = result.map(seat => ({
                        ...seat,
                        isSelected: false,
                        cssClass: this.getSeatClass(seat)
                    }));
                    this.error = undefined;

                    console.log(`✅ Successfully processed ${this.seats.length} seats`);
                    console.log('   - Rows:', this.seatRows.length);

                    this.showToast('Seats Loaded',
                        `${this.seats.length} seats available`,
                        'success',
                        'dismissible');
                } else {
                    console.log('⚠️ Empty result from Apex');
                    this.seats = [];
                    this.showToast('No Seats',
                        'No seats available for this showtime',
                        'warning',
                        'dismissible');
                }

                this.isLoading = false;
                console.log('=== IMPERATIVE LOAD COMPLETE ===');
            })
            .catch(error => {
                console.error('❌ Apex call FAILED');
                console.error('   - Error:', error);
                console.error('   - Error body:', error?.body);
                console.error('   - Error message:', error?.body?.message);
                console.error('   - Error stack:', error?.body?.stackTrace);

                this.error = error;
                this.seats = [];
                this.isLoading = false;

                const errorMessage = error?.body?.message ||
                    error?.message ||
                    'Unknown error occurred';

                this.showToast('Error Loading Seats',
                    `Could not load seats: ${errorMessage}`,
                    'error',
                    'sticky');

                console.log('=== IMPERATIVE LOAD FAILED ===');
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

