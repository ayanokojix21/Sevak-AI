# SevakAI MVP — Final Implementation Plan

**100% Free. No Credit Card. No Hallucinations.**

Every claim below has been verified against April 2026 documentation. Services marked ❌ have been replaced with free alternatives.

---

## 1. Verified Service Matrix

| Service | Free Tier Limits | Credit Card? | Role in SevakAI |
|:---|:---|:---|:---|
| **Firebase Auth** (Spark) | 50,000 MAU | ❌ No | Email/Password login |
| **Cloud Firestore** (Spark) | 1 GB, 50K reads/day, 20K writes/day | ❌ No | All structured data |
| **Firebase Cloud Messaging** | Unlimited, always free on any plan | ❌ No | Push notifications |
| **Firebase Hosting** (Spark) | 1 GB storage, 10 GB transfer/month | ❌ No | Coordinator web dashboard |
| **Gemini 1.5 Flash** (AI Studio) | ~15 RPM, Flash models only | ❌ No | OCR, scoring, matching |
| **Cloudinary** (Free) | 25 credits/month (~25 GB bandwidth) | ❌ No | Image uploads |
| **OpenStreetMap** (flutter_map) | Unlimited tiles (respect fair use) | ❌ No | Map display |
| **Nominatim** (OSM Geocoding) | Free, max 1 req/sec, custom User-Agent | ❌ No | Text → lat/lng |
| **Geolocator** (Flutter) | Device GPS, no API needed | ❌ No | Volunteer location |

### Services Removed (Require Credit Card)
| ~~Service~~ | Replacement |
|:---|:---|
| ~~Firebase Storage~~ | **Cloudinary** (unsigned upload) |
| ~~Cloud Functions~~ | **Client-side Dart logic** |
| ~~Cloud Run~~ | **Client-side Gemini matching** |
| ~~Google Maps SDK~~ | **flutter_map + OpenStreetMap** |
| ~~Google Geocoding API~~ | **Nominatim** (free) |

---

## 2. Architecture

```
┌──────────────────────────────────┐
│     VOLUNTEER APP (Android)      │
│                                  │
│  • Login (Email/Password)        │
│  • Submit Need (photo + text)    │
│  • View My Tasks                 │
│  • Accept / Decline / Complete   │
│  • Background Location (15 min)  │
│                                  │
│  Pipeline on submit:             │
│  1. Compress image (< 150KB)     │
│  2. Upload → Cloudinary → URL    │
│  3. Send text+image → Gemini     │
│  4. Parse JSON response          │
│  5. Geocode location → Nominatim │
│  6. Save to Firestore (SCORED)   │
└─────────────┬────────────────────┘
              │
              │ Firestore real-time sync
              ▼
┌──────────────────────────────────┐
│  COORDINATOR DASHBOARD (Web)     │
│  Hosted on Firebase Hosting      │
│                                  │
│  • Real-time map (OSM pins)      │
│  • Color-coded by urgency        │
│  • Need detail panel             │
│  • Stat cards                    │
│  • "Match Volunteer" button:     │
│    1. Fetch available volunteers │
│    2. Calculate distances        │
│    3. Send to Gemini → best match│
│    4. Update Firestore (ASSIGNED)│
│    5. Volunteer app detects      │
│       change → local notification│
└──────────────────────────────────┘
```

---

## 3. Firestore Data Schema

### `needs` collection
| Field | Type | Source | Description |
|:---|:---|:---|:---|
| `rawText` | string | Volunteer input | Original text description |
| `imageUrl` | string? | Cloudinary | URL of uploaded photo |
| `location` | string | Gemini | Extracted address text |
| `lat` | number | Nominatim | Geocoded latitude |
| `lng` | number | Nominatim | Geocoded longitude |
| `needType` | string | Gemini | `FOOD` / `MEDICAL` / `SHELTER` / `CLOTHING` / `OTHER` |
| `urgencyScore` | int | Gemini | 0–100 |
| `urgencyReason` | string | Gemini | Human-readable explanation |
| `peopleAffected` | int | Gemini | Estimated count |
| `status` | string | System | `RAW` → `SCORED` → `ASSIGNED` → `IN_PROGRESS` → `COMPLETED` |
| `submittedBy` | string | Firebase Auth | Volunteer UID |
| `assignedTo` | string? | Matching | Matched volunteer UID |
| `matchReason` | string? | Gemini | Why this volunteer was chosen |
| `ngoId` | string | System | NGO identifier |
| `createdAt` | timestamp | Firestore | Auto server timestamp |

