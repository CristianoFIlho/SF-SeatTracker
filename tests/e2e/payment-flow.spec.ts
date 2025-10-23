import { test, expect } from "../fixtures/salesforce-auth";

test.describe("Payment Flow", () => {
  test.skip("completes payment flow end-to-end", async ({
    authenticatedPage
  }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    await expect(
      authenticatedPage.locator("c-payment-processor")
    ).toBeVisible();
  });
});
