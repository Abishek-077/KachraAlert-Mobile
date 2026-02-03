# Kachra Alert ♻️  
**Smart Waste Management & Alert System (Flutter + Admin Panel + API Ready)**

Kachra Alert is a **Smart Waste Management & Alert System** built with **Flutter** using **Clean Architecture** principles.  
The app helps citizens report waste issues, view alerts, track report status, and manage profiles — while an admin panel manages incoming reports and updates their statuses.

> ✅ **Local storage is implemented using Hive** for offline persistence.  
> 🔜 **Backend API will be implemented using Node.js + TypeScript** for scalable, real-world deployments.

---

## 📱 Key Features

### Mobile App (Flutter)
- ✅ **Authentication flow** (login/signup) .
- ✅ **Home Dashboard** with stats, quick actions, and recent reports
- ✅ **Report Waste** flow (category, description, photo/location optional)
- ✅ **Alerts system** (user alerts + admin alerts)
- ✅ **Schedule / Pickup reminders**
- ✅ **Collection points map** (admin selects pickup locations, residents view on map)
- ✅ **Profile** with achievements + settings
- ✅ Premium modern UI (soft shadows, rounded cards, chips, dock navigation)
- ✅ Loading / empty / error states

### Admin (Web + Mobile)
- ✅ Admin can view reports and update status  .
- ✅ Admin can broadcast alerts (reflected on user alerts screen) .
- 🔜 Admin Web Panel (Next.js) planned for production-ready dashboard usage .

---

## 🧱 Tech Stack

### Frontend (Mobile)
- **Flutter (Dart)**
- **Riverpod** (State Management)
- **GoRouter** (Navigation)
- **Hive** (Local DB / Offline persistence)
- **SharedPreferences** (Lightweight local session config)
- **Google Fonts** (Premium typography / UI consistency)
- **Google Maps SDK** (collection points map)

### Backend (Planned)
- **Node.js + TypeScript**
- **Express.js**
- **JWT Auth**
- **MongoDB (Mongoose)**
- Clean Architecture / Layered services
- REST APIs for reports, alerts, users, admin status updates

---

## 🗂️ Project Structure (Clean Architecture)

---

## 🗺️ Google Maps Setup

To enable the collection points map, add your Google Maps API key in the following files:

### Android
Update the placeholder in `android/app/build.gradle.kts`:

```kotlin
manifestPlaceholders["MAPS_API_KEY"] = "YOUR_GOOGLE_MAPS_API_KEY"
```

### iOS
Set the key in `ios/Runner/Info.plist`:

```xml
<key>GMSApiKey</key>
<string>YOUR_GOOGLE_MAPS_API_KEY</string>
```

### Web
Replace the placeholder in `web/index.html`:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>
```

This project follows a scalable clean architecture structure:
