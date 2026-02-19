# ST6002CEM Mobile Application Development - Coursework 1 Report

## 1. Cover Page

- Module: ST6002CEM Mobile Application Development
- Assessment: Coursework 1 (Individual Report)
- Project Title: Kachra Alert - Smart Waste Management and Alert System
- Student Name: [Your Name]
- Student ID: [Your Student ID]
- Submission Date: [Insert Date]
- Word Count: ~2040 words (excluding cover page, references, appendix)

## 2. Introduction

### 2.1 Aims and Objectives

The aim of Kachra Alert is to improve waste-management communication between residents and municipal/admin teams through one mobile-first platform. The core objective is to let users quickly report waste issues with evidence while giving admins tools to monitor and respond.

The specific objectives are:

- Provide a simple reporting workflow for waste incidents.
- Reduce response time by structuring reports (category, severity, location, media).
- Allow two-way operational communication through alerts and messaging.
- Build a scalable architecture that can evolve from local persistence to cloud-backed APIs.

### 2.2 Background of Proposed Mobile App

Urban waste problems are often reported through fragmented channels, which creates missing data, duplicate complaints, and poor accountability. Kachra Alert addresses this with a structured digital workflow.

The current implementation is a Flutter mobile application with a Node.js/TypeScript backend in the same repository. The frontend follows feature-based clean architecture, while the backend exposes role-protected REST APIs and Socket.IO events.

### 2.3 Features of the App

Implemented user-facing and admin-facing features include:

- Authentication: Register/login with role-based flows.
- Reporting: Multi-step report form with waste category, severity, notes, location detail, and image attachment.
- Reports dashboard: List reports, status visibility, and admin status updates.
- Alerts: Admin broadcast alerts and resident alert feed.
- Schedule: Waste collection schedule management and viewing.
- Payments: Invoice listing and payment action flow.
- Messaging: Resident-admin chat with read/edit/delete and reply support.
- Profile and settings: Profile photo updates, language preferences, theme settings, motion/haptics preferences.
- Localization: English and Nepali language support.

From an engineering perspective, these features are designed around both functional and non-functional requirements. Functionally, the system captures and routes waste incidents from reporting to action. Non-functionally, the app emphasizes responsive UI feedback, role-based access, error-state handling, and modular maintainability. This is important because civic apps fail not only due to missing features, but also due to slow workflows, unclear status updates, and weak reliability under real user behavior.

### 2.4 App Monetization

Kachra Alert can be monetized with a mixed B2G/B2B2C model:

- Municipality subscription: SaaS fee paid by local government for the full dashboard and analytics package.
- Society/apartment plans: Private residential communities can subscribe for branded deployments.
- Transaction-based services: Small service fee on digital billing/payments.
- Premium analytics: Paid insights for route efficiency and complaint hotspots.

### 2.5 Similar App and Differentiation

A similar category app is SeeClickFix (civic issue reporting). Kachra Alert differs in three important ways:

- Domain focus: It is specialized for waste operations rather than generic civic complaints.
- Operational stack: It combines reporting with schedules, invoice/payments, and resident-admin messaging in one product.
- Local context readiness: Nepali localization and role setup (resident/admin_driver) align with real municipal operations in Nepalese contexts.

## 3. Cloud Computing

### 3.1 Why Cloud Computing and Big Data Matter for Mobile App Development

Cloud computing is critical for mobile systems because mobile devices have limited storage, compute, and battery. In Kachra Alert, cloud services are required for:

- Reliable central data storage across users and devices.
- Media handling for report attachments and profile images.
- Real-time communication events (alerts and messaging).
- Elastic scaling when report volume increases.

From a business perspective, Big Data becomes important when reports, schedules, payments, and message activity are aggregated over time. This supports:

- Geographic hotspot detection for recurring waste issues.
- Demand forecasting for vehicle routing and staff scheduling.
- Service quality monitoring (response times and closure rates).
- Budget optimization through data-driven decisions.

### 3.2 Cloud/Big Data Strategy for Kachra Alert

The current backend architecture already aligns with cloud migration:

- API layer: Express routes under `/api/v1` for modular services.
- Database: MongoDB model design for users, reports, alerts, schedules, invoices, and messages.
- Real-time events: Socket.IO for push-like behavior.
- Stateless auth: JWT access tokens with refresh-token lifecycle.

A production cloud deployment can add:

- Managed MongoDB (e.g., Atlas) for high availability.
- Object storage + CDN for media files.
- Message queues for async workloads (analytics, notifications).
- Dashboard analytics pipeline to transform operational records into business KPIs.

