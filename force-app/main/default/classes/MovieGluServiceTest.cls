/**
 * @description Test class for MovieGluService
 * @author Cristiano Filho
 * @date 2025-09-30
 */
@isTest
private class MovieGluServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test movie
        Movie__c movie = new Movie__c(
            Name = 'Test Movie',
            Movie_API_ID__c = '12345',
            Is_Active__c = true,
            Duration_Minutes__c = 120
        );
        insert movie;
        
        // Create test theater
        Theater__c theater = new Theater__c(
            Name = 'Test Theater',
            Theater_API_ID__c = 'cinema123',
            City__c = 'Test City',
            Is_Active__c = true
        );
        insert theater;
    }
    
    @isTest
    static void testSyncNowShowingFilms_Success() {
        Test.setMock(HttpCalloutMock.class, new MovieGluHttpCalloutMock('films', 200));
        
        Test.startTest();
        List<Movie__c> movies = MovieGluService.syncNowShowingFilms('-23.5505', '-46.6333');
        Test.stopTest();
        
        System.assertEquals(2, movies.size(), 'Should create 2 movies');
        System.assertEquals('Test Movie', movies[0].Name, 'Movie name should match');
    }
    
    @isTest
    static void testSyncNowShowingFilms_Error() {
        Test.setMock(HttpCalloutMock.class, new MovieGluHttpCalloutMock('films', 500));
        
        Test.startTest();
        try {
            MovieGluService.syncNowShowingFilms('-23.5505', '-46.6333');
            System.assert(false, 'Should throw exception');
        } catch (MovieGluService.MovieGluServiceException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSyncNearbyTheaters_Success() {
        Test.setMock(HttpCalloutMock.class, new MovieGluHttpCalloutMock('cinemas', 200));
        
        Test.startTest();
        List<Theater__c> theaters = MovieGluService.syncNearbyTheaters('-23.5505', '-46.6333', 10);
        Test.stopTest();
        
        System.assertEquals(2, theaters.size(), 'Should create 2 theaters');
        System.assertEquals('Test Theater', theaters[0].Name, 'Theater name should match');
    }
    
    @isTest
    static void testSyncShowtimes_Success() {
        Test.setMock(HttpCalloutMock.class, new MovieGluHttpCalloutMock('showtimes', 200));
        
        Test.startTest();
        List<Showtime__c> showtimes = MovieGluService.syncShowtimes(
            '12345', 
            '-23.5505', 
            '-46.6333', 
            Date.today().addDays(1)
        );
        Test.stopTest();
        
        System.assertEquals(2, showtimes.size(), 'Should create 2 showtimes');
    }
    
    @isTest
    static void testSyncShowtimes_MovieNotFound() {
        Test.setMock(HttpCalloutMock.class, new MovieGluHttpCalloutMock('showtimes', 200));
        
        Test.startTest();
        List<Showtime__c> showtimes = MovieGluService.syncShowtimes(
            'nonexistent', 
            '-23.5505', 
            '-46.6333', 
            Date.today()
        );
        Test.stopTest();
        
        System.assertEquals(0, showtimes.size(), 'Should not create showtimes for non-existent movie');
    }
}

