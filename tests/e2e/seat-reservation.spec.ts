import { test, expect, loginToSalesforce } from "../fixtures/salesforce-auth";

test.describe("Seat Reservation Component", () => {
  test.skip("displays seat grid with selectable seats", async ({
    authenticatedPage
  }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    const seatGrid = authenticatedPage.locator("c-seat-reservation");
    await expect(seatGrid).toBeVisible();

    const availableSeats = seatGrid.locator(".seat.available");
    await expect(availableSeats.first()).toBeVisible();
  });

  test.skip("allows selecting and deselecting seats", async ({
    authenticatedPage
  }) => {
    await authenticatedPage.goto("/lightning/n/Cinema_Booking");

    const seatGrid = authenticatedPage.locator("c-seat-reservation");
    const firstSeat = seatGrid.locator(".seat.available").first();

    await firstSeat.click();
    await expect(firstSeat).toHaveClass(/selected/);

    await firstSeat.click();
    await expect(firstSeat).not.toHaveClass(/selected/);
  });
});
