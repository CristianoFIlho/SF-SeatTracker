import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableShowtimes from '@salesforce/apex/ReservationController.getAvailableShowtimes';

export default class ShowtimeSelector extends LightningElement {
    @api movieId;
    @api movieName;
    
    @track showtimes = [];
    @track selectedShowtime = null;
    @track selectedDate;
    @track isLoading = false;
    @track error;
    @track mapMarkers = [];

    connectedCallback() {
        // Set default date to tomorrow
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        this.selectedDate = tomorrow.toISOString().split('T')[0];
        
        if (this.movieId) {
            this.loadShowtimes();
        }
    }

    loadShowtimes() {
        this.isLoading = true;
        const dateObj = new Date(this.selectedDate);
        
        getAvailableShowtimes({ 
            movieId: this.movieId,
            selectedDate: dateObj
        })
        .then(result => {
            this.showtimes = result;
            this.prepareMapMarkers(result);
            this.isLoading = false;
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.isLoading = false;
            this.showtimes = [];
            this.showToast('Error', 'Error loading showtimes: ' + error.body.message, 'error');
        });
    }

    prepareMapMarkers(showtimes) {
        const markerMap = new Map();
        
        showtimes.forEach(showtime => {
            const theater = showtime.Theater__r;
            if (theater.Location__Latitude__s && theater.Location__Longitude__s) {
                const key = `${theater.Id}`;
                
                if (!markerMap.has(key)) {
                    markerMap.set(key, {
                        location: {
                            Latitude: theater.Location__Latitude__s,
                            Longitude: theater.Location__Longitude__s
                        },
                        title: theater.Name,
                        description: `${theater.Address__c}, ${theater.City__c}`,
                        icon: 'custom:custom18'
                    });
                }
            }
        });
        
        this.mapMarkers = Array.from(markerMap.values());
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.loadShowtimes();
    }

    handleShowtimeSelect(event) {
        const showtimeId = event.currentTarget.dataset.id;
        const showtime = this.showtimes.find(st => st.Id === showtimeId);
        
        if (showtime) {
            this.selectedShowtime = showtime;
            
            const selectEvent = new CustomEvent('showtimeselect', {
                detail: { 
                    showtime: showtime,
                    showtimeId: showtimeId
                }
            });
            this.dispatchEvent(selectEvent);
        }
    }

    handleRefresh() {
        this.loadShowtimes();
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    get hasShowtimes() {
        return this.showtimes && this.showtimes.length > 0;
    }

    get hasMap() {
        return this.mapMarkers && this.mapMarkers.length > 0;
    }

    get minDate() {
        const today = new Date();
        return today.toISOString().split('T')[0];
    }

    get maxDate() {
        const maxDate = new Date();
        maxDate.setDate(maxDate.getDate() + 30);
        return maxDate.toISOString().split('T')[0];
    }

    get groupedShowtimes() {
        const grouped = {};
        
        this.showtimes.forEach(showtime => {
            const theaterName = showtime.Theater__r.Name;
            if (!grouped[theaterName]) {
                grouped[theaterName] = {
                    theater: showtime.Theater__r,
                    showtimes: []
                };
            }
            grouped[theaterName].showtimes.push(showtime);
        });
        
        return Object.keys(grouped).map(key => ({
            key: key,
            theater: grouped[key].theater,
            showtimes: grouped[key].showtimes.sort((a, b) => {
                return new Date('1970/01/01 ' + a.Session_Time__c) - 
                       new Date('1970/01/01 ' + b.Session_Time__c);
            })
        }));
    }

    formatTime(time) {
        if (!time) return '';
        const [hours, minutes] = time.split(':');
        const hour = parseInt(hours, 10);
        const ampm = hour >= 12 ? 'PM' : 'AM';
        const displayHour = hour % 12 || 12;
        return `${displayHour}:${minutes} ${ampm}`;
    }
}

