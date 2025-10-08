/**
 * @description Handler class for ShowtimeTrigger following Context7 best practices.
 * Handles seat generation in a bulk-safe manner with proper security and error handling.
 * @author Refactored based on Context7 Apex Recipes patterns
 * @date 2025-01-27
 */
public with sharing class ShowtimeTriggerHandler {
  private static final String[] ROWS = new List<String>{
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J'
  };
  private static final Integer SEATS_PER_ROW = 10;
  private static final Integer MAX_SEATS_PER_SHOWTIME = 200; // Governor limit protection

  /**
   * @description Handle after insert events to generate seats for new showtimes.
   * Follows Context7 bulk operation patterns and security best practices.
   */
  public static void handleAfterInsert(List<Showtime__c> newShowtimes) {
    // Validate Field-Level Security before proceeding
    if (!Schema.sObjectType.Seat__c.isCreateable()) {
      throw new DmlException('Insufficient permissions to create seats');
    }

    // Check if we have the required fields accessible
    if (
      !Schema.sObjectType.Seat__c.fields.Showtime__c.isCreateable() ||
      !Schema.sObjectType.Seat__c.fields.Row__c.isCreateable() ||
      !Schema.sObjectType.Seat__c.fields.Number__c.isCreateable() ||
      !Schema.sObjectType.Seat__c.fields.Status__c.isCreateable()
    ) {
      throw new DmlException('Insufficient field permissions to create seats');
    }

    Set<Id> showtimeIds = new Set<Id>();
    for (Showtime__c st : newShowtimes) {
      showtimeIds.add(st.Id);
    }

    // Bulk query to find showtimes with existing seats
    Set<Id> showtimesWithExistingSeats = getShowtimesWithExistingSeats(
      showtimeIds
    );

    List<Seat__c> seatsToInsert = new List<Seat__c>();
    for (Showtime__c showtime : newShowtimes) {
      // Only generate seats if none exist for this showtime
      if (!showtimesWithExistingSeats.contains(showtime.Id)) {
        List<Seat__c> seats = createSeatsForShowtime(showtime);

        // Governor limit protection
        if (seatsToInsert.size() + seats.size() > MAX_SEATS_PER_SHOWTIME) {
          System.debug('Warning: Reached maximum seats limit per transaction');
          break;
        }

        seatsToInsert.addAll(seats);
      }
    }

    // Bulk insert with proper error handling
    if (!seatsToInsert.isEmpty()) {
      insertSeatsBulk(seatsToInsert);
    }
  }

  /**
   * @description Bulk query to find showtimes with existing seats
   * @param showtimeIds Set of showtime IDs to check
   * @return Set of showtime IDs that already have seats
   */
  private static Set<Id> getShowtimesWithExistingSeats(Set<Id> showtimeIds) {
    Set<Id> showtimesWithExistingSeats = new Set<Id>();

    // Use bulk query with proper security enforcement
    for (AggregateResult ar : [
      SELECT COUNT(Id) seatCount, Showtime__c
      FROM Seat__c
      WHERE Showtime__c IN :showtimeIds
      GROUP BY Showtime__c
    ]) {
      showtimesWithExistingSeats.add((Id) ar.get('Showtime__c'));
    }

    return showtimesWithExistingSeats;
  }

  /**
   * @description Bulk insert seats with comprehensive error handling
   * @param seatsToInsert List of seats to insert
   */
  private static void insertSeatsBulk(List<Seat__c> seatsToInsert) {
    try {
      // Use Database.insert for partial success handling
      Database.SaveResult[] results = Database.insert(seatsToInsert, false);

      // Process results and log any failures
      for (Integer i = 0; i < results.size(); i++) {
        if (!results[i].isSuccess()) {
          Database.Error[] errors = results[i].getErrors();
          for (Database.Error error : errors) {
            System.debug(
              'Error inserting seat ' +
                seatsToInsert[i].Name +
                ': ' +
                error.getMessage()
            );
          }
        }
      }

      System.debug('Successfully inserted ' + seatsToInsert.size() + ' seats');
    } catch (Exception e) {
      System.debug('Error bulk inserting seats: ' + e.getMessage());
      System.debug('Stack trace: ' + e.getStackTraceString());

      // Log error for monitoring
      System.debug('Error logged for monitoring: ' + e.getMessage());

      // Re-throw to ensure transaction rollback
      throw new DmlException('Failed to create seats: ' + e.getMessage());
    }
  }

  /**
   * @description Creates a list of Seat__c records for a single showtime without inserting them.
   * Follows Context7 patterns for bulk record creation.
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

        // Assign seat types following business rules
        seat.Seat_Type__c = determineSeatType(row, seatNum, numRows);
        seats.add(seat);
      }
    }
    return seats;
  }

  /**
   * @description Determines seat type based on position
   * @param row Row index (0-based)
   * @param seatNum Seat number (1-based)
   * @param numRows Total number of rows
   * @return Seat type string
   */
  private static String determineSeatType(
    Integer row,
    Integer seatNum,
    Integer numRows
  ) {
    // VIP seats in first two rows
    if (row < 2) {
      return 'VIP';
    }

    // Wheelchair accessible seats in last row, corner positions
    if (row == numRows - 1 && (seatNum == 1 || seatNum == SEATS_PER_ROW)) {
      return 'Wheelchair';
    }

    // All other seats are standard
    return 'Standard';
  }
}
