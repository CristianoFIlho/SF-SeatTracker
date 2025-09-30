# SF-SeatTracker

Cinema seat management system developed in Lightning Web Components (LWC) for Salesforce, with integration to real movie and cinema showtime APIs.

![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)
![Lightning Web Components](https://img.shields.io/badge/LWC-0176D3?style=for-the-badge&logo=salesforce&logoColor=white)
![Apex](https://img.shields.io/badge/Apex-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)

## 📋 Table of Contents

- [About the Project](#about-the-project)
- [Features](#features)
- [Architecture](#architecture)
- [Technologies Used](#technologies-used)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Usage](#usage)
- [Testing](#testing)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## 🎬 About the Project

SF-SeatTracker is a complete cinema seat reservation management system developed on the Salesforce platform. The project integrates real data from movies, theaters, and showtimes through the MovieGlu API.

### Objectives

- Consume real API (MovieGlu) to display movies in theaters, cinemas, and showtimes
- Simulate seat selection and reservation for cinema
- Demonstrate complete architecture of the Salesforce ecosystem
- Offer responsive experience with Lightning Web Components
- Automate processes with Flows and triggers
- Provide analytics through reports and dashboards

## ✨ Features

- ✅ **Movie Search**: Search for movies in theaters by location (geolocation)
- ✅ **Theater Listing**: Display nearby theaters with map
- ✅ **Available Showtimes**: View sessions by movie and theater
- ✅ **Seat Selection**: Interactive interface for seat selection (visual grid)
- ✅ **Ticket Reservation**: Complete reservation process with confirmation
- ✅ **Reservation Management**: Track reservation status (Pending/Approved/Canceled)
- ✅ **Notifications**: Automatic sending of confirmation emails
- ✅ **Reports**: Dashboards with occupancy and reservation metrics
- ✅ **External Portal**: Experience Cloud for public access

## 🏗️ Architecture

### System Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Experience Cloud (UI)                     │
│                  (Lightning Communities)                     │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│              Lightning Web Components (LWC)                  │
│  movieSearch │ showtimeSelector │ seatReservation │ confirm  │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                      Apex Controllers                        │
│    MovieGluService │ ReservationController │ Triggers        │
└──────────────┬────────────────────┬─────────────────────────┘
               │                    │
       ┌───────▼────────┐   ┌──────▼──────────────────┐
       │  MovieGlu API  │   │  Custom Objects & Flows │
       │  (External)    │   │    (Data Layer)         │
       └────────────────┘   └─────────────────────────┘
```

### Custom Objects

| Object | Relationship | Description |
|--------|---------------|-----------|
| **Movie__c** | - | Stores movie information (name, description, poster, API ID) |
| **Theater__c** | - | Theater data (name, address, geographic location) |
| **Showtime__c** | Master-Detail → Movie__c, Theater__c | Session times with prices and available seats |
| **Reservation__c** | Lookup → Account, Movie__c, Showtime__c | Reservations with status and total amount |
| **Seat__c** | Master-Detail → Showtime__c | Individual seats per session |

## 🛠️ Technologies Used

### Salesforce Platform

- **Lightning Web Components (LWC)** - Modern frontend framework
- **Apex** - Backend and business logic
- **Flows** - Automations and processes
- **Experience Cloud** - External portal
- **Reports & Dashboards** - Analytics and visualizations
- **Named Credentials** - Secure API integration

### Integrations

- **MovieGlu API** - Real movie and theater data
- **Geolocation API** - Proximity search

### Development Tools

- Salesforce CLI (SFDX)
- Visual Studio Code + Salesforce Extensions
- Git/GitHub
- Postman (for API testing)

## 📦 Prerequisites

Before you begin, you need:

- **Salesforce Developer Org** ([Create free account](https://developer.salesforce.com/signup))
- **MovieGlu API Key** ([Register at developer.movieglu.com](https://developer.movieglu.com))
- **Salesforce CLI** installed ([Installation guide](https://developer.salesforce.com/tools/sfdxcli))
- **Visual Studio Code** with Salesforce extensions ([Download](https://code.visualstudio.com/))
- **Git** installed

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/CristianoFIlho/SF-SeatTracker.git
cd SF-SeatTracker
```

### 2. Authenticate to Salesforce

```bash
sfdx auth:web:login -a DevOrg -r https://login.salesforce.com
```

### 3. Create a Scratch Org (Optional)

```bash
sfdx force:org:create -f config/project-scratch-def.json -a SeatTrackerOrg -s -d 30
```

### 4. Deploy Metadata

```bash
sfdx force:source:push -u SeatTrackerOrg
```

### 5. Assign Permission Set

```bash
sfdx force:user:permset:assign -n Cinema_Reservation_Admin
```

### 6. Import Sample Data (Optional)

```bash
sfdx force:data:tree:import -p data/sample-data-plan.json
```

## ⚙️ Configuration

### 1. Configure Named Credential

1. Access **Setup** > **Named Credentials** > **New**
2. Fill in:
   - **Label**: MovieGlu_API
   - **URL**: `https://api-gate.movieglu.com`
   - **Identity Type**: Named Principal
   - **Authentication Protocol**: Custom
3. In **Custom Headers**, add:
   ```
   x-api-key: YOUR_API_KEY_HERE
   client: YOUR_CLIENT_ID_HERE
   authorization: Basic BASE64_ENCODED_CREDENTIALS
   x-api-key: YOUR_API_KEY
   ```

### 2. Configure Remote Site Settings

1. **Setup** > **Remote Site Settings** > **New**
2. **Remote Site URL**: `https://api-gate.movieglu.com`
3. Check **Active**

### 3. Adjust Geolocation

In the file `force-app/main/default/lwc/movieSearch/movieSearch.js`, adjust the default coordinates:

```javascript
// For São Paulo, Brazil
@track lat = '-23.5505';
@track lon = '-46.6333';
```

### 4. Configure Experience Cloud (Optional)

1. **Setup** > **Digital Experiences** > **All Sites** > **New**
2. Choose **Customer Service** template
3. Name: **Cinema Reservation Portal**
4. URL: `cinema-reserva`
5. Add LWC components to pages

## 📁 Project Structure

```
SF-SeatTracker/
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/                    # Apex Classes
│           │   ├── MovieGluService.cls     # API integration service
│           │   ├── ReservationController.cls
│           │   ├── SeatManagementService.cls
│           │   └── *Test.cls               # Test classes
│           ├── lwc/                        # Lightning Web Components
│           │   ├── cinemaBooking/          # Main component
│           │   ├── movieSearch/            # Movie search
│           │   ├── showtimeSelector/       # Showtime selection
│           │   ├── seatReservation/        # Seat grid
│           │   └── confirmationModal/      # Confirmation modal
│           ├── objects/                    # Custom Objects
│           │   ├── Movie__c/
│           │   ├── Theater__c/
│           │   ├── Showtime__c/
│           │   ├── Reservation__c/
│           │   └── Seat__c/
│           ├── flows/                      # Screen Flows and Automations
│           │   └── ReservaCinemaFlow.flow
│           ├── triggers/                   # Apex Triggers
│           │   └── ShowtimeTrigger.trigger
│           ├── namedCredentials/           # API Integrations
│           │   └── MovieGlu_API.namedCredential
│           └── permissionsets/             # Permission Sets
│               └── Cinema_Reservation_Admin.permissionset
├── data/                                   # Sample Data
│   └── sample-data-plan.json
├── config/
│   └── project-scratch-def.json
├── .gitignore
├── README.md
├── sfdx-project.json
└── package.json
```

## 💻 Usage

### For End Users

1. **Access Portal**: Navigate to `https://[your-domain].my.site.com/cinema-reserva`
2. **Search Movies**: Use the search bar or geolocation
3. **Select Session**: Click on a movie and choose a showtime
4. **Choose Seats**: Click on available seats (green)
5. **Confirm Reservation**: Fill in details and complete
6. **Receive Confirmation**: Check email with reservation details

### For Administrators

#### Sync Movies from API

```apex
// Execute in Developer Console
MovieGluService.syncNowShowingFilms('-23.5505', '-46.6333');
```

#### Update Showtimes

```apex
// Sync showtimes for a specific movie
MovieGluService.syncShowtimes('MOVIE_ID_API', '-23.5505', '-46.6333', Date.today());
```

#### View Dashboards

1. Access **App Launcher** > **Cinema Management**
2. Navigate to **Dashboards** tab
3. View metrics for:
   - Occupancy by theater
   - Most reserved movies
   - Revenue by period

## 🧪 Testing

### Run Unit Tests

```bash
# All tests
sfdx force:apex:test:run -l RunLocalTests -w 10 -r human

# Specific test
sfdx force:apex:test:run -n MovieGluServiceTest -r human
```

### Code Coverage

The project maintains **>75% coverage** in Apex:

```bash
sfdx force:apex:test:run -c -r human
```

### Integration Tests

MovieGlu API mock in `MovieGluHttpCalloutMock.cls`:

```apex
@isTest
global class MovieGluHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"films":[{"film_name":"Test Movie","synopsis":"Test"}]}');
        res.setStatusCode(200);
        return res;
    }
}
```

## 🗺️ Roadmap

### Phase 1 - Core Features (Completed)
- [x] MovieGlu API integration
- [x] Custom objects CRUD
- [x] LWC for search and reservation
- [x] Flows for email automation

### Phase 2 - Improvements (In Progress)
- [ ] Payment integration (Stripe/PayPal)
- [ ] Real-time notifications (Platform Events)
- [ ] Multi-language support
- [ ] QR Code for tickets

### Phase 3 - Advanced
- [ ] Einstein Analytics for predictions
- [ ] Chatbot with Einstein Bots
- [ ] Mobile app with Salesforce Mobile SDK
- [ ] Integration with real ticketing systems

## 🤝 Contributing

Contributions are welcome! Follow these steps:

1. Fork the project
2. Create a branch for your feature (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards

- **Apex**: Follow [Apex Style Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
- **LWC**: Use [Lightning Web Components Best Practices](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/)

## 📄 License

This project is under the MIT license. See the [LICENSE](LICENSE) file for more details.

## 👤 Contact

**Cristiano Filho**

- GitHub: [@CristianoFIlho](https://github.com/CristianoFIlho)
- LinkedIn: [Your LinkedIn](https://linkedin.com/in/your-profile)
- Email: your-email@example.com

---

## 📚 Additional Resources

### Documentation
- [MovieGlu API Docs](https://developer.movieglu.com/docs)
- [Salesforce LWC Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Apex Integration Services Trailhead](https://trailhead.salesforce.com/content/learn/modules/apex_integration_services)

### Recommended Trailheads
- 🎯 [Build Apps Together with Package Development](https://trailhead.salesforce.com/en/content/learn/trails/sfdx_get_started)
- 🎯 [Lightning Web Components Basics](https://trailhead.salesforce.com/content/learn/modules/lightning-web-components-basics)
- 🎯 [Apex Integration Services](https://trailhead.salesforce.com/content/learn/modules/apex_integration_services)

### Community
- [Salesforce Developers Forum](https://developer.salesforce.com/forums)
- [Salesforce Stack Exchange](https://salesforce.stackexchange.com/)
- [Trailblazer Community](https://trailblazers.salesforce.com/)

---

⭐ **If this project was helpful, consider giving it a star!** ⭐

---

**Developed with ❤️ using Salesforce Platform**