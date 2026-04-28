# SevakAI: Production-Grade Project Roadmap & Execution Checklist

This document outlines the professional execution strategy for the SevakAI MVP. It follows **Clean Architecture** principles, **SOLID** design patterns, and **Production-Grade** security/performance standards for the Google Solution Challenge 2026.

> **Status as of April 2026:** Phases 0–3 are complete. Work resumes from Phase 4.

---

## 📋 Pre-Flight Checklist (Required Inputs)

Before moving to Phase 1, the following infrastructure details are required from the user:

- [x] **Auth Strategy**: ✅ **Email/Password + Google Sign-In** confirmed.
- [x] **Dashboard Target**: ✅ **Flutter Web** (Hosted on Firebase Hosting) — same codebase, built for web.
- [x] **Notification Strategy**: ✅ **Firestore real-time listener** in volunteer app triggers `flutter_local_notifications` on task assignment (no Cloud Functions required on Spark plan).
- [x] **Environment Keys**: Gemini API Key, Cloudinary Cloud Name, Cloudinary Preset Name — stored via `--dart-define` / `.env`.

---

## 🏗️ Phase 0: Environment & Core Infrastructure ✅ DONE
*Goal: Zero-to-One project initialization with professional scaffolding.*

- [x] **Initialization**:
    - [x] `flutter create sevak_app --org com.sevakai --platforms android,web` ✅
    - [x] `pubspec.yaml` configured with all pinned dependencies (152 packages resolved) ✅
    - [x] `flutterfire configure` ✅
- [x] **Architecture Scaffolding**:
    - [x] Full `features/` directory created (Auth, Needs, Dashboard, Tasks, Matching, Location, NGOs, Partnerships) ✅
    - [x] Full `core/` directory created (Theme, Constants, Config, Errors, Utils) ✅
- [x] **Security Scaffolding**:
    - [x] `env_config.dart` — Secrets loaded via `--dart-define` only ✅
    - [x] `.gitignore` — API keys, keystores, google-services.json excluded ✅
- [x] **CI/CD Prep**:
    - [x] `analysis_options.yaml` — Strict linting ✅
    - [x] `proguard-rules.pro` — Code obfuscation rules configured ✅
- [x] **Core Files Written**:
    - [x] `main.dart`, `app.dart`, `app_theme.dart`, `app_constants.dart`, `failures.dart` ✅
    - [x] `image_compressor.dart`, `distance_calculator.dart` ✅
    - [x] `AndroidManifest.xml` — All permissions (location, camera, FCM, WorkManager) ✅
    - [x] `role_definitions.dart`, `super_admin_config.dart` — 5-role RBAC constants ✅

---

## 🔐 Phase 1: Authentication, Roles & User Profiles ✅ DONE
*Goal: Secure identity management for all 5 roles (SA, NA, CO, VL, CU).*

- [x] **Identity Layer**:
    - [x] `AuthRepository` with `signIn`, `signUp`, `signOut`, `signInWithGoogle` ✅
    - [x] Role reconciliation on login: checks SA config → existing profile → assigns default CU role ✅
    - [x] Role-based routing via GoRouter (Volunteer UI / Coordinator UI / NGO Admin / Super Admin) ✅
- [x] **Profile Management**:
    - [x] Volunteer onboarding: Name, Phone, Skills selection → saved to `volunteers` collection ✅
    - [x] `ngoId` and `ngoMemberships` array on volunteer profile (multi-NGO membership model) ✅
    - [x] Invite code redemption: `inviteCodes` datasource → upgrades CU to VL/CO + adds NGO membership ✅
    - [x] `UserRepository` — reads/writes `volunteers` + role field in Firestore ✅
- [x] **NGO Registration & Discovery**:
    - [x] `register_ngo_page.dart` → writes to `ngos` collection with `status: pending` ✅
    - [x] `ngo_discovery_page.dart` → browse and submit join requests ✅
    - [x] Join request datasource → `joinRequests` collection ✅
- [x] **UX Polish**:
    - [x] Glassmorphic Login UI with custom typography ✅
    - [x] Error handling with user-friendly Snackbars ✅

---

## 🧠 Phase 2: Need Submission & AI Pipeline ✅ DONE
*Goal: Multimodal ingestion with client-side Gemini processing.*

- [x] **Data Ingestion**:
    - [x] Camera + gallery integration with `image_picker` ✅
    - [x] Image compression: `flutter_image_compress` in a separate `Isolate` (< 150 KB target) ✅
- [x] **The "Magic" Pipeline** (all datasources written):
    - [x] `cloudinary_datasource.dart` — Unsigned upload with progress tracking ✅
    - [x] `gemini_datasource.dart` — OCR + extraction prompt → structured JSON ✅
    - [x] `nominatim_datasource.dart` — Geocoding address → lat/lng (1-sec rate-limit compliant) ✅
    - [x] `needs_firestore_datasource.dart` — Saves scored need to Firestore ✅
    - [x] `SubmitNeedUseCase` — Orchestrates full pipeline ✅
- [x] **Verification State**:
    - [x] `ai_processing_page.dart` — "Gemini is thinking…" shimmer animation ✅
    - [x] `need_confirmation_page.dart` — Volunteer can review/edit AI-extracted data before save ✅

---

## 🗺️ Phase 3: Coordinator Dashboard & Multi-NGO Role Infrastructure ✅ DONE
*Goal: Real-time command center with multi-NGO coordination layer.*

- [x] **Mapping Engine**:
    - [x] `flutter_map` + OpenStreetMap — real-time Firestore stream → urgency-colored markers ✅
    - [x] Marker clustering (`flutter_map_marker_cluster`) ✅
- [x] **Multi-NGO Coordination ("Claim" System)**:
    - [x] Global need heatmap (all city needs visible, filtered by NGO ownership) ✅
    - [x] Detail panel: "Claimed by NGO: [None / Name]" + "Claim for My NGO" button ✅
    - [x] `ngoId` updated atomically in Firestore on claim ✅
- [x] **Stats Dashboard**:
    - [x] Real-time stat cards: Active Needs, Volunteers Available, Resolved Today ✅
    - [x] `task_list_table.dart` — Sortable needs table with status badges ✅
- [x] **Role-Gated Pages Built**:
    - [x] `dashboard_page.dart` — Coordinator scope (CO) ✅
    - [x] `ngo_admin_page.dart` — NGO Admin scope (NA): join requests, invite code generation ✅
    - [x] `super_admin_page.dart` — Super Admin scope (SA): platform-wide NGO approval ✅
- [x] **Partnerships Data Layer**:
    - [x] `partnerships` collection model + datasource ✅
    - [x] `crossNgoTasks` collection model ✅
    - [x] `partnership_entity.dart`, `cross_ngo_task_entity.dart` ✅

---

## 🤝 Phase 4: Volunteer Task Flow, Matching Engine & Cross-NGO Logic
*Goal: Close the full loop — need → match → volunteer action → completion → cross-NGO escalation.*

> **This is the active phase.** The data models and Firestore schema for multi-NGO are already in place. Phase 4 wires up all the runtime logic and volunteer-facing UI.

### 4A · Volunteer "My Tasks" Flow (Highest Priority)
- [ ] **`tasks/` feature** — clean architecture scaffold (entities, repository, usecases):
    - [ ] `task_entity.dart` — maps `needs` doc fields: `assignedTo`, `status`, `matchReason`, `ngoId`
    - [ ] `TaskRepository` interface + `TaskRepositoryImpl`
    - [ ] `GetMyTasksStreamUseCase` — Firestore stream: `needs` where `assignedTo == currentUid`
    - [ ] `UpdateTaskStatusUseCase` — transitions `IN_PROGRESS` → `COMPLETED`
- [ ] **`my_tasks_page.dart`** — real-time list of assigned tasks (status badges, urgency color)
- [ ] **`task_detail_page.dart`**:
    - [ ] Full need info: description, photo (Cloudinary URL), people affected, urgency
    - [ ] Accept / Decline buttons → update `need.status` in Firestore
    - [ ] "Open in Maps" → launches Google Maps / Apple Maps via `url_launcher` with lat/lng deep-link
    - [ ] "Mark Complete" button → `UpdateTaskStatusUseCase`
    - [ ] Cross-NGO badge: if task sourced from partner NGO, show "via [Partner NGO Name]" label

