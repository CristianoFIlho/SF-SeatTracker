/**
 * @description Trigger for Showtime__c object
 * @author Cristiano Filho
 * @date 2025-09-30
 */
trigger ShowtimeTrigger on Showtime__c (after insert) {
    ShowtimeTriggerHandler.handleAfterInsert(Trigger.new);
}

