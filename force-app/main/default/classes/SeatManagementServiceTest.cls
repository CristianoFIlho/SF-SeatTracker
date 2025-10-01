/**
 * @description Test class for SeatManagementService
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
        insert showtime;
    }
    
    @isTest
    static void testGenerateSeats_Default() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        
        Test.startTest();
        List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 10, 10);
        Test.stopTest();
        
        System.assertEquals(100, seats.size(), 'Should create 100 seats (10x10)');
        
        // Verify seats are created correctly
        List<Seat__c> createdSeats = [SELECT Row__c, Number__c, Status__c, Seat_Type__c FROM Seat__c WHERE Showtime__c = :showtime.Id ORDER BY Row__c, Number__c];
        System.assertEquals(100, createdSeats.size(), 'Should have 100 seats in database');
        System.assertEquals('A', createdSeats[0].Row__c, 'First seat should be row A');
        System.assertEquals(1, createdSeats[0].Number__c, 'First seat should be number 1');
        System.assertEquals('Available', createdSeats[0].Status__c, 'Seats should be available');
        System.assertEquals('VIP', createdSeats[0].Seat_Type__c, 'Front row should be VIP');
    }
    
    @isTest
    static void testGenerateSeats_CustomSize() {
        Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
        Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];
        
        Showtime__c newShowtime = new Showtime__c(
            Movie__c = movie.Id,
            Theater__c = theater.Id,
            Session_Date__c = Date.today().addDays(2),
            Session_Time__c = Time.newInstance(19, 0, 0, 0),
            Total_Seats__c = 50,
            Reserved_Seats__c = 0,
            Ticket_Price__c = 20.00,
            Status__c = 'Scheduled'
        );
        insert newShowtime;
        
        Test.startTest();
        List<Seat__c> seats = SeatManagementService.generateSeats(newShowtime.Id, 5, 10);
        Test.stopTest();
        
        System.assertEquals(50, seats.size(), 'Should create 50 seats (5x10)');
    }
    
    @isTest
    static void testGenerateSeats_AlreadyExists() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        
        // Generate seats first time
        SeatManagementService.generateSeats(showtime.Id, 10, 10);
        
        Test.startTest();
        // Try to generate again
        List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 10, 10);
        Test.stopTest();
        
        System.assertEquals(0, seats.size(), 'Should not create duplicate seats');
    }
    
    @isTest
    static void testLockSeats() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 10, 10);
        List<Id> seatIds = new List<Id>{seats[0].Id, seats[1].Id, seats[2].Id};
        
        Test.startTest();
        SeatManagementService.lockSeats(seatIds, 5);
        Test.stopTest();
        
        List<Seat__c> lockedSeats = [SELECT Status__c FROM Seat__c WHERE Id IN :seatIds];
        for (Seat__c seat : lockedSeats) {
            System.assertEquals('Blocked', seat.Status__c, 'Seat should be blocked');
        }
    }
    
    @isTest
    static void testUnlockSeats() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 10, 10);
        List<Id> seatIds = new List<Id>{seats[0].Id, seats[1].Id};
        
        // Lock seats first
        SeatManagementService.lockSeats(seatIds, 5);
        
        Test.startTest();
        SeatManagementService.unlockSeats(seatIds);
        Test.stopTest();
        
        List<Seat__c> unlockedSeats = [SELECT Status__c FROM Seat__c WHERE Id IN :seatIds];
        for (Seat__c seat : unlockedSeats) {
            System.assertEquals('Available', seat.Status__c, 'Seat should be available');
        }
    }
    
    @isTest
    static void testGetSeatStatistics() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 10, 10);
        
        // Reserve some seats
        seats[0].Status__c = 'Reserved';
        seats[1].Status__c = 'Reserved';
        seats[2].Status__c = 'Blocked';
        update new List<Seat__c>{seats[0], seats[1], seats[2]};
        
        Test.startTest();
        Map<String, Integer> stats = SeatManagementService.getSeatStatistics(showtime.Id);
        Test.stopTest();
        
        System.assertEquals(100, stats.get('total'), 'Total should be 100');
        System.assertEquals(97, stats.get('available'), 'Should have 97 available');
        System.assertEquals(2, stats.get('reserved'), 'Should have 2 reserved');
        System.assertEquals(1, stats.get('blocked'), 'Should have 1 blocked');
    }
}