### 4B · Background Location Tracking
- [ ] **WorkManager periodic task** (15-min interval):
    ```dart
    Workmanager().registerPeriodicTask(
      "location_update",
      "updateVolunteerLocation",
      frequency: Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
    ```
- [ ] **Callback**: GPS → update `volunteers/{uid}.lat`, `.lng`, `.locationUpdatedAt`
- [ ] **`location/` feature** — `LocationService` interface + `LocationServiceImpl` using `geolocator`
- [ ] **`location_controller.dart`** — Riverpod notifier; manages permission state
- [ ] **Permission edge cases**:
    - [ ] GPS disabled → "Enable GPS" dialog
    - [ ] Background permission denied (Android 10+) → graceful degrade with last-known location
    - [ ] OEM battery kill (Xiaomi/Samsung) → in-app guide linking to `dontkillmyapp.com`

### 4C · Single-NGO Matching Engine (base)
- [ ] **`matching/` feature** scaffold:
    - [ ] `MatchingRepository` interface + `MatchingRepositoryImpl`
    - [ ] `MatchVolunteerUseCase`:
        1. Query `volunteers` where `isAvailable == true` AND `ngoId == need.ngoId`
        2. Filter by 25 km Haversine radius; expand to 50 km if empty
        3. Build JSON payload → Gemini Prompt 2 → parse `matchedVolunteerUid`
        4. Validate UID is in the volunteer list (guard against hallucination)
        5. Atomic Firestore write: `need.status = ASSIGNED`, `need.assignedTo`, `need.matchReason`; increment `volunteer.activeTasks`
    - [ ] `matching_gemini_datasource.dart` — Gemini Prompt 2 call
    - [ ] `matching_controller.dart` — Riverpod notifier; exposes `matchVolunteer(needId)` action
- [ ] **Coordinator Dashboard integration**:
    - [ ] "Find Best Volunteer" button in `need_detail_panel.dart` triggers `matchVolunteer()`
    - [ ] Show matched volunteer name + distance + reason in the panel after match

### 4D · Cross-NGO Matching Escalation
*Triggers when 4C finds 0 available volunteers within 50 km.*

- [ ] **`CrossNgoMatchUseCase`**:
    1. Query `partnerships` collection: find ACTIVE partnerships where `ngoA == need.ngoId` (or `ngoB`)
    2. Filter partners who have opted-in to sharing the relevant skill (e.g., MEDICAL)
    3. Fetch `volunteers` from each partner NGO where `isAvailable == true` AND `crossNgoConsent == true`
    4. Build combined volunteer pool → Gemini Prompt 2 with `crossNgo: true` flag in context
    5. On match: write to `crossNgoTasks` collection (`needId`, `sourceNgoId`, `volunteerNgoId`, `volunteerConsentGiven: true`, `status: ASSIGNED`)
    6. Update `need.assignedTo`, `need.crossNgoTaskId` (reference to crossNgoTasks doc)
    7. Set `isAvailable = false` across **all** of the volunteer's NGO memberships simultaneously (batch write)
- [ ] **Coordinator visibility rules**:
    - [ ] NGO A's coordinator sees the matched volunteer with a **"Partner NGO"** badge
    - [ ] NGO B's coordinator gets a notification banner: "Priya is on a cross-NGO task for NGO A"
    - [ ] NGO B's coordinator sees **only** that specific task (not NGO A's full need list)
- [ ] **Completion & attribution**:
    - [ ] On task `COMPLETED`: NGO A gets impact credit (resolved need count); NGO B gets volunteer-hours credit
    - [ ] Update `crossNgoTasks.status = COMPLETED`; restore `isAvailable = true` in all memberships

