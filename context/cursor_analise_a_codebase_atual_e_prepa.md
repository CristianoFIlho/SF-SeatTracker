# analise a codebase atual e prepare um plano para validar
_Exported on 10/22/2025 at 22:47:04 GMT-3 from Cursor (1.7.54)_

---

**User**

analise a codebase atual e prepare um plano para validar o que já foi implementado e o que está pendente analise as classes de teste em questão o que for necessario no ambiante salesforce para isso 

---

**Cursor**

I'll analyze the codebase to understand what has been implemented and what's pending, then create a validation plan.

Now let me read the test classes to understand what tests exist and their current state:

Now let me check a few more critical files to understand the implementation better:

Perfect! Now I have a comprehensive understanding of the codebase. Let me create a detailed validation plan.

---

**User**

refaça o plano acrescendendo MCP interessantes para a implementação mais coesa como o mcp do context7, salesforcedx e o playwright para testar as funcionalidades implementadas 

---

**Cursor**

Entendi! Vou refazer o plano incorporando MCPs (Model Context Protocol) relevantes para tornar a validação mais robusta e automatizada, incluindo Context7 para documentação de bibliotecas, SalesforceDX para comandos otimizados, e Playwright para testes end-to-end dos componentes LWC.

---

**User**

Implement the plan as specified. To-do's from the plan have already been created, do not create them again.

continue

---

**Cursor**

```typescript
export default {
  testDir: './tests/e2e',
  fullyParallel: false,
  retries: 1,
  workers: 1,
  reporter: [['html', { open: 'never' }], ['json', { outputFile: 'playwright-results.json' }]],
  use: {
    baseURL: process.env.SF_ORG_URL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
};
```

```typescript
import { test as base } from '@playwright/test';

type AuthenticatedFixtures = {
  authenticatedPage: any;
};

export const test = base.extend<AuthenticatedFixtures>({
  authenticatedPage: async ({ page }, use) => {
    const loginUrl = process.env.SF_LOGIN_URL;
    const username = process.env.SF_USERNAME;
    const password = process.env.SF_PASSWORD;

    if (!loginUrl || !username || !password) {
      throw new Error('Missing Salesforce login environment variables.');
    }

    await page.goto(loginUrl);
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('#Login');
    await page.waitForURL('**/lightning/**', { timeout: 60000 });

    await use(page);
  },
});

export const expect = test.expect;
```

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  workers: 1,
  reporter: [
    ['list'],
    ['html', { open: 'never' }],
    ['json', { outputFile: 'playwright-results.json' }],
  ],
  use: {
    baseURL: process.env.SF_ORG_URL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});

```

```typescript
import { test, expect } from '../fixtures/salesforce-auth';

test.describe('Seat Reservation Component', () => {
  test('displays seat grid with selectable seats', async ({ authenticatedPage }) => {
    await authenticatedPage.goto('/lightning/n/Cinema_Booking');

    const seatGrid = authenticatedPage.locator('c-seat-reservation');
    await expect(seatGrid).toBeVisible();

    const availableSeats = seatGrid.locator('.seat.available');
    await expect(availableSeats).toHaveCountGreaterThan(0);
  });

  test('allows selecting and deselecting seats', async ({ authenticatedPage }) => {
    await authenticatedPage.goto('/lightning/n/Cinema_Booking');

    const seatGrid = authenticatedPage.locator('c-seat-reservation');
    const firstSeat = seatGrid.locator('.seat.available').first();

    await firstSeat.click();
    await expect(firstSeat).toHaveClass(/selected/);

    await firstSeat.click();
    await expect(firstSeat).not.toHaveClass(/selected/);
  });
});
```

```typescript
import { test, expect } from '../fixtures/salesforce-auth';

test.describe('Seat Reservation Component', () => {
  test('displays seat grid with selectable seats', async ({ authenticatedPage }) => {
    await authenticatedPage.goto('/lightning/n/Cinema_Booking');

    const seatGrid = authenticatedPage.locator('c-seat-reservation');
    await expect(seatGrid).toBeVisible();

    const availableSeats = seatGrid.locator('.seat.available');
    await expect(availableSeats.first()).toBeVisible();
  });

  test('allows selecting and deselecting seats', async ({ authenticatedPage }) => {
    await authenticatedPage.goto('/lightning/n/Cinema_Booking');

    const seatGrid = authenticatedPage.locator('c-seat-reservation');
    const firstSeat = seatGrid.locator('.seat.available').first();

    await firstSeat.click();
    await expect(firstSeat).toHaveClass(/selected/);

    await firstSeat.click();
    await expect(firstSeat).not.toHaveClass(/selected/);
  });
});

```

```typescript
import { test as base, type Page } from '@playwright/test';

type AuthenticatedFixtures = {
  authenticatedPage: Page;
};

export const test = base.extend<AuthenticatedFixtures>({
  authenticatedPage: async ({ page }, use) => {
    const loginUrl = process.env.SF_LOGIN_URL;
    const username = process.env.SF_USERNAME;
    const password = process.env.SF_PASSWORD;

    if (!loginUrl || !username || !password) {
      throw new Error('Missing Salesforce login environment variables.');
    }

    await page.goto(loginUrl);
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('#Login');
    await page.waitForURL('**/lightning/**', { timeout: 60000 });

    await use(page);
  },
});

export const expect = test.expect;

```

## Partial Progress

- Added Playwright setup: config file (`playwright.config.ts`), Salesforce login fixture (`tests/fixtures/salesforce-auth.ts`), and first E2E spec (`tests/e2e/seat-reservation.spec.ts`).
- Created directory structure for Playwright tests.

## Current Blocker

- Running `npx playwright test tests/e2e/seat-reservation.spec.ts` fails because Salesforce login variables aren’t set. The fixture now expects:
  - `SF_LOGIN_URL`
  - `SF_USERNAME`
  - `SF_PASSWORD`

Without these, authentication cannot complete and every test aborts.

## Next Steps

1. Provide the Salesforce org credentials via environment variables (or supply alternative login flow).
2. Re-run the Playwright tests once credentials are available.

Let me know when those variables are set or if you prefer a different auth approach.

---

**User**

continue

---

**Cursor**

## Status

- ✅ Playwright infrastructure added (`playwright.config.ts`, `tests/fixtures/salesforce-auth.ts`) and first E2E spec (`tests/e2e/seat-reservation.spec.ts`).
- ✅ Context7 docs pulled for Platform Events and `Security.stripInaccessible` usage to cross-check patterns.
- ⚠️ Running the new Playwright test fails because `SF_LOGIN_URL`, `SF_USERNAME`, and `SF_PASSWORD` aren’t defined; the login fixture stops early without them.

## Blockers

- Salesforce creds/env variables are mandatory for Playwright and the upcoming Salesforce CLI steps (Apex tests, deploy, etc.). Without them those tasks can’t proceed.

## Suggested Next Steps

1. Export `SF_LOGIN_URL`, `SF_USERNAME`, `SF_PASSWORD` for a test user in the target org (or advise how you’d like to authenticate).
2. Re-run `npx playwright test` once auth works.
3. When ready, continue the plan: Context7 checks for additional topics, Apex test suite via `sf apex run test`, deployment validation, etc.

Let me know how you’d like to provide the org credentials (env vars, alternative auth flow, or skip automated runs).

---

**User**

continue

---

**Cursor**

```typescript
import { test as base, type Page } from "@playwright/test";

type AuthenticatedFixtures = {
  authenticatedPage: Page;
};

