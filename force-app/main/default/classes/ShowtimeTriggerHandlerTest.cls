/**
 * @description Test class for ShowtimeTriggerHandler
 * @author Cristiano Filho
 * @date 2025-09-30
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
    
    @isTest
    static void testAfterInsert_GeneratesSeats() {
        Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
        Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];
        
        Test.startTest();
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
        insert showtime;
        Test.stopTest();
        
        // Verify seats were automatically generated
        List<Seat__c> seats = [SELECT Id FROM Seat__c WHERE Showtime__c = :showtime.Id];
        System.assertEquals(100, seats.size(), 'Should auto-generate 100 seats');
    }
    
    @isTest
    static void testAfterInsert_MultipleShowtimes() {
        Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
        Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];
        
        List<Showtime__c> showtimes = new List<Showtime__c>();
        for (Integer i = 0; i < 3; i++) {
            showtimes.add(new Showtime__c(
                Movie__c = movie.Id,
                Theater__c = theater.Id,
                Session_Date__c = Date.today().addDays(i + 1),
                Session_Time__c = Time.newInstance(14, 30, 0, 0),
                Total_Seats__c = 100,
                Reserved_Seats__c = 0,
                Ticket_Price__c = 15.00,
                Status__c = 'Scheduled'
            ));
        }
        
        Test.startTest();
        insert showtimes;
        Test.stopTest();
        
        // Verify seats were generated for all showtimes
        for (Showtime__c st : showtimes) {
            List<Seat__c> seats = [SELECT Id FROM Seat__c WHERE Showtime__c = :st.Id];
            System.assertEquals(100, seats.size(), 'Each showtime should have 100 seats');
        }
    }
}

