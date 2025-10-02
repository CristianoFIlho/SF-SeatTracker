# Metaprompt: SF-SeatTracker Codebase Initialization

## Context
You are an expert Salesforce developer tasked with initializing the complete codebase for the SF-SeatTracker project based on the README.md specifications. This is a cinema seat reservation management system built on Salesforce using Lightning Web Components (LWC), Apex, and MovieGlu API integration.

**Repository**: CristianoFIlho/SF-SeatTracker
**Project Goal**: Create a production-ready Salesforce application for cinema seat booking with real-time movie data integration.

---

## Initialization Tasks

### Phase 1: Project Foundation

#### 1.1 SFDX Project Setup
```bash
# Initialize the SFDX project structure
sfdx force:project:create -n SF-SeatTracker -t standard

# Create the following directory structure:
force-app/main/default/
├── classes/
├── lwc/
├── objects/
├── flows/
├── triggers/
├── namedCredentials/
├── remoteSiteSettings/
├── permissionsets/
├── tabs/
├── applications/
└── layouts/
```

**Action Required**: Generate the complete `sfdx-project.json` configuration file with:
- Project name and namespace
- Package directories
- Source API version (v59.0 or latest)
- Plugin dependencies

#### 1.2 Configuration Files
Create the following files:
- `.gitignore` - Salesforce-specific patterns
- `config/project-scratch-def.json` - Scratch org definition with features (ExperienceCloud, Communities)
- `.forceignore` - Deployment exclusions
- `package.json` - npm scripts for automation

---

### Phase 2: Data Model (Custom Objects)

Generate complete metadata for the following custom objects:

#### 2.1 Movie__c Object
**Fields**:
- `Name` (Text, 80) - Movie title
- `Movie_API_ID__c` (Text, 100, Unique, External ID) - MovieGlu API identifier
- `Synopsis__c` (Long Text Area, 32768)
- `Poster_URL__c` (URL, 255)
- `Release_Date__c` (Date)
- `Duration_Minutes__c` (Number, 18, 0)
- `Rating__c` (Picklist: G, PG, PG-13, R, NC-17)
- `Genre__c` (Multi-Select Picklist: Action, Comedy, Drama, Horror, Sci-Fi, Romance, Thriller)
- `Director__c` (Text, 255)
- `Cast__c` (Long Text Area, 1000)
- `Trailer_URL__c` (URL, 255)
- `Is_Active__c` (Checkbox, Default: true)

**Validation Rules**:
- Duration must be > 0
- Release date cannot be in the future for active movies

**Page Layout**: Include all fields with poster preview

#### 2.2 Theater__c Object
**Fields**:
- `Name` (Text, 120) - Theater name
- `Theater_API_ID__c` (Text, 100, Unique, External ID)
- `Address__c` (Text Area, 255)
- `City__c` (Text, 80)
- `State__c` (Text, 80)
- `Postal_Code__c` (Text, 20)
- `Country__c` (Text, 80)
- `Latitude__c` (Geolocation - Latitude)
- `Longitude__c` (Geolocation - Longitude)
- `Phone__c` (Phone)
- `Total_Screens__c` (Number, 18, 0)
- `Is_Active__c` (Checkbox, Default: true)

**Formula Fields**:
- `Full_Address__c` (Text): Concatenate address, city, state, postal code

#### 2.3 Showtime__c Object
**Relationships**:
- `Movie__c` (Master-Detail to Movie__c)
- `Theater__c` (Master-Detail to Theater__c)

**Fields**:
- `Name` (Auto Number: SHW-{0000})
- `Showtime_API_ID__c` (Text, 100, External ID)
- `Session_Date__c` (Date)
- `Session_Time__c` (Time)
- `Session_DateTime__c` (DateTime, Formula: DATETIMEVALUE(TEXT(Session_Date__c) & ' ' & TEXT(Session_Time__c)))
- `Screen_Number__c` (Number, 18, 0)
- `Total_Seats__c` (Number, 18, 0, Default: 100)
- `Available_Seats__c` (Number, 18, 0)
- `Reserved_Seats__c` (Number, 18, 0, Default: 0)
- `Ticket_Price__c` (Currency, 16, 2)
- `Is_3D__c` (Checkbox)
- `Is_IMAX__c` (Checkbox)
- `Language__c` (Picklist: English, Spanish, Portuguese, French, Other)
- `Subtitles__c` (Text, 100)
- `Status__c` (Picklist: Scheduled, In Progress, Completed, Cancelled)