### 4E · Partnership Management UI (NGO Admin)
- [ ] **In `ngo_admin_page.dart`** — add Partnership tab:
    - [ ] List current active partners (from `partnerships` collection)
    - [ ] "Send Partnership Invite" → creates `partnerships` doc with `status: PENDING`, `ngoA`, `ngoB`
    - [ ] Incoming pending invites list → "Accept" / "Decline" buttons
    - [ ] Per-partner skill-sharing toggle: which need types (MEDICAL, FOOD, etc.) are shared
- [ ] **`partnerships/` feature** — add use cases:
    - [ ] `SendPartnershipInviteUseCase`
    - [ ] `AcceptPartnershipUseCase` — atomic write: sets `status: ACTIVE`, records `consentDate`
    - [ ] `GetPartnershipsStreamUseCase`

### 4F · Firestore Notification Listener (Volunteer App)
- [ ] **Firestore real-time listener** on volunteer's assigned needs:
    ```dart
    FirebaseFirestore.instance
      .collection('needs')
      .where('assignedTo', isEqualTo: currentUserUid)
      .where('status', isEqualTo: 'ASSIGNED')
      .snapshots()
      .listen((snapshot) {
        // New task assigned → trigger local notification
      });
    ```
- [ ] **`flutter_local_notifications`** displays notification with task title + urgency
- [ ] Tap notification → deep-link to `TaskDetailPage`
- [ ] **App-killed edge case**: On app launch, query for any `ASSIGNED` tasks and surface them immediately in the home screen

### 4G · Community User (CU) Flow
- [ ] **Phone OTP login** — or anonymous session for CU (no NGO membership needed):
    - [ ] CU submits need → goes to `communityReports` collection (NOT `needs` directly)
    - [ ] Gemini triage: extract urgency + location → auto-route to nearest active NGO
    - [ ] Coordinator sees community report in `need_detail_panel.dart` with "Approve" action → moves to `needs` collection
- [ ] **CU tracking screen**:
    - [ ] After submission: show a tracking token / phone OTP link
    - [ ] Real-time status: `PENDING_APPROVAL` → `APPROVED` → `ASSIGNED` → `COMPLETED`
    - [ ] Push notification when need is assigned (FCM token stored at submission)
- [ ] **Service rating**: on COMPLETED, CU gets a 1–5 star rating prompt

---

## 💎 Phase 5: Production Polish, Security Hardening & Deployment
*Goal: Performance optimization, security hardening, and store readiness.*

### 5A · Performance Audit
- [ ] Replace `Opacity` with `FadeTransition` everywhere
- [ ] Implement `const` constructors wherever possible
- [ ] Convert network images to cached via `cached_network_image`
- [ ] Profile with Flutter DevTools: eliminate jank on low-end devices (target: Redmi 9A)

### 5B · Security Hardening
- [ ] **Firestore Security Rules** — lock down all collections:
    - [ ] `needs`: read/write requires `ngoId` to match caller's JWT claim `ngoId`
    - [ ] `volunteers`: write only by owner (`uid == request.auth.uid`)
    - [ ] `partnerships`: write only by NGO Admin of either party
    - [ ] `crossNgoTasks`: write only by matching engine (coordinator-level auth)
    - [ ] `communityReports`: write by any auth user; read only by coordinator/admin
    - [ ] `platformMetrics`: read only by Super Admin (`email` in SA config)
    - [ ] `inviteCodes`: write by NGO Admin; redeem (delete) by authenticated user once
- [ ] Release build with `--obfuscate` and `--split-debug-info`
- [ ] Validate all Gemini responses before writing to Firestore (guard against prompt injection)

### 5C · Deployment
- [ ] **Firebase Hosting**: `flutter build web && firebase deploy --only hosting`
- [ ] **Release APK**: `flutter build apk --release --obfuscate --split-debug-info=build/debug-info`
- [ ] Test on physical low-end Android device (Redmi 9A or equivalent)
- [ ] Seed demo data: 8 needs + 15 volunteers in Lucknow + 2 partner NGOs with active partnership

### 5D · Documentation & Submission
- [ ] Generate final `walkthrough.md` with architecture decisions and screenshots
- [ ] Project demo video: end-to-end flow (CU submit → AI triage → Coordinator claim → Match → Volunteer complete)
- [ ] Submission write-up for Google Solution Challenge 2026
