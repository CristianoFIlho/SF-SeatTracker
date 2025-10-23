/**
 * @description Payment service for handling payment processing following Context7 Apex Recipes patterns
 * @author Cristiano Filho
 * @date 2025-01-27
 */
public with sharing class PaymentService {
  // Circuit breaker pattern for testing
  @TestVisible
  private static Boolean testCircuitBreaker = false;
  @TestVisible
  private static Boolean circuitBreakerThrown = false;

  /**
   * @description Process payment for a reservation
   * @param reservationId Reservation record ID
   * @param paymentMethodId Payment method ID (simulated)
   * @param amount Payment amount
   * @return PaymentResult with success status and transaction details
   */
  @AuraEnabled
  public static PaymentResult processPayment(
    Id reservationId,
    String paymentMethodId,
    Decimal amount
  ) {
    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Reservation__c.isAccessible()) {
        throw new PaymentException(
          'Insufficient permissions to read reservations'
        );
      }

      if (!Schema.sObjectType.Reservation__c.isUpdateable()) {
        throw new PaymentException(
          'Insufficient permissions to update reservations'
        );
      }

      // Validate input parameters
      if (reservationId == null) {
        throw new PaymentException('Reservation ID cannot be null');
      }

      if (String.isBlank(paymentMethodId)) {
        throw new PaymentException('Payment method ID cannot be blank');
      }

      if (amount == null || amount <= 0) {
        throw new PaymentException('Payment amount must be positive');
      }

      // Circuit breaker pattern for testing
      if (testCircuitBreaker) {
        circuitBreakerThrown = true;
        throw new PaymentException('Circuit breaker activated for testing');
      }

      // Get reservation details
      Reservation__c reservation = [
        SELECT
          Id,
          Total_Amount__c,
          Status__c,
          Payment_Status__c,
          Customer_Name__c,
          Customer_Email__c,
          Confirmation_Code__c
        FROM Reservation__c
        WHERE Id = :reservationId
        FOR UPDATE
      ];

      // Validate payment amount
      if (amount != reservation.Total_Amount__c) {
        throw new PaymentException(
          'Payment amount does not match reservation total.'
        );
      }

      // Validate reservation status
      if (reservation.Status__c != 'Confirmed') {
        throw new PaymentException(
          'Reservation is not in a valid state for payment.'
        );
      }

      // Simulate payment processing with external gateway
      PaymentResult result = processPaymentWithGateway(
        paymentMethodId,
        amount,
        reservation
      );

      if (result.success) {
        // Update reservation with payment details
        reservation.Payment_Status__c = 'Paid';
        reservation.Payment_Method__c = 'Credit Card';
        reservation.Payment_Transaction_Id__c = result.transactionId;
        reservation.Payment_Date__c = System.now();
        update reservation;

        // Generate QR Code after successful payment
        generateQRCode(reservation.Id);

        // Send payment confirmation email
        sendPaymentConfirmationEmail(reservation.Id);
      } else {
        reservation.Payment_Status__c = 'Failed';
        update reservation;
      }

      return result;
    } catch (Exception e) {
      System.debug('Payment processing error: ' + e.getMessage());
      throw new AuraHandledException(
        'Payment processing error: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Simulate payment processing with external gateway
   * @param paymentMethodId Payment method ID
   * @param amount Payment amount
   * @param reservation Reservation record
   * @return PaymentResult
   */
  private static PaymentResult processPaymentWithGateway(
    String paymentMethodId,
    Decimal amount,
    Reservation__c reservation
  ) {
    PaymentResult result = new PaymentResult();

    try {
      // Simulate API call to payment gateway (e.g., Stripe)
      // In a real implementation, this would make an HTTP callout

      // Simulate processing delay
      // In production, this would be an actual HTTP callout

      // Simulate success/failure based on amount (for demo purposes)
      if (amount > 0 && amount <= 1000) {
        result.success = true;
        result.transactionId =
          'TXN_' + String.valueOf(System.currentTimeMillis());
        result.message = 'Payment processed successfully';
        result.processedAmount = amount;
      } else {
        result.success = false;
        result.message = 'Payment failed: Amount exceeds limit';
        result.errorCode = 'AMOUNT_LIMIT_EXCEEDED';
      }
    } catch (Exception e) {
      result.success = false;
      result.message = 'Payment gateway error: ' + e.getMessage();
      result.errorCode = 'GATEWAY_ERROR';
    }

    return result;
  }

  /**
   * @description Generate QR Code for reservation
   * @param reservationId Reservation record ID
   */
  private static void generateQRCode(Id reservationId) {
    try {
      Reservation__c reservation = [
        SELECT
          Id,
          Confirmation_Code__c,
          Customer_Name__c,
          Movie__r.Name,
          Showtime__r.Session_DateTime__c,
          Seat_Numbers__c,
          Total_Amount__c
        FROM Reservation__c
        WHERE Id = :reservationId
      ];

      // Create QR Code data
      Map<String, Object> qrData = new Map<String, Object>();
      qrData.put('confirmationCode', reservation.Confirmation_Code__c);
      qrData.put('customerName', reservation.Customer_Name__c);
      qrData.put('movie', reservation.Movie__r.Name);
      qrData.put(
        'showtime',
        reservation.Showtime__r.Session_DateTime__c.format()
      );
      qrData.put('seats', reservation.Seat_Numbers__c);
      qrData.put('amount', reservation.Total_Amount__c);
      qrData.put('reservationId', reservation.Id);

      String qrDataString = JSON.serialize(qrData);

      // In a real implementation, you would call a QR Code generation service
      // For now, we'll store the data and generate a simple representation
      String qrCodeUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=' +
        EncodingUtil.urlEncode(qrDataString, 'UTF-8');

      // Update reservation with QR Code
      reservation.QR_Code__c = qrCodeUrl;
      update reservation;
    } catch (Exception e) {
      System.debug('Error generating QR Code: ' + e.getMessage());
    }
  }

  /**
   * @description Send payment confirmation email
   * @param reservationId Reservation record ID
   */
  private static void sendPaymentConfirmationEmail(Id reservationId) {
    try {
      Reservation__c reservation = [
        SELECT
          Id,
          Name,
          Confirmation_Code__c,
          Customer_Name__c,
          Customer_Email__c,
          Seat_Numbers__c,
          Number_of_Seats__c,
          Total_Amount__c,
          Movie__r.Name,
          Showtime__r.Session_DateTime__c,
          QR_Code__c
        FROM Reservation__c
        WHERE Id = :reservationId
      ];

      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setToAddresses(new List<String>{ reservation.Customer_Email__c });
      email.setSubject(
        'Payment Confirmed - Cinema Reservation ' +
        reservation.Confirmation_Code__c
      );

      String emailBody = 'Dear ' + reservation.Customer_Name__c + ',\n\n';
      emailBody += 'Your payment has been processed successfully!\n\n';
      emailBody +=
        'Confirmation Code: ' +
        reservation.Confirmation_Code__c +
        '\n';
      emailBody += 'Movie: ' + reservation.Movie__r.Name + '\n';
      emailBody +=
        'Showtime: ' +
        reservation.Showtime__r.Session_DateTime__c.format() +
        '\n';
      emailBody += 'Seats: ' + reservation.Seat_Numbers__c + '\n';
      emailBody +=
        'Number of Tickets: ' +
        reservation.Number_of_Seats__c +
        '\n';
      emailBody +=
        'Total Amount Paid: $' +
        reservation.Total_Amount__c +
        '\n\n';

      if (String.isNotBlank(reservation.QR_Code__c)) {
        emailBody +=
          'Your QR Code for entry: ' +
          reservation.QR_Code__c +
          '\n\n';
      }

      emailBody += 'Please arrive 15 minutes before showtime.\n';
      emailBody += 'Show this QR Code at the entrance.\n\n';
      emailBody += 'Thank you for choosing our cinema!\n';

      email.setPlainTextBody(emailBody);

      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    } catch (Exception e) {
      System.debug(
        'Error sending payment confirmation email: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Refund payment for cancelled reservation
   * @param reservationId Reservation record ID
   * @return PaymentResult with refund status
   */
  @AuraEnabled
  public static PaymentResult processRefund(Id reservationId) {
    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Reservation__c.isAccessible()) {
        throw new PaymentException(
          'Insufficient permissions to read reservations'
        );
      }

      if (!Schema.sObjectType.Reservation__c.isUpdateable()) {
        throw new PaymentException(
          'Insufficient permissions to update reservations'
        );
      }

      // Validate input parameters
      if (reservationId == null) {
        throw new PaymentException('Reservation ID cannot be null');
      }

      Reservation__c reservation = [
        SELECT Id, Payment_Transaction_Id__c, Total_Amount__c, Payment_Status__c
        FROM Reservation__c
        WHERE Id = :reservationId
        FOR UPDATE
      ];

      if (reservation.Payment_Status__c != 'Paid') {
        throw new PaymentException('Cannot refund unpaid reservation.');
      }

      // Simulate refund processing
      PaymentResult result = processRefundWithGateway(
        reservation.Payment_Transaction_Id__c,
        reservation.Total_Amount__c
      );

      if (result.success) {
        reservation.Payment_Status__c = 'Refunded';
        reservation.Refund_Transaction_Id__c = result.transactionId;
        reservation.Refund_Date__c = System.now();
        update reservation;
      }

      return result;
    } catch (Exception e) {
      System.debug('Refund processing error: ' + e.getMessage());
      throw new AuraHandledException(
        'Refund processing error: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Simulate refund processing with external gateway
   * @param transactionId Original transaction ID
   * @param amount Refund amount
   * @return PaymentResult
   */
  private static PaymentResult processRefundWithGateway(
    String transactionId,
    Decimal amount
  ) {
    PaymentResult result = new PaymentResult();

    try {
      // Simulate refund API call
      result.success = true;
      result.transactionId =
        'REF_' + String.valueOf(System.currentTimeMillis());
      result.message = 'Refund processed successfully';
      result.processedAmount = amount;
    } catch (Exception e) {
      result.success = false;
      result.message = 'Refund processing error: ' + e.getMessage();
      result.errorCode = 'REFUND_ERROR';
    }

    return result;
  }

  /**
   * @description Payment result wrapper class
   */
  public class PaymentResult {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String transactionId;
    @AuraEnabled
    public Decimal processedAmount;
    @AuraEnabled
    public String errorCode;

    public PaymentResult() {
      this.success = false;
      this.processedAmount = 0;
    }
  }

  /**
   * @description Custom exception class for payment errors
   */
  public class PaymentException extends Exception {
  }
}
