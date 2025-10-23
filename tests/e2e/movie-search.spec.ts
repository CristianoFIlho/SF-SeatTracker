import { test, expect } from "../fixtures/salesforce-auth";

test.describe("Movie Search Component", () => {
  test.skip("searches movies with default geolocation", async ({
    authenticatedPage
  }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    const movieSearch = authenticatedPage.locator("c-movie-search");
    await expect(movieSearch).toBeVisible();
  });
});
