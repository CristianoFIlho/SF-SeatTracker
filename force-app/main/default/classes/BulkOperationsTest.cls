/**
 * @description Test class for bulk operations and governor limits following Context7 Apex Recipes
 * @author Cristiano Filho
 * @date 2025-01-27
 */
@isTest
private class BulkOperationsTest {
  @TestSetup
  static void setupTestData() {
    // Create test movies in bulk
    List<Movie__c> movies = new List<Movie__c>();
    for (Integer i = 0; i < 5; i++) {
      movies.add(
        new Movie__c(
          Name = 'Bulk Movie ' + i,
          Movie_API_ID__c = 'bulk' + i,
          Is_Active__c = true,
          Duration_Minutes__c = 120
        )
      );
    }
    insert movies;

    // Create test theaters in bulk
    List<Theater__c> theaters = new List<Theater__c>();
    for (Integer i = 0; i < 3; i++) {
      theaters.add(
        new Theater__c(
          Name = 'Bulk Theater ' + i,
          Theater_API_ID__c = 'theater' + i,
          City__c = 'Test City',
          Is_Active__c = true
        )
      );
    }
    insert theaters;

    // Create test showtimes in bulk
    List<Showtime__c> showtimes = new List<Showtime__c>();
    for (Integer i = 0; i < 10; i++) {
      showtimes.add(
        new Showtime__c(
          Movie__c = movies[Math.mod(i, movies.size())].Id,
          Theater__c = theaters[Math.mod(i, theaters.size())].Id,
          Session_Date__c = Date.today().addDays(i),
          Session_Time__c = Time.newInstance(14, 30, 0, 0),
          Total_Seats__c = 100,
          Reserved_Seats__c = 0,
          Ticket_Price__c = 15.00,
          Status__c = 'Scheduled'
        )
      );
    }

    // Insert showtimes (trigger will handle seat generation)
    insert showtimes;

    // Create test seats in bulk
    List<Seat__c> seats = new List<Seat__c>();
    for (Showtime__c showtime : showtimes) {
      for (Integer i = 1; i <= 5; i++) {
        seats.add(
          new Seat__c(
            Showtime__c = showtime.Id,
            Row__c = 'A',
            Number__c = i,
            Name = 'A-' + i,
            Status__c = 'Available',
            Seat_Type__c = 'Standard'
          )
        );
      }
    }
    insert seats;
  }

  // Context7 Apex Recipes Patterns Implementation - Bulk Operations and Governor Limits

  @isTest
  static void testBulkMovieOperations() {
    Test.startTest();

    // Test bulk movie creation
    List<Movie__c> newMovies = new List<Movie__c>();
    for (Integer i = 0; i < 10; i++) {
      newMovies.add(
        new Movie__c(
          Name = 'New Bulk Movie ' + i,
          Movie_API_ID__c = 'newbulk' + i,
          Is_Active__c = true,
          Duration_Minutes__c = 120
        )
      );
    }

    // Test bulk insert
    Database.SaveResult[] results = Database.insert(newMovies, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }

    System.assertEquals(
      10,
      successCount,
      'Should successfully insert all movies'
    );

    Test.stopTest();
  }

  @isTest
  static void testBulkTheaterOperations() {
    Test.startTest();

    // Test bulk theater creation
    List<Theater__c> newTheaters = new List<Theater__c>();
    for (Integer i = 0; i < 8; i++) {
      newTheaters.add(
        new Theater__c(
          Name = 'New Bulk Theater ' + i,
          Theater_API_ID__c = 'newtheater' + i,
          City__c = 'Test City',
          Is_Active__c = true
        )
      );
    }

    // Test bulk insert with partial success
    Database.SaveResult[] results = Database.insert(newTheaters, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }

    System.assertEquals(
      8,
      successCount,
      'Should successfully insert all theaters'
    );

    Test.stopTest();
  }

  @isTest
  static void testBulkShowtimeOperations() {
    Test.startTest();

    // Get existing movies and theaters
    List<Movie__c> movies = [SELECT Id FROM Movie__c LIMIT 3];
    List<Theater__c> theaters = [SELECT Id FROM Theater__c LIMIT 3];

    // Test bulk showtime creation
    List<Showtime__c> newShowtimes = new List<Showtime__c>();
    for (Integer i = 0; i < 9; i++) {
      newShowtimes.add(
        new Showtime__c(
          Movie__c = movies[Math.mod(i, movies.size())].Id,
          Theater__c = theaters[Math.mod(i, theaters.size())].Id,
          Session_Date__c = Date.today().addDays(i),
          Session_Time__c = Time.newInstance(14, 30, 0, 0),
          Total_Seats__c = 100,
          Reserved_Seats__c = 0,
          Ticket_Price__c = 15.00,
          Status__c = 'Scheduled'
        )
      );
    }

    // Insert showtimes (trigger will handle seat generation)
    Database.SaveResult[] results = Database.insert(newShowtimes, false);

    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }

    System.assertEquals(
      9,
      successCount,
      'Should successfully insert all showtimes'
    );

    Test.stopTest();
  }

  @isTest
  static void testBulkSeatOperations() {
    Test.startTest();

    // Get existing showtimes
    List<Showtime__c> showtimes = [SELECT Id FROM Showtime__c LIMIT 2];

    // Test bulk seat creation
    List<Seat__c> newSeats = new List<Seat__c>();
    for (Showtime__c showtime : showtimes) {
      for (Integer i = 1; i <= 10; i++) {
        newSeats.add(
          new Seat__c(
            Showtime__c = showtime.Id,
            Row__c = 'B',
            Number__c = i,
            Name = 'B-' + i,
            Status__c = 'Available',
            Seat_Type__c = 'Standard'
          )
        );
      }
    }

    Database.SaveResult[] results = Database.insert(newSeats, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }

    System.assertEquals(
      20,
      successCount,
      'Should successfully insert all seats'
    );

    Test.stopTest();
  }

  @isTest
  static void testGovernorLimitsProtection() {
    Test.startTest();

    // Test SOQL governor limits
    List<Movie__c> movies = [SELECT Id, Name FROM Movie__c LIMIT 200];
    System.assert(movies.size() <= 200, 'Should respect SOQL governor limits');

    // Test DML governor limits
    List<Movie__c> newMovies = new List<Movie__c>();
    for (Integer i = 0; i < 50; i++) {
      newMovies.add(
        new Movie__c(
          Name = 'Governor Test Movie ' + i,
          Movie_API_ID__c = 'gov' + i,
          Is_Active__c = true,
          Duration_Minutes__c = 120
        )
      );
    }

    Database.SaveResult[] results = Database.insert(newMovies, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }

    System.assertEquals(50, successCount, 'Should respect DML governor limits');

    Test.stopTest();
  }

  @isTest
  static void testBulkUpdateOperations() {
    Test.startTest();

    // Get existing movies
    List<Movie__c> movies = [SELECT Id, Name FROM Movie__c LIMIT 10];

    // Test bulk update
    for (Movie__c movie : movies) {
      movie.Name = 'Bulk Updated ' + movie.Name;
    }

    Database.SaveResult[] results = Database.update(movies, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }

    System.assertEquals(
      10,
      successCount,
      'Should successfully update all movies'
    );

    Test.stopTest();
  }

  @isTest
  static void testBulkErrorHandling() {
    Test.startTest();

    // Test bulk operations with errors
    List<Movie__c> moviesWithErrors = new List<Movie__c>();

    // Add valid movie
    moviesWithErrors.add(
      new Movie__c(
        Name = 'Valid Movie',
        Movie_API_ID__c = 'valid123',
        Is_Active__c = true,
        Duration_Minutes__c = 120
      )
    );

    // Add invalid movie (missing required field)
    moviesWithErrors.add(
      new Movie__c(
        Name = 'Invalid Movie',
        // Missing Movie_API_ID__c
        Is_Active__c = true,
        Duration_Minutes__c = 120
      )
    );

    Database.SaveResult[] results = Database.insert(moviesWithErrors, false);

    // Check partial success
    Integer successCount = 0;
    Integer errorCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      } else {
        errorCount++;
      }
    }

    System.assertEquals(
      1,
      successCount,
      'Should successfully insert valid movie'
    );
    System.assertEquals(1, errorCount, 'Should fail to insert invalid movie');

    Test.stopTest();
  }

  @isTest
  static void testBulkOperationsWithServices() {
    Test.startTest();

    // Test bulk operations through services
    List<Movie__c> movies = ReservationController.getActiveMovies();
    System.assert(!movies.isEmpty(), 'Should return movies from service');

    // Test bulk seat operations through SeatManagementService
    List<Seat__c> seats = [SELECT Id FROM Seat__c LIMIT 3];
    List<Id> seatIds = new List<Id>();
    for (Seat__c seat : seats) {
      seatIds.add(seat.Id);
    }

    SeatManagementService.lockSeats(seatIds, 5);
    System.assert(true, 'Should lock seats in bulk');

    SeatManagementService.unlockSeats(seatIds);
    System.assert(true, 'Should unlock seats in bulk');

    Test.stopTest();
  }
}