Cloud computing is therefore not only hosting; it is an enabler for scalability, reliability, and measurable business value.

From a business architecture view, Kachra Alert can map cleanly to service models:

- SaaS layer: municipality/admin dashboards and operational workflows.
- PaaS layer: managed database, container hosting, and real-time infrastructure.
- Data layer: event and transaction streams for reporting, billing, and service trends.

This separation improves governance and cost control. For example, daily API traffic can scale independently of analytics jobs, and media storage can scale independently of core transactional data. Over time, this enables evidence-based governance, where policy and operational decisions are driven by measured waste patterns rather than assumptions.

## 4. Design Pattern and Architectural Pattern

### 4.1 Design Pattern Used (MVVM-Oriented with Repository)

A design pattern is a reusable software solution for common engineering problems. In this project, the presentation layer follows an MVVM-oriented approach using Riverpod state notifiers:

- View: Flutter pages/widgets (e.g., report form, reports list, schedule screen).
- ViewModel-like logic: Riverpod `StateNotifier` classes that manage UI state and async flow.
- Model: Hive models and API models (`ReportHiveModel`, `ScheduleHiveModel`, etc.).

This pattern gives clear separation between UI rendering and business logic. It also reduces widget complexity and improves testability.

Compared to directly placing business logic in widgets, this approach lowers coupling and prevents screen files from becoming unmaintainable as feature complexity grows. Compared to classical MVC, it provides a clearer reactive data flow for Flutter. Compared to over-engineered alternatives, it stays lightweight enough for coursework scope while still demonstrating professional structure.

### 4.2 Architectural Pattern Used (Clean, Layered Feature Architecture)

Architectural pattern defines high-level structure between modules. Kachra Alert uses a clean, layered architecture organized by feature:

```
Presentation (pages/widgets)
  -> Providers/StateNotifiers (state + orchestration)
  -> Repositories (domain/data boundary)
  -> Data sources (ApiClient, Hive)
  -> Backend services (REST + Socket.IO)
  -> MongoDB persistence
```

Each feature (reports, alerts, schedule, messages, payments, auth) keeps its own `presentation`, `data`, and model files. This has three benefits:

- Scalability: New modules can be added without tight coupling.
- Maintainability: Changes are localized inside features.
- Replaceability: Local and remote data strategies can be swapped with minimal UI impact.

Critical evaluation: the structure is strong, but some modules still show transitional parts (for example, report editing intentionally blocked, map integration placeholder, and some local/remote split still evolving). This is acceptable at coursework stage and demonstrates a realistic iterative architecture.

Another positive point is boundary clarity. Core infrastructure concerns such as API clients, routing, and storage services are centralized, while feature modules remain independently evolvable. This reduces regression risk when adding new modules like driver route optimization, citizen reward points, or public complaint heatmaps in later coursework phases.

## 5. State Management

State management is the method used to control how UI reflects data changes. In Kachra Alert, Riverpod is the primary state-management solution.

Implementation highlights:

- Providers expose API clients and repositories using dependency injection.
- `StateNotifier<AsyncValue<T>>` is used across major features for loading/data/error states.
- Authentication state controls route guarding via GoRouter redirect logic.
- Settings state persists theme, language, motion, and onboarding flags.
- Reports/schedules/messages/payments each have dedicated notifier classes.

Why Riverpod is suitable here:

- Predictable state flow for async API operations.
- Decoupled logic and UI (better testing and readability).
- Compile-time safety and provider scoping.
- Good fit for clean architecture and medium-scale mobile apps.

This shows a practical use of modern state management for real app complexity.

The use of `AsyncValue` is especially important because municipal operations are network-dependent and cannot assume constant connectivity. By explicitly modeling loading, data, and error states, the app avoids silent failures and improves user trust. In addition, route decisions are tied to provider state (auth, onboarding, startup gates), which creates a robust startup flow and prevents unauthorized screen access.

## 6. Sensors and API

### 6.1 Sensors and Device Capabilities

Kachra Alert currently uses practical device capabilities relevant to waste reporting:

- Camera and gallery access through `image_picker` to attach incident photos.
- Media permission flow through `permission_handler` for photo/video/storage access.
- Location context through structured location text and coordinates in alert creation.

Critical point: the map screen is currently a UI placeholder and direct GPS/map SDK integration is not yet complete. For production, adding geolocation and map APIs would improve precision and route planning.

### 6.2 Third-Party and Internal APIs

The app integrates with a backend REST API through a shared `ApiClient` that handles:

- JSON requests (`GET/POST/PATCH/PUT/DELETE`)
- Bearer token headers
- Multipart-like attachment payload handling
- Error extraction and timeout handling

