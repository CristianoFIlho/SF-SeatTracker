# SF-SeatTracker Deployment Guide

## 📋 Pre-Deployment Checklist

Before deploying, ensure you have:

- [ ] Salesforce Developer Org or higher
- [ ] Salesforce CLI (SFDX) installed
- [ ] Git installed
- [ ] MovieGlu API credentials (optional for testing)
- [ ] Visual Studio Code with Salesforce Extensions (recommended)

---

## 🚀 Deployment Steps

### Step 1: Authenticate to Salesforce

```bash
# Authenticate to your org
sfdx auth:web:login -a DevOrg -r https://login.salesforce.com

# Verify authentication
sfdx force:org:display -u DevOrg
```

### Step 2: Deploy All Metadata

```bash
# Deploy to your org
sfdx force:source:deploy -p force-app/main/default -u DevOrg

# Or use the npm script
npm run deploy:dev
```

**Expected deployment time:** 2-3 minutes

### Step 3: Assign Permission Set

```bash
# Assign Cinema Reservation Admin permission set to your user
sfdx force:user:permset:assign -n Cinema_Reservation_Admin -u DevOrg

# Or manually in Setup > Permission Sets > Cinema Reservation Admin > Manage Assignments
```

### Step 4: Configure Named Credential (Manual)

Since Named Credentials contain sensitive data, you must configure them manually:

1. Navigate to **Setup** > **Named Credentials**
2. Click **New Named Credential**
3. Fill in the following:
   - **Label:** `MovieGlu API`
   - **Name:** `MovieGlu_API`
   - **URL:** `https://api-gate.movieglu.com`
   - **Identity Type:** Named Principal
   - **Authentication Protocol:** Custom

4. Add Custom Headers:
   ```
   x-api-key: YOUR_MOVIEGLU_API_KEY
   client: YOUR_CLIENT_NAME
   authorization: Basic YOUR_BASE64_CREDENTIALS
   ```

5. Click **Save**

> **Note:** To get MovieGlu API credentials, register at [https://developer.movieglu.com](https://developer.movieglu.com)

### Step 5: Import Sample Data (Optional)

```bash
# Import test data
sfdx force:data:tree:import -p data/sample-data-plan.json -u DevOrg

# Or use npm script
npm run import:data
```

This will create:
- 3 Movies
- 2 Theaters
- 3 Showtimes
- 300 Seats (automatically via trigger)

### Step 6: Open Your Org

```bash
sfdx force:org:open -u DevOrg

# Navigate to App Launcher > Cinema Management
```

---

## 🧪 Testing the Deployment

### Test 1: Run Apex Tests

```bash
# Run all tests
sfdx force:apex:test:run -l RunLocalTests -w 10 -r human -u DevOrg

# Expected: All tests pass with >75% code coverage
```

### Test 2: Manual Testing Flow

1. **Open Cinema Management App**
   - App Launcher > Cinema Management

2. **View Movies**
   - Click Movies tab
   - Verify 3 sample movies are visible

3. **Create a Reservation (Manual)**
   - Go to Showtimes tab
   - Open a showtime record
   - Navigate to Related > Reservations
   - Click New
   - Fill in customer details
   - Save

4. **Sync Movies from API (Optional - requires API key)**
   ```apex
   // Execute in Developer Console
   MovieGluService.syncNowShowingFilms('-23.5505', '-46.6333');
   ```

### Test 3: Verify Automatic Seat Generation

1. Create a new Showtime record
2. Navigate to Related > Seats
3. Verify 100 seats were automatically created (rows A-J, numbers 1-10)

---

## 📊 Post-Deployment Configuration

### Configure Geolocation

If you're not in São Paulo, Brazil, update the default coordinates:

1. Open **Developer Console**
2. File > Open Resource > `MovieGluService`
3. Update latitude/longitude in method calls
4. Save

### Configure Email Settings

1. **Setup** > **Email Administration** > **Deliverability**
2. Set to **All Email**

### Create Dashboards (Optional)

1. Navigate to **Dashboards** tab
2. Create new dashboard: **Cinema Analytics**
3. Add components:
   - Reservations by Movie (Bar Chart)
   - Theater Occupancy (Gauge)
   - Daily Revenue (Line Chart)

---

## 🔧 Troubleshooting

### Issue: "Insufficient Privileges" Error

**Solution:** Ensure Cinema_Reservation_Admin permission set is assigned
```bash
sfdx force:user:permset:assign -n Cinema_Reservation_Admin -u DevOrg
```

### Issue: Named Credential Callout Fails

**Solution:** Verify Remote Site Settings
1. **Setup** > **Remote Site Settings**
2. Verify `MovieGlu_API` is Active
3. URL should be: `https://api-gate.movieglu.com`

### Issue: Seats Not Auto-Generating

**Solution:** Verify trigger is active
1. **Setup** > **Apex Triggers**
2. Find `ShowtimeTrigger`
3. Ensure Status = Active

### Issue: Tests Failing

**Solution:** Check test data setup
```bash
# Run specific test with debug logs
sfdx force:apex:test:run -n ReservationControllerTest -r human -d ./test-results
```

---

## 📦 Package Contents

### Custom Objects (5)
- Movie__c (12 fields)
- Theater__c (12 fields + geolocation)
- Showtime__c (18 fields)
- Reservation__c (16 fields)
- Seat__c (8 fields)

### Apex Classes (10)
- MovieGluService
- ReservationController
- SeatManagementService
- ShowtimeTriggerHandler
- MovieGluHttpCalloutMock
- MovieGluServiceTest
- ReservationControllerTest
- SeatManagementServiceTest
- ShowtimeTriggerHandlerTest

### Triggers (1)
- ShowtimeTrigger (auto-generates seats)

### Security
- Cinema_Reservation_Admin permission set
- Remote Site Setting (MovieGlu API)

### UI Components
- Cinema Management Lightning App
- 4 Custom Tabs (Movie, Theater, Showtime, Reservation)

---

## 🎯 Success Criteria

Your deployment is successful when:

✅ All Apex tests pass (>75% coverage)  
✅ Cinema Management app is accessible  
✅ Sample data is visible in Movies tab  
✅ Creating a Showtime auto-generates 100 seats  
✅ Reservations can be created and cancelled  
✅ Email confirmations are sent  

---

## 🔄 Continuous Deployment

### Using Scratch Orgs

```bash
# Create scratch org
npm run create:scratch

# Push source
npm run push:source

# Assign permission set
npm run assign:permset

# Import data
npm run import:data

# Open org
sfdx force:org:open -u SeatTrackerOrg
```

### Using Source Control

```bash
# Pull changes from org
sfdx force:source:pull -u DevOrg

# Commit changes
git add .
git commit -m "feat: add new feature"
git push origin develop
```

---

## 📞 Support

If you encounter issues:

1. Check [Salesforce DX Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
2. Review [MovieGlu API Documentation](https://developer.movieglu.com/docs)
3. Create an issue on GitHub: [SF-SeatTracker Issues](https://github.com/CristianoFIlho/SF-SeatTracker/issues)

---

## 🎉 Next Steps

After successful deployment:

1. **Customize for your region**
   - Update geolocation coordinates
   - Adjust currency and ticket prices
   - Translate picklist values

2. **Build LWC Components** (Coming Soon)
   - Movie search interface
   - Interactive seat selection grid
   - Booking confirmation modal

3. **Create Experience Cloud Site**
   - Public portal for customers
   - Embed LWC components
   - Guest user access

4. **Add Payment Integration**
   - Stripe or PayPal
   - Payment confirmation flow
   - Refund handling

---

**Developed with ❤️ using Salesforce Platform**

