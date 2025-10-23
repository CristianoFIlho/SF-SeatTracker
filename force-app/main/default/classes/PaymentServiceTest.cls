/**
 * @description Test class for PaymentService following Context7 Apex Recipes patterns
 */
@isTest
public class PaymentServiceTest {
  private class TestData {
    Reservation__c reservation;
    List<Seat__c> seats;

    TestData(Reservation__c reservation, List<Seat__c> seats) {
      this.reservation = reservation;
      this.seats = seats;
    }
  }

  private static TestData createConfirmedReservation() {
    return createConfirmedReservation(null, null, null);
  }

  private static TestData createConfirmedReservation(
    Decimal ticketPriceOverride,
    Decimal totalAmountOverride,
    Integer seatCountOverride
  ) {
    Integer seatCount = seatCountOverride != null ? seatCountOverride : 2;
    Decimal ticketPrice = ticketPriceOverride != null
      ? ticketPriceOverride
      : 15;
    Decimal totalAmount = totalAmountOverride != null
      ? totalAmountOverride
      : (ticketPrice * seatCount);

    Theater__c theater = new Theater__c(
      Name = 'Test Theater',
      Address__c = '123 Test St',
      City__c = 'Test City',
      Number_of_Rows__c = 8,
      Seats_Per_Row__c = 12,
      Seat_Layout_Type__c = 'Standard'
    );
    insert theater;

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

    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = Date.today().addDays(1),
      Session_Time__c = Time.newInstance(19, 0, 0, 0),
      Ticket_Price__c = ticketPrice,
      Status__c = 'Scheduled',
      Reserved_Seats__c = 0,
      Total_Seats__c = 96
    );
    insert showtime;

    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      8,
      12
    );

    List<String> seatLabels = new List<String>();
    for (Integer i = 0; i < seatCount && i < seats.size(); i++) {
      seatLabels.add(seats[i].Name);
    }
    if (seatLabels.isEmpty()) {
      seatLabels.add('A-1');
    }

    Reservation__c reservation = new Reservation__c(
      Showtime__c = showtime.Id,
      Movie__c = movie.Id,
      Customer_Name__c = 'Test Customer',
      Customer_Email__c = 'test@example.com',
      Customer_Phone__c = '1234567890',
      Number_of_Seats__c = seatCount,
      Total_Amount__c = totalAmount,
      Status__c = 'Confirmed',
      Payment_Status__c = 'Pending',
      Confirmation_Code__c = 'TEST123',
      Seat_Numbers__c = String.join(seatLabels, ', ')
    );
    insert reservation;

    return new TestData(reservation, seats);
  }

  @IsTest
  static void testProcessPaymentSuccess() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processPayment(
      data.reservation.Id,
      'pm_test123',
      30.00
    );
    Test.stopTest();

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

    Reservation__c updatedReservation = [
      SELECT
        Payment_Status__c,
        Payment_Method__c,
        Payment_Transaction_Id__c,
        QR_Code__c
      FROM Reservation__c
      WHERE Id = :data.reservation.Id
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

  @IsTest
  static void testProcessPaymentFailure() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', 1500.00);
      System.assert(
        false,
        'Should have thrown exception for amount exceeding limit'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment processing error'),
        'Should throw payment processing error'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void testProcessPaymentInvalidAmount() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', 50.00);
      System.assert(false, 'Should have thrown exception for amount mismatch');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment amount does not match'),
        'Should throw amount mismatch error'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void testProcessRefundSuccess() {
    TestData data = createConfirmedReservation();
    PaymentService.processPayment(data.reservation.Id, 'pm_test123', 30.00);

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processRefund(
      data.reservation.Id
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Refund should be successful');
    System.assertNotEquals(
      null,
      result.transactionId,
      'Refund transaction ID should be generated'
    );

    Reservation__c updatedReservation = [
      SELECT Payment_Status__c, Refund_Transaction_Id__c, Refund_Date__c
      FROM Reservation__c
      WHERE Id = :data.reservation.Id
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

  @IsTest
  static void testProcessRefundUnpaidReservation() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    try {
      PaymentService.processRefund(data.reservation.Id);
      System.assert(
        false,
        'Should have thrown exception for unpaid reservation'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Cannot refund unpaid reservation'),
        'Should throw unpaid reservation error'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void testProcessPaymentGatewayFailure() {
    TestData data = createConfirmedReservation(600, 1200, 2);

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processPayment(
      data.reservation.Id,
      'pm_high_amount',
      1200
    );
    Test.stopTest();

    System.assertEquals(
      false,
      result.success,
      'Gateway failure should be reported'
    );
    System.assert(
      result.message.contains('Amount exceeds limit'),
      'Should describe gateway failure'
    );

    Reservation__c updatedReservation = [
      SELECT Payment_Status__c
      FROM Reservation__c
      WHERE Id = :data.reservation.Id
    ];
    System.assertEquals(
      'Failed',
      updatedReservation.Payment_Status__c,
      'Payment status should be Failed after gateway error'
    );
  }

  @IsTest
  static void testProcessPaymentWithCircuitBreaker() {
    TestData data = createConfirmedReservation();
    PaymentService.testCircuitBreaker = true;

    Test.startTest();
    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', 30.00);
      System.assert(
        false,
        'Should have thrown exception due to circuit breaker'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Circuit breaker activated'),
        'Should throw circuit breaker exception'
      );
      System.assertEquals(
        true,
        PaymentService.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    PaymentService.testCircuitBreaker = false;
    PaymentService.circuitBreakerThrown = false;
  }

  @IsTest
  static void testProcessPaymentWithValidation() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processPayment(
      data.reservation.Id,
      'pm_test123',
      30.00
    );
    System.assertEquals(true, result.success, 'Payment should succeed');

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
      PaymentService.processPayment(data.reservation.Id, '', 30.00);
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
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', -10.00);
      System.assert(false, 'Should have thrown exception for negative amount');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment amount must be positive'),
        'Should throw appropriate exception'
      );
    }

    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', null);
      System.assert(false, 'Should have thrown exception for null amount');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment amount must be positive'),
        'Should throw appropriate exception'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void testProcessRefundWithValidation() {
    TestData data = createConfirmedReservation();
    PaymentService.processPayment(data.reservation.Id, 'pm_test123', 30.00);

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processRefund(
      data.reservation.Id
    );
    System.assertEquals(true, result.success, 'Refund should succeed');

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

  @IsTest
  static void testProcessRefundWithCircuitBreaker() {
    TestData data = createConfirmedReservation();
    PaymentService.processPayment(data.reservation.Id, 'pm_test123', 30.00);
    PaymentService.testCircuitBreaker = true;

    Test.startTest();
    try {
      PaymentService.processRefund(data.reservation.Id);
      System.assert(
        false,
        'Should have thrown exception due to circuit breaker'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Circuit breaker activated'),
        'Should throw circuit breaker exception'
      );
      System.assertEquals(
        true,
        PaymentService.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    PaymentService.testCircuitBreaker = false;
    PaymentService.circuitBreakerThrown = false;
  }

  @IsTest
  static void testBulkOperations() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    List<PaymentService.PaymentResult> results = new List<PaymentService.PaymentResult>();
    for (Integer i = 0; i < 5; i++) {
      results.add(
        PaymentService.processPayment(data.reservation.Id, 'pm_test' + i, 30.00)
      );
    }
    Test.stopTest();

    for (PaymentService.PaymentResult result : results) {
      System.assertEquals(true, result.success, 'All payments should succeed');
    }
  }

  @IsTest
  static void testDataValidationPatterns() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processPayment(
      data.reservation.Id,
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

  @IsTest
  static void testPaymentAmountValidation() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', 25.00);
      System.assert(false, 'Should have thrown exception for wrong amount');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Payment amount does not match'),
        'Should throw amount mismatch exception'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void testReservationStatusValidation() {
    TestData data = createConfirmedReservation();
    data.reservation.Status__c = 'Cancelled';
    update data.reservation;

    Test.startTest();
    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', 30.00);
      System.assert(false, 'Should have thrown exception for invalid status');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Reservation is not in a valid state'),
        'Should throw status validation exception'
      );
    }
    Test.stopTest();
  }
}
