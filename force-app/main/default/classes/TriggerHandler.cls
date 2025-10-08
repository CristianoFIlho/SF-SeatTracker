/**
 * @description Base trigger handler framework following Salesforce best practices
 * @author Refactored based on Context7 Apex Recipes patterns
 * @date 2025-01-27
 */
public abstract class TriggerHandler {
  // Static map to track bypassed handlers
  private static Map<String, Set<String>> bypassedHandlers = new Map<String, Set<String>>();

  // Instance variables for trigger context
  protected List<SObject> triggerNew;
  protected List<SObject> triggerOld;
  protected Map<Id, SObject> triggerMapNew;
  protected Map<Id, SObject> triggerMapOld;
  protected Map<Id, SObject> triggerMapOldMap;

  // Loop prevention
  private static Map<String, Integer> loopCountMap = new Map<String, Integer>();
  private static Map<String, Integer> maxLoopCountMap = new Map<String, Integer>();

  /**
   * @description Constructor that sets up trigger context variables
   */
  public TriggerHandler() {
    this.triggerNew = Trigger.new;
    this.triggerOld = Trigger.old;
    this.triggerMapNew = Trigger.newMap;
    this.triggerMapOld = Trigger.oldMap;
    this.triggerMapOldMap = Trigger.oldMap;
  }

  /**
   * @description Main entry point for trigger execution
   */
  public void run() {
    if (!validateRun()) {
      return;
    }

    // Check loop count
    if (isMaxLoopCountReached()) {
      return;
    }

    // Increment loop count
    incrementLoopCount();

    // Execute appropriate context method
    if (Trigger.isBefore) {
      if (Trigger.isInsert) {
        beforeInsert();
      } else if (Trigger.isUpdate) {
        beforeUpdate();
      } else if (Trigger.isDelete) {
        beforeDelete();
      }
    } else if (Trigger.isAfter) {
      if (Trigger.isInsert) {
        afterInsert();
      } else if (Trigger.isUpdate) {
        afterUpdate();
      } else if (Trigger.isDelete) {
        afterDelete();
      } else if (Trigger.isUndelete) {
        afterUndelete();
      }
    }
  }

  /**
   * @description Validate that handler should run
   */
  protected Boolean validateRun() {
    if (!Trigger.isExecuting) {
      throw new TriggerHandlerException(
        'Trigger handler called outside of trigger context'
      );
    }

    String handlerName = String.valueOf(this)
      .substring(0, String.valueOf(this).indexOf(':'));
    if (isBypassed(handlerName)) {
      return false;
    }

    return true;
  }

  /**
   * @description Check if handler is bypassed
   */
  private Boolean isBypassed(String handlerName) {
    return bypassedHandlers.containsKey(handlerName);
  }

  /**
   * @description Bypass a specific handler
   */
  public static void bypass(String handlerName) {
    if (!bypassedHandlers.containsKey(handlerName)) {
      bypassedHandlers.put(handlerName, new Set<String>());
    }
    bypassedHandlers.get(handlerName).add(UserInfo.getUserId());
  }

  /**
   * @description Clear bypass for a specific handler
   */
  public static void clearBypass(String handlerName) {
    bypassedHandlers.remove(handlerName);
  }

  /**
   * @description Clear all bypasses
   */
  public static void clearAllBypasses() {
    bypassedHandlers.clear();
  }

  /**
   * @description Set maximum loop count
   */
  public void setMaxLoopCount(Integer max) {
    String handlerName = String.valueOf(this)
      .substring(0, String.valueOf(this).indexOf(':'));
    maxLoopCountMap.put(handlerName, max);
  }

  /**
   * @description Clear maximum loop count
   */
  public void clearMaxLoopCount() {
    String handlerName = String.valueOf(this)
      .substring(0, String.valueOf(this).indexOf(':'));
    maxLoopCountMap.remove(handlerName);
  }

  /**
   * @description Check if max loop count reached
   */
  private Boolean isMaxLoopCountReached() {
    String handlerName = String.valueOf(this)
      .substring(0, String.valueOf(this).indexOf(':'));
    Integer maxCount = maxLoopCountMap.get(handlerName);
    Integer currentCount = loopCountMap.get(handlerName);

    if (maxCount != null && currentCount != null && currentCount >= maxCount) {
      return true;
    }

    return false;
  }

  /**
   * @description Increment loop count
   */
  private void incrementLoopCount() {
    String handlerName = String.valueOf(this)
      .substring(0, String.valueOf(this).indexOf(':'));
    Integer currentCount = loopCountMap.get(handlerName);
    loopCountMap.put(handlerName, currentCount == null ? 1 : currentCount + 1);
  }

  // Abstract methods to be implemented by concrete handlers
  protected virtual void beforeInsert() {
    // Override in concrete handler classes
  }
  protected virtual void afterInsert() {
    // Override in concrete handler classes
  }
  protected virtual void beforeUpdate() {
    // Override in concrete handler classes
  }
  protected virtual void afterUpdate() {
    // Override in concrete handler classes
  }
  protected virtual void beforeDelete() {
    // Override in concrete handler classes
  }
  protected virtual void afterDelete() {
    // Override in concrete handler classes
  }
  protected virtual void afterUndelete() {
    // Override in concrete handler classes
  }

  /**
   * @description Custom exception for trigger handler errors
   */
  public class TriggerHandlerException extends Exception {
  }
}