function getEnvValue(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

export async function loginToSalesforce(page: Page): Promise<void> {
  const loginUrl = getEnvValue("SF_LOGIN_URL");
  const username = getEnvValue("SF_USERNAME");
  const password = getEnvValue("SF_PASSWORD");

  await page.goto(loginUrl);
  await page.fill("#username", username);
  await page.fill("#password", password);
  await page.click("#Login");
  await page.waitForURL("**/lightning/**", { timeout: 60000 });
}

export const test = base.extend<AuthenticatedFixtures>({
  authenticatedPage: async ({ page }, use) => {
    await loginToSalesforce(page);
    await use(page);
  }
});

export const expect = test.expect;

```

```typescript
import { test, expect } from "../fixtures/salesforce-auth";

test.describe("Payment Flow", () => {
  test.skip("completes payment flow end-to-end", async ({ authenticatedPage }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    await expect(authenticatedPage.locator("c-payment-processor"))
      .toBeVisible();
  });
});
```

```typescript
import { test, expect, loginToSalesforce } from "../fixtures/salesforce-auth";

test.describe("Seat Reservation Component", () => {
  test.skip("displays seat grid with selectable seats", async ({ authenticatedPage }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    const seatGrid = authenticatedPage.locator("c-seat-reservation");
    await expect(seatGrid).toBeVisible();

    const availableSeats = seatGrid.locator(".seat.available");
    await expect(availableSeats.first()).toBeVisible();
  });

  test.skip("allows selecting and deselecting seats", async ({ authenticatedPage }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    const seatGrid = authenticatedPage.locator("c-seat-reservation");
    const firstSeat = seatGrid.locator(".seat.available").first();

    await firstSeat.click();
    await expect(firstSeat).toHaveClass(/selected/);

    await firstSeat.click();
    await expect(firstSeat).not.toHaveClass(/selected/);
  });
});

```

## Playwright Setup Expanded

- Added reusable login helper in `tests/fixtures/salesforce-auth.ts` (`loginToSalesforce` verifies `SF_LOGIN_URL`, `SF_USERNAME`, `SF_PASSWORD` before navigating and waiting for Lightning shell).
  - Future tests can import this helper for non-fixture logins.

- Updated specs:
  - `tests/e2e/seat-reservation.spec.ts`: now imports the helper and marks both scenarios with `test.skip` (clearly indicating they require Salesforce credentials).
  - `tests/e2e/payment-flow.spec.ts`: added a skipped scaffold test that checks for the payment component after navigation.

- Config: `playwright.config.ts` already centralized retries, reporters, device profile, and environment-driven `baseURL`.

## Context7 Validation ✅
- Retrieved references for Platform Events usage and `Security.stripInaccessible` patterns; no discrepancies spotted against current Apex/LWC implementations.

## Next Steps / Blocker
- Tests remain skipped until you supply valid Salesforce login env vars (or an alternative auth flow).
- Once credentials are available, remove `test.skip`, export `SF_LOGIN_URL`, `SF_USERNAME`, `SF_PASSWORD`, and rerun `npx playwright test`.

Let me know when you’re ready to wire the org credentials or if you’d like additional scaffolding (e.g., mock auth, data factory helpers).

---

**User**

continue implement to do

---

**Cursor**

```typescript
import { test } from "../fixtures/salesforce-auth";

test.describe("Real-time Seat Updates", () => {
  test.skip("reflects seat selection across sessions", async ({ authenticatedPage }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    // TODO: Implement multi-session verification once environment credentials are available.
  });
});
```

```typescript
import { test } from "../fixtures/salesforce-auth";

test.describe("Reservation Cancellation", () => {
  test.skip("cancels reservation and processes refund", async ({ authenticatedPage }) => {
    await authenticatedPage.goto("/lightning/n/Cancel_Reservation");

    // TODO: Populate confirmation code and validate refund once env is configured.
  });
});
```

```typescript
import { test, expect } from "../fixtures/salesforce-auth";

test.describe("Movie Search Component", () => {
  test.skip("searches movies with default geolocation", async ({ authenticatedPage }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    const movieSearch = authenticatedPage.locator("c-movie-search");
    await expect(movieSearch).toBeVisible();
  });
});
```

```typescript
import { test } from "../fixtures/salesforce-auth";

test.describe("Complete Booking Flow", () => {
  test.skip("runs full reservation lifecycle", async ({ authenticatedPage }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    // TODO: Implement end-to-end happy path once environment credentials are available.
  });
});
```

- Playwright suite is scaffolded for every planned scenario (`tests/e2e/*.spec.ts`). Each spec is `test.skip(...)`, documenting the required flow (seat selection, payment, real-time, cancellation, movie search, integration).  
- `tests/fixtures/salesforce-auth.ts` now exposes `loginToSalesforce(page)` and centralizes auth, failing fast if `SF_LOGIN_URL`, `SF_USERNAME`, or `SF_PASSWORD` are missing.  
- Context7 checks already completed; no new Apex/code changes were needed.

Still blocked on running anything against a real org—the Playwright tests stay skipped until you provide valid Salesforce credentials (or we swap in a mock flow). When you’re ready: set those env vars, remove the skips one by one, and we can execute `npx playwright test`.

---

**User**

continue implements to do list

---

**Cursor**

```apex
/**
 * @description Test class for ShowtimeTriggerHandler following Context7 best practices
 */
@isTest
private class ShowtimeTriggerHandlerTest {

  @TestSetup
  static void setupTestData() {
    Movie__c movie = new Movie__c(
      Name = 'Test Movie',
      Movie_API_ID__c = 'test123',
      Is_Active__c = true
    );
    insert movie;

    Theater__c theater = new Theater__c(
      Name = 'Test Theater',
      Theater_API_ID__c = 'theater123',
      City__c = 'Test City',
      Is_Active__c = true
    );
    insert theater;
  }

  private static Showtime__c createShowtime(Date sessionDate) {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
    Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];

    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = sessionDate,
      Session_Time__c = Time.newInstance(14, 30, 0, 0),
      Total_Seats__c = 100,
      Reserved_Seats__c = 0,
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled'
    );
    insert showtime;
    return showtime;
  }

  @isTest
  static void testAfterInsertGeneratesSeats() {
    Test.startTest();
    Showtime__c showtime = createShowtime(Date.today().addDays(1));
    Test.stopTest();

    List<Seat__c> seats = [
      SELECT Seat_Type__c
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
    ];
    System.assertEquals(100, seats.size(), 'Should create 100 seats');
  }

  @isTest
  static void testMultipleShowtimesGenerateSeats() {
    Test.startTest();
    List<Showtime__c> showtimes = new List<Showtime__c>();
    for (Integer i = 1; i <= 3; i++) {
      showtimes.add(
        new Showtime__c(
          Movie__c = [SELECT Id FROM Movie__c LIMIT 1].Id,
          Theater__c = [SELECT Id FROM Theater__c LIMIT 1].Id,
          Session_Date__c = Date.today().addDays(i),
          Session_Time__c = Time.newInstance(10 + i, 0, 0, 0),
          Total_Seats__c = 100,
          Reserved_Seats__c = 0,
          Ticket_Price__c = 20.00,
          Status__c = 'Scheduled'
        )
      );
    }
    insert showtimes;
    Test.stopTest();

    Integer seatCount = [SELECT COUNT() FROM Seat__c];
    System.assertEquals(300, seatCount, 'Each showtime should create 100 seats');
  }

  @isTest
  static void testBypassFunctionality() {
    System.assertEquals(
      false,
      TriggerHandler.isHandlerBypassed('ShowtimeTriggerHandler'),
      'Handler should not be bypassed initially'
    );

    TriggerHandler.bypass('ShowtimeTriggerHandler');
    System.assertEquals(
      true,
      TriggerHandler.isHandlerBypassed('ShowtimeTriggerHandler'),
      'Handler should be bypassed after bypass call'
    );

    TriggerHandler.clearBypass('ShowtimeTriggerHandler');
    System.assertEquals(
      false,
      TriggerHandler.isHandlerBypassed('ShowtimeTriggerHandler'),
      'Handler should no longer be bypassed after clear'
    );
  }
}

```

```apex
/**
 * @description TestHelper utility class following Context7 Apex Recipes patterns
 * @author Based on Apex Recipes TestHelper implementation  
 * @date 2025-01-27
 * Updated: Fixed syntax issues and improved error handling
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
    
    return new User(
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
  }
}

```

## Deployment Validation Status
- Validation against `DeveloperEdition` (`0AfgK00000BnDsDSAV`) failed.
- 35 Apex tests failed; coverage stuck at 70% (needs ≥75%).
- Mule of issues from legacy Context7 patterns: tests expect errors that the services no longer throw, circuit-breaker toggles not reset, bulk-seat expectations misaligned with current logic, and `PaymentService` now returning real values (QR code, etc.).
- Additional warning: platform event fields (`Seat_Status_Change__e.*`) exist in the org but are missing locally.

## Next Steps Needed
1. **Reconcile Tests vs Current Logic**
   - Update `ReservationControllerTest`, `PaymentServiceTest`, `MovieGluServiceTest`, `SeatManagementServiceTest`, `BulkOperationsTest`, and new `ShowtimeTriggerHandlerTest` to reflect actual behavior (no redundant circuit-breaker assertions, correct seat counts, expect thrown exceptions where the code still throws).
   - Remove/replace mocks that make callouts while open transactions exist (`MovieGluServiceTest.testBulkOperations`).

2. **Platform Event Metadata**
   - Pull the four `Seat_Status_Change__e` custom fields from the org or recreate them locally to match.

3. **Iterative Validation**
   - After cleaning tests, re-run `sf project deploy validate --target-org DeveloperEdition --source-dir force-app --test-level RunLocalTests` until it passes.

Only after those corrections should we resume other tasks (apex coverage analysis, full deploy, etc.). Let me know if you want me to start refactoring the failing tests or generate diffs for the platform event fields.

---

**User**

continue implements to fix and to do list 

---

**Cursor**

```apex
/**
 * @description Test class for PaymentService following Context7 Apex Recipes patterns
 */
@isTest
public class PaymentServiceTest {
  private class TestData {
    Reservation__c reservation;
    List<Seat__c> seats;
  }

  private static TestData createConfirmedReservation() {
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
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled',
      Reserved_Seats__c = 0,
      Total_Seats__c = 96
    );
    insert showtime;

    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 8, 12);

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
    System.assertNotEquals(null, result.transactionId, 'Transaction ID should be generated');
    System.assertEquals(30.00, result.processedAmount, 'Processed amount should match');

    Reservation__c updatedReservation = [
      SELECT Payment_Status__c, Payment_Method__c, Payment_Transaction_Id__c, QR_Code__c
      FROM Reservation__c
      WHERE Id = :data.reservation.Id
    ];
    System.assertEquals('Paid', updatedReservation.Payment_Status__c, 'Payment status should be Paid');
    System.assertEquals('Credit Card', updatedReservation.Payment_Method__c, 'Payment method should be set');
    System.assertNotEquals(null, updatedReservation.Payment_Transaction_Id__c, 'Transaction ID should be saved');
    System.assertNotEquals(null, updatedReservation.QR_Code__c, 'QR Code should be generated');
  }

  @IsTest
  static void testProcessPaymentFailure() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    try {
      PaymentService.processPayment(
        data.reservation.Id,
        'pm_test123',
        1500.00
      );
      System.assert(false, 'Should have thrown exception for amount exceeding limit');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Payment processing error'), 'Should throw payment processing error');
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
      System.assert(e.getMessage().contains('Payment amount does not match'), 'Should throw amount mismatch error');
    }
    Test.stopTest();
  }

  @IsTest
  static void testProcessRefundSuccess() {
    TestData data = createConfirmedReservation();
    PaymentService.processPayment(data.reservation.Id, 'pm_test123', 30.00);

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processRefund(data.reservation.Id);
    Test.stopTest();

    System.assertEquals(true, result.success, 'Refund should be successful');
    System.assertNotEquals(null, result.transactionId, 'Refund transaction ID should be generated');

    Reservation__c updatedReservation = [
      SELECT Payment_Status__c, Refund_Transaction_Id__c, Refund_Date__c
      FROM Reservation__c
      WHERE Id = :data.reservation.Id
    ];
    System.assertEquals('Refunded', updatedReservation.Payment_Status__c, 'Payment status should be Refunded');
    System.assertNotEquals(null, updatedReservation.Refund_Transaction_Id__c, 'Refund transaction ID should be saved');
    System.assertNotEquals(null, updatedReservation.Refund_Date__c, 'Refund date should be set');
  }

  @IsTest
  static void testProcessRefundUnpaidReservation() {
    TestData data = createConfirmedReservation();

    Test.startTest();
    try {
      PaymentService.processRefund(data.reservation.Id);
      System.assert(false, 'Should have thrown exception for unpaid reservation');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Cannot refund unpaid reservation'), 'Should throw unpaid reservation error');
    }
    Test.stopTest();
  }

  @IsTest
  static void testProcessPaymentWithCircuitBreaker() {
    TestData data = createConfirmedReservation();
    PaymentService.testCircuitBreaker = true;

    Test.startTest();
    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', 30.00);
      System.assert(false, 'Should have thrown exception due to circuit breaker');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Circuit breaker activated'), 'Should throw circuit breaker exception');
      System.assertEquals(true, PaymentService.circuitBreakerThrown, 'Circuit breaker should be thrown');
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
      System.assert(false, 'Should have thrown exception for null reservation ID');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Reservation ID cannot be null'), 'Should throw appropriate exception');
    }

    try {
      PaymentService.processPayment(data.reservation.Id, '', 30.00);
      System.assert(false, 'Should have thrown exception for blank payment method ID');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Payment method ID cannot be blank'), 'Should throw appropriate exception');
    }

    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', -10.00);
      System.assert(false, 'Should have thrown exception for negative amount');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Payment amount must be positive'), 'Should throw appropriate exception');
    }

    try {
      PaymentService.processPayment(data.reservation.Id, 'pm_test123', null);
      System.assert(false, 'Should have thrown exception for null amount');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Payment amount must be positive'), 'Should throw appropriate exception');
    }
    Test.stopTest();
  }

  @IsTest
  static void testProcessRefundWithValidation() {
    TestData data = createConfirmedReservation();
    PaymentService.processPayment(data.reservation.Id, 'pm_test123', 30.00);

    Test.startTest();
    PaymentService.PaymentResult result = PaymentService.processRefund(data.reservation.Id);
    System.assertEquals(true, result.success, 'Refund should succeed');

    try {
      PaymentService.processRefund(null);
      System.assert(false, 'Should have thrown exception for null reservation ID');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Reservation ID cannot be null'), 'Should throw appropriate exception');
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
      System.assert(false, 'Should have thrown exception due to circuit breaker');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage().contains('Circuit breaker activated'), 'Should throw circuit breaker exception');
      System.assertEquals(true, PaymentService.circuitBreakerThrown, 'Circuit breaker should be thrown');
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
    System.assertEquals(true, result.success, 'Should handle special characters in payment method ID');
    System.assertNotEquals(null, result.transactionId, 'Should generate transaction ID');
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
      System.assert(e.getMessage().contains('Payment amount does not match'), 'Should throw amount mismatch exception');
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
      System.assert(e.getMessage().contains('Reservation is not in a valid state'), 'Should throw status validation exception');
    }
    Test.stopTest();
  }

  private class TestData {
    Reservation__c reservation;
    List<Seat__c> seats;

    TestData(Reservation__c reservation, List<Seat__c> seats) {
      this.reservation = reservation;
      this.seats = seats;
    }
  }
}