### `volunteers` collection
| Field | Type | Source | Description |
|:---|:---|:---|:---|
| `uid` | string | Firebase Auth | User ID |
| `name` | string | Registration | Full name |
| `email` | string | Firebase Auth | Login email |
| `phone` | string | Registration | Contact number |
| `skills` | List\<string\> | Registration | e.g. `["medical", "driving"]` |
| `lat` | number | Geolocator | Last known latitude |
| `lng` | number | Geolocator | Last known longitude |
| `locationUpdatedAt` | timestamp | WorkManager | When location was last refreshed |
| `isAvailable` | bool | Toggle in app | Can receive new tasks |
| `fcmToken` | string | FCM SDK | For push notifications |
| `activeTasks` | int | System | Currently assigned tasks count |
| `primaryNgoId` | string | Registration | Primary NGO for tasks |
| `ngoMemberships` | List\<Map\> | System | Array of `{ ngoId, role, joinedAt, crossNgoConsent, status }` |

### `ngos` collection
| Field | Type | Description |
|:---|:---|:---|
| `id` | string | Document ID |
| `name` | string | Organization name |
| `coordinatorUid` | string | Firebase Auth UID |
| `city` | string | Operating city |

### New Multi-NGO Collections
| Collection | Description | Key Fields |
|:---|:---|:---|
| `partnerships` | NGO-to-NGO agreements | `ngoA`, `ngoB`, `status` (PENDING/ACTIVE), `sharedSkills`, `consentDate` |
| `crossNgoTasks` | Escalated tasks between NGOs | `needId`, `sourceNgoId`, `volunteerNgoId`, `volunteerConsentGiven`, `status` |
| `communityReports`| Needs from unauthenticated users | `rawText`, `imageUrl`, `lat`, `lng`, `status` (PENDING_APPROVAL) |
| `ngoInvites` | Invite codes for NGOs | `code`, `ngoId`, `role` (VOLUNTEER/COORDINATOR), `expiresAt` |
| `platformMetrics` | System-wide aggregates | `totalNeeds`, `resolvedNeeds`, `activeVolunteers` (Super Admin only) |

---

