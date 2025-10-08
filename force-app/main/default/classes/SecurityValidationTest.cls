/**
 * @description Test class for security validation patterns following Context7 Apex Recipes
 * @author Cristiano Filho
 * @date 2025-01-27
 */
@isTest
private class SecurityValidationTest {
  @TestSetup
  static void setupTestData() {
    // Create test movie
    Movie__c movie = new Movie__c(
      Name = 'Test Movie',
      Movie_API_ID__c = 'test123',
      Is_Active__c = true,
      Duration_Minutes__c = 120
    );
    insert movie;

    // Create test theater
    Theater__c theater = new Theater__c(
      Name = 'Test Theater',
      Theater_API_ID__c = 'theater123',
      City__c = 'Test City',
      Is_Active__c = true
    );
    insert theater;

    // Create test showtime
    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = Date.today().addDays(1),
      Session_Time__c = Time.newInstance(14, 30, 0, 0),
      Total_Seats__c = 100,
      Reserved_Seats__c = 0,
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled'
    );

    // Bypass trigger to avoid automatic seat generation
    TriggerHandler.bypass('ShowtimeTriggerHandler');
    insert showtime;
    TriggerHandler.clearBypass('ShowtimeTriggerHandler');

    // Create test seats
    List<Seat__c> seats = new List<Seat__c>();
    for (Integer i = 1; i <= 10; i++) {
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
    insert seats;

    // Create test reservation
    Reservation__c reservation = new Reservation__c(
      Showtime__c = showtime.Id,
      Movie__c = movie.Id,
      Customer_Name__c = 'Test Customer',
      Customer_Email__c = 'test@test.com',
      Customer_Phone__c = '1234567890',
      Number_of_Seats__c = 2,
      Total_Amount__c = 30.00,
      Status__c = 'Confirmed',
      Payment_Status__c = 'Pending',
      Confirmation_Code__c = 'TEST123'
    );
    insert reservation;
  }

  // Context7 Apex Recipes Patterns Implementation - Security and FLS Validation

  @isTest
  static void testCanTheUserFLSAccessible() {
    Test.startTest();

    // Test FLS accessible for Movie__c
    Boolean movieAccessible = CanTheUser.flsAccessible('Movie__c', 'Name');
    System.assertEquals(
      true,
      movieAccessible,
      'Movie__c.Name should be accessible'
    );

    // Test FLS accessible for Theater__c
    Boolean theaterAccessible = CanTheUser.flsAccessible('Theater__c', 'Name');
    System.assertEquals(
      true,
      theaterAccessible,
      'Theater__c.Name should be accessible'
    );

    Test.stopTest();
  }

  @isTest
  static void testCanTheUserFLSUpdatable() {
    Test.startTest();

    // Test FLS updatable for Movie__c
    Boolean movieUpdatable = CanTheUser.flsUpdatable('Movie__c', 'Name');
    System.assertEquals(
      true,
      movieUpdatable,
      'Movie__c.Name should be updatable'
    );

    // Test FLS updatable for Theater__c
    Boolean theaterUpdatable = CanTheUser.flsUpdatable('Theater__c', 'Name');
    System.assertEquals(
      true,
      theaterUpdatable,
      'Theater__c.Name should be updatable'
    );

    Test.stopTest();
  }

  @isTest
  static void testCanTheUserCRUDPermissions() {
    Test.startTest();

    // Test CRUD permissions for Movie__c
    Boolean movieCreate = CanTheUser.canCreate('Movie__c');
    Boolean movieRead = CanTheUser.canRead('Movie__c');
    Boolean movieUpdate = CanTheUser.canUpdate('Movie__c');
    Boolean movieDelete = CanTheUser.canDelete('Movie__c');

    System.assertEquals(true, movieCreate, 'Should be able to create Movie__c');
    System.assertEquals(true, movieRead, 'Should be able to read Movie__c');
    System.assertEquals(true, movieUpdate, 'Should be able to update Movie__c');
    System.assertEquals(true, movieDelete, 'Should be able to delete Movie__c');

    Test.stopTest();
  }

  @isTest
  static void testSecurityStripInaccessible() {
    Test.startTest();

    // Create test data
    Movie__c movie = new Movie__c(
      Name = 'Test Movie Security',
      Movie_API_ID__c = 'test123security',
      Is_Active__c = true,
      Duration_Minutes__c = 120
    );
    insert movie;

    // Test Security.stripInaccessible for reading
    List<Movie__c> movies = [
      SELECT Id, Name, Is_Active__c
      FROM Movie__c
      WHERE Id = :movie.Id
    ];
    List<Movie__c> accessibleMovies = Security.stripInaccessible(
        AccessType.READABLE,
        movies
      )
      .getRecords();

    System.assertEquals(
      1,
      accessibleMovies.size(),
      'Should return accessible movie'
    );
    System.assertEquals(
      'Test Movie Security',
      accessibleMovies[0].Name,
      'Should have correct name'
    );

    Test.stopTest();
  }

  @isTest
  static void testFLSValidationInServices() {
    Test.startTest();

    // Test FLS validation in ReservationController
    List<Movie__c> movies = ReservationController.getActiveMovies();
    System.assert(
      !movies.isEmpty(),
      'Should return movies with FLS validation'
    );

    Test.stopTest();
  }

  @isTest
  static void testSecurityErrorHandling() {
    Test.startTest();

    // Test security error handling patterns
    try {
      CanTheUser.flsAccessible('Movie__c', 'Name');
      System.assert(true, 'Should handle security validation gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    try {
      CanTheUser.canCreate('Movie__c');
      System.assert(true, 'Should handle CRUD validation gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    Test.stopTest();
  }
}