Major API domains implemented:

- Auth (`/auth`): register, login, token lifecycle, password reset.
- Reports (`/reports`): create/list/update status with attachments.
- Alerts (`/alerts`): list and admin broadcast.
- Schedules (`/schedules`): CRUD by admin, read by residents.
- Invoices (`/invoices`): list and payment action.
- Messages (`/messages`): contacts, conversation, send/edit/delete.

Real-time APIs are also present through Socket.IO for alerts and chat events.

API integration also demonstrates defensive engineering. The client standardizes base URL resolution, timeout boundaries, bearer header injection, response decoding, and fallback error messaging. This reduces repeated networking code and creates one consistent contract between UI and backend modules. As a result, feature teams can focus on domain behavior rather than rewriting transport logic for each screen.

## 7. Data and Security

### 7.1 Data Kept in the Mobile App and Storage Strategy

Data handled by the app includes:

- User session and role data (including access token).
- Settings/preferences (theme, language, onboarding, motion/haptics).
- Operational data models (reports, alerts, schedules, admin alerts).
- Temporary media attachment bytes before upload.

Local persistence strategy:

- Hive is used for structured local data boxes.
- SharedPreferences is used for lightweight session/config keys.

Remote persistence strategy:

- MongoDB stores users, reports, alerts, schedules, invoices, payments, refresh tokens, and messages.
- Backend models enforce schema structure and enum constraints.

### 7.2 Security of Local and Remote Data

Implemented security controls:

- Password hashing using bcrypt (`saltRounds = 12`).
- JWT access tokens and refresh-token rotation.
- Hashed refresh token storage and reuse detection.
- Role-based access control (`requireAuth`, `requireAdmin`).
- Rate limiting for sensitive endpoints (login/forgot-password).
- Input validation via Zod schemas.
- HTTP hardening middleware (`helmet`) and controlled CORS.
- Ownership checks for protected resources (report/message access).

Data ethics considerations are also relevant for this domain. Waste reports can contain sensitive location context and potentially identifiable media. Therefore, responsible design should include: data minimization (collect only what is required), role-limited access to records, retention policies for old attachments, and transparent user communication on what data is stored and why. These principles improve legal compliance and public trust.

Security gaps and improvements (critical evaluation):

- Local token storage currently uses Hive/SharedPreferences; production should move tokens to secure key storage.
- Local database encryption is not yet enabled for Hive boxes.
- TLS and secret management must be enforced in production cloud deployment.
- Media scanning/content moderation can be added for attachment safety.

Overall, the backend security posture is stronger than many prototype projects, but local-at-rest hardening is a clear next step.

## 8. Conclusion

Kachra Alert demonstrates a strong foundation for a practical civic-tech mobile product. The project already integrates core modules that many student apps keep as separate prototypes: incident reporting, admin alerts, schedules, payments, messaging, and role-aware security. Technically, the use of Flutter + Riverpod + clean feature architecture on the client, and Express + MongoDB + JWT + Socket.IO on the server, provides a scalable and maintainable baseline.

From the perspective of module learning outcomes, the project shows critical understanding of mobile development tools and architectural tradeoffs, and it clearly positions cloud computing and data analytics as direct business enablers rather than optional add-ons. The most important next improvements are secure local credential storage, map/GPS completion, and analytics pipelines for operational intelligence. With these enhancements, Kachra Alert can evolve from coursework implementation into a deployable municipal service platform.

## 9. References

1. Flutter Documentation. https://docs.flutter.dev/
2. Riverpod Documentation. https://riverpod.dev/
3. Hive Documentation. https://docs.hivedb.dev/
4. GoRouter Documentation. https://pub.dev/packages/go_router
5. Socket.IO Documentation. https://socket.io/docs/v4/
6. MongoDB Documentation. https://www.mongodb.com/docs/
7. Express.js Documentation. https://expressjs.com/
8. Zod Documentation. https://zod.dev/
9. Coursework brief: Mobile Application Development ST6002CEM - CW1 (provided PDF).

## 10. Appendix

### 10.1 YouTube Video Link

- [Add your demo link here]

### 10.2 GitHub Link (Mobile and API)

- Mobile + API repository: https://github.com/Abishek-077/Kachra-Alert
- API directory in repository: `back-end/`

### 10.3 Screenshots of App

Attach screenshots for the following pages in final submission document:

- Login and Signup screens
- Home dashboard
- Report creation flow (3 steps)
- Reports list and status chips
- Alerts hub and admin broadcast page
- Schedule management page
- Messaging screen
- Payments/invoice screen
- Profile and settings page