## 4. Folder Structure (Feature-First Clean Architecture)

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, GoRouter, Theme
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # Collection names, API base URLs
│   ├── config/
│   │   └── env_config.dart           # API keys loaded via --dart-define
│   ├── theme/
│   │   └── app_theme.dart            # Colors, typography, urgency palette
│   ├── errors/
│   │   ├── failures.dart             # Abstract Failure class
│   │   └── exceptions.dart           # NetworkException, AIException, etc.
│   ├── network/
│   │   └── api_client.dart           # Shared HTTP client with retry logic
│   └── utils/
│       ├── image_compressor.dart      # Compress to < 150KB
│       ├── distance_calculator.dart   # Haversine formula
│       └── validators.dart            # Form validation
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/user_entity.dart
│   │   │   └── repositories/auth_repository.dart      # Interface
│   │   └── presentation/
│   │       ├── controllers/auth_controller.dart
│   │       └── pages/login_page.dart
│   │
│   ├── needs/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── gemini_datasource.dart              # Gemini API calls
│   │   │   │   ├── cloudinary_datasource.dart           # Image upload
│   │   │   │   ├── nominatim_datasource.dart            # Geocoding
│   │   │   │   └── needs_firestore_datasource.dart      # Firestore CRUD
│   │   │   ├── models/need_model.dart                   # toJson / fromJson
│   │   │   └── repositories/need_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/need_entity.dart
│   │   │   ├── repositories/need_repository.dart        # Interface
│   │   │   └── usecases/
│   │   │       ├── submit_need_usecase.dart              # Full pipeline
│   │   │       └── get_needs_stream_usecase.dart
│   │   └── presentation/
│   │       ├── controllers/need_controller.dart
│   │       ├── pages/
│   │       │   ├── submit_need_page.dart
│   │       │   └── ai_processing_page.dart
│   │       └── widgets/
│   │           └── urgency_badge.dart
│   │
│   ├── matching/
│   │   ├── data/
│   │   │   ├── datasources/matching_gemini_datasource.dart
│   │   │   └── repositories/matching_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── repositories/matching_repository.dart    # Interface
│   │   │   └── usecases/match_volunteer_usecase.dart
│   │   └── presentation/
│   │       └── controllers/matching_controller.dart
│   │
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── pages/dashboard_page.dart
│   │       └── widgets/
│   │           ├── needs_map.dart                       # flutter_map
│   │           ├── need_detail_panel.dart
│   │           ├── stat_cards.dart
│   │           └── task_list_table.dart
│   │
│   ├── tasks/
│   │   ├── data/
│   │   │   └── repositories/task_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/task_entity.dart
│   │   │   └── repositories/task_repository.dart        # Interface
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── my_tasks_page.dart
│   │       │   └── task_detail_page.dart
│   │       └── widgets/task_card.dart
│   │
│   └── location/
│       ├── data/
│       │   └── location_service_impl.dart               # Geolocator + WorkManager
│       ├── domain/
│       │   └── location_service.dart                    # Interface
│       └── presentation/
│           └── controllers/location_controller.dart
│
└── providers/
    └── providers.dart                                   # All Riverpod providers
```

---

## 5. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # --- Firebase (Free on Spark) ---
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0
  firebase_messaging: ^16.2.0

  # --- AI (Free via Google AI Studio) ---
  google_generative_ai: ^0.4.7

  # --- Maps (Free, no API key) ---
  flutter_map: ^6.1.0
  latlong2: ^0.9.1

  # --- Image Pipeline ---
  image_picker: ^1.2.1
  flutter_image_compress: ^2.3.0
  cloudinary_public: ^0.23.1

  # --- Geocoding & Location ---
  http: ^1.2.0                     # For Nominatim API
  geolocator: ^13.0.0              # Device GPS
  permission_handler: ^11.3.0      # Location permissions
  workmanager: ^0.5.2              # Background location updates

  # --- State & Navigation ---
  flutter_riverpod: ^3.3.1
  go_router: ^14.0.0

  # --- Utilities ---
  intl: ^0.19.0                    # Date formatting
  connectivity_plus: ^6.1.0        # Network status detection
  flutter_local_notifications: ^18.0.0  # Local notification display
```

---

## 6. Step-by-Step Build Order

### Step 1: Account Setup (You Do This)

