/**
 * @description Controller for reservation operations
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class ReservationController {
    
    /**
     * @description Get available showtimes for a movie
     * @param movieId Movie record ID
     * @param selectedDate Date to search showtimes
     * @return List of Showtime__c with theater info
     */
    @AuraEnabled(cacheable=true)
    public static List<Showtime__c> getAvailableShowtimes(Id movieId, Date selectedDate) {
        try {
            return [
                SELECT Id, Name, Session_Date__c, Session_Time__c, Session_DateTime__c,
                       Available_Seats__c, Reserved_Seats__c, Total_Seats__c,
                       Ticket_Price__c, Is_3D__c, Is_IMAX__c, Language__c, Status__c,
                       Theater__c, Theater__r.Name, Theater__r.Address__c, 
                       Theater__r.City__c, Theater__r.Full_Address__c,
                       Theater__r.Location__Latitude__s, Theater__r.Location__Longitude__s,
                       Movie__c, Movie__r.Name
                FROM Showtime__c
                WHERE Movie__c = :movieId
                AND Session_Date__c = :selectedDate
                AND Available_Seats__c > 0
                AND Status__c = 'Scheduled'
                AND Session_DateTime__c > :System.now()
                ORDER BY Session_Time__c ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching showtimes: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get seat layout for a showtime
     * @param showtimeId Showtime record ID
     * @return List of Seat__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Seat__c> getSeatsForShowtime(Id showtimeId) {
        try {
            return [
                SELECT Id, Name, Row__c, Number__c, Status__c, Seat_Type__c, 
                       Is_Available__c, Showtime__c, Reservation__c
                FROM Seat__c
                WHERE Showtime__c = :showtimeId
                ORDER BY Row__c ASC, Number__c ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching seats: ' + e.getMessage());
        }
    }
    
    /**
     * @description Create reservation with selected seats
     * @param showtimeId Showtime record ID
     * @param seatIds List of selected Seat IDs
     * @param customerInfo JSON with customer details
     * @return Reservation__c record with confirmation code
     */
    @AuraEnabled
    public static Reservation__c createReservation(Id showtimeId, List<Id> seatIds, String customerInfo) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Parse customer info
            Map<String, Object> customerData = (Map<String, Object>) JSON.deserializeUntyped(customerInfo);
            
            // Validate seats are available
            List<Seat__c> selectedSeats = [
                SELECT Id, Status__c, Row__c, Number__c, Showtime__c
                FROM Seat__c
                WHERE Id IN :seatIds
                AND Showtime__c = :showtimeId
                FOR UPDATE
            ];
            
            if (selectedSeats.size() != seatIds.size()) {
                throw new ReservationException('Some seats were not found.');
            }
            
            for (Seat__c seat : selectedSeats) {
                if (seat.Status__c != 'Available') {
                    throw new ReservationException('Seat ' + seat.Row__c + '-' + seat.Number__c + ' is no longer available.');
                }
            }
            
            // Get showtime details
            Showtime__c showtime = [
                SELECT Id, Movie__c, Theater__c, Ticket_Price__c, Reserved_Seats__c, 
                       Available_Seats__c, Total_Seats__c
                FROM Showtime__c
                WHERE Id = :showtimeId
                FOR UPDATE
            ];
            
            // Create reservation
            Reservation__c reservation = new Reservation__c();
            reservation.Showtime__c = showtimeId;
            reservation.Movie__c = showtime.Movie__c;
            reservation.Customer_Name__c = String.valueOf(customerData.get('name'));
            reservation.Customer_Email__c = String.valueOf(customerData.get('email'));
            reservation.Customer_Phone__c = String.valueOf(customerData.get('phone'));
            reservation.Number_of_Seats__c = seatIds.size();
            reservation.Total_Amount__c = showtime.Ticket_Price__c * seatIds.size();
            reservation.Status__c = 'Confirmed';
            reservation.Payment_Status__c = 'Pending';
            reservation.Confirmation_Code__c = generateConfirmationCode();
            
            // Build seat numbers string
            List<String> seatNames = new List<String>();
            for (Seat__c seat : selectedSeats) {
                seatNames.add(seat.Row__c + '-' + seat.Number__c);
            }
            reservation.Seat_Numbers__c = String.join(seatNames, ', ');
            
            insert reservation;
            
            // Update seats to Reserved
            for (Seat__c seat : selectedSeats) {
                seat.Status__c = 'Reserved';
                seat.Reservation__c = reservation.Id;
            }
            update selectedSeats;
            
            // Update showtime reserved count
            showtime.Reserved_Seats__c = showtime.Reserved_Seats__c + seatIds.size();
            update showtime;
            
            // Send confirmation email asynchronously
            sendConfirmationEmailAsync(reservation.Id);
            
            return reservation;
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error creating reservation: ' + e.getMessage());
        }
    }
    
    /**
     * @description Cancel an existing reservation
     * @param reservationId Reservation record ID
     * @return Boolean success indicator
     */
    @AuraEnabled
    public static Boolean cancelReservation(Id reservationId) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            Reservation__c reservation = [
                SELECT Id, Status__c, Showtime__c, Showtime__r.Session_DateTime__c,
                       Number_of_Seats__c
                FROM Reservation__c
                WHERE Id = :reservationId
                FOR UPDATE
            ];
            
            // Validate cancellation is allowed
            if (reservation.Status__c == 'Cancelled') {
                throw new ReservationException('Reservation is already cancelled.');
            }
            
            if (reservation.Status__c == 'Completed') {
                throw new ReservationException('Cannot cancel completed reservation.');
            }
            
            // Check if within 2 hours of showtime
            Datetime showtimeStart = reservation.Showtime__r.Session_DateTime__c;
            Datetime now = System.now();
            Long hoursDiff = (showtimeStart.getTime() - now.getTime()) / (1000 * 60 * 60);
            
            if (hoursDiff < 2) {
                throw new ReservationException('Cannot cancel reservation within 2 hours of showtime.');
            }
            
            // Release seats
            List<Seat__c> seats = [
                SELECT Id, Status__c
                FROM Seat__c
                WHERE Reservation__c = :reservationId
                FOR UPDATE
            ];
            
            for (Seat__c seat : seats) {
                seat.Status__c = 'Available';
                seat.Reservation__c = null;
            }
            update seats;
            
            // Update showtime count
            Showtime__c showtime = [
                SELECT Id, Reserved_Seats__c
                FROM Showtime__c
                WHERE Id = :reservation.Showtime__c
                FOR UPDATE
            ];
            showtime.Reserved_Seats__c = showtime.Reserved_Seats__c - reservation.Number_of_Seats__c;
            update showtime;
            
            // Update reservation status
            reservation.Status__c = 'Cancelled';
            reservation.Payment_Status__c = 'Refunded';
            update reservation;
            
            return true;
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error cancelling reservation: ' + e.getMessage());
        }
    }
    
    /**
     * @description Send confirmation email to customer (async wrapper)
     * @param reservationId Reservation record ID
     */
    @future
    private static void sendConfirmationEmailAsync(Id reservationId) {
        try {
            sendConfirmationEmail(reservationId);
        } catch (Exception e) {
            System.debug('Error sending confirmation email: ' + e.getMessage());
        }
    }
    
    /**
     * @description Send confirmation email to customer
     * @param reservationId Reservation record ID
     */
    private static void sendConfirmationEmail(Id reservationId) {
        Reservation__c reservation = [
            SELECT Id, Name, Confirmation_Code__c, Customer_Name__c, Customer_Email__c,
                   Seat_Numbers__c, Number_of_Seats__c, Total_Amount__c,
                   Movie__r.Name, Showtime__r.Session_DateTime__c, Showtime__r.Theater__r.Name,
                   Showtime__r.Theater__r.Full_Address__c
            FROM Reservation__c
            WHERE Id = :reservationId
        ];
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ reservation.Customer_Email__c });
        email.setSubject('Cinema Reservation Confirmation - ' + reservation.Confirmation_Code__c);
        
        String emailBody = 'Dear ' + reservation.Customer_Name__c + ',\n\n';
        emailBody += 'Your reservation has been confirmed!\n\n';
        emailBody += 'Confirmation Code: ' + reservation.Confirmation_Code__c + '\n';
        emailBody += 'Movie: ' + reservation.Movie__r.Name + '\n';
        emailBody += 'Theater: ' + reservation.Showtime__r.Theater__r.Name + '\n';
        emailBody += 'Address: ' + reservation.Showtime__r.Theater__r.Full_Address__c + '\n';
        emailBody += 'Showtime: ' + reservation.Showtime__r.Session_DateTime__c.format() + '\n';
        emailBody += 'Seats: ' + reservation.Seat_Numbers__c + '\n';
        emailBody += 'Number of Tickets: ' + reservation.Number_of_Seats__c + '\n';
        emailBody += 'Total Amount: $' + reservation.Total_Amount__c + '\n\n';
        emailBody += 'Please arrive 15 minutes before showtime.\n\n';
        emailBody += 'Thank you for choosing our cinema!\n';
        
        email.setPlainTextBody(emailBody);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
    
    /**
     * @description Generate unique confirmation code
     * @return String confirmation code (e.g., "ABC123XYZ")
     */
    private static String generateConfirmationCode() {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String code = '';
        
        while (true) {
            code = '';
            for (Integer i = 0; i < 9; i++) {
                Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
                code += chars.substring(idx, idx + 1);
            }
            
            // Check uniqueness
            List<Reservation__c> existing = [
                SELECT Id 
                FROM Reservation__c 
                WHERE Confirmation_Code__c = :code 
                LIMIT 1
            ];
            
            if (existing.isEmpty()) {
                break;
            }
        }
        
        return code;
    }
    
    /**
     * @description Custom exception class for reservation errors
     */
    public class ReservationException extends Exception {}
}

