/**
 * @description Test class for ReservationController
 * @author Cristiano Filho
 * @date 2025-09-30
 */
@isTest
private class ReservationControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create movie
        Movie__c movie = new Movie__c(
            Name = 'Test Movie',
            Movie_API_ID__c = 'test123',
            Is_Active__c = true
        );
        insert movie;
        
        // Create theater
        Theater__c theater = new Theater__c(
            Name = 'Test Theater',
            Theater_API_ID__c = 'theater123',
            City__c = 'Test City',
            Is_Active__c = true
        );
        insert theater;
        
        // Create showtime
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
        
        // Create seats
        List<Seat__c> seats = new List<Seat__c>();
        for (Integer i = 1; i <= 10; i++) {
            seats.add(new Seat__c(
                Showtime__c = showtime.Id,
                Row__c = 'A',
                Number__c = i,
                Name = 'A-' + i,
                Status__c = 'Available',
                Seat_Type__c = 'Standard'
            ));
        }
        insert seats;
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
        System.assertEquals(100, showtimes[0].Available_Seats__c, 'Should have 100 available seats');
    }
    
    @isTest
    static void testGetSeatsForShowtime() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        
        Test.startTest();
        List<Seat__c> seats = ReservationController.getSeatsForShowtime(showtime.Id);
        Test.stopTest();
        
        System.assertEquals(10, seats.size(), 'Should return 10 seats');
        System.assertEquals('Available', seats[0].Status__c, 'Seats should be available');
    }
    
    @isTest
    static void testCreateReservation_Success() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        List<Seat__c> seats = [SELECT Id FROM Seat__c WHERE Showtime__c = :showtime.Id LIMIT 2];
        
        String customerInfo = '{"name":"John Doe","email":"john@test.com","phone":"1234567890"}';
        
        Test.startTest();
        Reservation__c reservation = ReservationController.createReservation(
            showtime.Id,
            new List<Id>{seats[0].Id, seats[1].Id},
            customerInfo
        );
        Test.stopTest();
        
        System.assertNotEquals(null, reservation.Id, 'Reservation should be created');
        System.assertEquals('John Doe', reservation.Customer_Name__c, 'Customer name should match');
        System.assertEquals(2, reservation.Number_of_Seats__c, 'Should have 2 seats');
        System.assertEquals(30.00, reservation.Total_Amount__c, 'Total should be $30.00');
        System.assertNotEquals(null, reservation.Confirmation_Code__c, 'Should have confirmation code');
        
        // Verify seats are reserved
        List<Seat__c> updatedSeats = [SELECT Status__c FROM Seat__c WHERE Id IN :new List<Id>{seats[0].Id, seats[1].Id}];
        for (Seat__c seat : updatedSeats) {
            System.assertEquals('Reserved', seat.Status__c, 'Seat should be reserved');
        }
    }
    
    @isTest
    static void testCreateReservation_SeatNotAvailable() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        List<Seat__c> seats = [SELECT Id FROM Seat__c WHERE Showtime__c = :showtime.Id LIMIT 1];
        
        // Reserve the seat first
        seats[0].Status__c = 'Reserved';
        update seats[0];
        
        String customerInfo = '{"name":"Jane Doe","email":"jane@test.com","phone":"9876543210"}';
        
        Test.startTest();
        try {
            ReservationController.createReservation(
                showtime.Id,
                new List<Id>{seats[0].Id},
                customerInfo
            );
            System.assert(false, 'Should throw exception for unavailable seat');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('no longer available'), 'Should mention seat unavailability');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCancelReservation_Success() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        List<Seat__c> seats = [SELECT Id FROM Seat__c WHERE Showtime__c = :showtime.Id LIMIT 2];
        
        // Create reservation
        String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';
        Reservation__c reservation = ReservationController.createReservation(
            showtime.Id,
            new List<Id>{seats[0].Id, seats[1].Id},
            customerInfo
        );
        
        Test.startTest();
        Boolean result = ReservationController.cancelReservation(reservation.Id);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Cancellation should succeed');
        
        // Verify reservation is cancelled
        Reservation__c cancelledRes = [SELECT Status__c, Payment_Status__c FROM Reservation__c WHERE Id = :reservation.Id];
        System.assertEquals('Cancelled', cancelledRes.Status__c, 'Status should be Cancelled');
        System.assertEquals('Refunded', cancelledRes.Payment_Status__c, 'Payment should be Refunded');
        
        // Verify seats are released
        List<Seat__c> releasedSeats = [SELECT Status__c, Reservation__c FROM Seat__c WHERE Id IN :new List<Id>{seats[0].Id, seats[1].Id}];
        for (Seat__c seat : releasedSeats) {
            System.assertEquals('Available', seat.Status__c, 'Seat should be available');
            System.assertEquals(null, seat.Reservation__c, 'Seat should have no reservation');
        }
    }
    
    @isTest
    static void testCancelReservation_AlreadyCancelled() {
        Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
        List<Seat__c> seats = [SELECT Id FROM Seat__c WHERE Showtime__c = :showtime.Id LIMIT 1];
        
        String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';
        Reservation__c reservation = ReservationController.createReservation(
            showtime.Id,
            new List<Id>{seats[0].Id},
            customerInfo
        );
        
        // Cancel once
        ReservationController.cancelReservation(reservation.Id);
        
        Test.startTest();
        try {
            ReservationController.cancelReservation(reservation.Id);
            System.assert(false, 'Should throw exception for already cancelled reservation');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('already cancelled'), 'Should mention already cancelled');
        }
        Test.stopTest();
    }
}

