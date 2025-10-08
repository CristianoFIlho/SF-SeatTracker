/**
 * @description TestHelper utility class following Context7 Apex Recipes patterns
 * @author Based on Apex Recipes TestHelper implementation
 * @date 2025-01-27
 */
@isTest
public class TestHelper {
  /**
   * @description Get the class name of an object as a string
   * @param obj The object to get the class name from
   * @return String The class name
   */
  public static String getClassName(Object obj) {
    return String.valueOf(obj).substring(0, String.valueOf(obj).indexOf(':'));
  }

  /**
   * @description Create test data for a given object type
   * @param objectType The API name of the object type
   * @param count Number of records to create
   * @return List<SObject> List of created records
   */
  public static List<SObject> createTestData(String objectType, Integer count) {
    List<SObject> records = new List<SObject>();
    
    for (Integer i = 0; i < count; i++) {
      SObject record = Schema.getGlobalDescribe().get(objectType).newSObject();
      
      // Set common fields based on object type
      if (objectType == 'Movie__c') {
        record.put('Name', 'Test Movie ' + i);
        record.put('Movie_API_ID__c', 'test' + i);
        record.put('Is_Active__c', true);
      } else if (objectType == 'Theater__c') {
        record.put('Name', 'Test Theater ' + i);
        record.put('Theater_API_ID__c', 'theater' + i);
        record.put('City__c', 'Test City ' + i);
        record.put('Is_Active__c', true);
      } else if (objectType == 'Showtime__c') {
        record.put('Session_Date__c', Date.today().addDays(i + 1));
        record.put('Session_Time__c', Time.newInstance(14, 30, 0, 0));
        record.put('Total_Seats__c', 100);
        record.put('Reserved_Seats__c', 0);
        record.put('Ticket_Price__c', 15.00);
        record.put('Status__c', 'Scheduled');
      }
      
      records.add(record);
    }
    
    return records;
  }

  /**
   * @description Create test data with relationships
   * @param objectType The API name of the object type
   * @param count Number of records to create
   * @param parentRecords Parent records to relate to
   * @return List<SObject> List of created records
   */
  public static List<SObject> createTestDataWithRelationships(
    String objectType, 
    Integer count, 
    List<SObject> parentRecords
  ) {
    List<SObject> records = new List<SObject>();
    
    for (Integer i = 0; i < count; i++) {
      SObject record = Schema.getGlobalDescribe().get(objectType).newSObject();
      
      // Set relationship fields
      if (objectType == 'Showtime__c' && parentRecords.size() >= 2) {
        record.put('Movie__c', parentRecords[0].Id);
        record.put('Theater__c', parentRecords[1].Id);
        record.put('Session_Date__c', Date.today().addDays(i + 1));
        record.put('Session_Time__c', Time.newInstance(14, 30, 0, 0));
        record.put('Total_Seats__c', 100);
        record.put('Reserved_Seats__c', 0);
        record.put('Ticket_Price__c', 15.00);
        record.put('Status__c', 'Scheduled');
      }
      
      records.add(record);
    }
    
    return records;
  }

  /**
   * @description Assert that a list of records has the expected size
   * @param records List of records to check
   * @param expectedSize Expected number of records
   * @param message Assertion message
   */
  public static void assertRecordCount(List<SObject> records, Integer expectedSize, String message) {
    System.assertEquals(expectedSize, records.size(), message);
  }

  /**
   * @description Assert that a record has a specific field value
   * @param record The record to check
   * @param fieldName The field name to check
   * @param expectedValue The expected value
   * @param message Assertion message
   */
  public static void assertFieldValue(SObject record, String fieldName, Object expectedValue, String message) {
    System.assertEquals(expectedValue, record.get(fieldName), message);
  }

  /**
   * @description Create a test user with specific profile
   * @param profileName The profile name
   * @param username The username
   * @return User The created user
   */
  public static User createTestUser(String profileName, String username) {
    Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
    
    User testUser = new User(
      FirstName = 'Test',
      LastName = 'User',
      Email = username + '@test.com',
      Username = username + '@test.com',
      Alias = 'test',
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = profile.Id
    );
    
    return testUser;
  }

  /**
   * @description Run tests as a specific user
   * @param testUser The user to run tests as
   * @param testMethod The test method to run
   */
  public static void runAsUser(User testUser, String testMethod) {
    System.runAs(testUser) {
      // This would need to be implemented based on specific test requirements
      System.debug('Running test method: ' + testMethod + ' as user: ' + testUser.Username);
    }
  }
}
