/**
 * @description Trigger for Showtime__c object following Context7 best practices
 * @author Refactored based on Context7 Apex Recipes patterns
 * @date 2025-01-27
 */
trigger ShowtimeTrigger on Showtime__c(after insert) {
  ShowtimeTriggerHandler handler = new ShowtimeTriggerHandler();
  handler.run();
}
