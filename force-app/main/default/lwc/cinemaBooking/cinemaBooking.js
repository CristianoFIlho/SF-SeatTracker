import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableShowtimes from '@salesforce/apex/ReservationController.getAvailableShowtimes';
import getActiveMovies from '@salesforce/apex/ReservationController.getActiveMovies';

// Test console immediately
console.log('🔥 CINEMA BOOKING CLASS LOADING...');

export default class CinemaBooking extends LightningElement {
    @track currentStep = 1;
    @track selectedMovie = null;
    @track selectedShowtime = null;
    @track selectedSeats = [];
    @track showtimes = [];
    @track totalPrice = 0;
    @track showConfirmationModal = false;
    @track selectedDate;

    constructor() {
        super();
        console.log('🏗️ CINEMA BOOKING CONSTRUCTOR CALLED');
        this.selectedDate = this.getTomorrowDate();
        console.log('📅 Default date set to:', this.selectedDate);
    }

    handleDateChange(event) {
        try {
            this.selectedDate = event.target.value;
            this.loadShowtimes();
        } catch (error) {
            console.error('❌ Error handling date change:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erro ao alterar a data',
                    message: error?.body?.message || error?.message || 'Não foi possível atualizar os horários.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }
    }

    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }

    // lightning-progress-indicator expects a string value
    get currentStepStr() {
        return String(this.currentStep);
    }

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
        tomorrow.setDate(tomorrow.getDate() + 2); // 03/10/2025
        return tomorrow.toISOString().split('T')[0];
    }

    connectedCallback() {
        console.log('🚀 CINEMA BOOKING INITIALIZED');
        console.log('🎬 Testing data connection...');
        this.testDataConnection();
    }

    testDataConnection() {
        console.log('📊 Testing getActiveMovies...');
        getActiveMovies()
            .then(movies => {
                console.log('✅ Movies loaded:', movies.length);
                movies.forEach(movie => {
                    console.log(`   - ${movie.Name} (${movie.Id})`);
                });

                if (movies.length > 0) {
                    console.log('📅 Testing getAvailableShowtimes for first movie...');
                    const testDate = new Date('2025-10-03');
                    return getAvailableShowtimes({
                        movieId: movies[0].Id,
                        selectedDate: testDate
                    });
                }
            })
            .then(showtimes => {
                if (showtimes) {
                    console.log('✅ Showtimes loaded:', showtimes.length);
                    showtimes.forEach(st => {
                        console.log(`   - ${st.Theater__r.Name} at ${st.Session_Time__c}`);
                    });
                }
            })
            .catch(error => {
                console.error('❌ Data connection test failed:', error);
                console.error('Error details:', error.body);
            });
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
                console.log(`✅ Loaded ${result.length} showtimes`);

                // Notificar usuário se não há showtimes disponíveis
                if (!result || result.length === 0) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Nenhum Horário Disponível',
                            message: 'Não há sessões disponíveis para este filme na data selecionada.',
                            variant: 'warning',
                            mode: 'dismissible'
                        })
                    );
                }
            })
            .catch(error => {
                console.error('❌ Error loading showtimes:', error);

                // Feedback para o usuário
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erro ao Carregar os Horários',
                        message: error.body ? error.body.message : 'Ocorreu um erro ao buscar os horários disponíveis.',
                        variant: 'error',
                        mode: 'sticky'
                    })
                );

                // Limpar showtimes em caso de erro
                this.showtimes = [];
            });
    }

    handleShowtimeSelect(event) {
        console.log('=== CINEMA BOOKING DEBUG ===');
        console.log('handleShowtimeSelect called with event:', event);

        // Check if event comes from custom event (showtimeSelector component)
        if (event && event.detail && event.detail.showtime) {
            this.selectedShowtime = event.detail.showtime;
            console.log('Showtime Selected from event.detail:', JSON.stringify(this.selectedShowtime));
            console.log('Selected showtime ID:', this.selectedShowtime.Id);
            this.currentStep = 3;
        }
        // Handle click event from inline showtime cards
        else if (event && event.currentTarget) {
            const showtimeId = event.currentTarget.dataset.id;
            const showtime = this.showtimes ? this.showtimes.find(st => st.Id === showtimeId) : null;
            console.log('Showtime Selected from click - ID:', showtimeId);
            console.log('Found showtime:', JSON.stringify(showtime));
            if (showtime) {
                this.selectedShowtime = showtime;
                console.log('Showtime Selected from click:', JSON.stringify(this.selectedShowtime));
                console.log('Selected showtime ID:', this.selectedShowtime.Id);
                this.currentStep = 3;
            }
        }
        console.log('Final selectedShowtime:', JSON.stringify(this.selectedShowtime));
        console.log('Current step set to:', this.currentStep);
        console.log('=== END CINEMA BOOKING DEBUG ===');
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

    handleReservationSuccess(event) {
        // Close modal and reset flow
        this.showConfirmationModal = false;
        
        // Show success toast with confirmation code if available
        const reservation = event?.detail?.reservation;
        const code = reservation?.Confirmation_Code__c;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Reserva confirmada',
                message: code ? `Código de confirmação: ${code}` : 'Sua reserva foi confirmada com sucesso.',
                variant: 'success'
            })
        );

        this.handleStartOver();
    }

    get canProceed() {
        if (this.currentStep === 1) return this.selectedMovie !== null;
        if (this.currentStep === 2) return this.selectedShowtime !== null;
        if (this.currentStep === 3) return this.selectedSeats.length > 0;
        return false;
    }

    get isNextDisabled() {
        return !this.canProceed;
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

