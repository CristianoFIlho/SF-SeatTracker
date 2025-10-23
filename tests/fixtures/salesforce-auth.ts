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