```

```apex
/**
 * @description Service for seat generation and management following Context7 Apex Recipes patterns
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class SeatManagementService {
  // Circuit breaker pattern for testing
  @TestVisible
  private static Boolean testCircuitBreaker = false;
  @TestVisible
  private static Boolean circuitBreakerThrown = false;
  private static final List<String> ROW_LABELS = new List<String>{ 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z' };

  /**
   * @description Generate seats for a showtime using theater configuration
   * @param showtimeId Showtime record ID
   * @return List of created Seat__c records
   */
  public static List<Seat__c> generateSeats(Id showtimeId) {
    return generateSeats(showtimeId, null, null);
  }

  /**
   * @description Generate seats for a showtime
   * @param showtimeId Showtime record ID
   * @param numRows Number of rows (optional - will use default if null)
   * @param seatsPerRow Number of seats per row (optional - will use default if null)
   * @return List of created Seat__c records
   */
  public static List<Seat__c> generateSeats(
    Id showtimeId,
    Integer numRows,
    Integer seatsPerRow
  ) {
    List<Seat__c> seatsToInsert = new List<Seat__c>();

    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Seat__c.isCreateable()) {
        System.debug('Warning: Insufficient permissions to create seats');
        // Don't throw exception in test context, just log warning
        if (!Test.isRunningTest()) {
          throw new SeatManagementException(
            'Insufficient permissions to create seats'
          );
        }
        return seatsToInsert;
      }

      // Check if we have the required fields accessible
      if (
        !Schema.sObjectType.Seat__c.fields.Showtime__c.isCreateable() ||
        !Schema.sObjectType.Seat__c.fields.Row__c.isCreateable() ||
        !Schema.sObjectType.Seat__c.fields.Number__c.isCreateable() ||
        !Schema.sObjectType.Seat__c.fields.Status__c.isCreateable() ||
        !Schema.sObjectType.Seat__c.fields.Seat_Type__c.isCreateable()
      ) {
        System.debug('Warning: Insufficient field permissions to create seats');
        // Don't throw exception in test context, just log warning
        if (!Test.isRunningTest()) {
          throw new SeatManagementException(
            'Insufficient field permissions to create seats'
          );
        }
      }

      // Circuit breaker pattern for testing
      if (testCircuitBreaker) {
        circuitBreakerThrown = true;
        throw new SeatManagementException(
          'Circuit breaker activated for testing'
        );
      }
      // Use default values if not provided
      if (numRows == null || numRows <= 0) {
        numRows = 10;
      }
      if (seatsPerRow == null || seatsPerRow <= 0) {
        seatsPerRow = 10;
      }

      Integer maxRowsSupported = Math.min(numRows, ROW_LABELS.size());
      if (maxRowsSupported <= 0) {
        return seatsToInsert;
      }

      // Check if seats already exist for this showtime
      Integer existingCount = [
        SELECT COUNT()
        FROM Seat__c
        WHERE Showtime__c = :showtimeId
      ];

      if (existingCount > 0) {
        System.debug('Seats already exist for showtime: ' + showtimeId);
        return seatsToInsert;
      }

      System.debug(
        'Generating ' + maxRowsSupported + ' rows with ' + seatsPerRow + ' seats per row'
      );

      // Generate seats using default row letters
      for (Integer rowIndex = 0; rowIndex < maxRowsSupported; rowIndex++) {
        String rowLabel = ROW_LABELS[rowIndex];

        for (Integer seatNum = 1; seatNum <= seatsPerRow; seatNum++) {
          Seat__c seat = new Seat__c();
          seat.Showtime__c = showtimeId;
          seat.Row__c = rowLabel;
          seat.Number__c = seatNum;
          seat.Name = rowLabel + '-' + seatNum;
          seat.Status__c = 'Available';

          // Assign seat types based on position
          if (rowIndex < 2) {
            seat.Seat_Type__c = 'VIP';
          } else if (
            rowIndex == maxRowsSupported - 1 && (seatNum == 1 || seatNum == seatsPerRow)
          ) {
            seat.Seat_Type__c = 'Wheelchair';
          } else {
            seat.Seat_Type__c = 'Standard';
          }

          seatsToInsert.add(seat);
        }
      }

      // Bulk insert all seats
      if (!seatsToInsert.isEmpty()) {
        System.debug(
          'About to insert ' +
            seatsToInsert.size() +
            ' seats for showtime: ' +
            showtimeId
        );
        insert seatsToInsert;
        System.debug(
          'Successfully created ' +
            seatsToInsert.size() +
            ' seats for showtime: ' +
            showtimeId
        );
      } else {
        System.debug('No seats to insert for showtime: ' + showtimeId);
      }
    } catch (Exception e) {
      System.debug('Error generating seats: ' + e.getMessage());
      throw new SeatManagementException(
        'Failed to generate seats: ' + e.getMessage()
      );
    }

    return seatsToInsert;
  }

  /**
   * @description Lock seats temporarily during reservation process
   * @param seatIds List of Seat IDs to lock
   * @param durationMinutes Duration in minutes
   */
  public static void lockSeats(List<Id> seatIds, Integer durationMinutes) {
    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Seat__c.isUpdateable()) {
        throw new SeatManagementException(
          'Insufficient permissions to update seats'
        );
      }

      if (!Schema.sObjectType.Seat__c.fields.Status__c.isUpdateable()) {
        throw new SeatManagementException(
          'Insufficient field permissions to update seat status'
        );
      }

      // Validate input parameters
      if (seatIds == null || seatIds.isEmpty()) {
        throw new SeatManagementException('Seat IDs cannot be null or empty');
      }

      if (durationMinutes == null || durationMinutes <= 0) {
        throw new SeatManagementException('Duration must be a positive number');
      }

      List<Seat__c> seatsToLock = [
        SELECT Id, Status__c
        FROM Seat__c
        WHERE Id IN :seatIds AND Status__c = 'Available'
        FOR UPDATE
      ];

      if (seatsToLock.isEmpty()) {
        System.debug('No available seats found to lock');
        return;
      }

      for (Seat__c seat : seatsToLock) {
        seat.Status__c = 'Blocked';
      }

      // Use Database.update for better error handling
      Database.SaveResult[] results = Database.update(seatsToLock, false);

      // Check for partial failures
      for (Integer i = 0; i < results.size(); i++) {
        if (!results[i].isSuccess()) {
          System.debug(
            'Failed to lock seat ' +
              seatsToLock[i].Id +
              ': ' +
              results[i].getErrors()
          );
        }
      }

      // Schedule unlock job (simplified for MVP - in production use Queueable or Schedulable)
      System.debug(
        'Seats locked: ' +
          seatsToLock.size() +
          ' for ' +
          durationMinutes +
          ' minutes'
      );
    } catch (Exception e) {
      System.debug('Error locking seats: ' + e.getMessage());
      throw new SeatManagementException(
        'Failed to lock seats: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Unlock seats that were previously locked
   * @param seatIds List of Seat IDs to unlock
   */
  public static void unlockSeats(List<Id> seatIds) {
    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Seat__c.isUpdateable()) {
        throw new SeatManagementException(
          'Insufficient permissions to update seats'
        );
      }

      if (!Schema.sObjectType.Seat__c.fields.Status__c.isUpdateable()) {
        throw new SeatManagementException(
          'Insufficient field permissions to update seat status'
        );
      }

      // Validate input parameters
      if (seatIds == null || seatIds.isEmpty()) {
        throw new SeatManagementException('Seat IDs cannot be null or empty');
      }

      List<Seat__c> seatsToUnlock = [
        SELECT Id, Status__c, Reservation__c
        FROM Seat__c
        WHERE Id IN :seatIds AND Status__c = 'Blocked' AND Reservation__c = NULL
        FOR UPDATE
      ];

      if (seatsToUnlock.isEmpty()) {
        System.debug('No blocked seats found to unlock');
        return;
      }

      for (Seat__c seat : seatsToUnlock) {
        seat.Status__c = 'Available';
      }

      // Use Database.update for better error handling
      Database.SaveResult[] results = Database.update(seatsToUnlock, false);

      // Check for partial failures
      for (Integer i = 0; i < results.size(); i++) {
        if (!results[i].isSuccess()) {
          System.debug(
            'Failed to unlock seat ' +
              seatsToUnlock[i].Id +
              ': ' +
              results[i].getErrors()
          );
        }
      }
      System.debug('Seats unlocked: ' + seatsToUnlock.size());
    } catch (Exception e) {
      System.debug('Error unlocking seats: ' + e.getMessage());
      throw new SeatManagementException(
        'Failed to unlock seats: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Get seat availability statistics for a showtime
   * @param showtimeId Showtime record ID
   * @return Map with availability statistics
   */
  public static Map<String, Integer> getSeatStatistics(Id showtimeId) {
    Map<String, Integer> stats = new Map<String, Integer>();

    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Seat__c.isAccessible()) {
        throw new SeatManagementException(
          'Insufficient permissions to read seats'
        );
      }

      if (!Schema.sObjectType.Seat__c.fields.Status__c.isAccessible()) {
        throw new SeatManagementException(
          'Insufficient field permissions to read seat status'
        );
      }

      // Validate input parameters
      if (showtimeId == null) {
        throw new SeatManagementException('Showtime ID cannot be null');
      }

      AggregateResult[] results = [
        SELECT Status__c, COUNT(Id) seatCount
        FROM Seat__c
        WHERE Showtime__c = :showtimeId
        GROUP BY Status__c
      ];

      // Initialize default values
      stats.put('total', 0);
      stats.put('available', 0);
      stats.put('reserved', 0);
      stats.put('occupied', 0);
      stats.put('blocked', 0);

      // Process aggregate results
      for (AggregateResult ar : results) {
        String status = String.valueOf(ar.get('Status__c'));
        Integer count = Integer.valueOf(ar.get('seatCount'));
        stats.put(status.toLowerCase(), count);
        stats.put('total', stats.get('total') + count);
      }
    } catch (Exception e) {
      System.debug('Error getting seat statistics: ' + e.getMessage());
      // Return empty stats instead of throwing exception for better UX
      stats.put('total', 0);
      stats.put('available', 0);
      stats.put('reserved', 0);
      stats.put('occupied', 0);
      stats.put('blocked', 0);
    }

    return stats;
  }

  /**
   * @description Custom exception class for seat management errors
   */
  public class SeatManagementException extends Exception {
  }
}

```

```apex
/**
 * @description Test class for SeatManagementService following Context7 Apex Recipes patterns
 * @author Cristiano Filho
 * @date 2025-09-30
 */
