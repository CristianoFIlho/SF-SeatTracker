/**
 * @description Service for seat generation and management
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class SeatManagementService {
    
    private static final String[] ROWS = new String[]{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'};
    
    /**
     * @description Generate seats for a showtime
     * @param showtimeId Showtime record ID
     * @param rows Number of rows (default 10)
     * @param seatsPerRow Number of seats per row (default 10)
     * @return List of created Seat__c records
     */
    public static List<Seat__c> generateSeats(Id showtimeId, Integer numRows, Integer seatsPerRow) {
        List<Seat__c> seatsToInsert = new List<Seat__c>();
        
        try {
            // Validate parameters
            if (numRows == null || numRows <= 0) {
                numRows = 10;
            }
            if (seatsPerRow == null || seatsPerRow <= 0) {
                seatsPerRow = 10;
            }
            
            // Check if seats already exist for this showtime
            Integer existingCount = [
                SELECT COUNT() 
                FROM Seat__c 
                WHERE Showtime__c = :showtimeId
            ];
            
            if (existingCount > 0) {
                System.debug('Seats already exist for showtime: ' + showtimeId);
                return new List<Seat__c>();
            }
            
            // Generate seat matrix
            for (Integer row = 0; row < numRows && row < ROWS.size(); row++) {
                String rowLetter = ROWS[row];
                
                for (Integer seatNum = 1; seatNum <= seatsPerRow; seatNum++) {
                    Seat__c seat = new Seat__c();
                    seat.Showtime__c = showtimeId;
                    seat.Row__c = rowLetter;
                    seat.Number__c = seatNum;
                    seat.Name = rowLetter + '-' + seatNum;
                    seat.Status__c = 'Available';
                    
                    // Assign seat types (VIP for front rows, Wheelchair for specific seats)
                    if (row < 2) {
                        seat.Seat_Type__c = 'VIP';
                    } else if (row == numRows - 1 && (seatNum == 1 || seatNum == seatsPerRow)) {
                        seat.Seat_Type__c = 'Wheelchair';
                    } else {
                        seat.Seat_Type__c = 'Standard';
                    }
                    
                    seatsToInsert.add(seat);
                }
            }
            
            // Bulk insert all seats
            if (!seatsToInsert.isEmpty()) {
                insert seatsToInsert;
                System.debug('Successfully created ' + seatsToInsert.size() + ' seats for showtime: ' + showtimeId);
            }
            
        } catch (Exception e) {
            System.debug('Error generating seats: ' + e.getMessage());
            throw new SeatManagementException('Failed to generate seats: ' + e.getMessage());
        }
        
        return seatsToInsert;
    }
    
    /**
     * @description Lock seats temporarily during reservation process
     * @param seatIds List of Seat IDs to lock
     * @param durationMinutes Duration in minutes
     */
    public static void lockSeats(List<Id> seatIds, Integer durationMinutes) {
        try {
            List<Seat__c> seatsToLock = [
                SELECT Id, Status__c
                FROM Seat__c
                WHERE Id IN :seatIds
                AND Status__c = 'Available'
                FOR UPDATE
            ];
            
            for (Seat__c seat : seatsToLock) {
                seat.Status__c = 'Blocked';
            }
            
            update seatsToLock;
            
            // Schedule unlock job (simplified for MVP - in production use Queueable or Schedulable)
            System.debug('Seats locked: ' + seatsToLock.size() + ' for ' + durationMinutes + ' minutes');
            
        } catch (Exception e) {
            System.debug('Error locking seats: ' + e.getMessage());
            throw new SeatManagementException('Failed to lock seats: ' + e.getMessage());
        }
    }
    
    /**
     * @description Unlock seats that were previously locked
     * @param seatIds List of Seat IDs to unlock
     */
    public static void unlockSeats(List<Id> seatIds) {
        try {
            List<Seat__c> seatsToUnlock = [
                SELECT Id, Status__c, Reservation__c
                FROM Seat__c
                WHERE Id IN :seatIds
                AND Status__c = 'Blocked'
                AND Reservation__c = null
                FOR UPDATE
            ];
            
            for (Seat__c seat : seatsToUnlock) {
                seat.Status__c = 'Available';
            }
            
            update seatsToUnlock;
            System.debug('Seats unlocked: ' + seatsToUnlock.size());
            
        } catch (Exception e) {
            System.debug('Error unlocking seats: ' + e.getMessage());
            throw new SeatManagementException('Failed to unlock seats: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get seat availability statistics for a showtime
     * @param showtimeId Showtime record ID
     * @return Map with availability statistics
     */
    public static Map<String, Integer> getSeatStatistics(Id showtimeId) {
        Map<String, Integer> stats = new Map<String, Integer>();
        
        try {
            AggregateResult[] results = [
                SELECT Status__c, COUNT(Id) seatCount
                FROM Seat__c
                WHERE Showtime__c = :showtimeId
                GROUP BY Status__c
            ];
            
            stats.put('total', 0);
            stats.put('available', 0);
            stats.put('reserved', 0);
            stats.put('occupied', 0);
            stats.put('blocked', 0);
            
            for (AggregateResult ar : results) {
                String status = String.valueOf(ar.get('Status__c'));
                Integer count = Integer.valueOf(ar.get('seatCount'));
                stats.put(status.toLowerCase(), count);
                stats.put('total', stats.get('total') + count);
            }
            
        } catch (Exception e) {
            System.debug('Error getting seat statistics: ' + e.getMessage());
        }
        
        return stats;
    }
    
    /**
     * @description Custom exception class for seat management errors
     */
    public class SeatManagementException extends Exception {}
}

