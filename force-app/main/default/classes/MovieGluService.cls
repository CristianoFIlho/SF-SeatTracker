/**
 * @description Service class for MovieGlu API integration
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class MovieGluService {
    
    private static final String NAMED_CREDENTIAL = 'callout:MovieGlu_API';
    private static final String FILMS_ENDPOINT = '/filmsNowShowing';
    private static final String CINEMAS_ENDPOINT = '/cinemasNearby';
    private static final String SHOWTIMES_ENDPOINT = '/filmShowTimes';
    
    /**
     * @description Fetch and sync movies currently showing
     * @param latitude Geographic latitude
     * @param longitude Geographic longitude
     * @return List of created Movie__c records
     */
    public static List<Movie__c> syncNowShowingFilms(String latitude, String longitude) {
        List<Movie__c> moviesToUpsert = new List<Movie__c>();
        
        try {
            Map<String, String> params = new Map<String, String>{
                'n' => '20'
            };
            
            HttpResponse response = makeCallout(FILMS_ENDPOINT, params, latitude, longitude);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (jsonResponse.containsKey('films')) {
                    List<Object> films = (List<Object>) jsonResponse.get('films');
                    
                    for (Object filmObj : films) {
                        Map<String, Object> filmData = (Map<String, Object>) filmObj;
                        Movie__c movie = parseMovie(filmData);
                        if (movie != null) {
                            moviesToUpsert.add(movie);
                        }
                    }
                    
                    if (!moviesToUpsert.isEmpty()) {
                        Database.upsert(moviesToUpsert, Movie__c.Movie_API_ID__c, false);
                        System.debug('Successfully synced ' + moviesToUpsert.size() + ' movies');
                    }
                }
            } else {
                System.debug('Error from MovieGlu API: ' + response.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error syncing movies: ' + e.getMessage());
            throw new MovieGluServiceException('Failed to sync movies: ' + e.getMessage());
        }
        
        return moviesToUpsert;
    }
    
    /**
     * @description Fetch nearby theaters
     * @param latitude Geographic latitude
     * @param longitude Geographic longitude
     * @param radiusKm Search radius in kilometers
     * @return List of Theater__c records
     */
    public static List<Theater__c> syncNearbyTheaters(String latitude, String longitude, Integer radiusKm) {
        List<Theater__c> theatersToUpsert = new List<Theater__c>();
        
        try {
            Map<String, String> params = new Map<String, String>{
                'n' => '10'
            };
            
            HttpResponse response = makeCallout(CINEMAS_ENDPOINT, params, latitude, longitude);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (jsonResponse.containsKey('cinemas')) {
                    List<Object> cinemas = (List<Object>) jsonResponse.get('cinemas');
                    
                    for (Object cinemaObj : cinemas) {
                        Map<String, Object> cinemaData = (Map<String, Object>) cinemaObj;
                        Theater__c theater = parseTheater(cinemaData);
                        if (theater != null) {
                            theatersToUpsert.add(theater);
                        }
                    }
                    
                    if (!theatersToUpsert.isEmpty()) {
                        Database.upsert(theatersToUpsert, Theater__c.Theater_API_ID__c, false);
                        System.debug('Successfully synced ' + theatersToUpsert.size() + ' theaters');
                    }
                }
            } else {
                System.debug('Error from MovieGlu API: ' + response.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error syncing theaters: ' + e.getMessage());
            throw new MovieGluServiceException('Failed to sync theaters: ' + e.getMessage());
        }
        
        return theatersToUpsert;
    }
    
    /**
     * @description Sync showtimes for a specific movie and theater
     * @param movieApiId External movie ID
     * @param latitude Geographic latitude
     * @param longitude Geographic longitude
     * @param showDate Date for showtimes
     * @return List of Showtime__c records
     */
    public static List<Showtime__c> syncShowtimes(String movieApiId, String latitude, String longitude, Date showDate) {
        List<Showtime__c> showtimesToUpsert = new List<Showtime__c>();
        
        try {
            Map<String, String> params = new Map<String, String>{
                'film_id' => movieApiId,
                'date' => String.valueOf(showDate)
            };
            
            HttpResponse response = makeCallout(SHOWTIMES_ENDPOINT, params, latitude, longitude);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                // Get Movie__c record
                List<Movie__c> movies = [SELECT Id FROM Movie__c WHERE Movie_API_ID__c = :movieApiId LIMIT 1];
                if (movies.isEmpty()) {
                    System.debug('Movie not found with API ID: ' + movieApiId);
                    return showtimesToUpsert;
                }
                
                if (jsonResponse.containsKey('cinemas')) {
                    List<Object> cinemas = (List<Object>) jsonResponse.get('cinemas');
                    
                    for (Object cinemaObj : cinemas) {
                        Map<String, Object> cinemaData = (Map<String, Object>) cinemaObj;
                        
                        // Get or create theater
                        String theaterApiId = String.valueOf(cinemaData.get('cinema_id'));
                        List<Theater__c> theaters = [SELECT Id FROM Theater__c WHERE Theater_API_ID__c = :theaterApiId LIMIT 1];
                        
                        if (!theaters.isEmpty() && cinemaData.containsKey('showings')) {
                            List<Object> showings = (List<Object>) cinemaData.get('showings');
                            
                            for (Object showingObj : showings) {
                                Map<String, Object> showingData = (Map<String, Object>) showingObj;
                                Showtime__c showtime = parseShowtime(showingData, movies[0].Id, theaters[0].Id, showDate);
                                if (showtime != null) {
                                    showtimesToUpsert.add(showtime);
                                }
                            }
                        }
                    }
                    
                    if (!showtimesToUpsert.isEmpty()) {
                        Database.upsert(showtimesToUpsert, Showtime__c.Showtime_API_ID__c, false);
                        System.debug('Successfully synced ' + showtimesToUpsert.size() + ' showtimes');
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error syncing showtimes: ' + e.getMessage());
            throw new MovieGluServiceException('Failed to sync showtimes: ' + e.getMessage());
        }
        
        return showtimesToUpsert;
    }
    
    /**
     * @description Make HTTP callout to MovieGlu API
     * @param endpoint API endpoint path
     * @param queryParams Map of query parameters
     * @param latitude Geographic latitude
     * @param longitude Geographic longitude
     * @return HTTPResponse
     */
    @TestVisible
    private static HttpResponse makeCallout(String endpoint, Map<String, String> queryParams, String latitude, String longitude) {
        HttpRequest req = new HttpRequest();
        
        // Build URL with query parameters
        String url = NAMED_CREDENTIAL + endpoint + '?';
        if (queryParams != null && !queryParams.isEmpty()) {
            for (String key : queryParams.keySet()) {
                url += key + '=' + EncodingUtil.urlEncode(queryParams.get(key), 'UTF-8') + '&';
            }
        }
        url = url.removeEnd('&');
        
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setTimeout(120000);
        
        // Set required headers for MovieGlu API
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('geolocation', latitude + ';' + longitude);
        
        Http http = new Http();
        return http.send(req);
    }
    
    /**
     * @description Parse movie JSON and create Movie__c record
     * @param filmJson JSON object for a single film
     * @return Movie__c record
     */
    private static Movie__c parseMovie(Map<String, Object> filmJson) {
        try {
            Movie__c movie = new Movie__c();
            movie.Movie_API_ID__c = String.valueOf(filmJson.get('film_id'));
            movie.Name = String.valueOf(filmJson.get('film_name'));
            movie.Synopsis__c = String.valueOf(filmJson.get('synopsis_long'));
            
            // Parse images
            if (filmJson.containsKey('images')) {
                Map<String, Object> images = (Map<String, Object>) filmJson.get('images');
                if (images.containsKey('poster')) {
                    Map<String, Object> poster = (Map<String, Object>) images.get('poster');
                    if (poster.containsKey('1')) {
                        Map<String, Object> posterSize = (Map<String, Object>) poster.get('1');
                        movie.Poster_URL__c = String.valueOf(posterSize.get('medium'));
                    }
                }
            }
            
            // Parse other fields
            if (filmJson.containsKey('release_dates')) {
                List<Object> releaseDates = (List<Object>) filmJson.get('release_dates');
                if (!releaseDates.isEmpty()) {
                    Map<String, Object> firstRelease = (Map<String, Object>) releaseDates[0];
                    String dateStr = String.valueOf(firstRelease.get('release_date'));
                    if (dateStr != null && dateStr != 'null') {
                        movie.Release_Date__c = Date.valueOf(dateStr);
                    }
                }
            }
            
            if (filmJson.containsKey('duration_mins')) {
                movie.Duration_Minutes__c = Integer.valueOf(filmJson.get('duration_mins'));
            }
            
            if (filmJson.containsKey('age_rating')) {
                List<Object> ageRatings = (List<Object>) filmJson.get('age_rating');
                if (!ageRatings.isEmpty()) {
                    Map<String, Object> rating = (Map<String, Object>) ageRatings[0];
                    movie.Rating__c = String.valueOf(rating.get('rating'));
                }
            }
            
            movie.Is_Active__c = true;
            
            return movie;
        } catch (Exception e) {
            System.debug('Error parsing movie: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Parse theater JSON and create Theater__c record
     * @param cinemaJson JSON object for a single cinema
     * @return Theater__c record
     */
    private static Theater__c parseTheater(Map<String, Object> cinemaJson) {
        try {
            Theater__c theater = new Theater__c();
            theater.Theater_API_ID__c = String.valueOf(cinemaJson.get('cinema_id'));
            theater.Name = String.valueOf(cinemaJson.get('cinema_name'));
            theater.Address__c = String.valueOf(cinemaJson.get('address'));
            theater.City__c = String.valueOf(cinemaJson.get('city'));
            theater.Country__c = String.valueOf(cinemaJson.get('country'));
            
            if (cinemaJson.containsKey('lat') && cinemaJson.containsKey('lng')) {
                Decimal lat = Decimal.valueOf(String.valueOf(cinemaJson.get('lat')));
                Decimal lng = Decimal.valueOf(String.valueOf(cinemaJson.get('lng')));
                theater.Location__Latitude__s = lat;
                theater.Location__Longitude__s = lng;
            }
            
            theater.Is_Active__c = true;
            
            return theater;
        } catch (Exception e) {
            System.debug('Error parsing theater: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Parse showtime JSON and create Showtime__c record
     * @param showingJson JSON object for a single showing
     * @param movieId Movie record ID
     * @param theaterId Theater record ID
     * @param showDate Showtime date
     * @return Showtime__c record
     */
    private static Showtime__c parseShowtime(Map<String, Object> showingJson, Id movieId, Id theaterId, Date showDate) {
        try {
            Showtime__c showtime = new Showtime__c();
            showtime.Showtime_API_ID__c = String.valueOf(showingJson.get('showing_id'));
            showtime.Movie__c = movieId;
            showtime.Theater__c = theaterId;
            showtime.Session_Date__c = showDate;
            
            // Parse time
            String timeStr = String.valueOf(showingJson.get('start_time'));
            if (timeStr != null) {
                showtime.Session_Time__c = Time.newInstance(
                    Integer.valueOf(timeStr.substring(0, 2)),
                    Integer.valueOf(timeStr.substring(3, 5)),
                    0,
                    0
                );
            }
            
            showtime.Status__c = 'Scheduled';
            showtime.Total_Seats__c = 100;
            showtime.Reserved_Seats__c = 0;
            showtime.Ticket_Price__c = 15.00; // Default price
            
            return showtime;
        } catch (Exception e) {
            System.debug('Error parsing showtime: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Custom exception class for MovieGlu service errors
     */
    public class MovieGluServiceException extends Exception {}
}