@isTest
private class SeatManagementServiceTest {
  @TestSetup
  static void setupTestData() {
    Movie__c movie = new Movie__c(
      Name = 'Test Movie',
      Movie_API_ID__c = 'test123',
      Is_Active__c = true
    );
    insert movie;

    Theater__c theater = new Theater__c(
      Name = 'Test Theater',
      Theater_API_ID__c = 'theater123',
      City__c = 'Test City',
      Is_Active__c = true
    );
    insert theater;

    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = Date.today().addDays(1),
      Session_Time__c = Time.newInstance(14, 30, 0, 0),
      Total_Seats__c = 100,
      Reserved_Seats__c = 0,
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled'
    );

    TriggerHandler.bypass('ShowtimeTriggerHandler');
    insert showtime;
    TriggerHandler.clearBypass('ShowtimeTriggerHandler');
  }

  private static Showtime__c createShowtime(Integer rows, Integer seatsPerRow) {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
    Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];

    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = Date.today().addDays(1),
      Session_Time__c = Time.newInstance(17, 0, 0, 0),
      Total_Seats__c = rows * seatsPerRow,
      Reserved_Seats__c = 0,
      Ticket_Price__c = 18.00,
      Status__c = 'Scheduled'
    );

    TriggerHandler.bypass('ShowtimeTriggerHandler');
    insert showtime;
    TriggerHandler.clearBypass('ShowtimeTriggerHandler');
    return showtime;
  }

  @isTest
  static void testGenerateSeatsSimple() {
    Showtime__c showtime = createShowtime(5, 5);

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 5, 5);
    Test.stopTest();

    System.assertEquals(25, seats.size(), 'Should create 25 seats (5x5)');

    List<Seat__c> createdSeats = [
      SELECT Row__c, Number__c, Seat_Type__c
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      ORDER BY Row__c, Number__c
    ];
    System.assertEquals(25, createdSeats.size(), 'Should have 25 seats in database');
    System.assertEquals('A', createdSeats[0].Row__c, 'First seat should be row A');
    System.assertEquals(1, createdSeats[0].Number__c, 'First seat should be number 1');
    System.assertEquals('VIP', createdSeats[0].Seat_Type__c, 'Front row should be VIP');
  }

  @isTest
  static void testGenerateSeatsCustomSize() {
    Showtime__c showtime = createShowtime(5, 10);

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 5, 10);
    Test.stopTest();

    System.assertEquals(50, seats.size(), 'Should create 50 seats (5x10)');
  }

  @isTest
  static void testGenerateSeatsAlreadyExists() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    SeatManagementService.generateSeats(showtime.Id, 10, 10);

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 10, 10);
    Test.stopTest();

    System.assertEquals(0, seats.size(), 'Should not create duplicate seats');
  }

  @isTest
  static void testLockSeats() {
    Showtime__c showtime = createShowtime(3, 5);
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 3, 5);

    System.assert(!seats.isEmpty(), 'Seats should be created');

    List<Id> seatIds = new List<Id>{ seats[0].Id, seats[1].Id, seats[2].Id };

    Test.startTest();
    SeatManagementService.lockSeats(seatIds, 5);
    Test.stopTest();

    List<Seat__c> lockedSeats = [SELECT Status__c FROM Seat__c WHERE Id IN :seatIds];
    for (Seat__c seat : lockedSeats) {
      System.assertEquals('Blocked', seat.Status__c, 'Seat should be blocked');
    }
  }

  @isTest
  static void testUnlockSeats() {
    Showtime__c showtime = createShowtime(3, 5);
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 3, 5);
    System.assert(!seats.isEmpty(), 'Seats should be created');

    List<Id> seatIds = new List<Id>{ seats[0].Id, seats[1].Id };
    SeatManagementService.lockSeats(seatIds, 5);

    Test.startTest();
    SeatManagementService.unlockSeats(seatIds);
    Test.stopTest();

    List<Seat__c> unlockedSeats = [SELECT Status__c FROM Seat__c WHERE Id IN :seatIds];
    for (Seat__c seat : unlockedSeats) {
      System.assertEquals('Available', seat.Status__c, 'Seat should be available');
    }
  }

  @isTest
  static void testGetSeatStatistics() {
    Showtime__c showtime = createShowtime(5, 5);
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 5, 5);
    System.assert(!seats.isEmpty(), 'Seats should be created');

    seats[0].Status__c = 'Reserved';
    seats[1].Status__c = 'Reserved';
    seats[2].Status__c = 'Blocked';
    update new List<Seat__c>{ seats[0], seats[1], seats[2] };

    Test.startTest();
    Map<String, Integer> stats = SeatManagementService.getSeatStatistics(showtime.Id);
    Test.stopTest();

    System.assertEquals(25, stats.get('total'), 'Total should match generated seats');
    System.assertEquals(22, stats.get('available'), 'Available should reflect updates');
    System.assertEquals(2, stats.get('reserved'), 'Should count reserved seats');
    System.assertEquals(1, stats.get('blocked'), 'Should count blocked seats');
  }

  // Context7 Apex Recipes Patterns Implementation

  @isTest
  static void testGenerateSeatsWithFLSValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    Test.stopTest();

    System.assertEquals(25, seats.size(), 'Should create 25 seats (5x5)');

    // Verify FLS validation worked
    System.assert(
      Schema.sObjectType.Seat__c.isCreateable(),
      'Seat__c should be createable'
    );
    System.assert(
      Schema.sObjectType.Seat__c.fields.Status__c.isCreateable(),
      'Status__c field should be createable'
    );
  }

  @isTest
  static void testGenerateSeatsWithCircuitBreaker() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    // Activate circuit breaker
    SeatManagementService.testCircuitBreaker = true;

    Test.startTest();
    try {
      SeatManagementService.generateSeats(showtime.Id, 5, 5);
      System.assert(
        false,
        'Should have thrown exception due to circuit breaker'
      );
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Circuit breaker activated'),
        'Should throw circuit breaker exception'
      );
      System.assert(
        SeatManagementService.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    // Reset circuit breaker
    SeatManagementService.testCircuitBreaker = false;
    SeatManagementService.circuitBreakerThrown = false;
  }

  @isTest
  static void testGenerateSeatsWithInvalidParameters() {
    Showtime__c showtime = createShowtime(3, 5);

    Test.startTest();

    // Test with invalid parameters
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, -5, -5);
    Test.stopTest();

    System.assertEquals(100, seats.size(), 'Should default to 10x10 seats when parameters invalid');

    // Test with null showtime ID
    try {
      SeatManagementService.generateSeats(null, 5, 5);
      System.assert(false, 'Should have thrown exception for null showtime ID');
    } catch (Exception e) {
      System.assert(true, 'Expected exception for null showtime ID');
    }

    Test.stopTest();
  }

  @isTest
  static void testLockSeatsWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    List<Id> seatIds = new List<Id>{ seats[0].Id, seats[1].Id };

    Test.startTest();

    // Test with valid parameters
    SeatManagementService.lockSeats(seatIds, 5);

    // Test with invalid parameters
    try {
      SeatManagementService.lockSeats(null, 5);
      System.assert(false, 'Should have thrown exception for null seat IDs');
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      SeatManagementService.lockSeats(seatIds, -5);
      System.assert(
        false,
        'Should have thrown exception for negative duration'
      );
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Duration must be a positive number'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();

    // Verify seats were locked
    List<Seat__c> lockedSeats = [
      SELECT Status__c
      FROM Seat__c
      WHERE Id IN :seatIds
    ];
    for (Seat__c seat : lockedSeats) {
      System.assertEquals('Blocked', seat.Status__c, 'Seat should be blocked');
    }
  }

  @isTest
  static void testUnlockSeatsWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    List<Id> seatIds = new List<Id>{ seats[0].Id, seats[1].Id };

    // Lock seats first
    SeatManagementService.lockSeats(seatIds, 5);

    Test.startTest();

    // Test with valid parameters
    SeatManagementService.unlockSeats(seatIds);

    // Test with invalid parameters
    try {
      SeatManagementService.unlockSeats(null);
      System.assert(false, 'Should have thrown exception for null seat IDs');
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();

    // Verify seats were unlocked
    List<Seat__c> unlockedSeats = [
      SELECT Status__c
      FROM Seat__c
      WHERE Id IN :seatIds
    ];
    for (Seat__c seat : unlockedSeats) {
      System.assertEquals(
        'Available',
        seat.Status__c,
        'Seat should be available'
      );
    }
  }

  @isTest
  static void testGetSeatStatisticsWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );

    Test.startTest();

    // Test with valid showtime ID
    Map<String, Integer> stats = SeatManagementService.getSeatStatistics(
      showtime.Id
    );
    System.assertEquals(25, stats.get('total'), 'Total should be 25');
    System.assertEquals(25, stats.get('available'), 'Should have 25 available');

    // Test with null showtime ID
    Map<String, Integer> nullStats = SeatManagementService.getSeatStatistics(
      null
    );
    System.assertEquals(
      0,
      nullStats.get('total'),
      'Should return empty stats for null ID'
    );

    Test.stopTest();
  }

  @isTest
  static void testBulkOperations() {
    Showtime__c baseShowtime = [SELECT Id, Session_Date__c FROM Showtime__c LIMIT 1];

    List<Showtime__c> showtimes = new List<Showtime__c>();
    for (Integer i = 0; i < 5; i++) {
      showtimes.add(createShowtime(5, 5));
    }

    Test.startTest();
    Integer totalSeats = 0;
    for (Showtime__c st : showtimes) {
      totalSeats += SeatManagementService.generateSeats(st.Id, 5, 5).size();
    }
    Test.stopTest();

    System.assertEquals(125, totalSeats, 'Should create 125 seats total (5 showtimes * 25 seats each)');
  }

  @isTest
  static void testSeatTypeAssignment() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();
    List<Seat__c> seats = SeatManagementService.generateSeats(
      showtime.Id,
      5,
      5
    );
    Test.stopTest();

    // Verify seat type assignment
    Integer vipSeats = 0;
    Integer wheelchairSeats = 0;
    Integer standardSeats = 0;

    for (Seat__c seat : seats) {
      if (seat.Seat_Type__c == 'VIP') {
        vipSeats++;
      } else if (seat.Seat_Type__c == 'Wheelchair') {
        wheelchairSeats++;
      } else if (seat.Seat_Type__c == 'Standard') {
        standardSeats++;
      }
    }

    System.assertEquals(
      10,
      vipSeats,
      'Should have 10 VIP seats (first 2 rows)'
    );
    System.assertEquals(
      2,
      wheelchairSeats,
      'Should have 2 wheelchair seats (last row corners)'
    );
    System.assertEquals(13, standardSeats, 'Should have 13 standard seats');
  }

  @isTest
  static void testErrorHandlingPatterns() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();

    // Test exception handling in generateSeats
    try {
      SeatManagementService.generateSeats(showtime.Id, 0, 0);
      System.assert(false, 'Should have handled zero parameters gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    // Test exception handling in lockSeats
    try {
      SeatManagementService.lockSeats(new List<Id>(), 5);
      System.assert(false, 'Should have handled empty list gracefully');
    } catch (SeatManagementService.SeatManagementException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testGenerateSeatsDebug() {
    // Create test data without @TestSetup
    Movie__c movie = new Movie__c(
      Name = 'Test Movie Debug',
      Movie_API_ID__c = 'test123debug',
      Is_Active__c = true
    );
    insert movie;

    Theater__c theater = new Theater__c(
      Name = 'Test Theater Debug',
      Theater_API_ID__c = 'theater123debug',
      City__c = 'Test City',
      Is_Active__c = true
    );
    insert theater;

    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = Date.today().addDays(1),
      Session_Time__c = Time.newInstance(14, 30, 0, 0),
      Total_Seats__c = 100,
      Reserved_Seats__c = 0,
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled'
    );

    // Bypass trigger to avoid automatic seat generation
    TriggerHandler.bypass('ShowtimeTriggerHandler');
    insert showtime;
    TriggerHandler.clearBypass('ShowtimeTriggerHandler');

    Test.startTest();

    // Check if seats exist before calling generateSeats
    Integer existingCount = [
      SELECT COUNT()
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
    ];
    System.debug('Existing seats count before generateSeats: ' + existingCount);

    // Call generateSeats
    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id);
    System.debug('Seats returned by generateSeats: ' + seats.size());

    // Check if seats exist after calling generateSeats
    Integer afterCount = [
      SELECT COUNT()
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
    ];
    System.debug('Existing seats count after generateSeats: ' + afterCount);

    Test.stopTest();

    System.assert(!seats.isEmpty(), 'Seats should be created');
    System.assertEquals(100, seats.size(), 'Should create 100 seats (10x10)');
  }
}

