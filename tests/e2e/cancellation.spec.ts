import { test } from "../fixtures/salesforce-auth";

test.describe("Reservation Cancellation", () => {
  test.skip("cancels reservation and processes refund", async ({
    authenticatedPage
  }) => {
    await authenticatedPage.goto("/lightning/n/Cancel_Reservation");

    // TODO: Populate confirmation code and validate refund once env is configured.
  });
});
