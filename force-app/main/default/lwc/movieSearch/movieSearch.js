import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getActiveMovies from '@salesforce/apex/ReservationController.getActiveMovies';

export default class MovieSearch extends LightningElement {
    @track movies = [];
    @track filteredMovies = [];
    @track searchTerm = '';
    @track isLoading = false;
    @track error;
    @track latitude = '-23.5505';
    @track longitude = '-46.6333';

    connectedCallback() {
        this.loadMovies();
    }

    loadMovies() {
        this.isLoading = true;
        getActiveMovies()
            .then(result => {
                this.movies = result;
                this.filteredMovies = result;
                this.isLoading = false;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                this.showToast('Error', 'Error loading movies: ' + error.body.message, 'error');
            });
    }

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        if (this.searchTerm) {
            this.filteredMovies = this.movies.filter(movie => 
                movie.Name.toLowerCase().includes(this.searchTerm) ||
                (movie.Synopsis__c && movie.Synopsis__c.toLowerCase().includes(this.searchTerm)) ||
                (movie.Genre__c && movie.Genre__c.toLowerCase().includes(this.searchTerm))
            );
        } else {
            this.filteredMovies = this.movies;
        }
    }

    handleMovieSelect(event) {
        const movieId = event.currentTarget.dataset.id;
        const selectedMovie = this.movies.find(movie => movie.Id === movieId);
        
        const selectEvent = new CustomEvent('movieselect', {
            detail: { movieId, movie: selectedMovie }
        });
        this.dispatchEvent(selectEvent);
    }

    handleGetLocation() {
        if (navigator.geolocation) {
            this.isLoading = true;
            navigator.geolocation.getCurrentPosition(
                position => {
                    this.latitude = position.coords.latitude.toString();
                    this.longitude = position.coords.longitude.toString();
                    this.showToast('Success', 'Location obtained successfully', 'success');
                    this.isLoading = false;
                },
                error => {
                    this.showToast('Error', 'Unable to get your location', 'error');
                    this.isLoading = false;
                }
            );
        } else {
            this.showToast('Error', 'Geolocation is not supported by your browser', 'error');
        }
    }

    handleRefresh() {
        this.loadMovies();
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    get hasMovies() {
        return this.filteredMovies && this.filteredMovies.length > 0;
    }
}

