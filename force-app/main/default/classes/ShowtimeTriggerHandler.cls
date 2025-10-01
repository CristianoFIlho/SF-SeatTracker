/**
 * @description Handler class for ShowtimeTrigger
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class ShowtimeTriggerHandler {
    
    /**
     * @description Handle after insert events
     * @param newShowtimes List of newly inserted showtimes
     */
    public static void handleAfterInsert(List<Showtime__c> newShowtimes) {
        generateSeatsForShowtimes(newShowtimes);
    }
    
    /**
     * @description Generate seats for newly created showtimes
     * @param showtimes List of showtimes
     */
    private static void generateSeatsForShowtimes(List<Showtime__c> showtimes) {
        for (Showtime__c showtime : showtimes) {
            try {
                // Generate 10x10 seat layout (100 seats)
                SeatManagementService.generateSeats(showtime.Id, 10, 10);
            } catch (Exception e) {
                System.debug('Error generating seats for showtime ' + showtime.Id + ': ' + e.getMessage());
            }
        }
    }
}