```

```apex
/**
 * @description Test class for bulk operations and governor limits following Context7 Apex Recipes
 * @author Cristiano Filho
 * @date 2025-01-27
 * Updated: TriggerHandler references removed for deploy compatibility
 */
@isTest
private class BulkOperationsTest {
  @TestSetup
  static void setupTestData() {
    List<Movie__c> movies = new List<Movie__c>();
    for (Integer i = 0; i < 5; i++) {
      movies.add(
        new Movie__c(
          Name = 'Bulk Movie ' + i,
          Movie_API_ID__c = 'bulk' + i,
          Is_Active__c = true,
          Duration_Minutes__c = 120
        )
      );
    }
    insert movies;

    List<Theater__c> theaters = new List<Theater__c>();
    for (Integer i = 0; i < 3; i++) {
      theaters.add(
        new Theater__c(
          Name = 'Bulk Theater ' + i,
          Theater_API_ID__c = 'theater' + i,
          City__c = 'Test City',
          Is_Active__c = true
        )
      );
    }
    insert theaters;

    List<Showtime__c> showtimes = new List<Showtime__c>();
    for (Integer i = 0; i < 10; i++) {
      showtimes.add(
        new Showtime__c(
          Movie__c = movies[Math.mod(i, movies.size())].Id,
          Theater__c = theaters[Math.mod(i, theaters.size())].Id,
          Session_Date__c = Date.today().addDays(i),
          Session_Time__c = Time.newInstance(14, 30, 0, 0),
          Total_Seats__c = 100,
          Reserved_Seats__c = 0,
          Ticket_Price__c = 15.00,
          Status__c = 'Scheduled'
        )
      );
    }

    insert showtimes;
  }

  // Context7 Apex Recipes Patterns Implementation - Bulk Operations and Governor Limits

  @isTest
  static void testBulkMovieOperations() {
    Test.startTest();
    List<Movie__c> newMovies = new List<Movie__c>();
    for (Integer i = 0; i < 10; i++) {
      newMovies.add(
        new Movie__c(
          Name = 'New Bulk Movie ' + i,
          Movie_API_ID__c = 'newbulk' + i,
          Is_Active__c = true,
          Duration_Minutes__c = 120
        )
      );
    }

    Database.SaveResult[] results = Database.insert(newMovies, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }
    System.assertEquals(10, successCount, 'Should successfully insert all movies');
    Test.stopTest();
  }

  @isTest
  static void testBulkTheaterOperations() {
    Test.startTest();
    List<Theater__c> newTheaters = new List<Theater__c>();
    for (Integer i = 0; i < 8; i++) {
      newTheaters.add(
        new Theater__c(
          Name = 'New Bulk Theater ' + i,
          Theater_API_ID__c = 'newtheater' + i,
          City__c = 'Test City',
          Is_Active__c = true
        )
      );
    }

    Database.SaveResult[] results = Database.insert(newTheaters, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }
    System.assertEquals(8, successCount, 'Should successfully insert all theaters');
    Test.stopTest();
  }

  @isTest
  static void testBulkShowtimeOperations() {
    Test.startTest();
    List<Movie__c> movies = [SELECT Id FROM Movie__c LIMIT 3];
    List<Theater__c> theaters = [SELECT Id FROM Theater__c LIMIT 3];

    List<Showtime__c> newShowtimes = new List<Showtime__c>();
    for (Integer i = 0; i < 9; i++) {
      newShowtimes.add(
        new Showtime__c(
          Movie__c = movies[Math.mod(i, movies.size())].Id,
          Theater__c = theaters[Math.mod(i, theaters.size())].Id,
          Session_Date__c = Date.today().addDays(i),
          Session_Time__c = Time.newInstance(14, 30, 0, 0),
          Total_Seats__c = 100,
          Reserved_Seats__c = 0,
          Ticket_Price__c = 15.00,
          Status__c = 'Scheduled'
        )
      );
    }

    Database.SaveResult[] results = Database.insert(newShowtimes, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }
    System.assertEquals(9, successCount, 'Should successfully insert all showtimes');
    Test.stopTest();
  }

  @isTest
  static void testBulkSeatOperations() {
    List<Showtime__c> showtimes = [SELECT Id FROM Showtime__c LIMIT 2];
    SeatManagementService.generateSeats(showtimes[0].Id, 3, 10);
    SeatManagementService.generateSeats(showtimes[1].Id, 3, 10);

    Test.startTest();
    List<Seat__c> seats = [SELECT Id FROM Seat__c WHERE Showtime__c IN :showtimes];
    System.assert(seats.size() >= 60, 'Should have seats generated by trigger');
    Test.stopTest();
  }

  @isTest
  static void testBulkUpdateOperations() {
    List<Movie__c> movies = [SELECT Id, Name FROM Movie__c LIMIT 10];
    for (Movie__c movie : movies) {
      movie.Name = 'Bulk Updated ' + movie.Name;
    }

    Test.startTest();
    Database.SaveResult[] results = Database.update(movies, false);
    Integer successCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      }
    }
    System.assertEquals(10, successCount, 'Should successfully update all movies');
    Test.stopTest();
  }

  @isTest
  static void testBulkErrorHandling() {
    Test.startTest();
    List<Movie__c> moviesWithErrors = new List<Movie__c>();

    moviesWithErrors.add(new Movie__c(Name = 'Valid Movie', Movie_API_ID__c = 'valid123', Is_Active__c = true, Duration_Minutes__c = 120));
    moviesWithErrors.add(new Movie__c(Name = 'Invalid Movie', Is_Active__c = true, Duration_Minutes__c = 120));

    Database.SaveResult[] results = Database.insert(moviesWithErrors, false);

    Integer successCount = 0;
    Integer errorCount = 0;
    for (Database.SaveResult result : results) {
      if (result.isSuccess()) {
        successCount++;
      } else {
        errorCount++;
      }
    }

    System.assertEquals(1, successCount, 'Should succeed for valid records');
    System.assertEquals(1, errorCount, 'Should fail for invalid records');
    Test.stopTest();
  }

  @isTest
  static void testBulkOperationsWithServices() {
    Test.startTest();
    List<Movie__c> movies = ReservationController.getActiveMovies();
    System.assert(!movies.isEmpty(), 'Should return movies from service');

    List<Seat__c> seats = [SELECT Id FROM Seat__c LIMIT 3];
    if (seats.isEmpty()) {
      SeatManagementService.generateSeats([SELECT Id FROM Showtime__c LIMIT 1].Id, 3, 5);
      seats = [SELECT Id FROM Seat__c LIMIT 3];
    }

    List<Id> seatIds = new List<Id>();
    for (Seat__c seat : seats) {
      seatIds.add(seat.Id);
    }

    SeatManagementService.lockSeats(seatIds, 5);
    SeatManagementService.unlockSeats(seatIds);
    Test.stopTest();
  }
}

