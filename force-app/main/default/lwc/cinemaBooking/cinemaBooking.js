import { LightningElement, track } from 'lwc';
import getAvailableShowtimes from '@salesforce/apex/ReservationController.getAvailableShowtimes';

export default class CinemaBooking extends LightningElement {
    @track currentStep = 1;
    @track selectedMovie = null;
    @track selectedShowtime = null;
    @track selectedSeats = [];
    @track showtimes = [];
    @track totalPrice = 0;
    @track showConfirmationModal = false;
    @track selectedDate = this.getTomorrowDate();

    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }

    get progressValue() {
        return (this.currentStep / 3) * 100;
    }

    get currentStepLabel() {
        const steps = {
            1: 'Step 1: Select Movie',
            2: 'Step 2: Choose Showtime',
            3: 'Step 3: Pick Your Seats'
        };
        return steps[this.currentStep];
    }

    getTomorrowDate() {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        return tomorrow.toISOString().split('T')[0];
    }

    handleMovieSelect(event) {
        if (event && event.detail && event.detail.movie) {
            this.selectedMovie = event.detail.movie;
            this.currentStep = 2;
            this.loadShowtimes();
        }
    }

    loadShowtimes() {
        if (!this.selectedMovie || !this.selectedMovie.Id) {
            console.error('No movie selected');
            return;
        }
        const dateObj = new Date(this.selectedDate);
        getAvailableShowtimes({ 
            movieId: this.selectedMovie.Id,
            selectedDate: dateObj
        })
        .then(result => {
            this.showtimes = result;
        })
        .catch(error => {
            console.error('Error loading showtimes:', error);
        });
    }

    handleShowtimeSelect(event) {
        // Check if event comes from custom event (showtimeSelector component)
        if (event && event.detail && event.detail.showtime) {
            this.selectedShowtime = event.detail.showtime;
            this.currentStep = 3;
        } 
        // Handle click event from inline showtime cards
        else if (event && event.currentTarget) {
            const showtimeId = event.currentTarget.dataset.id;
            const showtime = this.showtimes ? this.showtimes.find(st => st.Id === showtimeId) : null;
            if (showtime) {
                this.selectedShowtime = showtime;
                this.currentStep = 3;
            }
        }
    }

    handleSeatSelection(event) {
        if (event && event.detail) {
            this.selectedSeats = event.detail.selectedSeats || [];
            this.totalPrice = event.detail.totalPrice || 0;
        }
    }

    handleNext() {
        if (this.currentStep < 3) {
            this.currentStep++;
        } else {
            this.showConfirmationModal = true;
        }
    }

    handleBack() {
        if (this.currentStep > 1) {
            this.currentStep--;
        }
    }

    handleStartOver() {
        this.currentStep = 1;
        this.selectedMovie = null;
        this.selectedShowtime = null;
        this.selectedSeats = [];
        this.totalPrice = 0;
        this.showConfirmationModal = false;
    }

    handleCloseModal() {
        this.showConfirmationModal = false;
    }

    handleReservationSuccess() {
        this.showConfirmationModal = false;
        this.handleStartOver();
    }

    get canProceed() {
        if (this.currentStep === 1) return this.selectedMovie !== null;
        if (this.currentStep === 2) return this.selectedShowtime !== null;
        if (this.currentStep === 3) return this.selectedSeats.length > 0;
        return false;
    }

    get nextButtonLabel() {
        return this.currentStep === 3 ? 'Confirm Reservation' : 'Next';
    }

    get sessionDateTime() {
        if (!this.selectedShowtime || !this.selectedShowtime.Session_DateTime__c) return '';
        try {
            const date = new Date(this.selectedShowtime.Session_DateTime__c);
            return date.toLocaleString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        } catch (error) {
            console.error('Error formatting date:', error);
            return '';
        }
    }

    get seatNumbers() {
        if (!this.selectedSeats || !this.selectedSeats.length) return '';
        const seatComponent = this.template.querySelector('c-seat-reservation');
        return seatComponent ? seatComponent.selectedSeatNumbers : '';
    }
}

