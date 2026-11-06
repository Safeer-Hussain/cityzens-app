# Cityzens

[![Cityzens CI](https://github.com/Safeer-Hussain/cityzens/actions/workflows/ci.yml/badge.svg)](https://github.com/Safeer-Hussain/cityzens/actions/workflows/ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.47.8-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.13.7-0175C2?logo=dart)](https://dart.dev)
[![Android SDK](https://img.shields.io/badge/Android%20SDK-36-3DDC84?logo=android)](https://developer.android.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20MVVM-4F46E5)](docs/PRD.md)
[![License](https://img.shields.io/badge/License-Proprietary%20Clean--Room-0F172A)](LICENSE)

Production-grade Smart Campus, Digital Library Records, Automated Attendance Tracking, Native Camera Scanner, and AI Academic Ecosystem in Flutter.

---

## Architecture Blueprint

Cityzens follows Feature-First Clean Architecture paired with reactive Model-View-ViewModel (MVVM) state management via Provider, Dependency Injection via GetIt, and local relational persistence via SQLite.

```mermaid
graph TD
    subgraph UI ["Presentation Layer (MVVM)"]
        A[SplashView] --> B[AdaptiveScaffold]
        B --> C[AttendanceView]
        B --> D[LibraryView]
        B --> E[ScannerHubView]
        B --> F[AiAcademicTutorView]
        B --> G[CampusFeedView]
        B --> H[RecruiterDebugDrawer]
    end

    subgraph State ["State Management (Provider)"]
        I[AttendanceProvider]
        J[LibraryProvider]
        K[ScannerProvider]
        L[AiTutorProvider]
        M[CampusFeedProvider]
        N[ThemeProvider]
        O[ConnectivityService]
        P[TelemetryService]
    end

    subgraph Repositories ["Data Layer (Repositories)"]
        Q[AttendanceRepository]
        R[LibraryRepository]
        S[ScannerRepository]
        T[CampusFeedRepository]
    end

    subgraph Core ["Infrastructure & Native Bridges"]
        U[AppDatabase - SQLite]
        V[NativeCameraBridge - MethodChannel]
        W[ApiClient - Dio + MockNetworkInterceptor]
        X[SharedPreferences]
    end

    C --> I
    D --> J
    E --> K
    F --> L
    G --> M
    B --> N
    B --> O

    I --> Q
    J --> R
    K --> S
    L --> Q
    L --> R
    M --> T

    Q --> U
    R --> U
    S --> V
    T --> U
    W --> P
```

---

## Native Optical Camera Bridge Sequence

```mermaid
sequenceDiagram
    autonumber
    participant UI as ScannerHubView (Flutter)
    participant Provider as ScannerProvider
    participant Bridge as NativeCameraBridge
    participant Platform as MainActivity.kt / AppDelegate.swift
    participant DB as SQLite AppDatabase

    UI->>Provider: Tap 'Capture & Verify' (heroTag: fab_camera_capture)
    Provider->>Bridge: scanOpticalPayload(mode: attendance_qr)
    Bridge->>Platform: MethodChannel invokeMethod('scanOpticalPayload')
    Platform->>Platform: Hardware optical capture + SHA256 CRC check
    Platform-->>Bridge: Return Map {code, courseCode, checksum, timestamp}
    Bridge-->>Provider: Parse OpticalPayload
    Provider->>DB: Record attendance entry & update course ledger
    DB-->>Provider: Updated course statistics
    Provider-->>UI: Reactive notifyListeners & AppFeedback.showSuccess
```

---

## Feature Matrix

| Module | Core Capabilities | Persistence / Hardware Driver | Viewport Safety |
| :--- | :--- | :--- | :--- |
| **Attendance Tracker** | Student/Faculty role switch, 6-week trendline chart, at-risk calculator, manual PIN & leave modals | SQLite `courses` and `attendance_ledger` tables | Two-pane master-detail landscape, wrap-safe chips |
| **Digital Library** | 42 seeded CS books, debounced search, category chips, 1-tap renew loan (+14 days), fine computation | SQLite `library_books` and `library_loans` tables | Explicit `mainAxisExtent: 145` preventing RenderFlex collapse |
| **Optical Scanner Hub** | Viewfinder targeting reticles, animated laser line, torch toggle, QR / ISBN / Smart ID modes | `com.safeer.cityzens/native_camera` | Landscape split pane with live hardware telemetry |
| **AI Academic Tutor** | Queries live SQLite attendance & loans, word-by-word streaming animation, 4 research prompt chips | On-device contextual synthesis with guaranteed `try ... finally` cleanup | `resizeToAvoidBottomInset: true` flush keyboard docking |
| **Campus Feed & ID** | Digital ID card (CGPA 3.94 / 4.00), reactive post likes, SQLite comments, publish notices, recruiter hub | SQLite `campus_posts` and `campus_comments` tables | Longitudinal timeline cards and recruiter debug drawer |

---

## Engineering Guidelines & Physical Device Safeguards

1. **Android SDK 36 Compatibility**: `compileSdk = 36` and `targetSdk = 36` with `minSdk = 21` configured in `android/app/build.gradle.kts`.
2. **Impeller Vulkan Crash Protection**: MediaTek and Mali GPU rendering crashes are prevented by explicitly configuring `io.flutter.embedding.android.EnableImpeller = false` in `AndroidManifest.xml`.
3. **Physical Device Boot Hygiene**: `main.dart` initializations run inside `runZonedGuarded` with error interception; all heavy SQLite seeding and image precaching are deferred into `WidgetsBinding.instance.addPostFrameCallback` inside `SplashView`.
4. **Zero Hardcoded Colors**: Colors resolve dynamically through `Theme.of(context).colorScheme`, ensuring complete dark and light mode parity.
5. **Clean Code Hygiene**: Zero tutorial comments, zero placeholders, zero emojis across all code and logs.

---

## Getting Started

### Prerequisites
- Flutter SDK 3.47.8 or higher
- Android SDK 36.0.0
- Java Development Kit (JDK) 17

### Installation & Execution
```bash
# Clone the repository
git clone https://github.com/Safeer-Hussain/cityzens.git
cd cityzens

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Execute automated unit and widget test suite
flutter test --coverage

# Launch application
flutter run
```

---

## Autonomous Sprint Engine

Cityzens includes an autonomous backlog engine in `docs/AUTONOMOUS_BACKLOG.md` comprising 25 daily engineering sprints. To execute the next sprint autonomously:

```bash
# Within an Antigravity agentic session:
"run daily sprint"
```

The system will locate the next unchecked backlog item, engineer the full feature set across layers with SQLite persistence and unit tests, verify static analysis and tests, mark the item as complete, and push to `origin main`.

---

## Clean-Room NDA Disclaimer

This software represents an original, clean-room software architecture developed independently by Safeer Hussain. All database schemas, software algorithms, native optical camera bridges, and UI components were created from first principles without incorporation of proprietary third-party trade secrets or non-disclosure agreements.