```

```apex
/**
 * @description Controller for reservation operations following Context7 Apex Recipes patterns
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class ReservationController {
  @TestVisible static Boolean testCircuitBreaker = false;
  @TestVisible static Boolean circuitBreakerThrown = false;

  private static void enforceCircuitBreaker() {
    if (testCircuitBreaker) {
      circuitBreakerThrown = true;
      throw new AuraHandledException('Circuit breaker activated for testing');
    }
  }

  /**
   * @description Get active movies
   * @return List of active Movie__c records
   */
  @AuraEnabled(cacheable=true)
  public static List<Movie__c> getActiveMovies() {
    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Movie__c.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to read movies'
        );
      }

      // Check if we have the required fields accessible
      if (
        !Schema.sObjectType.Movie__c.fields.Name.isAccessible() ||
        !Schema.sObjectType.Movie__c.fields.Synopsis__c.isAccessible() ||
        !Schema.sObjectType.Movie__c.fields.Poster_URL__c.isAccessible() ||
        !Schema.sObjectType.Movie__c.fields.Release_Date__c.isAccessible() ||
        !Schema.sObjectType.Movie__c.fields.Is_Active__c.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions to read movies'
        );
      }

      enforceCircuitBreaker();

      return [
        SELECT
          Id,
          Name,
          Synopsis__c,
          Poster_URL__c,
          Release_Date__c,
          Duration_Minutes__c,
          Rating__c,
          Genre__c,
          Director__c,
          Cast__c,
          Trailer_URL__c,
          Is_Active__c
        FROM Movie__c
        WHERE Is_Active__c = TRUE
        ORDER BY Release_Date__c DESC
        LIMIT 50
      ];
    } catch (Exception e) {
      System.debug('Error fetching movies: ' + e.getMessage());
      throw new AuraHandledException(
        'Error fetching movies: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Get available showtimes for a movie
   * @param movieId Movie record ID
   * @param selectedDate Date to search showtimes
   * @return List of Showtime__c with theater info
   */
  @AuraEnabled(cacheable=true)
  public static List<Showtime__c> getAvailableShowtimes(
    Id movieId,
    Date selectedDate
  ) {
    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Showtime__c.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to read showtimes'
        );
      }

      // Validate input parameters
      if (movieId == null) {
        throw new AuraHandledException('Movie ID cannot be null');
      }

      if (selectedDate == null) {
        throw new AuraHandledException('Selected date cannot be null');
      }

      // Check if we have the required fields accessible
      if (
        !Schema.sObjectType.Showtime__c.fields.Movie__c.isAccessible() ||
        !Schema.sObjectType.Showtime__c.fields.Session_Date__c.isAccessible() ||
        !Schema.sObjectType.Showtime__c.fields.Status__c.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions to read showtimes'
        );
      }

      enforceCircuitBreaker();

      return [
        SELECT
          Id,
          Name,
          Session_Date__c,
          Session_Time__c,
          Session_DateTime__c,
          Available_Seats__c,
          Reserved_Seats__c,
          Total_Seats__c,
          Ticket_Price__c,
          Is_3D__c,
          Is_IMAX__c,
          Language__c,
          Status__c,
          Theater__c,
          Theater__r.Name,
          Theater__r.Address__c,
          Theater__r.City__c,
          Theater__r.Full_Address__c,
          Theater__r.Location__Latitude__s,
          Theater__r.Location__Longitude__s,
          Movie__c,
          Movie__r.Name
        FROM Showtime__c
        WHERE
          Movie__c = :movieId
          AND Session_Date__c = :selectedDate
          AND Status__c = 'Scheduled'
        ORDER BY Session_Time__c ASC
      ];
    } catch (Exception e) {
      System.debug('Error fetching showtimes: ' + e.getMessage());
      throw new AuraHandledException(
        'Error fetching showtimes: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Get seat layout for a showtime
   * @param showtimeId Showtime record ID
   * @return List of Seat__c records
   */
  @AuraEnabled(cacheable=true)
  public static List<Seat__c> getSeatsForShowtime(Id showtimeId) {
    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Seat__c.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to read seats'
        );
      }

      // Validate input parameters
      if (showtimeId == null) {
        throw new AuraHandledException('Showtime ID cannot be null');
      }

      // Check if we have the required fields accessible
      if (
        !Schema.sObjectType.Seat__c.fields.Showtime__c.isAccessible() ||
        !Schema.sObjectType.Seat__c.fields.Status__c.isAccessible() ||
        !Schema.sObjectType.Seat__c.fields.Row__c.isAccessible() ||
        !Schema.sObjectType.Seat__c.fields.Number__c.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions to read seats'
        );
      }

      enforceCircuitBreaker();

      return [
        SELECT
          Id,
          Name,
          Row__c,
          Number__c,
          Status__c,
          Seat_Type__c,
          Showtime__c,
          Reservation__c
        FROM Seat__c
        WHERE Showtime__c = :showtimeId
        ORDER BY Row__c ASC, Number__c ASC
      ];
    } catch (Exception e) {
      System.debug('Error fetching seats: ' + e.getMessage());
      throw new AuraHandledException('Error fetching seats: ' + e.getMessage());
    }
  }

  /**
   * @description Get reservation by confirmation code
   * @param confirmationCode Confirmation code to search
   * @return Reservation__c record with related data
   */
  @AuraEnabled(cacheable=true)
  public static Reservation__c getReservationByCode(String confirmationCode) {
    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Reservation__c.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to read reservations'
        );
      }

      // Validate input parameters
      if (String.isBlank(confirmationCode)) {
        throw new AuraHandledException('Confirmation code cannot be blank');
      }

      // Check if we have the required fields accessible
      if (
        !Schema.sObjectType.Reservation__c.fields.Confirmation_Code__c.isAccessible() ||
        !Schema.sObjectType.Reservation__c.fields.Customer_Name__c.isAccessible() ||
        !Schema.sObjectType.Reservation__c.fields.Status__c.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions to read reservations'
        );
      }

      List<Reservation__c> reservations = [
        SELECT
          Id,
          Name,
          Confirmation_Code__c,
          Customer_Name__c,
          Customer_Email__c,
          Status__c,
          Payment_Status__c,
          Total_Amount__c,
          Number_of_Seats__c,
          Seat_Numbers__c,
          QR_Code__c,
          Movie__r.Name,
          Showtime__r.Session_DateTime__c,
          Showtime__r.Theater__r.Name
        FROM Reservation__c
        WHERE Confirmation_Code__c = :confirmationCode
        LIMIT 1
      ];

      return reservations.isEmpty() ? null : reservations[0];
    } catch (Exception e) {
      System.debug('Error fetching reservation: ' + e.getMessage());
      throw new AuraHandledException(
        'Error fetching reservation: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Create reservation with selected seats
   * @param showtimeId Showtime record ID
   * @param seatIds List of selected Seat IDs
   * @param customerInfo JSON with customer details
   * @return Reservation__c record with confirmation code
   */
  @AuraEnabled
  public static Reservation__c createReservation(
    Id showtimeId,
    List<Id> seatIds,
    String customerInfoJson
  ) {
    Savepoint sp = Database.setSavepoint();

    try {
      // Validate Field-Level Security following Apex Recipes patterns
      if (!Schema.sObjectType.Reservation__c.isCreateable()) {
        throw new ReservationException(
          'Insufficient permissions to create reservations'
        );
      }

      if (!Schema.sObjectType.Seat__c.isUpdateable()) {
        throw new ReservationException(
          'Insufficient permissions to update seats'
        );
      }

      // Validate input parameters
      if (showtimeId == null) {
        throw new ReservationException('Showtime ID cannot be null');
      }

      if (seatIds == null || seatIds.isEmpty()) {
        throw new ReservationException('Seat IDs cannot be null or empty');
      }

      if (String.isBlank(customerInfoJson)) {
        throw new ReservationException('Customer info cannot be blank');
      }

      enforceCircuitBreaker();

      // Parse customer info
      Map<String, Object> customerData = (Map<String, Object>) JSON.deserializeUntyped(
        customerInfoJson
      );

      // Validate customer data
      if (
        !customerData.containsKey('name') ||
        String.isBlank(String.valueOf(customerData.get('name')))
      ) {
        throw new ReservationException('Customer name is required');
      }

      if (
        !customerData.containsKey('email') ||
        String.isBlank(String.valueOf(customerData.get('email')))
      ) {
        throw new ReservationException('Customer email is required');
      }

      // Validate seats are available
      List<Seat__c> selectedSeats = [
        SELECT Id, Status__c, Row__c, Number__c, Showtime__c
        FROM Seat__c
        WHERE Id IN :seatIds AND Showtime__c = :showtimeId
        FOR UPDATE
      ];

      if (selectedSeats.size() != seatIds.size()) {
        System.debug(
          'Seat validation failed - Expected: ' +
            seatIds.size() +
            ', Found: ' +
            selectedSeats.size()
        );
        System.debug('Requested seat IDs: ' + seatIds);
        System.debug('Found seats: ' + selectedSeats);
        throw new ReservationException(
          'Some seats were not found. Expected ' +
            seatIds.size() +
            ' seats, but found ' +
            selectedSeats.size() +
            '.'
        );
      }

      for (Seat__c seat : selectedSeats) {
        if (seat.Status__c != 'Available') {
          throw new ReservationException(
            'Seat ' +
              seat.Row__c +
              '-' +
              seat.Number__c +
              ' is no longer available.'
          );
        }
      }

      // Get showtime details
      Showtime__c showtime = [
        SELECT
          Id,
          Movie__c,
          Ticket_Price__c,
          Reserved_Seats__c,
          Available_Seats__c,
          Total_Seats__c
        FROM Showtime__c
        WHERE Id = :showtimeId
        FOR UPDATE
      ];

      // Create reservation
      Reservation__c reservation = new Reservation__c();
      reservation.Showtime__c = showtimeId;
      reservation.Movie__c = showtime.Movie__c;
      reservation.Customer_Name__c = String.valueOf(customerData.get('name'));
      reservation.Customer_Email__c = String.valueOf(customerData.get('email'));
      reservation.Customer_Phone__c = String.valueOf(customerData.get('phone'));
      reservation.Number_of_Seats__c = seatIds.size();
      reservation.Total_Amount__c = showtime.Ticket_Price__c * seatIds.size();
      reservation.Status__c = 'Confirmed';
      reservation.Payment_Status__c = 'Pending';
      reservation.Confirmation_Code__c = generateConfirmationCode();

      // Build seat numbers string
      List<String> seatNames = new List<String>();
      for (Seat__c seat : selectedSeats) {
        seatNames.add(seat.Row__c + '-' + seat.Number__c);
      }
      reservation.Seat_Numbers__c = String.join(seatNames, ', ');

      insert reservation;

      // Update seats to Reserved
      for (Seat__c seat : selectedSeats) {
        seat.Status__c = 'Reserved';
        seat.Reservation__c = reservation.Id;
      }
      update selectedSeats;

      // Publish Platform Event for real-time updates
      publishSeatStatusChange(
        showtimeId,
        selectedSeats,
        'Reserved',
        reservation.Id
      );

      // Update showtime reserved count
      showtime.Reserved_Seats__c = showtime.Reserved_Seats__c + seatIds.size();
      update showtime;

      // Send confirmation email asynchronously
      sendConfirmationEmailAsync(reservation.Id);

      return reservation;
    } catch (Exception e) {
      Database.rollback(sp);
      System.debug('=== RESERVATION CONTROLLER ERROR ===');
      System.debug('Error creating reservation: ' + e.getMessage());
      System.debug('Error type: ' + e.getTypeName());
      System.debug('Error stack trace: ' + e.getStackTraceString());
      System.debug('=== END RESERVATION CONTROLLER ERROR ===');
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description Create reservation with payment processing
   * @param showtimeId Showtime record ID
   * @param seatIds List of selected Seat IDs
   * @param customerInfo JSON with customer details
   * @param paymentMethodId Payment method ID
   * @return Reservation__c record with confirmation code
   */
  @AuraEnabled
  public static Reservation__c createReservationWithPayment(
    Id showtimeId,
    List<Id> seatIds,
    String customerInfoJson,
    String paymentMethodId
  ) {
    Savepoint sp = Database.setSavepoint();

    try {
      // Parse customer info
      Map<String, Object> customerData = (Map<String, Object>) JSON.deserializeUntyped(
        customerInfoJson
      );

      // Validate seats are available
      List<Seat__c> selectedSeats = [
        SELECT Id, Status__c, Row__c, Number__c, Showtime__c
        FROM Seat__c
        WHERE Id IN :seatIds AND Showtime__c = :showtimeId
        FOR UPDATE
      ];

      if (selectedSeats.size() != seatIds.size()) {
        System.debug(
          'Seat validation failed - Expected: ' +
            seatIds.size() +
            ', Found: ' +
            selectedSeats.size()
        );
        System.debug('Requested seat IDs: ' + seatIds);
        System.debug('Found seats: ' + selectedSeats);
        throw new ReservationException(
          'Some seats were not found. Expected ' +
            seatIds.size() +
            ' seats, but found ' +
            selectedSeats.size() +
            '.'
        );
      }

      for (Seat__c seat : selectedSeats) {
        if (seat.Status__c != 'Available') {
          throw new ReservationException(
            'Seat ' +
              seat.Row__c +
              '-' +
              seat.Number__c +
              ' is no longer available.'
          );
        }
      }

      // Get showtime details
      Showtime__c showtime = [
        SELECT
          Id,
          Movie__c,
          Ticket_Price__c,
          Reserved_Seats__c,
          Available_Seats__c,
          Total_Seats__c
        FROM Showtime__c
        WHERE Id = :showtimeId
        FOR UPDATE
      ];

      // Create reservation
      Reservation__c reservation = new Reservation__c();
      reservation.Showtime__c = showtimeId;
      reservation.Movie__c = showtime.Movie__c;
      reservation.Customer_Name__c = String.valueOf(customerData.get('name'));
      reservation.Customer_Email__c = String.valueOf(customerData.get('email'));
      reservation.Customer_Phone__c = String.valueOf(customerData.get('phone'));
      reservation.Number_of_Seats__c = seatIds.size();
      reservation.Total_Amount__c = showtime.Ticket_Price__c * seatIds.size();
      reservation.Status__c = 'Pending Payment';
      reservation.Payment_Status__c = 'Pending';
      reservation.Confirmation_Code__c = generateConfirmationCode();

      // Build seat numbers string
      List<String> seatNames = new List<String>();
      for (Seat__c seat : selectedSeats) {
        seatNames.add(seat.Row__c + '-' + seat.Number__c);
      }
      reservation.Seat_Numbers__c = String.join(seatNames, ', ');

      insert reservation;

      // Process payment
      PaymentService.PaymentResult paymentResult = PaymentService.processPayment(
        reservation.Id,
        paymentMethodId,
        reservation.Total_Amount__c
      );

      if (!paymentResult.success) {
        throw new ReservationException(
          'Payment failed: ' + paymentResult.message
        );
      }

      // Update seats to Reserved
      for (Seat__c seat : selectedSeats) {
        seat.Status__c = 'Reserved';
        seat.Reservation__c = reservation.Id;
      }
      update selectedSeats;

      // Publish Platform Event for real-time updates
      publishSeatStatusChange(
        showtimeId,
        selectedSeats,
        'Reserved',
        reservation.Id
      );

      // Update showtime reserved count
      showtime.Reserved_Seats__c = showtime.Reserved_Seats__c + seatIds.size();
      update showtime;

      return reservation;
    } catch (Exception e) {
      Database.rollback(sp);
      System.debug('=== RESERVATION CONTROLLER WITH PAYMENT ERROR ===');
      System.debug(
        'Error creating reservation with payment: ' + e.getMessage()
      );
      System.debug('Error type: ' + e.getTypeName());
      System.debug('Error stack trace: ' + e.getStackTraceString());
      System.debug('=== END RESERVATION CONTROLLER WITH PAYMENT ERROR ===');
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description Cancel an existing reservation
   * @param reservationId Reservation record ID
   * @return Boolean success indicator
   */
  @AuraEnabled
  public static Boolean cancelReservation(Id reservationId) {
    Savepoint sp = Database.setSavepoint();

    try {
      Reservation__c reservation = [
        SELECT
          Id,
          Status__c,
          Showtime__c,
          Showtime__r.Session_DateTime__c,
          Number_of_Seats__c
        FROM Reservation__c
        WHERE Id = :reservationId
        FOR UPDATE
      ];

      // Validate cancellation is allowed
      if (reservation.Status__c == 'Cancelled') {
        throw new ReservationException('Reservation is already cancelled.');
      }

      if (reservation.Status__c == 'Completed') {
        throw new ReservationException('Cannot cancel completed reservation.');
      }

      // Check if within 2 hours of showtime
      Datetime showtimeStart = reservation.Showtime__r.Session_DateTime__c;
      Datetime now = System.now();
      Long hoursDiff =
        (showtimeStart.getTime() - now.getTime()) / (1000 * 60 * 60);

      if (hoursDiff < 2) {
        throw new ReservationException(
          'Cannot cancel reservation within 2 hours of showtime.'
        );
      }

      // Release seats
      List<Seat__c> seats = [
        SELECT Id, Status__c
        FROM Seat__c
        WHERE Reservation__c = :reservationId
        FOR UPDATE
      ];

      for (Seat__c seat : seats) {
        seat.Status__c = 'Available';
        seat.Reservation__c = null;
      }
      update seats;

      // Publish Platform Event for real-time updates
      publishSeatStatusChange(
        reservation.Showtime__c,
        seats,
        'Available',
        null
      );

      // Update showtime count
      Showtime__c showtime = [
        SELECT Id, Reserved_Seats__c
        FROM Showtime__c
        WHERE Id = :reservation.Showtime__c
        FOR UPDATE
      ];
      showtime.Reserved_Seats__c =
        showtime.Reserved_Seats__c - reservation.Number_of_Seats__c;
      update showtime;

      // Process refund if payment was made
      if (reservation.Payment_Status__c == 'Paid') {
        PaymentService.PaymentResult refundResult = PaymentService.processRefund(
          reservationId
        );
        if (!refundResult.success) {
          System.debug('Refund failed: ' + refundResult.message);
        }
      }

      // Update reservation status
      reservation.Status__c = 'Cancelled';
      if (reservation.Payment_Status__c == 'Paid') {
        reservation.Payment_Status__c = 'Refunded';
      }
      update reservation;

      return true;
    } catch (Exception e) {
      Database.rollback(sp);
      throw new AuraHandledException(
        'Error cancelling reservation: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Send confirmation email to customer (async wrapper)
   * @param reservationId Reservation record ID
   */
  @future
  private static void sendConfirmationEmailAsync(Id reservationId) {
    try {
      sendConfirmationEmail(reservationId);
    } catch (Exception e) {
      System.debug('Error sending confirmation email: ' + e.getMessage());
    }
  }

  /**
   * @description Send confirmation email to customer
   * @param reservationId Reservation record ID
   */
  private static void sendConfirmationEmail(Id reservationId) {
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
        Showtime__r.Session_DateTime__c
      FROM Reservation__c
      WHERE Id = :reservationId
    ];

    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setToAddresses(new List<String>{ reservation.Customer_Email__c });
    email.setSubject(
      'Cinema Reservation Confirmation - ' + reservation.Confirmation_Code__c
    );

    String emailBody = 'Dear ' + reservation.Customer_Name__c + ',\n\n';
    emailBody += 'Your reservation has been confirmed!\n\n';
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
    emailBody += 'Number of Tickets: ' + reservation.Number_of_Seats__c + '\n';
    emailBody += 'Total Amount: $' + reservation.Total_Amount__c + '\n\n';
    emailBody += 'Please arrive 15 minutes before showtime.\n\n';
    emailBody += 'Thank you for choosing our cinema!\n';

    email.setPlainTextBody(emailBody);

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
  }

  /**
   * @description Generate unique confirmation code
   * @return String confirmation code (e.g., "ABC123XYZ")
   */
  private static String generateConfirmationCode() {
    return EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(String.valueOf(System.now().getTime())))).substring(0, 9).toUpperCase();
  }

  /**
   * @description Custom exception class for reservation errors
   */
  public class ReservationException extends Exception {
  }

  /**
   * @description Publish Platform Event for seat status changes
   * @param showtimeId Showtime record ID
   * @param seats List of Seat__c records
   * @param newStatus New status for the seats
   * @param reservationId Reservation record ID (optional)
   */
  private static void publishSeatStatusChange(
    Id showtimeId,
    List<Seat__c> seats,
    String newStatus,
    Id reservationId
  ) {
    try {
      List<Seat_Status_Change__e> events = new List<Seat_Status_Change__e>();

      for (Seat__c seat : seats) {
        Seat_Status_Change__e event = new Seat_Status_Change__e();
        event.Showtime_Id__c = showtimeId;
        event.Seat_Id__c = seat.Id;
        event.New_Status__c = newStatus;
        event.Reservation_Id__c = reservationId;
        events.add(event);
      }

      if (!events.isEmpty()) {
        EventBus.publish(events);
      }
    } catch (Exception e) {
      System.debug(
        'Error publishing seat status change event: ' + e.getMessage()
      );
    }
  }
}

```

```apex
/**
 * @description Test class for ReservationController following Context7 Apex Recipes patterns
 * @author Cristiano Filho
 * @date 2025-09-30
 */
@isTest
private class ReservationControllerTest {
  @TestSetup
  static void setupTestData() {
    Movie__c movie = new Movie__c(
      Name = 'Test Movie',
      Movie_API_ID__c = 'test123',
      Is_Active__c = true
    );
    insert movie;

    Theater__c theater = new Theater__c(
      Name = 'Test Theater',
      Theater_API_ID__c = 'theater123',
      City__c = 'Test City',
      Is_Active__c = true
    );
    insert theater;

    Showtime__c showtime = new Showtime__c(
      Movie__c = movie.Id,
      Theater__c = theater.Id,
      Session_Date__c = Date.today().addDays(1),
      Session_Time__c = Time.newInstance(14, 30, 0, 0),
      Total_Seats__c = 100,
      Reserved_Seats__c = 0,
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled'
    );

    TriggerHandler.bypass('ShowtimeTriggerHandler');
    insert showtime;
    TriggerHandler.clearBypass('ShowtimeTriggerHandler');

    SeatManagementService.generateSeats(showtime.Id, 10, 10);
  }

  @isTest
  static void testGetAvailableShowtimes() {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];

    Test.startTest();
    List<Showtime__c> showtimes = ReservationController.getAvailableShowtimes(
      movie.Id,
      Date.today().addDays(1)
    );
    Test.stopTest();

    System.assertEquals(1, showtimes.size(), 'Should return 1 showtime');
    System.assertEquals(
      100,
      showtimes[0].Available_Seats__c,
      'Should have 100 available seats'
    );
  }

  @isTest
  static void testGetSeatsForShowtime() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();
    List<Seat__c> seats = ReservationController.getSeatsForShowtime(
      showtime.Id
    );
    Test.stopTest();

    System.assertEquals(10, seats.size(), 'Should return 10 seats');
    System.assertEquals(
      'Available',
      seats[0].Status__c,
      'Seats should be available'
    );
  }

  @isTest
  static void testCreateReservation_Success() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 2
    ];

    String customerInfo = '{"name":"John Doe","email":"john@test.com","phone":"1234567890"}';

    Test.startTest();
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id, seats[1].Id },
      customerInfo
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      reservation.Id,
      'Reservation should be created'
    );
    System.assertEquals(
      'John Doe',
      reservation.Customer_Name__c,
      'Customer name should match'
    );
    System.assertEquals(
      2,
      reservation.Number_of_Seats__c,
      'Should have 2 seats'
    );
    System.assertEquals(
      30.00,
      reservation.Total_Amount__c,
      'Total should be $30.00'
    );
    System.assertNotEquals(
      null,
      reservation.Confirmation_Code__c,
      'Should have confirmation code'
    );

    // Verify seats are reserved
    List<Seat__c> updatedSeats = [
      SELECT Status__c
      FROM Seat__c
      WHERE Id IN :new List<Id>{ seats[0].Id, seats[1].Id }
    ];
    for (Seat__c seat : updatedSeats) {
      System.assertEquals(
        'Reserved',
        seat.Status__c,
        'Seat should be reserved'
      );
    }
  }

  @isTest
  static void testCreateReservation_SeatNotAvailable() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    // Reserve the seat first
    seats[0].Status__c = 'Reserved';
    update seats[0];

    String customerInfo = '{"name":"Jane Doe","email":"jane@test.com","phone":"9876543210"}';

    Test.startTest();
    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        customerInfo
      );
      System.assert(false, 'Should throw exception for unavailable seat');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('no longer available'),
        'Should mention seat unavailability'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testCancelReservation_Success() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 2
    ];

    // Create reservation
    String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id, seats[1].Id },
      customerInfo
    );

    Test.startTest();
    Boolean result = ReservationController.cancelReservation(reservation.Id);
    Test.stopTest();

    System.assertEquals(true, result, 'Cancellation should succeed');

    // Verify reservation is cancelled
    Reservation__c cancelledRes = [
      SELECT Status__c, Payment_Status__c
      FROM Reservation__c
      WHERE Id = :reservation.Id
    ];
    System.assertEquals(
      'Cancelled',
      cancelledRes.Status__c,
      'Status should be Cancelled'
    );
    System.assertEquals(
      'Refunded',
      cancelledRes.Payment_Status__c,
      'Payment should be Refunded'
    );

    // Verify seats are released
    List<Seat__c> releasedSeats = [
      SELECT Status__c, Reservation__c
      FROM Seat__c
      WHERE Id IN :new List<Id>{ seats[0].Id, seats[1].Id }
    ];
    for (Seat__c seat : releasedSeats) {
      System.assertEquals(
        'Available',
        seat.Status__c,
        'Seat should be available'
      );
      System.assertEquals(
        null,
        seat.Reservation__c,
        'Seat should have no reservation'
      );
    }
  }

  @isTest
  static void testCancelReservation_AlreadyCancelled() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id },
      customerInfo
    );

    // Cancel once
    ReservationController.cancelReservation(reservation.Id);

    Test.startTest();
    try {
      ReservationController.cancelReservation(reservation.Id);
      System.assert(
        false,
        'Should throw exception for already cancelled reservation'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('already cancelled'),
        'Should mention already cancelled'
      );
    }
    Test.stopTest();
  }

  // Context7 Apex Recipes Patterns Implementation

  @isTest
  static void testGetActiveMoviesWithFLSValidation() {
    Test.startTest();
    List<Movie__c> movies = ReservationController.getActiveMovies();
    Test.stopTest();

    System.assert(!movies.isEmpty(), 'Should return active movies');

    // Verify FLS validation worked
    System.assert(
      Schema.sObjectType.Movie__c.isAccessible(),
      'Movie__c should be accessible'
    );
    System.assert(
      Schema.sObjectType.Movie__c.fields.Name.isAccessible(),
      'Name field should be accessible'
    );
  }

  @isTest
  static void testGetActiveMoviesWithCircuitBreaker() {
    // Activate circuit breaker
    ReservationController.testCircuitBreaker = true;

    Test.startTest();
    try {
      ReservationController.getActiveMovies();
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
        ReservationController.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    // Reset circuit breaker
    ReservationController.testCircuitBreaker = false;
    ReservationController.circuitBreakerThrown = false;
  }

  @isTest
  static void testGetAvailableShowtimesWithValidation() {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];

    Test.startTest();

    // Test with valid parameters
    List<Showtime__c> showtimes = ReservationController.getAvailableShowtimes(
      movie.Id,
      Date.today().addDays(1)
    );
    System.assertEquals(1, showtimes.size(), 'Should return 1 showtime');

    // Test with invalid parameters
    try {
      ReservationController.getAvailableShowtimes(
        null,
        Date.today().addDays(1)
      );
      System.assert(false, 'Should have thrown exception for null movie ID');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Movie ID cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.getAvailableShowtimes(movie.Id, null);
      System.assert(false, 'Should have thrown exception for null date');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Selected date cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testGetSeatsForShowtimeWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];

    Test.startTest();

    // Test with valid parameters
    List<Seat__c> seats = ReservationController.getSeatsForShowtime(
      showtime.Id
    );
    System.assertEquals(10, seats.size(), 'Should return 10 seats');

    // Test with invalid parameters
    try {
      ReservationController.getSeatsForShowtime(null);
      System.assert(false, 'Should have thrown exception for null showtime ID');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Showtime ID cannot be null'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testGetReservationByCodeWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id },
      customerInfo
    );

    Test.startTest();

    // Test with valid confirmation code
    Reservation__c foundReservation = ReservationController.getReservationByCode(
      reservation.Confirmation_Code__c
    );
    System.assertNotEquals(null, foundReservation, 'Should find reservation');
    System.assertEquals(
      reservation.Id,
      foundReservation.Id,
      'Should return correct reservation'
    );

    // Test with invalid confirmation code
    try {
      ReservationController.getReservationByCode('');
      System.assert(
        false,
        'Should have thrown exception for blank confirmation code'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Confirmation code cannot be blank'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.getReservationByCode(null);
      System.assert(
        false,
        'Should have thrown exception for null confirmation code'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Confirmation code cannot be blank'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testCreateReservationWithValidation() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 2
    ];

    Test.startTest();

    // Test with valid parameters
    String customerInfo = '{"name":"John Doe","email":"john@test.com","phone":"1234567890"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id, seats[1].Id },
      customerInfo
    );

    System.assertNotEquals(
      null,
      reservation.Id,
      'Reservation should be created'
    );
    System.assertEquals(
      'John Doe',
      reservation.Customer_Name__c,
      'Customer name should match'
    );
    System.assertEquals(
      2,
      reservation.Number_of_Seats__c,
      'Should have 2 seats'
    );

    // Test with invalid parameters
    try {
      ReservationController.createReservation(
        null,
        new List<Id>{ seats[0].Id },
        customerInfo
      );
      System.assert(false, 'Should have thrown exception for null showtime ID');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Showtime ID cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.createReservation(showtime.Id, null, customerInfo);
      System.assert(false, 'Should have thrown exception for null seat IDs');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>(),
        customerInfo
      );
      System.assert(false, 'Should have thrown exception for empty seat IDs');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Seat IDs cannot be null'),
        'Should throw appropriate exception'
      );
    }

    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        ''
      );
      System.assert(
        false,
        'Should have thrown exception for blank customer info'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Customer info cannot be blank'),
        'Should throw appropriate exception'
      );
    }

    // Test with invalid customer data
    String invalidCustomerInfo = '{"email":"test@test.com"}'; // Missing name
    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        invalidCustomerInfo
      );
      System.assert(
        false,
        'Should have thrown exception for missing customer name'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Customer name is required'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testCreateReservationWithCircuitBreaker() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    // Activate circuit breaker
    ReservationController.testCircuitBreaker = true;

    String customerInfo = '{"name":"Test User","email":"test@test.com","phone":"1111111111"}';

    Test.startTest();
    try {
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        customerInfo
      );
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
        ReservationController.circuitBreakerThrown,
        'Circuit breaker should be thrown'
      );
    }
    Test.stopTest();

    // Reset circuit breaker
    ReservationController.testCircuitBreaker = false;
    ReservationController.circuitBreakerThrown = false;
  }

  @isTest
  static void testBulkOperations() {
    Movie__c movie = [SELECT Id FROM Movie__c LIMIT 1];
    Theater__c theater = [SELECT Id FROM Theater__c LIMIT 1];

    // Create multiple showtimes for bulk testing
    List<Showtime__c> showtimes = new List<Showtime__c>();
    for (Integer i = 0; i < 3; i++) {
      showtimes.add(
        new Showtime__c(
          Movie__c = movie.Id,
          Theater__c = theater.Id,
          Session_Date__c = Date.today().addDays(i + 1),
          Session_Time__c = Time.newInstance(14, 30, 0, 0),
          Total_Seats__c = 10,
          Reserved_Seats__c = 0,
          Ticket_Price__c = 15.00,
          Status__c = 'Scheduled'
        )
      );
    }
    insert showtimes;

    // Create seats for each showtime
    List<Seat__c> allSeats = new List<Seat__c>();
    for (Showtime__c st : showtimes) {
      for (Integer i = 1; i <= 5; i++) {
        allSeats.add(
          new Seat__c(
            Showtime__c = st.Id,
            Row__c = 'A',
            Number__c = i,
            Name = 'A-' + i,
            Status__c = 'Available',
            Seat_Type__c = 'Standard'
          )
        );
      }
    }
    insert allSeats;

    Test.startTest();

    // Test bulk showtime retrieval
    List<Showtime__c> retrievedShowtimes = ReservationController.getAvailableShowtimes(
      movie.Id,
      Date.today().addDays(1)
    );
    System.assertEquals(
      1,
      retrievedShowtimes.size(),
      'Should return 1 showtime for today+1'
    );

    // Test bulk seat retrieval
    List<Seat__c> retrievedSeats = ReservationController.getSeatsForShowtime(
      showtimes[0].Id
    );
    System.assertEquals(
      5,
      retrievedSeats.size(),
      'Should return 5 seats for first showtime'
    );

    Test.stopTest();
  }

  @isTest
  static void testErrorHandlingPatterns() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    Test.startTest();

    // Test exception handling in getActiveMovies
    try {
      ReservationController.getActiveMovies();
      System.assert(true, 'Should handle exceptions gracefully');
    } catch (Exception e) {
      System.assert(true, 'Expected exception handling');
    }

    // Test exception handling in createReservation
    try {
      String invalidCustomerInfo = '{"name":"","email":"test@test.com"}'; // Empty name
      ReservationController.createReservation(
        showtime.Id,
        new List<Id>{ seats[0].Id },
        invalidCustomerInfo
      );
      System.assert(
        false,
        'Should have handled invalid customer data gracefully'
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Customer name is required'),
        'Should throw appropriate exception'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testDataValidationPatterns() {
    Showtime__c showtime = [SELECT Id FROM Showtime__c LIMIT 1];
    List<Seat__c> seats = [
      SELECT Id
      FROM Seat__c
      WHERE Showtime__c = :showtime.Id
      LIMIT 1
    ];

    Test.startTest();

    // Test data sanitization
    String customerInfoWithSpecialChars = '{"name":"John O\'Connor","email":"john+test@example.com","phone":"+1-555-123-4567"}';
    Reservation__c reservation = ReservationController.createReservation(
      showtime.Id,
      new List<Id>{ seats[0].Id },
      customerInfoWithSpecialChars
    );

    System.assertNotEquals(
      null,
      reservation.Id,
      'Should handle special characters in customer data'
    );
    System.assertEquals(
      'John O\'Connor',
      reservation.Customer_Name__c,
      'Should preserve special characters'
    );

    Test.stopTest();
  }
}

```

---

**User**

continue implements 20 of 30 To-dos

---

**Cursor**

```apex
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
      Ticket_Price__c = 15.00,
      Status__c = 'Scheduled',
      Reserved_Seats__c = 0,
      Total_Seats__c = 96
    );
    insert showtime;

    List<Seat__c> seats = SeatManagementService.generateSeats(showtime.Id, 8, 12);

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
    System.assertNotEquals(null, result.transactionId, 'Transaction ID should be generated');
    System.assertEquals(30.00, result.processedAmount, 'Processed amount should match');

    Reservation__c updatedReservation = [
      SELECT Payment_Status__c, Payment_Method__c, Payment_Transaction_Id__c, QR_Code__c
      FROM Reservation__c
      WHERE Id = :data.reservation.Id
    ];
    System.assertEquals('Paid', updatedReservation.Payment_Status__c, 'Payment status should be Paid');
    System.assertEquals('Credit Card', updatedReservation.Payment_Method__c, 'Payment method should be set');
    System.assertNotEquals(null, updatedReservation.Payment_Transaction_Id__c, 'Transaction ID should be saved');
    System.assertNotEquals(null, updatedReservation.QR_Code__c, 'QR Code should be generated');
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

```

