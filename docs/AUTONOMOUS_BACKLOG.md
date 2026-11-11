# Autonomous Daily Engineering Sprints: Cityzens Campus Ecosystem

This backlog defines 25 granular, production-ready engineering sprints. Prompting `"run daily sprint"` instructs the autonomous agent to select the next unchecked `[ ]` sprint, implement the complete feature set end-to-end with SQLite persistence, state management, and unit/widget tests, verify `flutter analyze` and `flutter test`, mark `[x]`, commit with conventional commit format, and push to `origin main`.

---

- [x] **Sprint 01: Semester GPA/CGPA What-If Projection Calculator**
  - Interactive credit hours and target grade slider simulation.
  - Recalculates projected graduation honors and stores historical grade transcripts in SQLite.
  - Comprehensive unit tests verifying GPA calculation formulas.

- [x] **Sprint 02: Exam Hall Seat Finder & Digital Admission Slip**
  - Optical examination hall pass generator with cryptographic checksum.
  - Visual seat assignment matrix for Turing Hall and Hopper Auditorium.
  - Offline timetable reminder notification triggers.

- [x] **Sprint 03: Library Citation BibTeX & APA 7th Edition Generator**
  - 1-tap citation exporter for all 42 catalog books in BibTeX, APA, IEEE, and Chicago styles.
  - Direct clipboard copy and Markdown file export options.
  - Unit tests verifying citation formatting compliance.

- [x] **Sprint 04: Peer Study Room Booking Engine**
  - Real-time room availability matrix across Campus Floors 1 through 4.
  - Slot reservation workflow with automated collision detection and attendee invitation badges.
  - SQLite persistence for study group bookings.

- [ ] **Sprint 05: Offline Flashcard Deck Builder with SuperMemo-2 (SM-2)**
  - Spaced repetition algorithm computing optimal repetition intervals and ease factors.
  - Category decks for Algorithms, Distributed Systems, and Mobile Architecture.
  - Full-width analytics chart displaying card retention performance.

- [ ] **Sprint 06: Campus Cafeteria Smart Meal Credits & Pre-Order Hub**
  - Menu catalog with macronutrient data and campus dining hall operational hours.
  - Digital wallet debit balance ledger in SQLite with simulated NFC tap receipt.
  - Form validation for dietary allergy flags.

- [ ] **Sprint 07: Student Parking Permit & EV Charging Radar**
  - Live occupancy gauge for North and South student parking structures.
  - EV charger status monitoring and queue reservation slot tokens.
  - Native camera license plate scanner OCR mode bridge.

- [ ] **Sprint 08: Academic Timetable Conflict Resolver**
  - Automated detection of overlapping course schedules and laboratory blocks.
  - Smart heuristic suggestions for alternative lecture sections.
  - Interactive weekly schedule grid supporting landscape master-detail view.

- [ ] **Sprint 09: Research Paper PDF Reader & Local Annotation Sync**
  - Clean embedded document viewer for course syllabus and lecture notes.
  - Highlight and sticky note annotations stored in relational SQLite tables.
  - Export annotated reading notes directly to AI Academic Tutor.

- [ ] **Sprint 10: Faculty Office Hours Appointment Scheduler**
  - Faculty availability calendar with 15-minute consultation slots.
  - Agenda description form with academic topic tagging.
  - Cancellation and rescheduling audit trail in SQLite.

- [ ] **Sprint 11: Campus Emergency SOS Beacon & Security Dispatch**
  - One-touch emergency trigger alerting campus security dispatchers.
  - Simulated offline mesh packet generation with room-level beacon coordinates.
  - Safety checklist and emergency exit route diagrams.

- [ ] **Sprint 12: Lost & Found Optical Matcher with Item Ledger**
  - Public lost item reporting form with photo upload and location tagging.
  - Optical matching algorithm pairing recovered items with claimed belongings.
  - Automated clearance badge upon verified ownership return.

- [ ] **Sprint 13: Degree Audit & Graduation Requirements Checklist**
  - Progress tracker for general education, major core, and elective credit completion.
  - Prerequisite dependency tree visualization.
  - Dean degree petition submission modal.

- [ ] **Sprint 14: Laboratory Equipment Checkout & Calibration Logs**
  - Inventory tracking for oscilloscopes, FPGA boards, robotics kits, and GPUs.
  - Calibration maintenance logs and overdue equipment fine integration.
  - Barcode scanning mode for rapid physical hardware checkout.

- [ ] **Sprint 15: Student Club Marketplace & Campus Event Ticketing**
  - Discover student engineering societies, ACM chapters, and robotics clubs.
  - Event registration with QR admission ticket issuance.
  - Ticket validation scanner mode for club officers.

- [ ] **Sprint 16: Campus Shuttle Live GPS Tracker & ETA Forecaster**
  - Route maps with scheduled stops across north, central, and satellite campuses.
  - Moving transit simulation with arrival countdown badges.
  - Offline route timetable cache.

- [ ] **Sprint 17: Internship & Research Assistantship Job Board**
  - On-campus research openings and corporate partner internship listings.
  - Resume builder and one-tap application submission using student profile credentials.
  - Application status tracking pipeline (Applied, Under Review, Interview, Accepted).

- [ ] **Sprint 18: Campus Gym Occupancy Gauge & Workout Logger**
  - Real-time fitness center crowd meter and equipment availability breakdown.
  - Personal workout session logger with personal record tracking.
  - Health and fitness telemetry card in student profile.

- [ ] **Sprint 19: Digital Wallet & Student ID NFC Tap-to-Pay Emulation**
  - Simulated Host Card Emulation (HCE) NFC payment token generation.
  - Transaction history for printing, laundry, cafeteria, and bookstore purchases.
  - Biometric PIN authentication before payment authorization.

- [ ] **Sprint 20: Anonymous Faculty Course Evaluation & Quality Feedback**
  - End-of-semester course feedback surveys with rating matrices.
  - Sentiment analysis preview rendered via local heuristics.
  - Cryptographically blinded submissions ensuring complete student anonymity.

- [ ] **Sprint 21: Mental Health & Wellness Check-in Diary**
  - Daily cognitive wellbeing check-in with sentiment tag selections.
  - Longitudinal mood trendline chart comparing exam stress vs. rest periods.
  - Direct 1-tap confidential counseling appointment shortcut.

- [ ] **Sprint 22: Alumni Mentorship Network & Direct Career Bridge**
  - Directory of verified university alumni working in top tech organizations.
  - 1-on-1 mentorship session request modal with career focus filters.
  - SQLite message history between mentors and students.

- [ ] **Sprint 23: Campus Wi-Fi Signal Heatmap & Network Diagnostic**
  - Building-by-building Wi-Fi performance benchmark telemetry.
  - Local ping, latency jitter, and packet loss diagnostic tester.
  - Offline report dispatch when reconnecting to network.

- [ ] **Sprint 24: Hackathon Team Builder & Project Pitch Deck Hub**
  - Annual campus hackathon registration and skill-based team matchmaking.
  - Project repository URL submission and live demo slide preview.
  - Peer voting and judge evaluation scorecard.

- [ ] **Sprint 25: Senior Thesis Archival Repository & Plagiarism Guard**
  - Final capstone project submission with PDF metadata indexing.
  - Local n-gram similarity checker against seeded database papers.
  - Permanent digital object identifier (DOI) issuance slip.