**Validation Rules**:
- Reserved_Seats__c <= Total_Seats__c
- Session_DateTime__c must be in the future for new records

**Workflow/Flow**: Auto-update Available_Seats__c when Reserved_Seats__c changes

#### 2.4 Reservation__c Object
**Relationships**:
- `Account__c` (Lookup to Account)
- `Movie__c` (Lookup to Movie__c)
- `Showtime__c` (Lookup to Showtime__c)

**Fields**:
- `Name` (Auto Number: RES-{00000})
- `Reservation_Date__c` (DateTime, Default: NOW())
- `Customer_Email__c` (Email, Required)
- `Customer_Name__c` (Text, 120, Required)
- `Customer_Phone__c` (Phone)
- `Number_of_Seats__c` (Number, 18, 0)
- `Seat_Numbers__c` (Text, 255) - Comma-separated seat IDs
- `Total_Amount__c` (Currency, 16, 2)
- `Status__c` (Picklist: Pending, Confirmed, Cancelled, Completed) - Default: Pending
- `Confirmation_Code__c` (Text, 20, Unique) - Auto-generated
- `Payment_Status__c` (Picklist: Pending, Paid, Refunded)
- `QR_Code__c` (Text, 255) - URL to QR code
- `Notes__c` (Long Text Area, 1000)

**Formula Fields**:
- `Is_Past_Showtime__c` (Checkbox): Showtime__r.Session_DateTime__c < NOW()

**Validation Rules**:
- Cannot cancel confirmed reservation within 2 hours of showtime
- Number_of_Seats__c must be between 1 and 10

#### 2.5 Seat__c Object
**Relationships**:
- `Showtime__c` (Master-Detail to Showtime__c)
- `Reservation__c` (Lookup to Reservation__c)

**Fields**:
- `Name` (Text, 80) - Seat identifier (e.g., "A-1")
- `Row__c` (Text, 5)
- `Number__c` (Number, 18, 0)
- `Status__c` (Picklist: Available, Reserved, Occupied, Blocked) - Default: Available
- `Seat_Type__c` (Picklist: Standard, VIP, Wheelchair, Companion)
- `Is_Available__c` (Checkbox, Default: true)

**Validation Rules**:
- Unique seat per showtime (Row + Number + Showtime)

---

### Phase 3: Apex Classes

Generate complete Apex classes with the following specifications:

#### 3.1 MovieGluService.cls
```apex
/**
 * @description Service class for MovieGlu API integration
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class MovieGluService {
    
    private static final String NAMED_CREDENTIAL = 'callout:MovieGlu_API';
    private static final String FILMS_ENDPOINT = '/filmsNowShowing';
    private static final String CINEMAS_ENDPOINT = '/cinemasNearby';
    private static final String SHOWTIMES_ENDPOINT = '/filmShowTimes';
    
    /**
     * @description Fetch and sync movies currently showing
     * @param latitude Geographic latitude
     * @param longitude Geographic longitude
     * @return List of created Movie__c records
     */
    public static List<Movie__c> syncNowShowingFilms(String latitude, String longitude) {
        // TODO: Implement HTTP callout to MovieGlu API
        // TODO: Parse JSON response
        // TODO: Upsert Movie__c records using Movie_API_ID__c
        // TODO: Handle errors and logging
    }
    
    /**
     * @description Fetch nearby theaters
     * @param latitude Geographic latitude
     * @param longitude Geographic longitude
     * @param radiusKm Search radius in kilometers
     * @return List of Theater__c records
     */
    public static List<Theater__c> syncNearbyTheaters(String latitude, String longitude, Integer radiusKm) {
        // TODO: Implement
    }
    
    /**
     * @description Sync showtimes for a specific movie and theater
     * @param movieApiId External movie ID
     * @param theaterApiId External theater ID
     * @param showDate Date for showtimes
     * @return List of Showtime__c records
     */
    public static List<Showtime__c> syncShowtimes(String movieApiId, String theaterApiId, Date showDate) {
        // TODO: Implement
    }
    
    /**
     * @description Make HTTP callout to MovieGlu API
     * @param endpoint API endpoint path
     * @param queryParams Map of query parameters
     * @return HTTPResponse
     */
    @TestVisible
    private static HttpResponse makeCallout(String endpoint, Map<String, String> queryParams) {
        // TODO: Build request with Named Credential
        // TODO: Add custom headers (x-api-key, client, authorization)
        // TODO: Execute and return response
    }
    
    /**
     * @description Parse movie JSON and create Movie__c record
     * @param filmJson JSON object for a single film
     * @return Movie__c record
     */
    private static Movie__c parseMovie(Map<String, Object> filmJson) {
        // TODO: Extract fields from JSON
        // TODO: Map to Movie__c fields
    }
}
```

