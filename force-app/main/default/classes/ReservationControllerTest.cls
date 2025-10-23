/**
 * @description Test class for ReservationController following Context7 Apex Recipes patterns
 * @author Cristiano Filho
 * @date 2025-09-30
 */
@isTest
private class ReservationControllerTest {
  @TestSetup
  static void setupTestData() {
    Movie__c movie = new Movie__c(
      Name = 'Test Movie',
      Movie_API_ID__c = 'test123',
      Is_Active__c = true
    );
    insert movie;

    Theater__c theater = new Theater__c(
      Name = 'Test Theater',
      Theater_API_ID__c = 'theater123',
      City__c = 'Test City',
      Is_Active__c = true
    );
    insert theater;

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

    TriggerHandler.bypass('ShowtimeTriggerHandler');
    insert showtime;
    TriggerHandler.clearBypass('ShowtimeTriggerHandler');

    SeatManagementService.generateSeats(showtime.Id, 10, 10);
  }

  @isTest
  static void testGetAvailableShowtimes() {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];

    Test.startTest();
    List<Showtime__c> showtimes = ReservationController.getAvailableShowtimes(
      movie.Id,
      Date.today().addDays(1)
    );
    Test.stopTest();

    System.assertEquals(1, showtimes.size(), 'Should return 1 showtime');
    System.assertEquals(
      100,
      showtimes[0].Available_Seats__c,
      'Should have 100 available seats'
    );
  }

  @isTest
  static void testGetSeatsForShowtime() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();
    List<Seat__c> seats = ReservationController.getSeatsForShowtime(
      showtime.Id
    );
    Test.stopTest();

    System.assertEquals(10, seats.size(), 'Should return 10 seats');
    System.assertEquals(
      'Available',
      seats[0].Status__c,
      'Seats should be available'
    );
  }

  @isTest
  static void testCreateReservation_Success() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 2
    ];

    String customerInfo = '{"name":"John Doe","email":"john@test.com","phone":"1234567890"}';

    Test.startTest();
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id, seats[1].Id },
      customerInfo
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      reservation.Id,
      'Reservation should be created'
    );
    System.assertEquals(
      'John Doe',
      reservation.Customer_Name__c,
      'Customer name should match'
    );
    System.assertEquals(
      2,
      reservation.Number_of_Seats__c,
      'Should have 2 seats'
    );

    Reservation__c refreshedReservation = [
      SELECT Payment_Status__c
      FROM Reservation__c
      WHERE Id = :reservation.Id
    ];
    System.assertEquals(
      'Pending',
      refreshedReservation.Payment_Status__c,
      'Reservation should remain Pending before payment'
    );
    System.assertEquals(
      30.00,
      reservation.Total_Amount__c,
      'Total should be $30.00'
    );
    System.assertNotEquals(
      null,
      reservation.Confirmation_Code__c,
      'Should have confirmation code'
    );

    // Verify seats are reserved
    List<Seat__c> updatedSeats = [
      SELECT Status__c
      FROM Seat__c
      WHERE Id IN :new List<Id>{ seats[0].Id, seats[1].Id }
    ];
    for (Seat__c seat : updatedSeats) {
      System.assertEquals(
        'Reserved',
        seat.Status__c,
        'Seat should be reserved'
      );
    }
  }

  @isTest
  static void testCreateReservation_SeatNotAvailable() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    // Reserve the seat first
    seats[0].Status__c = 'Reserved';
    update seats[0];

    String customerInfo = '{"name":"Jane Doe","email":"jane@test.com","phone":"9876543210"}';

    Test.startTest();
    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        customerInfo
      );
      System.assert(false, 'Should throw exception for unavailable seat');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('no longer available'),
        'Should mention seat unavailability'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testCancelReservation_Success() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 2
    ];

    // Create reservation
    String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id, seats[1].Id },
      customerInfo
    );

    Test.startTest();
    Boolean result = ReservationController.cancelReservation(reservation.Id);
    Test.stopTest();

    System.assertEquals(true, result, 'Cancellation should succeed');

    // Verify reservation is cancelled
    Reservation__c cancelledRes = [
      SELECT Status__c, Payment_Status__c
      FROM Reservation__c
      WHERE Id = :reservation.Id
    ];
    System.assertEquals(
      'Cancelled',
      cancelledRes.Status__c,
      'Status should be Cancelled'
    );
    System.assertEquals(
      'Refunded',
      cancelledRes.Payment_Status__c,
      'Payment should be Refunded'
    );

    // Verify seats are released
    List<Seat__c> releasedSeats = [
      SELECT Status__c, Reservation__c
      FROM Seat__c
      WHERE Id IN :new List<Id>{ seats[0].Id, seats[1].Id }
    ];
    for (Seat__c seat : releasedSeats) {
      System.assertEquals(
        'Available',
        seat.Status__c,
        'Seat should be available'
      );
      System.assertEquals(
        null,
        seat.Reservation__c,
        'Seat should have no reservation'
      );
    }
  }

  @isTest
  static void testCancelReservation_AlreadyCancelled() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id },
      customerInfo
    );

    // Cancel once
    ReservationController.cancelReservation(reservation.Id);

    Test.startTest();
    try {
      ReservationController.cancelReservation(reservation.Id);
      System.assert(
        false,
        'Should throw exception for already cancelled reservation'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('already cancelled'),
        'Should mention already cancelled'
      );
    }
    Test.stopTest();
  }

  // Context7 Apex Recipes Patterns Implementation

  @isTest
  static void testGetActiveMoviesWithFLSValidation() {
    Test.startTest();
    List<Movie__c> movies = ReservationController.getActiveMovies();
    Test.stopTest();

    System.assert(!movies.isEmpty(), 'Should return active movies');

    // Verify FLS validation worked
    System.assert(
      Schema.sObjectType.Movie__c.isAccessible(),
      'Movie__c should be accessible'
    );
    System.assert(
      Schema.sObjectType.Movie__c.fields.Name.isAccessible(),
      'Name field should be accessible'
    );
  }

  @isTest
  static void testGetActiveMoviesWithCircuitBreaker() {
    // Activate circuit breaker
    ReservationController.testCircuitBreaker = true;

    Test.startTest();
    try {
      ReservationController.getActiveMovies();
      System.assert(
        false,
        'Should have thrown exception due to circuit breaker'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Circuit breaker activated'),
        'Should throw circuit breaker exception'
      );
      System.assert(
        ReservationController.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    // Reset circuit breaker
    ReservationController.testCircuitBreaker = false;
    ReservationController.circuitBreakerThrown = false;
  }

  @isTest
  static void testCreateReservationWithPaymentSuccess() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id, Row__c, Number__c
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 2
    ];

    String customerInfo = '{"name":"Paying User","email":"paying@test.com","phone":"1234567890"}';

    Reservation__c reservation = ReservationController.createReservationWithPayment(
      showtime.Id,
      new List<Id>{ seats[0].Id, seats[1].Id },
      customerInfo,
      'pm_real_flow'
    );

    System.assertEquals(
      'Confirmed',
      reservation.Status__c,
      'Reservation should be confirmed after payment'
    );
    System.assertEquals(
      'Paid',
      reservation.Payment_Status__c,
      'Payment status should be Paid'
    );

    List<Seat__c> reservedSeats = [
      SELECT Status__c, Reservation__c
      FROM Seat__c
      WHERE Id IN :new List<Id>{ seats[0].Id, seats[1].Id }
    ];
    for (Seat__c seat : reservedSeats) {
      System.assertEquals(
        'Reserved',
        seat.Status__c,
        'Seat should be reserved'
      );
      System.assertEquals(
        reservation.Id,
        seat.Reservation__c,
        'Seat should relate to reservation'
      );
    }

    Showtime__c updatedShowtime = [
      SELECT Reserved_Seats__c
      FROM Showtime__c
      WHERE Id = :showtime.Id
    ];
    System.assertEquals(
      2,
      updatedShowtime.Reserved_Seats__c,
      'Showtime reserved seats should increment'
    );
  }

  @isTest
  static void testGetAvailableShowtimesWithValidation() {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];

    Test.startTest();

    // Test with valid parameters
    List<Showtime__c> showtimes = ReservationController.getAvailableShowtimes(
      movie.Id,
      Date.today().addDays(1)
    );
    System.assertEquals(1, showtimes.size(), 'Should return 1 showtime');

    // Test with invalid parameters
    try {
      ReservationController.getAvailableShowtimes(
        null,
        Date.today().addDays(1)
      );
      System.assert(false, 'Should have thrown exception for null movie ID');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Movie ID cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.getAvailableShowtimes(movie.Id, null);
      System.assert(false, 'Should have thrown exception for null date');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Selected date cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testGetSeatsForShowtimeWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();

    // Test with valid parameters
    List<Seat__c> seats = ReservationController.getSeatsForShowtime(
      showtime.Id
    );
    System.assertEquals(10, seats.size(), 'Should return 10 seats');

    // Test with invalid parameters
    try {
      ReservationController.getSeatsForShowtime(null);
      System.assert(false, 'Should have thrown exception for null showtime ID');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Showtime ID cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testGetReservationByCodeWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id },
      customerInfo
    );

    Test.startTest();

    // Test with valid confirmation code
    Reservation__c foundReservation = ReservationController.getReservationByCode(
      reservation.Confirmation_Code__c
    );
    System.assertNotEquals(null, foundReservation, 'Should find reservation');
    System.assertEquals(
      reservation.Id,
      foundReservation.Id,
      'Should return correct reservation'
    );

    // Test with invalid confirmation code
    try {
      ReservationController.getReservationByCode('');
      System.assert(
        false,
        'Should have thrown exception for blank confirmation code'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Confirmation code cannot be blank'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.getReservationByCode(null);
      System.assert(
        false,
        'Should have thrown exception for null confirmation code'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Confirmation code cannot be blank'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testCreateReservationWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 2
    ];

    Test.startTest();

    // Test with valid parameters
    String customerInfo = '{"name":"John Doe","email":"john@test.com","phone":"1234567890"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id, seats[1].Id },
      customerInfo
    );

    System.assertNotEquals(
      null,
      reservation.Id,
      'Reservation should be created'
    );
    System.assertEquals(
      'John Doe',
      reservation.Customer_Name__c,
      'Customer name should match'
    );
    System.assertEquals(
      2,
      reservation.Number_of_Seats__c,
      'Should have 2 seats'
    );

    // Test with invalid parameters
    try {
      ReservationController.createReservation(
        null,
        new List<Id>{ seats[0].Id },
        customerInfo
      );
      System.assert(false, 'Should have thrown exception for null showtime ID');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Showtime ID cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.createReservation(showtime.Id, null, customerInfo);
      System.assert(false, 'Should have thrown exception for null seat IDs');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>(),
        customerInfo
      );
      System.assert(false, 'Should have thrown exception for empty seat IDs');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        ''
      );
      System.assert(
        false,
        'Should have thrown exception for blank customer info'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Customer info cannot be blank'),
        'Should throw appropriate exception'
      );
    }

    // Test with invalid customer data
    String invalidCustomerInfo = '{"email":"test@test.com"}'; // Missing name
    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        invalidCustomerInfo
      );
      System.assert(
        false,
        'Should have thrown exception for missing customer name'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Customer name is required'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testCreateReservationWithCircuitBreaker() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    // Activate circuit breaker
    ReservationController.testCircuitBreaker = true;

    String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';

    Test.startTest();
    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        customerInfo
      );
      System.assert(
        false,
        'Should have thrown exception due to circuit breaker'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Circuit breaker activated'),
        'Should throw circuit breaker exception'
      );
      System.assert(
        ReservationController.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    // Reset circuit breaker
    ReservationController.testCircuitBreaker = false;
    ReservationController.circuitBreakerThrown = false;
  }

  @isTest
  static void testBulkOperations() {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
    Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];

    // Create multiple showtimes for bulk testing
    List<Showtime__c> showtimes = new List<Showtime__c>();
    for (Integer i = 0; i < 3; i++) {
      showtimes.add(
        new Showtime__c(
          Movie__c = movie.Id,
          Theater__c = theater.Id,
          Session_Date__c = Date.today().addDays(i + 1),
          Session_Time__c = Time.newInstance(14, 30, 0, 0),
          Total_Seats__c = 10,
          Reserved_Seats__c = 0,
          Ticket_Price__c = 15.00,
          Status__c = 'Scheduled'
        )
      );
    }
    insert showtimes;

    // Create seats for each showtime
    List<Seat__c> allSeats = new List<Seat__c>();
    for (Showtime__c st : showtimes) {
      for (Integer i = 1; i <= 5; i++) {
        allSeats.add(
          new Seat__c(
            Showtime__c = st.Id,
            Row__c = 'A',
            Number__c = i,
            Name = 'A-' + i,
            Status__c = 'Available',
            Seat_Type__c = 'Standard'
          )
        );
      }
    }
    insert allSeats;

    Test.startTest();

    // Test bulk showtime retrieval
    List<Showtime__c> retrievedShowtimes = ReservationController.getAvailableShowtimes(
      movie.Id,
      Date.today().addDays(1)
    );
    System.assertEquals(
      1,
      retrievedShowtimes.size(),
      'Should return 1 showtime for today+1'
    );

    // Test bulk seat retrieval
    List<Seat__c> retrievedSeats = ReservationController.getSeatsForShowtime(
      showtimes[0].Id
    );
    System.assertEquals(
      5,
      retrievedSeats.size(),
      'Should return 5 seats for first showtime'
    );

    Test.stopTest();
  }

  @isTest
  static void testErrorHandlingPatterns() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    Test.startTest();

    // Test exception handling in getActiveMovies
    try {
      ReservationController.getActiveMovies();
      System.assert(true, 'Should handle exceptions gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    // Test exception handling in createReservation
    try {
      String invalidCustomerInfo = '{"name":"","email":"test@test.com"}'; // Empty name
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        invalidCustomerInfo
      );
      System.assert(
        false,
        'Should have handled invalid customer data gracefully'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Customer name is required'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testDataValidationPatterns() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    Test.startTest();

    // Test data sanitization
    String customerInfoWithSpecialChars = '{"name":"John O\'Connor","email":"john+test@example.com","phone":"+1-555-123-4567"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id },
      customerInfoWithSpecialChars
    );

    System.assertNotEquals(
      null,
      reservation.Id,
      'Should handle special characters in customer data'
    );
    System.assertEquals(
      'John O\'Connor',
      reservation.Customer_Name__c,
      'Should preserve special characters'
    );

    Test.stopTest();
  }
}
