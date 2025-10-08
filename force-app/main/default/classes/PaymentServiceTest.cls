/**
 * @description Test class for PaymentService
 * @author Cristiano Filho
 * @date 2025-01-27
 */
@isTest
public class PaymentServiceTest {
  @TestSetup
  static void setupTestData() {
    // Create test theater
    Theater__c theater = new Theater__c(
      Name = 'Test Theater',
      Address__c = '123 Test St',
      City__c = 'Test City',
      Number_of_Rows__c = 8,
      Seats_Per_Row__c = 12,
      Seat_Layout_Type__c = 'Standard'
    );
    insert theater;

    // Create test movie
    Movie__c movie = new Movie__c(
      Name = 'Test Movie',
      Synopsis__c = 'Test Synopsis',
      Release_Date__c = Date.today(),
      Duration_Minutes__c = 120,
      Rating__c = 'PG-13',
      Genre__c = 'Action',
      Is_Active__c = true
    );
    insert movie;

    // Create test showtime
    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = Date.today().addDays(1),
      Session_Time__c = Time.newInstance(19, 0, 0, 0),
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled',
      Reserved_Seats__c = 0,
      Total_Seats__c = 96
    );
    insert showtime;

    // Generate seats
    SeatManagementService.generateSeats(showtime.Id);

    // Create test reservation
    Reservation__c reservation = new Reservation__c(
      Showtime__c = showtime.Id,
      Movie__c = movie.Id,
      Customer_Name__c = 'Test Customer',
      Customer_Email__c = 'test@example.com',
      Customer_Phone__c = '1234567890',
      Number_of_Seats__c = 2,
      Total_Amount__c = 30.00,
      Status__c = 'Confirmed',
      Payment_Status__c = 'Pending',
      Confirmation_Code__c = 'TEST123',
      Seat_Numbers__c = 'A-1, A-2'
    );
    insert reservation;
  }

  @isTest
  static void testProcessPaymentSuccess() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processPayment(
      reservation.Id,
      'pm_test123',
      30.00
    );
    Test.stopTest();

    // Verify payment result
    System.assertEquals(true, result.success, 'Payment should be successful');
    System.assertNotEquals(
      null,
      result.transactionId,
      'Transaction ID should be generated'
    );
    System.assertEquals(
      30.00,
      result.processedAmount,
      'Processed amount should match'
    );

    // Verify reservation update
    Reservation__c updatedReservation = [
      SELECT
        Payment_Status__c,
        Payment_Method__c,
        Payment_Transaction_Id__c,
        QR_Code__c
      FROM Reservation__c
      WHERE Id = :reservation.Id
    ];
    System.assertEquals(
      'Paid',
      updatedReservation.Payment_Status__c,
      'Payment status should be Paid'
    );
    System.assertEquals(
      'Credit Card',
      updatedReservation.Payment_Method__c,
      'Payment method should be set'
    );
    System.assertNotEquals(
      null,
      updatedReservation.Payment_Transaction_Id__c,
      'Transaction ID should be saved'
    );
    System.assertNotEquals(
      null,
      updatedReservation.QR_Code__c,
      'QR Code should be generated'
    );
  }

  @isTest
  static void testProcessPaymentFailure() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];

    Test.startTest();
    try {
      PaymentService.PaymentResult result = PaymentService.processPayment(
        reservation.Id,
        'pm_test123',
        1500.00 // Amount exceeds limit
      );
      System.assert(
        false,
        'Should have thrown exception for amount exceeding limit'
      );
    } catch (Exception e) {
      System.assert(
        e.getMessage().contains('Payment processing error'),
        'Should throw payment processing error'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testProcessPaymentInvalidAmount() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];

    Test.startTest();
    try {
      PaymentService.processPayment(reservation.Id, 'pm_test123', 50.00);
      System.assert(false, 'Should have thrown exception for amount mismatch');
    } catch (Exception e) {
      System.assert(
        e.getMessage().contains('Payment amount does not match'),
        'Should throw amount mismatch error'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testProcessRefundSuccess() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];

    // First process payment
    PaymentService.processPayment(reservation.Id, 'pm_test123', 30.00);

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processRefund(
      reservation.Id
    );
    Test.stopTest();

    // Verify refund result
    System.assertEquals(true, result.success, 'Refund should be successful');
    System.assertNotEquals(
      null,
      result.transactionId,
      'Refund transaction ID should be generated'
    );

    // Verify reservation update
    Reservation__c updatedReservation = [
      SELECT Payment_Status__c, Refund_Transaction_Id__c, Refund_Date__c
      FROM Reservation__c
      WHERE Id = :reservation.Id
    ];
    System.assertEquals(
      'Refunded',
      updatedReservation.Payment_Status__c,
      'Payment status should be Refunded'
    );
    System.assertNotEquals(
      null,
      updatedReservation.Refund_Transaction_Id__c,
      'Refund transaction ID should be saved'
    );
    System.assertNotEquals(
      null,
      updatedReservation.Refund_Date__c,
      'Refund date should be set'
    );
  }

  @isTest
  static void testProcessRefundUnpaidReservation() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];

    Test.startTest();
    try {
      PaymentService.processRefund(reservation.Id);
      System.assert(
        false,
        'Should have thrown exception for unpaid reservation'
      );
    } catch (Exception e) {
      System.assert(
        e.getMessage().contains('Cannot refund unpaid reservation'),
        'Should throw unpaid reservation error'
      );
    }
    Test.stopTest();
  }
}
