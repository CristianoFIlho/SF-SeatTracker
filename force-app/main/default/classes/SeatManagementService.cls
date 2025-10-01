/**
 * @description Service for seat generation and management
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class SeatManagementService {
    
    private static final String[] ROWS = new String[]{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'};
    
    /**
     * @description Generate seats for a showtime using theater configuration
     * @param showtimeId Showtime record ID
     * @return List of created Seat__c records
     */
    public static List<Seat__c> generateSeats(Id showtimeId) {
        return generateSeats(showtimeId, null, null);
    }
    
    /**
     * @description Generate seats for a showtime
     * @param showtimeId Showtime record ID
     * @param numRows Number of rows (optional - will use theater config if null)
     * @param seatsPerRow Number of seats per row (optional - will use theater config if null)
     * @return List of created Seat__c records
     */
    public static List<Seat__c> generateSeats(Id showtimeId, Integer numRows, Integer seatsPerRow) {
        List<Seat__c> seatsToInsert = new List<Seat__c>();
        
        try {
            // Get theater configuration if parameters are not provided
            if (numRows == null || seatsPerRow == null) {
                System.debug('Getting theater configuration for showtime: ' + showtimeId);
                Showtime__c showtime = [
                    SELECT Id, Theater__c, Theater__r.Number_of_Rows__c, 
                           Theater__r.Seats_Per_Row__c, Theater__r.Seat_Layout_Type__c
                    FROM Showtime__c
                    WHERE Id = :showtimeId
                    LIMIT 1
                ];
                
                System.debug('Theater config - Rows: ' + showtime.Theater__r.Number_of_Rows__c + 
                           ', Seats per row: ' + showtime.Theater__r.Seats_Per_Row__c + 
                           ', Layout: ' + showtime.Theater__r.Seat_Layout_Type__c);
                
                if (numRows == null) {
                    numRows = showtime.Theater__r.Number_of_Rows__c != null ? 
                             Integer.valueOf(showtime.Theater__r.Number_of_Rows__c) : 10;
                }
                if (seatsPerRow == null) {
                    seatsPerRow = showtime.Theater__r.Seats_Per_Row__c != null ? 
                                 Integer.valueOf(showtime.Theater__r.Seats_Per_Row__c) : 10;
                }
            }
            
            // Validate parameters
            if (numRows <= 0) {
                numRows = 10;
            }
            if (seatsPerRow <= 0) {
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
            
            // Get theater layout type for seat configuration
            String layoutType = 'Standard';
            if (numRows == null || seatsPerRow == null) {
                Showtime__c showtime = [
                    SELECT Theater__r.Seat_Layout_Type__c
                    FROM Showtime__c
                    WHERE Id = :showtimeId
                    LIMIT 1
                ];
                layoutType = showtime.Theater__r.Seat_Layout_Type__c != null ? 
                            showtime.Theater__r.Seat_Layout_Type__c : 'Standard';
            }
            
            // Generate seat matrix with dynamic row letters
            String[] rowLetters = generateRowLetters(numRows);
            
            for (Integer row = 0; row < numRows; row++) {
                String rowLetter = rowLetters[row];
                
                for (Integer seatNum = 1; seatNum <= seatsPerRow; seatNum++) {
                    Seat__c seat = new Seat__c();
                    seat.Showtime__c = showtimeId;
                    seat.Row__c = rowLetter;
                    seat.Number__c = seatNum;
                    seat.Name = rowLetter + '-' + seatNum;
                    seat.Status__c = 'Available';
                    
                    // Assign seat types based on layout type
                    seat.Seat_Type__c = determineSeatType(layoutType, row, seatNum, numRows, seatsPerRow);
                    
                    seatsToInsert.add(seat);
                }
            }
            
            // Bulk insert all seats
            if (!seatsToInsert.isEmpty()) {
                System.debug('About to insert ' + seatsToInsert.size() + ' seats for showtime: ' + showtimeId);
                insert seatsToInsert;
                System.debug('Successfully created ' + seatsToInsert.size() + ' seats for showtime: ' + showtimeId);
            } else {
                System.debug('No seats to insert for showtime: ' + showtimeId);
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
     * @description Generate row letters dynamically based on number of rows
     * @param numRows Number of rows
     * @return Array of row letters
     */
    private static String[] generateRowLetters(Integer numRows) {
        String[] rowLetters = new String[]{};
        
        // Generate letters A-Z, then AA-ZZ, etc.
        for (Integer i = 0; i < numRows; i++) {
            String rowLetter = '';
            Integer temp = i;
            
            do {
                rowLetter = String.fromCharArray(new Integer[]{65 + Math.mod(temp, 26)}) + rowLetter;
                temp = temp / 26;
            } while (temp > 0);
            
            rowLetters.add(rowLetter);
        }
        
        return rowLetters;
    }
    
    /**
     * @description Determine seat type based on layout and position
     * @param layoutType Theater layout type
     * @param row Row index (0-based)
     * @param seatNum Seat number
     * @param totalRows Total number of rows
     * @param seatsPerRow Seats per row
     * @return Seat type string
     */
    private static String determineSeatType(String layoutType, Integer row, Integer seatNum, Integer totalRows, Integer seatsPerRow) {
        switch on layoutType {
            when 'VIP' {
                // VIP layout: front 3 rows are VIP, back row has wheelchair accessible seats
                if (row < 3) {
                    return 'VIP';
                } else if (row == totalRows - 1 && (seatNum == 1 || seatNum == seatsPerRow)) {
                    return 'Wheelchair';
                } else {
                    return 'Premium';
                }
            }
            when 'IMAX' {
                // IMAX layout: larger theater with more VIP seats
                if (row < 4) {
                    return 'VIP';
                } else if (row < totalRows - 2) {
                    return 'Premium';
                } else if (row == totalRows - 1 && (seatNum == 1 || seatNum == seatsPerRow)) {
                    return 'Wheelchair';
                } else {
                    return 'Standard';
                }
            }
            when 'Premium' {
                // Premium layout: front 2 rows VIP, middle rows Premium, back rows Standard
                if (row < 2) {
                    return 'VIP';
                } else if (row < totalRows - 2) {
                    return 'Premium';
                } else if (row == totalRows - 1 && (seatNum == 1 || seatNum == seatsPerRow)) {
                    return 'Wheelchair';
                } else {
                    return 'Standard';
                }
            }
            when else { // Standard
                // Standard layout: front row VIP, back row wheelchair accessible
                if (row < 1) {
                    return 'VIP';
                } else if (row == totalRows - 1 && (seatNum == 1 || seatNum == seatsPerRow)) {
                    return 'Wheelchair';
                } else {
                    return 'Standard';
                }
            }
        }
    }
    
    /**
     * @description Custom exception class for seat management errors
     */
    public class SeatManagementException extends Exception {}
}

