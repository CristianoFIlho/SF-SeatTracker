/**
 * @description Test class for ShowtimeTriggerHandler following Context7 best practices
 */
@isTest
private class ShowtimeTriggerHandlerTest {

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
  }

  private static Showtime__c createShowtime(Date sessionDate) {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
    Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];

    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = sessionDate,
      Session_Time__c = Time.newInstance(14, 30, 0, 0),
      Total_Seats__c = 100,
      Reserved_Seats__c = 0,
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled'
    );
    insert showtime;
    return showtime;
  }

  @isTest
  static void testAfterInsertGeneratesSeats() {
    Test.startTest();
    Showtime__c showtime = createShowtime(Date.today().addDays(1));
    Test.stopTest();

    List<Seat__c> seats = [
      SELECT Seat_Type__c
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
    ];
    System.assertEquals(100, seats.size(), 'Should create 100 seats');
  }

  @isTest
  static void testMultipleShowtimesGenerateSeats() {
    Test.startTest();
    List<Showtime__c> showtimes = new List<Showtime__c>();
    for (Integer i = 1; i <= 3; i++) {
      showtimes.add(
        new Showtime__c(
          Movie__c = [SELECT Id FROM Movie__c LIMIT 1].Id,
          Theater__c = [SELECT Id FROM Theater__c LIMIT 1].Id,
          Session_Date__c = Date.today().addDays(i),
          Session_Time__c = Time.newInstance(10 + i, 0, 0, 0),
          Total_Seats__c = 100,
          Reserved_Seats__c = 0,
          Ticket_Price__c = 20.00,
          Status__c = 'Scheduled'
        )
      );
    }
    insert showtimes;
    Test.stopTest();

    Integer seatCount = [SELECT COUNT() FROM Seat__c];
    System.assertEquals(300, seatCount, 'Each showtime should create 100 seats');
  }

  @isTest
  static void testBypassFunctionality() {
    System.assertEquals(
      false,
      TriggerHandler.isHandlerBypassed('ShowtimeTriggerHandler'),
      'Handler should not be bypassed initially'
    );

    TriggerHandler.bypass('ShowtimeTriggerHandler');
    System.assertEquals(
      true,
      TriggerHandler.isHandlerBypassed('ShowtimeTriggerHandler'),
      'Handler should be bypassed after bypass call'
    );

    TriggerHandler.clearBypass('ShowtimeTriggerHandler');
    System.assertEquals(
      false,
      TriggerHandler.isHandlerBypassed('ShowtimeTriggerHandler'),
      'Handler should no longer be bypassed after clear'
    );
  }
}
