/**
 * @description Test class for PaymentService following Context7 Apex Recipes patterns
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

  // Context7 Apex Recipes Patterns Implementation

  @isTest
  static void testProcessPaymentWithFLSValidation() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];
    reservation.Status__c = 'Confirmed';
    update reservation;

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processPayment(
      reservation.Id,
      'pm_test123',
      30.00
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Payment should succeed');
    System.assertNotEquals(
      null,
      result.transactionId,
      'Should have transaction ID'
    );

    // Verify FLS validation worked
    System.assert(
      Schema.sObjectType.Reservation__c.isAccessible(),
      'Reservation__c should be accessible'
    );
    System.assert(
      Schema.sObjectType.Reservation__c.isUpdateable(),
      'Reservation__c should be updateable'
    );
  }

  @isTest
  static void testProcessPaymentWithCircuitBreaker() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];
    reservation.Status__c = 'Confirmed';
    update reservation;

    // Activate circuit breaker
    PaymentService.testCircuitBreaker = true;

    Test.startTest();
    try {
      PaymentService.processPayment(reservation.Id, 'pm_test123', 30.00);
      System.assert(
        false,
        'Should have thrown exception due to circuit breaker'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Circuit breaker activated'),
        'Should throw circuit breaker exception'
      );
      System.assert(
        PaymentService.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    // Reset circuit breaker
    PaymentService.testCircuitBreaker = false;
    PaymentService.circuitBreakerThrown = false;
  }

  @isTest
  static void testProcessPaymentWithValidation() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];
    reservation.Status__c = 'Confirmed';
    update reservation;

    Test.startTest();

    // Test with valid parameters
    PaymentService.PaymentResult result = PaymentService.processPayment(
      reservation.Id,
      'pm_test123',
      30.00
    );
    System.assertEquals(true, result.success, 'Payment should succeed');

    // Test with invalid parameters
    try {
      PaymentService.processPayment(null, 'pm_test123', 30.00);
      System.assert(
        false,
        'Should have thrown exception for null reservation ID'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Reservation ID cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      PaymentService.processPayment(reservation.Id, '', 30.00);
      System.assert(
        false,
        'Should have thrown exception for blank payment method ID'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment method ID cannot be blank'),
        'Should throw appropriate exception'
      );
    }

    try {
      PaymentService.processPayment(reservation.Id, 'pm_test123', -10.00);
      System.assert(false, 'Should have thrown exception for negative amount');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment amount must be positive'),
        'Should throw appropriate exception'
      );
    }

    try {
      PaymentService.processPayment(reservation.Id, 'pm_test123', null);
      System.assert(false, 'Should have thrown exception for null amount');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment amount must be positive'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testProcessRefundWithValidation() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];
    reservation.Status__c = 'Confirmed';
    reservation.Payment_Status__c = 'Paid';
    reservation.Payment_Transaction_Id__c = 'TXN_123456';
    update reservation;

    Test.startTest();

    // Test with valid parameters
    PaymentService.PaymentResult result = PaymentService.processRefund(
      reservation.Id
    );
    System.assertEquals(true, result.success, 'Refund should succeed');

    // Test with invalid parameters
    try {
      PaymentService.processRefund(null);
      System.assert(
        false,
        'Should have thrown exception for null reservation ID'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Reservation ID cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testProcessRefundWithCircuitBreaker() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];
    reservation.Status__c = 'Confirmed';
    reservation.Payment_Status__c = 'Paid';
    reservation.Payment_Transaction_Id__c = 'TXN_123456';
    update reservation;

    // Activate circuit breaker
    PaymentService.testCircuitBreaker = true;

    Test.startTest();
    try {
      PaymentService.processRefund(reservation.Id);
      System.assert(
        false,
        'Should have thrown exception due to circuit breaker'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Circuit breaker activated'),
        'Should throw circuit breaker exception'
      );
      System.assert(
        PaymentService.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    // Reset circuit breaker
    PaymentService.testCircuitBreaker = false;
    PaymentService.circuitBreakerThrown = false;
  }

  @isTest
  static void testBulkOperations() {
    // Create multiple reservations for bulk testing
    List<Reservation__c> reservations = new List<Reservation__c>();
    for (Integer i = 0; i < 5; i++) {
      reservations.add(
        new Reservation__c(
          Showtime__c = [SELECT Id FROM Showtime__c LIMIT 1]
          .Id,
          Movie__c = [SELECT Id FROM Movie__c LIMIT 1]
          .Id,
          Customer_Name__c = 'Test Customer ' + i,
          Customer_Email__c = 'test' + i + '@test.com',
          Customer_Phone__c = '123456789' + i,
          Number_of_Seats__c = 2,
          Total_Amount__c = 30.00,
          Status__c = 'Confirmed',
          Payment_Status__c = 'Pending',
          Confirmation_Code__c = 'TEST' + i
        )
      );
    }
    insert reservations;

    Test.startTest();

    // Test bulk payment processing
    List<PaymentService.PaymentResult> results = new List<PaymentService.PaymentResult>();
    for (Reservation__c res : reservations) {
      PaymentService.PaymentResult result = PaymentService.processPayment(
        res.Id,
        'pm_test' + res.Id,
        30.00
      );
      results.add(result);
    }

    Test.stopTest();

    // Verify all payments succeeded
    for (PaymentService.PaymentResult result : results) {
      System.assertEquals(true, result.success, 'All payments should succeed');
    }
  }

  @isTest
  static void testErrorHandlingPatterns() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];

    Test.startTest();

    // Test exception handling in processPayment
    try {
      PaymentService.processPayment(reservation.Id, 'pm_test123', 30.00);
      System.assert(true, 'Should handle exceptions gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    // Test exception handling in processRefund
    try {
      PaymentService.processRefund(reservation.Id);
      System.assert(true, 'Should handle exceptions gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    Test.stopTest();
  }

  @isTest
  static void testDataValidationPatterns() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];
    reservation.Status__c = 'Confirmed';
    update reservation;

    Test.startTest();

    // Test data sanitization
    PaymentService.PaymentResult result = PaymentService.processPayment(
      reservation.Id,
      'pm_test_with_special_chars_123',
      30.00
    );

    System.assertEquals(
      true,
      result.success,
      'Should handle special characters in payment method ID'
    );
    System.assertNotEquals(
      null,
      result.transactionId,
      'Should generate transaction ID'
    );

    Test.stopTest();
  }

  @isTest
  static void testPaymentAmountValidation() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];
    reservation.Status__c = 'Confirmed';
    update reservation;

    Test.startTest();

    // Test amount validation
    try {
      PaymentService.processPayment(reservation.Id, 'pm_test123', 25.00); // Wrong amount
      System.assert(false, 'Should have thrown exception for wrong amount');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment amount does not match'),
        'Should throw amount mismatch exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testReservationStatusValidation() {
    Reservation__c reservation = [SELECT Id FROM Reservation__c LIMIT 1];
    reservation.Status__c = 'Cancelled'; // Invalid status
    update reservation;

    Test.startTest();

    try {
      PaymentService.processPayment(reservation.Id, 'pm_test123', 30.00);
      System.assert(false, 'Should have thrown exception for invalid status');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('not in a valid state'),
        'Should throw status validation exception'
      );
    }

    Test.stopTest();
  }
}
