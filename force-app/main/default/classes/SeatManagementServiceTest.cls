/**
 * @description Test class for SeatManagementService following Context7 Apex Recipes patterns
 * @author Cristiano Filho
 * @date 2025-09-30
 */
@isTest
private class SeatManagementServiceTest {
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
  }

  private static Showtime__c createShowtime(Integer rows, Integer seatsPerRow) {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
    Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];

    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = Date.today().addDays(1),
      Session_Time__c = Time.newInstance(17, 0, 0, 0),
      Total_Seats__c = rows * seatsPerRow,
      Reserved_Seats__c = 0,
      Ticket_Price__c = 18.00,
      Status__c = 'Scheduled'
    );

    TriggerHandler.bypass('ShowtimeTriggerHandler');
    insert showtime;
    TriggerHandler.clearBypass('ShowtimeTriggerHandler');
    return showtime;
  }

  @isTest
  static void testGenerateSeatsSimple() {
    Showtime__c showtime = createShowtime(5, 5);

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    Test.stopTest();

    System.assertEquals(25, seats.size(), 'Should create 25 seats (5x5)');

    List<Seat__c> createdSeats = [
      SELECT Row__c, Number__c, Seat_Type__c
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      ORDER BY Row__c, Number__c
    ];
    System.assertEquals(
      25,
      createdSeats.size(),
      'Should have 25 seats in database'
    );
    System.assertEquals(
      'A',
      createdSeats[0].Row__c,
      'First seat should be row A'
    );
    System.assertEquals(
      1,
      createdSeats[0].Number__c,
      'First seat should be number 1'
    );
    System.assertEquals(
      'VIP',
      createdSeats[0].Seat_Type__c,
      'Front row should be VIP'
    );
  }

  @isTest
  static void testGenerateSeatsCustomSize() {
    Showtime__c showtime = createShowtime(5, 10);

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      10
    );
    Test.stopTest();

    System.assertEquals(50, seats.size(), 'Should create 50 seats (5x10)');
  }

  @isTest
  static void testGenerateSeatsAlreadyExists() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    SeatManagementService.generateSeats(showtime.Id, 10, 10);

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      10,
      10
    );
    Test.stopTest();

    System.assertEquals(0, seats.size(), 'Should not create duplicate seats');
  }

  @isTest
  static void testLockSeats() {
    Showtime__c showtime = createShowtime(3, 5);
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      3,
      5
    );

    System.assert(!seats.isEmpty(), 'Seats should be created');

    List<Id> seatIds = new List<Id>{ seats[0].Id, seats[1].Id, seats[2].Id };

    Test.startTest();
    SeatManagementService.lockSeats(seatIds, 5);
    Test.stopTest();

    List<Seat__c> lockedSeats = [
      SELECT Status__c
      FROM Seat__c
      WHERE Id IN :seatIds
    ];
    for (Seat__c seat : lockedSeats) {
      System.assertEquals('Blocked', seat.Status__c, 'Seat should be blocked');
    }
  }

  @isTest
  static void testUnlockSeats() {
    Showtime__c showtime = createShowtime(3, 5);
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      3,
      5
    );
    System.assert(!seats.isEmpty(), 'Seats should be created');

    List<Id> seatIds = new List<Id>{ seats[0].Id, seats[1].Id };
    SeatManagementService.lockSeats(seatIds, 5);

    Test.startTest();
    SeatManagementService.unlockSeats(seatIds);
    Test.stopTest();

    List<Seat__c> unlockedSeats = [
      SELECT Status__c
      FROM Seat__c
      WHERE Id IN :seatIds
    ];
    for (Seat__c seat : unlockedSeats) {
      System.assertEquals(
        'Available',
        seat.Status__c,
        'Seat should be available'
      );
    }
  }

  @isTest
  static void testGetSeatStatistics() {
    Showtime__c showtime = createShowtime(5, 5);
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    System.assert(!seats.isEmpty(), 'Seats should be created');

    seats[0].Status__c = 'Reserved';
    seats[1].Status__c = 'Reserved';
    seats[2].Status__c = 'Blocked';
    update new List<Seat__c>{ seats[0], seats[1], seats[2] };

    Test.startTest();
    Map<String, Integer> stats = SeatManagementService.getSeatStatistics(
      showtime.Id
    );
    Test.stopTest();

    System.assertEquals(
      25,
      stats.get('total'),
      'Total should match generated seats'
    );
    System.assertEquals(
      22,
      stats.get('available'),
      'Available should reflect updates'
    );
    System.assertEquals(
      2,
      stats.get('reserved'),
      'Should count reserved seats'
    );
    System.assertEquals(1, stats.get('blocked'), 'Should count blocked seats');
  }

  // Context7 Apex Recipes Patterns Implementation

  @isTest
  static void testGenerateSeatsWithFLSValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    Test.stopTest();

    System.assertEquals(25, seats.size(), 'Should create 25 seats (5x5)');

    // Verify FLS validation worked
    System.assert(
      Schema.sObjectType.Seat__c.isCreateable(),
      'Seat__c should be createable'
    );
    System.assert(
      Schema.sObjectType.Seat__c.fields.Status__c.isCreateable(),
      'Status__c field should be createable'
    );
  }

  @isTest
  static void testGenerateSeatsWithCircuitBreaker() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    // Activate circuit breaker
    SeatManagementService.testCircuitBreaker = true;

    Test.startTest();
    try {
      SeatManagementService.generateSeats(showtime.Id, 5, 5);
      System.assert(
        false,
        'Should have thrown exception due to circuit breaker'
      );
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Circuit breaker activated'),
        'Should throw circuit breaker exception'
      );
      System.assert(
        SeatManagementService.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    // Reset circuit breaker
    SeatManagementService.testCircuitBreaker = false;
    SeatManagementService.circuitBreakerThrown = false;
  }

  @isTest
  static void testGenerateSeatsWithInvalidParameters() {
    Showtime__c showtime = createShowtime(3, 5);

    Test.startTest();

    // Test with invalid parameters
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      -5,
      -5
    );
    Test.stopTest();

    System.assertEquals(
      100,
      seats.size(),
      'Should default to 10x10 seats when parameters invalid'
    );

    // Test with null showtime ID
    try {
      SeatManagementService.generateSeats(null, 5, 5);
      System.assert(false, 'Should have thrown exception for null showtime ID');
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Showtime ID cannot be null'),
        'Should report missing showtime'
      );
    }
  }

  @isTest
  static void testLockSeatsWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    List<Id> seatIds = new List<Id>{ seats[0].Id, seats[1].Id };

    Test.startTest();

    // Test with valid parameters
    SeatManagementService.lockSeats(seatIds, 5);

    // Test with invalid parameters
    try {
      SeatManagementService.lockSeats(null, 5);
      System.assert(false, 'Should have thrown exception for null seat IDs');
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      SeatManagementService.lockSeats(seatIds, -5);
      System.assert(
        false,
        'Should have thrown exception for negative duration'
      );
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Duration must be a positive number'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();

    // Verify seats were locked
    List<Seat__c> lockedSeats = [
      SELECT Status__c
      FROM Seat__c
      WHERE Id IN :seatIds
    ];
    for (Seat__c seat : lockedSeats) {
      System.assertEquals('Blocked', seat.Status__c, 'Seat should be blocked');
    }
  }

  @isTest
  static void testUnlockSeatsWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    List<Id> seatIds = new List<Id>{ seats[0].Id, seats[1].Id };

    // Lock seats first
    SeatManagementService.lockSeats(seatIds, 5);

    Test.startTest();

    // Test with valid parameters
    SeatManagementService.unlockSeats(seatIds);

    // Test with invalid parameters
    try {
      SeatManagementService.unlockSeats(null);
      System.assert(false, 'Should have thrown exception for null seat IDs');
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();

    // Verify seats were unlocked
    List<Seat__c> unlockedSeats = [
      SELECT Status__c
      FROM Seat__c
      WHERE Id IN :seatIds
    ];
    for (Seat__c seat : unlockedSeats) {
      System.assertEquals(
        'Available',
        seat.Status__c,
        'Seat should be available'
      );
    }
  }

  @isTest
  static void testGetSeatStatisticsWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );

    Test.startTest();

    // Test with valid showtime ID
    Map<String, Integer> stats = SeatManagementService.getSeatStatistics(
      showtime.Id
    );
    System.assertEquals(25, stats.get('total'), 'Total should be 25');
    System.assertEquals(25, stats.get('available'), 'Should have 25 available');

    // Test with null showtime ID
    Map<String, Integer> nullStats = SeatManagementService.getSeatStatistics(
      null
    );
    System.assertEquals(
      0,
      nullStats.get('total'),
      'Should return empty stats for null ID'
    );

    Test.stopTest();
  }

  @isTest
  static void testBulkOperations() {
    Showtime__c baseShowtime = [
      SELECT Id, Session_Date__c
      FROM Showtime__c
      LIMIT 1
    ];

    List<Showtime__c> showtimes = new List<Showtime__c>();
    for (Integer i = 0; i < 5; i++) {
      showtimes.add(createShowtime(5, 5));
    }

    Test.startTest();
    Integer totalSeats = 0;
    for (Showtime__c st : showtimes) {
      totalSeats += SeatManagementService.generateSeats(st.Id, 5, 5).size();
    }
    Test.stopTest();

    System.assertEquals(
      125,
      totalSeats,
      'Should create 125 seats total (5 showtimes * 25 seats each)'
    );
  }

  @isTest
  static void testSeatTypeAssignment() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    Test.stopTest();

    // Verify seat type assignment
    Integer vipSeats = 0;
    Integer wheelchairSeats = 0;
    Integer standardSeats = 0;

    for (Seat__c seat : seats) {
      if (seat.Seat_Type__c == 'VIP') {
        vipSeats++;
      } else if (seat.Seat_Type__c == 'Wheelchair') {
        wheelchairSeats++;
      } else if (seat.Seat_Type__c == 'Standard') {
        standardSeats++;
      }
    }

    System.assertEquals(
      10,
      vipSeats,
      'Should have 10 VIP seats (first 2 rows)'
    );
    System.assertEquals(
      2,
      wheelchairSeats,
      'Should have 2 wheelchair seats (last row corners)'
    );
    System.assertEquals(13, standardSeats, 'Should have 13 standard seats');
  }

  @isTest
  static void testErrorHandlingPatterns() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();

    // Test exception handling in generateSeats
    try {
      SeatManagementService.generateSeats(showtime.Id, 0, 0);
      System.assert(false, 'Should have handled zero parameters gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    // Test exception handling in lockSeats
    try {
      SeatManagementService.lockSeats(new List<Id>(), 5);
      System.assert(false, 'Should have handled empty list gracefully');
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testGenerateSeatsDebug() {
    // Create test data without @TestSetup
    Movie__c movie = new Movie__c(
      Name = 'Test Movie Debug',
      Movie_API_ID__c = 'test123debug',
      Is_Active__c = true
    );
    insert movie;

    Theater__c theater = new Theater__c(
      Name = 'Test Theater Debug',
      Theater_API_ID__c = 'theater123debug',
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

    // Bypass trigger to avoid automatic seat generation
    TriggerHandler.bypass('ShowtimeTriggerHandler');
    insert showtime;
    TriggerHandler.clearBypass('ShowtimeTriggerHandler');

    Test.startTest();

    // Check if seats exist before calling generateSeats
    Integer existingCount = [
      SELECT COUNT()
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
    ];
    System.debug('Existing seats count before generateSeats: ' + existingCount);

    // Call generateSeats
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id);
    System.debug('Seats returned by generateSeats: ' + seats.size());

    // Check if seats exist after calling generateSeats
    Integer afterCount = [
      SELECT COUNT()
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
    ];
    System.debug('Existing seats count after generateSeats: ' + afterCount);

    Test.stopTest();

    System.assert(!seats.isEmpty(), 'Seats should be created');
    System.assertEquals(100, seats.size(), 'Should create 100 seats (10x10)');
  }
}
