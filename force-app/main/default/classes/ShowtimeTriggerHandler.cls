/**
 * @description Handler class for ShowtimeTrigger. Handles seat generation in a bulk-safe manner.
 * @author Cristiano Filho
 * @date 2025-10-01
 */
public with sharing class ShowtimeTriggerHandler {

    private static final String[] ROWS = new String[]{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'};
    private static final Integer SEATS_PER_ROW = 10;

    /**
     * @description Handle after insert events to generate seats for new showtimes.
     * @param newShowtimes List of newly inserted showtimes from the trigger context.
     */
    public static void handleAfterInsert(List<Showtime__c> newShowtimes) {
        Set<Id> showtimeIds = new Set<Id>();
        for (Showtime__c st : newShowtimes) {
            showtimeIds.add(st.Id);
        }

        // Find which showtimes already have seats to avoid creating duplicates.
        Set<Id> showtimesWithExistingSeats = new Set<Id>();
        for (AggregateResult ar : [
            SELECT COUNT(Id) seatCount, Showtime__c 
            FROM Seat__c 
            WHERE Showtime__c IN :showtimeIds 
            GROUP BY Showtime__c
        ]) {
            showtimesWithExistingSeats.add((Id)ar.get('Showtime__c'));
        }

        List<Seat__c> seatsToInsert = new List<Seat__c>();
        for (Showtime__c showtime : newShowtimes) {
            // Only generate seats if none exist for this showtime.
            if (!showtimesWithExistingSeats.contains(showtime.Id)) {
                seatsToInsert.addAll(createSeatsForShowtime(showtime));
            }
        }

        if (!seatsToInsert.isEmpty()) {
            try {
                insert seatsToInsert;
            } catch (Exception e) {
                System.debug('Error bulk inserting seats: ' + e.getMessage());
                // Optionally, add error handling to the records themselves.
            }
        }
    }

    /**
     * @description Creates a list of Seat__c records for a single showtime without inserting them.
     * @param showtime The Showtime__c record to generate seats for.
     * @return A list of new Seat__c records.
     */
    private static List<Seat__c> createSeatsForShowtime(Showtime__c showtime) {
        List<Seat__c> seats = new List<Seat__c>();
        Integer numRows = ROWS.size();

        for (Integer row = 0; row < numRows; row++) {
            String rowLetter = ROWS[row];
            for (Integer seatNum = 1; seatNum <= SEATS_PER_ROW; seatNum++) {
                Seat__c seat = new Seat__c(
                    Showtime__c = showtime.Id,
                    Row__c = rowLetter,
                    Number__c = seatNum,
                    Name = rowLetter + '-' + seatNum,
                    Status__c = 'Available'
                );

                // Assign seat types (example logic)
                if (row < 2) {
                    seat.Seat_Type__c = 'VIP';
                } else if (row == numRows - 1 && (seatNum == 1 || seatNum == SEATS_PER_ROW)) {
                    seat.Seat_Type__c = 'Wheelchair';
                } else {
                    seat.Seat_Type__c = 'Standard';
                }
                seats.add(seat);
            }
        }
        return seats;
    }
}