**Requirements**:
- Implement proper error handling with try-catch
- Add logging using System.debug
- Use @future (callout=true) for async operations
- Implement bulkification for DML operations
- Create test class with 100% coverage using HttpCalloutMock

#### 3.2 ReservationController.cls
```apex
/**
 * @description Controller for reservation operations
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class ReservationController {
    
    /**
     * @description Get available showtimes for a movie
     * @param movieId Movie record ID
     * @param selectedDate Date to search showtimes
     * @return List of Showtime__c with theater info
     */
    @AuraEnabled(cacheable=true)
    public static List<Showtime__c> getAvailableShowtimes(Id movieId, Date selectedDate) {
        // TODO: Query showtimes with available seats > 0
        // TODO: Include Movie__c and Theater__c fields
        // TODO: Filter by date and active status
    }
    
    /**
     * @description Get seat layout for a showtime
     * @param showtimeId Showtime record ID
     * @return List of Seat__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Seat__c> getSeatsForShowtime(Id showtimeId) {
        // TODO: Query all seats for showtime
        // TODO: Order by Row and Number
    }
    
    /**
     * @description Create reservation with selected seats
     * @param showtimeId Showtime record ID
     * @param seatIds List of selected Seat IDs
     * @param customerInfo JSON with customer details
     * @return Reservation__c record with confirmation code
     */
    @AuraEnabled
    public static Reservation__c createReservation(Id showtimeId, List<Id> seatIds, String customerInfo) {
        // TODO: Parse customer info JSON
        // TODO: Validate seat availability
        // TODO: Create Reservation__c record
        // TODO: Update Seat__c records to Reserved
        // TODO: Update Showtime__c Reserved_Seats__c count
        // TODO: Generate unique confirmation code
        // TODO: Use Database.SavePoint for rollback on error
        // TODO: Call sendConfirmationEmail method
    }
    
    /**
     * @description Cancel an existing reservation
     * @param reservationId Reservation record ID
     * @return Boolean success indicator
     */
    @AuraEnabled
    public static Boolean cancelReservation(Id reservationId) {
        // TODO: Validate cancellation rules (time before showtime)
        // TODO: Update reservation status to Cancelled
        // TODO: Release seats back to Available
        // TODO: Update showtime reserved count
    }
    
    /**
     * @description Send confirmation email to customer
     * @param reservationId Reservation record ID
     */
    @future
    private static void sendConfirmationEmail(Id reservationId) {
        // TODO: Query reservation with related records
        // TODO: Create email template with ticket details
        // TODO: Send using Messaging.SingleEmailMessage
    }
    
    /**
     * @description Generate unique confirmation code
     * @return String confirmation code (e.g., "ABC123XYZ")
     */
    private static String generateConfirmationCode() {
        // TODO: Create random alphanumeric code
        // TODO: Ensure uniqueness by checking existing reservations
    }
}
```

#### 3.3 SeatManagementService.cls
```apex
/**
 * @description Service for seat generation and management
 * @author Cristiano Filho
 * @date 2025-09-30
 */
public with sharing class SeatManagementService {
    
    /**
     * @description Generate seats for a showtime
     * @param showtimeId Showtime record ID
     * @param rows Number of rows (default 10)
     * @param seatsPerRow Number of seats per row (default 10)
     * @return List of created Seat__c records
     */
    public static List<Seat__c> generateSeats(Id showtimeId, Integer rows, Integer seatsPerRow) {
        // TODO: Create seat matrix (A-1, A-2, B-1, etc.)
        // TODO: Insert all seats in bulk
    }
    
    /**
     * @description Lock seats temporarily during reservation process
     * @param seatIds List of Seat IDs to lock
     * @param duration Duration in minutes
     */
    public static void lockSeats(List<Id> seatIds, Integer duration) {
        // TODO: Update seats to Blocked status
        // TODO: Schedule unlock job using Schedulable
    }
}
```

#### 3.4 Test Classes
Generate test classes for each Apex class:
- `MovieGluServiceTest.cls` - Mock HTTP callouts
- `ReservationControllerTest.cls` - Test all AuraEnabled methods
- `SeatManagementServiceTest.cls` - Test seat generation logic

