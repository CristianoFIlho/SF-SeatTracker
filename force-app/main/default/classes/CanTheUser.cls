/**
 * @description CanTheUser utility class following Context7 Apex Recipes patterns
 * @author Based on Apex Recipes CanTheUser implementation
 * @date 2025-01-27
 */
public class CanTheUser {
  /**
   * @description Check if a field is accessible (readable) for the current user
   * @param obj The object API name
   * @param field The field API name
   * @return Boolean True if field is accessible
   */
  public static Boolean flsAccessible(String obj, String field) {
    try {
      SObjectType objType = Schema.getGlobalDescribe().get(obj);
      if (objType == null) {
        return false;
      }

      SObjectField fieldToken = objType.getDescribe()
        .fields.getMap()
        .get(field);
      if (fieldToken == null) {
        return false;
      }

      return fieldToken.getDescribe().isAccessible();
    } catch (Exception e) {
      System.debug('Error checking FLS accessible: ' + e.getMessage());
      return false;
    }
  }

  /**
   * @description Check if a field is updatable for the current user
   * @param obj The object API name
   * @param field The field API name
   * @return Boolean True if field is updatable
   */
  public static Boolean flsUpdatable(String obj, String field) {
    try {
      SObjectType objType = Schema.getGlobalDescribe().get(obj);
      if (objType == null) {
        return false;
      }

      SObjectField fieldToken = objType.getDescribe()
        .fields.getMap()
        .get(field);
      if (fieldToken == null) {
        return false;
      }

      return fieldToken.getDescribe().isUpdateable();
    } catch (Exception e) {
      System.debug('Error checking FLS updatable: ' + e.getMessage());
      return false;
    }
  }

  /**
   * @description Bulk check FLS accessible for multiple fields
   * @param obj The object API name
   * @param fields Set of field names to check
   * @return Map<String,Boolean> Map of field names to accessibility
   */
  public static Map<String, Boolean> bulkFLSAccessible(
    String obj,
    Set<String> fields
  ) {
    Map<String, Boolean> results = new Map<String, Boolean>();

    try {
      SObjectType objType = Schema.getGlobalDescribe().get(obj);
      if (objType == null) {
        for (String field : fields) {
          results.put(field, false);
        }
        return results;
      }

      Map<String, SObjectField> fieldMap = objType.getDescribe()
        .fields.getMap();

      for (String field : fields) {
        SObjectField fieldToken = fieldMap.get(field);
        if (fieldToken != null) {
          results.put(field, fieldToken.getDescribe().isAccessible());
        } else {
          results.put(field, false);
        }
      }
    } catch (Exception e) {
      System.debug('Error checking bulk FLS accessible: ' + e.getMessage());
      for (String field : fields) {
        results.put(field, false);
      }
    }

    return results;
  }

  /**
   * @description Bulk check FLS updatable for multiple fields
   * @param obj The object API name
   * @param fields Set of field names to check
   * @return Map<String,Boolean> Map of field names to updatability
   */
  public static Map<String, Boolean> bulkFLSUpdatable(
    String obj,
    Set<String> fields
  ) {
    Map<String, Boolean> results = new Map<String, Boolean>();

    try {
      SObjectType objType = Schema.getGlobalDescribe().get(obj);
      if (objType == null) {
        for (String field : fields) {
          results.put(field, false);
        }
        return results;
      }

      Map<String, SObjectField> fieldMap = objType.getDescribe()
        .fields.getMap();

      for (String field : fields) {
        SObjectField fieldToken = fieldMap.get(field);
        if (fieldToken != null) {
          results.put(field, fieldToken.getDescribe().isUpdateable());
        } else {
          results.put(field, false);
        }
      }
    } catch (Exception e) {
      System.debug('Error checking bulk FLS updatable: ' + e.getMessage());
      for (String field : fields) {
        results.put(field, false);
      }
    }

    return results;
  }

  /**
   * @description Check if user can create records of a given type
   * @param obj The object API name
   * @return Boolean True if user can create records
   */
  public static Boolean canCreate(String obj) {
    try {
      SObjectType objType = Schema.getGlobalDescribe().get(obj);
      if (objType == null) {
        return false;
      }

      return objType.getDescribe().isCreateable();
    } catch (Exception e) {
      System.debug('Error checking can create: ' + e.getMessage());
      return false;
    }
  }

  /**
   * @description Check if user can read records of a given type
   * @param obj The object API name
   * @return Boolean True if user can read records
   */
  public static Boolean canRead(String obj) {
    try {
      SObjectType objType = Schema.getGlobalDescribe().get(obj);
      if (objType == null) {
        return false;
      }

      return objType.getDescribe().isAccessible();
    } catch (Exception e) {
      System.debug('Error checking can read: ' + e.getMessage());
      return false;
    }
  }

  /**
   * @description Check if user can update records of a given type
   * @param obj The object API name
   * @return Boolean True if user can update records
   */
  public static Boolean canUpdate(String obj) {
    try {
      SObjectType objType = Schema.getGlobalDescribe().get(obj);
      if (objType == null) {
        return false;
      }

      return objType.getDescribe().isUpdateable();
    } catch (Exception e) {
      System.debug('Error checking can update: ' + e.getMessage());
      return false;
    }
  }

  /**
   * @description Check if user can delete records of a given type
   * @param obj The object API name
   * @return Boolean True if user can delete records
   */
  public static Boolean canDelete(String obj) {
    try {
      SObjectType objType = Schema.getGlobalDescribe().get(obj);
      if (objType == null) {
        return false;
      }

      return objType.getDescribe().isDeletable();
    } catch (Exception e) {
      System.debug('Error checking can delete: ' + e.getMessage());
      return false;
    }
  }

  /**
   * @description Custom exception class for CanTheUser errors
   */
  public class CanTheUserException extends Exception {
  }
}
