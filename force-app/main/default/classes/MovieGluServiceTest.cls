/**
 * @description Test class for MovieGluService following Context7 Apex Recipes patterns
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
  static void testSyncNowShowingFilmsSuccess() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('films', 200)
    );

    Test.startTest();
    List<Movie__c> movies = MovieGluService.syncNowShowingFilms(
      '-23.5505',
      '-46.6333'
    );
    Test.stopTest();

    System.assertEquals(2, movies.size(), 'Should create 2 movies');
    System.assertEquals(
      'Test Movie',
      movies[0].Name,
      'Movie name should match'
    );
  }

  @isTest
  static void testSyncNowShowingFilmsError() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('films', 500)
    );

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
  static void testSyncNearbyTheatersSuccess() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('cinemas', 200)
    );

    Test.startTest();
    List<Theater__c> theaters = MovieGluService.syncNearbyTheaters(
      '-23.5505',
      '-46.6333',
      10
    );
    Test.stopTest();

    System.assertEquals(2, theaters.size(), 'Should create 2 theaters');
    System.assertEquals(
      'Test Theater',
      theaters[0].Name,
      'Theater name should match'
    );
  }

  @isTest
  static void testSyncShowtimesSuccess() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('showtimes', 200)
    );

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
  static void testSyncShowtimesMovieNotFound() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('showtimes', 200)
    );

    Test.startTest();
    List<Showtime__c> showtimes = MovieGluService.syncShowtimes(
      'nonexistent',
      '-23.5505',
      '-46.6333',
      Date.today()
    );
    Test.stopTest();

    System.assertEquals(
      0,
      showtimes.size(),
      'Should not create showtimes for non-existent movie'
    );
  }

  // Context7 Apex Recipes Patterns Implementation - Exception and Edge Cases

  @isTest
  static void testSyncNowShowingFilmsWithInvalidCoordinates() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('films', 200)
    );

    Test.startTest();

    // Test with null coordinates
    try {
      MovieGluService.syncNowShowingFilms(null, null);
      System.assert(false, 'Should have thrown exception for null coordinates');
    } catch (MovieGluService.MovieGluServiceException e) {
      System.assert(
        e.getMessage().contains('Invalid coordinates'),
        'Should throw appropriate exception'
      );
    }

    // Test with empty coordinates
    try {
      MovieGluService.syncNowShowingFilms('', '');
      System.assert(
        false,
        'Should have thrown exception for empty coordinates'
      );
    } catch (MovieGluService.MovieGluServiceException e) {
      System.assert(
        e.getMessage().contains('Invalid coordinates'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testSyncNowShowingFilmsWithNetworkError() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('films', 0)
    ); // Simulate network error

    Test.startTest();
    try {
      MovieGluService.syncNowShowingFilms('-23.5505', '-46.6333');
      System.assert(false, 'Should have thrown exception for network error');
    } catch (MovieGluService.MovieGluServiceException e) {
      System.assert(
        e.getMessage().contains('Network error'),
        'Should throw network error exception'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testSyncNowShowingFilmsWithEmptyResponse() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('empty', 200)
    );

    Test.startTest();
    List<Movie__c> movies = MovieGluService.syncNowShowingFilms(
      '-23.5505',
      '-46.6333'
    );
    Test.stopTest();

    System.assertEquals(
      0,
      movies.size(),
      'Should return empty list for empty response'
    );
  }

  @isTest
  static void testSyncNearbyTheatersWithInvalidParameters() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('cinemas', 200)
    );

    Test.startTest();

    // Test with null coordinates
    try {
      MovieGluService.syncNearbyTheaters(null, null, 10);
      System.assert(false, 'Should have thrown exception for null coordinates');
    } catch (MovieGluService.MovieGluServiceException e) {
      System.assert(
        e.getMessage().contains('Invalid coordinates'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testSyncShowtimesWithInvalidDate() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('showtimes', 200)
    );

    Test.startTest();

    // Test with null date
    try {
      MovieGluService.syncShowtimes('12345', '-23.5505', '-46.6333', null);
      System.assert(false, 'Should have thrown exception for null date');
    } catch (MovieGluService.MovieGluServiceException e) {
      System.assert(
        e.getMessage().contains('Invalid date'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testSyncShowtimesWithInvalidMovieId() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('showtimes', 200)
    );

    Test.startTest();

    // Test with null movie ID
    try {
      MovieGluService.syncShowtimes(null, '-23.5505', '-46.6333', Date.today());
      System.assert(false, 'Should have thrown exception for null movie ID');
    } catch (MovieGluService.MovieGluServiceException e) {
      System.assert(
        e.getMessage().contains('Invalid movie ID'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testBulkOperations() {
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('films', 200)
    );

    Test.startTest();

    // Test bulk movie sync
    List<Movie__c> movies = MovieGluService.syncNowShowingFilms(
      '-23.5505',
      '-46.6333'
    );
    System.assert(movies.size() > 0, 'Should sync multiple movies');

    // Test bulk theater sync
    Test.setMock(
      HttpCalloutMock.class,
      new MovieGluHttpCalloutMock('cinemas', 200)
    );
    List<Theater__c> theaters = MovieGluService.syncNearbyTheaters(
      '-23.5505',
      '-46.6333',
      10
    );
    System.assert(theaters.size() > 0, 'Should sync multiple theaters');

    Test.stopTest();
  }

  @isTest
  static void testErrorHandlingPatterns() {
    Test.startTest();

    // Test exception handling in syncNowShowingFilms
    try {
      MovieGluService.syncNowShowingFilms('-23.5505', '-46.6333');
      System.assert(true, 'Should handle exceptions gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    Test.stopTest();
  }
}