| # | Action | Where |
|:--|:---|:---|
| 1a | Create Firebase Project (stay on **Spark Plan**) | [console.firebase.google.com](https://console.firebase.google.com) |
| 1b | Enable **Email/Password** sign-in | Firebase → Authentication → Sign-in method |
| 1c | Enable **Cloud Firestore** in test mode | Firebase → Firestore Database → Create database |
| 1d | Create **Cloudinary** account | [cloudinary.com/users/register_free](https://cloudinary.com/users/register_free) |
| 1e | Create **Unsigned Upload Preset** in Cloudinary | Cloudinary → Settings → Upload → Add preset → Signing Mode: **Unsigned** |
| 1f | Get **Gemini API Key** | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) |

**Give me these 3 values to proceed:**
1. Gemini API Key
2. Cloudinary Cloud Name
3. Cloudinary Upload Preset Name

*(Keys will be stored via `--dart-define`, never hardcoded in source.)*

---

### Step 2: Initialize Project
- `flutter create sevak_app`
- Add all dependencies
- Create full folder structure
- Run `flutterfire configure` to link Firebase
- Enable web support: `flutter config --enable-web`

---

### Step 3: Core Layer
- **`env_config.dart`** — Load API keys from `--dart-define` (secure, never in Git)
- **`app_theme.dart`** — Premium dark theme; urgency palette:
  - Red (#FF4444) = Critical (80–100)
  - Amber (#FFB300) = Urgent (50–79)
  - Green (#4CAF50) = Moderate (0–49)
- **`image_compressor.dart`** — Uses `flutter_image_compress`:
  - Resize to max 1080px width
  - Iteratively reduce JPEG quality until < 150KB
  - Runs in `Isolate` to avoid UI jank
- **`distance_calculator.dart`** — Haversine formula using `Geolocator.distanceBetween()`
- **`api_client.dart`** — HTTP client with:
  - Custom `User-Agent: SevakAI/1.0` (required by Nominatim)
  - 1-second delay between geocoding requests (Nominatim policy)
  - Exponential backoff for Gemini 429 errors (rate limit)

---

### Step 4: Auth Feature
- Abstract `AuthRepository` interface (OOP: Dependency Inversion)
- `AuthRepositoryImpl` using `firebase_auth`
- `LoginPage`:
  - Email + Password fields with validation
  - Role selector: **Volunteer** or **Coordinator**
  - On login: route to volunteer app or coordinator dashboard
  - On first login as Volunteer: prompt for name, phone, skills (saved to `volunteers` collection)

---

### Step 5: Location Feature (Background Tracking)
- **On App Open**: Request `ACCESS_FINE_LOCATION` permission
- **On "Availability Toggle"**: Request `ACCESS_BACKGROUND_LOCATION` (separate prompt on Android 10+)
- **WorkManager Registration**:
  ```dart
  Workmanager().registerPeriodicTask(
    "location_update",
    "updateVolunteerLocation",
    frequency: Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
  ```
- **Callback**: Get GPS → update `volunteers/{uid}.lat`, `.lng`, `.locationUpdatedAt` in Firestore
- **Edge Cases**:
  - GPS disabled → Show "Enable GPS" dialog
  - Permission denied → Gracefully degrade; use last-known location
  - OEM battery kill (Xiaomi/Samsung) → Show in-app guide linking to [dontkillmyapp.com](https://dontkillmyapp.com)
  - Location accuracy: Use `LocationAccuracy.medium` to save battery on low-end devices

---

### Step 6: Needs Feature (AI Pipeline)
This is the **core loop**. The `SubmitNeedUseCase` orchestrates these steps:

1. **Compress Image** → `image_compressor.dart` → Target < 150KB
2. **Upload to Cloudinary** → `cloudinary_datasource.dart` → Returns `secureUrl`
3. **Call Gemini** → `gemini_datasource.dart`:
   - Send text + image bytes to Gemini 1.5 Flash
   - Prompt extracts: category, urgency, location text, people affected
   - Parse JSON response; validate all fields present
4. **Geocode Location** → `nominatim_datasource.dart`:
   - Send extracted location text to Nominatim
   - Get `lat` and `lng` back
   - Cache result locally to avoid repeat requests
5. **Save to Firestore** → `needs_firestore_datasource.dart`:
   - Write all fields; `status = 'SCORED'`

**Edge Cases Handled**:
| Scenario | Handling |
|:---|:---|
| No internet | Firestore queues write offline; show "Saved locally, will sync" |
| Gemini returns invalid JSON | Retry once; if fails, save with `status = 'RAW'` for coordinator to review manually |
| Gemini rate limit (429) | Exponential backoff: wait 2s → 4s → 8s → show "AI busy, try again in 30s" |
| Nominatim returns no results | Use volunteer's own GPS coordinates as fallback |
| Cloudinary upload fails | Save need without image; show "Photo upload failed, need saved without image" |
| Photo is very large (> 10MB) | Compression handles it; still uploads a < 150KB version |
| Hindi/Urdu text in photo | Gemini 1.5 Flash handles multilingual OCR natively |

---

### Step 7: Single & Cross-NGO Matching Engine
Triggered by the **Coordinator** clicking "Find Best Volunteer".

1. **Single-NGO Matching (Base)**:
   - Query Firestore for volunteers in the current NGO where `isAvailable == true`
   - Calculate Haversine distance, filter to 25 km radius
   - Send payload to Gemini (Prompt 2). If matched, assign task.
2. **Cross-NGO Matching (Escalation)**:
   - If no match found, query `partnerships` for active partner NGOs opted into this need type (e.g., MEDICAL).
   - Fetch available volunteers from partners with `crossNgoConsent == true`.
   - Send combined pool to Gemini with `crossNgo=true` flag.
   - If matched, save to `crossNgoTasks` collection and update `need` document.
   - **Important**: Set `isAvailable = false` across *all* of the volunteer's NGO memberships simultaneously.

---

### Step 8: Volunteer Task Flow & Notification
1. **My Tasks Screen**: Real-time list of assigned tasks using Firestore listener.
2. **Task Details Screen**: Accept/Decline buttons, Open in Google Maps, Mark Complete. Shows "via [Partner NGO]" if it's a cross-NGO task.
3. **Notification System**: 
   - Firestore listener on `needs` (where `assignedTo == currentUserUid` and `status == ASSIGNED`).
   - Triggers `flutter_local_notifications` pop-up.
   - On app launch, query for pending tasks directly to catch missed notifications.

---

### Step 9: Partnership Management UI
- **NGO Admin Panel**:
  - View list of active partnerships.
  - "Send Partnership Invite" flow (creates `partnerships` doc with `status: PENDING`).
  - View incoming invites → Accept/Decline.
  - Per-partner skill-sharing toggles (which need types are shared).

---

### Step 10: Community User (CU) Flow
- **Submission**: Phone OTP login or anonymous session. Submission writes to `communityReports` collection.
- **Routing**: Gemini triage extracts location + urgency, routes to nearest active NGO. Coordinator must "Approve" to move it to the `needs` collection.
- **Tracking**: CU receives tracking token/OTP link to view real-time status. Can rate the service 1-5 stars upon completion.

---

## 7. Gemini Prompts

### Prompt 1: Need Extraction (from photo/text)
```
You are SevakAI, an AI for NGO volunteer coordination in India.
Analyze the following community need report and extract structured data.

Input text: {rawText}
(An image may also be attached showing a handwritten form)

Return ONLY valid JSON with NO markdown formatting:
{
  "location": "extracted address or landmark",
  "needType": "FOOD | MEDICAL | SHELTER | CLOTHING | OTHER",
  "urgencyScore": <number 0-100>,
  "urgencyReason": "one sentence why this score",
  "peopleAffected": <number>,
  "description": "brief 2-sentence summary"
}

Scoring rules:
- 80-100: Life-threatening (medical emergency, no food for children)
- 50-79: Urgent but not life-threatening (shelter needed, clothing shortage)
- 0-49: Important but can wait 24+ hours

If a field cannot be determined, use "UNKNOWN" for strings or 0 for numbers.
If the image contains Hindi or Urdu text, transliterate to English.
```

### Prompt 2: Volunteer Matching (Single-NGO)
```
You are SevakAI's volunteer matching engine.

COMMUNITY NEED:
- Type: {needType}
- Location coordinates: ({lat}, {lng})
- Urgency score: {urgencyScore}/100
- Description: {description}
- People affected: {peopleAffected}

AVAILABLE VOLUNTEERS (with pre-calculated distances):
{JSON array of volunteers with uid, name, skills, distanceKm, activeTasks}

Select the single BEST volunteer for this need. Return ONLY valid JSON:
{
  "matchedVolunteerUid": "<uid>",
  "reason": "<one human-readable sentence>",
  "estimatedDistanceKm": <number>
}

Priority order:
1. Skills matching the need type (e.g., medical skill for MEDICAL need)
2. Closest distance
3. Fewest active tasks (least loaded volunteer)
```

### Prompt 3: Volunteer Matching (Cross-NGO)
```
You are SevakAI's cross-NGO volunteer matching engine. 

COMMUNITY NEED:
- Type: {needType}
- Location coordinates: ({lat}, {lng})
- Urgency score: {urgencyScore}/100

AVAILABLE VOLUNTEERS FROM MULTIPLE NGOS (with pre-calculated distances):
{JSON array of volunteers with uid, name, skills, distanceKm, activeTasks, ngoName}

Select the single BEST volunteer. Priority goes to skill match, then closest distance.

Return ONLY valid JSON:
{
  "matchedVolunteerUid": "<uid>",
  "reason": "<one human-readable sentence explaining the choice and mentioning their source NGO>",
  "estimatedDistanceKm": <number>
}
```

---

## 8. Security

| Concern | Solution |
|:---|:---|
| API keys in source code | Use `--dart-define` at build time; never commit keys to Git |
| Firestore rules — own data | All `needs` / `volunteers` reads require `ngoId` to match caller's JWT claim |
| Firestore rules — cross-NGO | `crossNgoTasks` writable only by coordinator-level auth; readable by both `sourceNgoId` and `volunteerNgoId` |
| Firestore rules — CU reports | `communityReports` writable by any authenticated user; readable only by coordinator/admin |
| Firestore rules — invites | `ngoInvites` writable by NGO Admin; redeemable (delete) once by authenticated user |
| Firestore rules — metrics | `platformMetrics` readable only by email in Super Admin config |
| Cloudinary abuse | Unsigned preset restricted to images only, max 10MB, specific folder |
| Nominatim abuse | 1 req/sec rate limit enforced in code; results cached |
| Gemini prompt injection | Input text is sanitized; prompt includes "Return ONLY valid JSON" instruction |
| Cross-NGO data privacy | NGO B coordinator sees only the specific task their volunteer is on — not NGO A's full need list |

---

## 9. Verification Plan

| # | Test | Expected Result |
|:--|:---|:---|
| 1 | Register a new volunteer | Account in Firebase Auth + profile in `volunteers` collection |
| 2 | Toggle availability ON | GPS saved; WorkManager periodic task registered |
| 3 | Submit photo of handwritten form | Cloudinary < 150KB; Firestore shows all Gemini-extracted fields |
| 4 | Submit with no internet | "Saved locally" toast; syncs automatically when back online |
| 5 | Submit 16 needs in 1 minute | 15 succeed; 16th shows rate-limit message |
| 6 | Open coordinator dashboard | Map shows urgency-colored pins; stat cards reflect live data |
| 7 | Click "Match Volunteer" — volunteers available | Gemini picks best; need updated to `ASSIGNED` |
| 8 | Click "Match Volunteer" — no volunteers in own NGO | Cross-NGO escalation triggers; partner volunteer selected with "Partner" badge |
| 9 | Check volunteer app after assignment | Local notification shown; task detail page opens with cross-NGO label if applicable |
| 10 | Volunteer marks "Complete" | Need → `COMPLETED`; both NGO A (impact) and NGO B (volunteer-hours) analytics updated |
| 11 | NGO Admin sends partnership invite | `partnerships` doc created with `status: PENDING`; partner NGO sees incoming invite |
| 12 | NGO Admin accepts partnership | `partnerships.status` → `ACTIVE`; cross-NGO escalation now possible between these two NGOs |
| 13 | Community User submits need | Saved to `communityReports`; coordinator sees it with "Approve" button |
| 14 | Coordinator approves CU report | Moved to `needs` collection; enters normal matching flow |
| 15 | Super Admin approves NGO | `ngos.status` → `active`; NGO creator promoted to NGO Admin |
| 16 | Test on Redmi 9A | App loads < 3 seconds; no jank during AI processing |

---

## 10. Resolved Decisions

> [!NOTE]
> **1. Auth Method** ✅ **Email/Password + Google Sign-In** — implemented in Phase 1. No Phone OTP (avoids Blaze plan quota).

> [!NOTE]
> **2. Dashboard Platform** ✅ **Flutter Web** hosted on Firebase Hosting — same codebase, `flutter build web`. Coordinator dashboard accessible from laptop/desktop.

> [!NOTE]
> **3. Notification Strategy** ✅ **Firestore real-time listener** → `flutter_local_notifications`. Works in foreground and background. On app kill, tasks surface immediately on next app launch. Acceptable for demo.