**Test Requirements**:
- Minimum 75% code coverage
- Test positive and negative scenarios
- Use @TestSetup for test data
- Mock external callouts

---

### Phase 4: Lightning Web Components

Generate complete LWC components with the following structure:

#### 4.1 cinemaBooking (Parent Container)
**Files**: 
- `cinemaBooking.js`
- `cinemaBooking.html`
- `cinemaBooking.css`
- `cinemaBooking.js-meta.xml`

**Functionality**:
- Container component managing navigation flow
- Wizard-style interface with steps: Search → Select Showtime → Choose Seats → Confirm
- State management for selected movie, showtime, seats
- Progress indicator

#### 4.2 movieSearch
**Files**:
- `movieSearch.js`
- `movieSearch.html`
- `movieSearch.css`
- `movieSearch.js-meta.xml`

**Functionality**:
- Search bar for movie titles
- Geolocation button to get user's coordinates
- Display movie cards with poster, title, synopsis
- Click to select movie (fire event to parent)
- Loading spinner during API calls

**Key JavaScript**:
```javascript
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import syncNowShowingFilms from '@salesforce/apex/MovieGluService.syncNowShowingFilms';

export default class MovieSearch extends LightningElement {
    @track movies = [];
    @track latitude = '-23.5505';
    @track longitude = '-46.6333';
    @track isLoading = false;
    @track error;
    
    // TODO: Implement connectedCallback to load movies
    // TODO: Handle geolocation using navigator.geolocation
    // TODO: Fire custom event when movie selected
}
```

#### 4.3 showtimeSelector
**Files**: Standard LWC structure

**Functionality**:
- Display showtimes grouped by theater
- Show theater name, address, distance
- List session times with price, 3D/IMAX badges
- Date picker to change showtime date
- Lightning map component showing theater locations

**Apex Wire**: Wire `getAvailableShowtimes`

#### 4.4 seatReservation
**Files**: Standard LWC structure

**Functionality**:
- Visual seat grid (rows A-J, numbers 1-10)
- Color-coded seats:
  - Green: Available
  - Yellow: Selected
  - Red: Occupied
  - Gray: Blocked
- Click to toggle seat selection
- Max 10 seats per reservation
- Show running total price
- Legend explaining colors

**CSS Grid Layout**:
```css
.seat-grid {
    display: grid;
    grid-template-columns: repeat(10, 1fr);
    gap: 8px;
    padding: 20px;
}

.seat {
    aspect-ratio: 1;
    border: 2px solid;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.3s;
}

.seat.available { background: #4caf50; }
.seat.selected { background: #ffc107; }
.seat.occupied { background: #f44336; cursor: not-allowed; }
```

#### 4.5 confirmationModal
**Files**: Standard LWC structure

**Functionality**:
- Modal overlay with reservation summary
- Form fields: Customer Name, Email, Phone
- Display selected seats, showtime, total amount
- Terms and conditions checkbox
- Confirm button calling `createReservation`
- Success message with confirmation code

---

### Phase 5: Automation (Flows & Triggers)

#### 5.1 ShowtimeTrigger.trigger
**Events**: before insert, before update, after insert, after update

**Logic**:
- Before Insert/Update: Validate session datetime is future
- After Insert: Generate seats using `SeatManagementService`
- After Update: Recalculate Available_Seats__c formula

**Handler Class**: `ShowtimeTriggerHandler.cls`

#### 5.2 Record-Triggered Flow: Send Reservation Confirmation
**Object**: Reservation__c
**Trigger**: Record is created or updated
**Condition**: Status = 'Confirmed'

**Actions**:
1. Get related Movie, Showtime, Theater records
2. Send Email using template "Reservation_Confirmation"
3. Update field "Confirmation_Sent__c" = true

#### 5.3 Screen Flow: Cinema Reservation Flow
**API Name**: `ReservaCinemaFlow`

**Screens**:
1. Welcome Screen
2. Movie Selection (embedded cinemaBooking component)
3. Customer Information
4. Review and Confirm
5. Confirmation Screen with ticket details

---

### Phase 6: Integration & Security

#### 6.1 Named Credential: MovieGlu_API
**XML Metadata**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<NamedCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>MovieGlu API</label>
    <endpoint>https://api-gate.movieglu.com</endpoint>
    <principalType>NamedUser</principalType>
    <protocol>Password</protocol>
    <username>your_client_id</username>
    <password>your_api_key</password>
</NamedCredential>
```

#### 6.2 Remote Site Setting
```xml
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>MovieGlu_API</fullName>
    <description>MovieGlu API integration</description>
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>https://api-gate.movieglu.com</url>
</RemoteSiteSetting>
```

#### 6.3 Permission Set: Cinema_Reservation_Admin
**Permissions**:
- Read/Create/Edit/Delete on all custom objects
- Execute Apex classes
- View Setup and Configuration
- Manage Experience Cloud Sites

---

### Phase 7: Experience Cloud Setup

#### 7.1 Site Configuration
- Template: Customer Service
- URL: cinema-reserva
- Home Page: Add cinemaBooking LWC component

#### 7.2 Guest User Profile
- Read access to Movie__c, Theater__c, Showtime__c
- Create access to Reservation__c (with sharing rules)

---

### Phase 8: Reports & Dashboards

#### 8.1 Reports
1. **Reservations by Movie** (Grouped by Movie, sum Total_Amount)
2. **Theater Occupancy** (Showtime report with % occupied)
3. **Daily Revenue** (Grouped by date)
4. **Cancelled Reservations** (Filter: Status = Cancelled)

#### 8.2 Dashboard: Cinema Management
**Components**:
- Top 5 Movies by Revenue (Bar Chart)
- Occupancy Rate by Theater (Gauge)
- Reservations Trend (Line Chart)
- Today's Showtimes (Table)

---

### Phase 9: Sample Data

#### 9.1 data/sample-data-plan.json
Create sample data file with:
- 5 Movie__c records
- 3 Theater__c records
- 10 Showtime__c records
- 100 Seat__c records per showtime

---

## Validation Checklist

Before completing initialization, verify:

- [ ] All custom objects have proper relationships
- [ ] Apex classes compile without errors
- [ ] Test classes achieve >75% coverage
- [ ] LWC components render correctly
- [ ] Named Credential connects to API successfully
- [ ] Flows are activated
- [ ] Permission sets are assigned
- [ ] Sample data imports successfully
- [ ] Experience Cloud site is published
- [ ] No hardcoded credentials in code

---

## Deployment Commands

```bash
# Validate deployment
sfdx force:source:deploy -p force-app/main/default --checkonly -u DevOrg

# Deploy to org
sfdx force:source:deploy -p force-app/main/default -u DevOrg

# Run tests
sfdx force:apex:test:run -l RunLocalTests -w 10 -r human -u DevOrg

# Assign permission set
sfdx force:user:permset:assign -n Cinema_Reservation_Admin -u DevOrg

# Import data
sfdx force:data:tree:import -p data/sample-data-plan.json -u DevOrg

# Open org
sfdx force:org:open -u DevOrg
```

---

## Success Criteria

The codebase initialization is complete when:

1. ✅ Project compiles without errors
2. ✅ All unit tests pass with >75% coverage
3. ✅ MovieGlu API integration works (test with real API call)
4. ✅ Full reservation flow works end-to-end:
   - Search movies → Select showtime → Choose seats → Confirm → Receive email
5. ✅ Experience Cloud site is accessible and functional
6. ✅ Reports and dashboards display data correctly
7. ✅ README.md matches implemented features

---

## Additional Instructions

- Use ES6+ syntax for JavaScript (arrow functions, destructuring, async/await)
- Follow Salesforce naming conventions (PascalCase for classes, camelCase for methods)
- Add JSDoc comments to all Apex methods
- Include error handling in all LWC components
- Use lightning-input, lightning-button base components
- Implement accessibility (ARIA labels, keyboard navigation)
- Add loading spinners during async operations
- Use constants for magic strings/numbers
- Implement proper separation of concerns (MVC pattern)

---

## Questions to Clarify Before Starting

1. What is the target Salesforce API version? (Recommend: v59.0 or v60.0)
2. Do you have MovieGlu API credentials already?
3. Should we implement payment integration (Stripe/PayPal) in Phase 1?
4. What email template style do you prefer for confirmations?
5. Should the system support multiple languages initially?
6. What is the preferred seating layout (rows/columns)?
7. Do you want QR code generation for tickets?
8. Should we implement seat locking/timeout mechanism?

---

**Next Steps**: 
Once you confirm the above details, I will begin generating the complete codebase file by file, starting with the SFDX project structure and custom objects.

