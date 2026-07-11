# AKPA - Medical/NEET-PG Flashcard Application

## 📌 Project Overview
AKPA is a high-performance, offline-first medical flashcard application designed specifically for NEET-PG preparation. The core architectural mandate is extreme performance: sub-500ms cold startup times, single-digit millisecond query execution, and a buttery-smooth 60/120fps UI even when handling a massive dataset of over 78,000 flashcards.

## 🛠 Tech Stack
* **Framework:** Flutter (Dart)
* **Local Database:** Isar (v3.1.0) - Chosen for its high performance, flat relational structure, and sub-millisecond query capabilities.
* **State Management:** Riverpod (`flutter_riverpod`) - Used for dependency injection, reactive state, and managing complex spaced-repetition logic asynchronously.
* **Backend/Sync:** Firebase (Auth, Firestore) - Stubbed for future cloud synchronization, but the app is explicitly designed to be offline-first.

## 🏗 Architecture & Core Implementations

### 1. High-Performance Data Layer (Isar)
To achieve the sub-500ms startup constraint, the traditional approach of parsing JSON at runtime was discarded.
* **Pre-built Binary:** The app ships with a pre-built Isar binary (`assets/default.isar`).
* **Initialization Service:** `DatabaseInitService` securely copies this binary to the app's document directory on first launch, entirely bypassing the parsing overhead of 77MB+ of JSON data.
* **Canonical Schema:** 
  * `Subject`: Represents high-level medical subjects (e.g., Anatomy, Pathology).
  * `Topic`: Sub-categories within subjects, establishing a hierarchy.
  * `Flashcard`: The core entity containing Q&A, explanations, and spaced-repetition metadata.
* **Query Performance:** Data retrieval is heavily optimized using indexed fields in Isar, ensuring UI threads are never blocked.

### 2. State Management (Riverpod)
* **Providers Directory:** Located in `lib/core/providers`.
* **`IsarProviders`:** Exposes reactive streams and futures for database queries (e.g., fetching subjects, topics, and cards).
* **`SyllabusStateProvider`:** Manages the complex state of user progress, tracking which topics have been mastered, reviewed, or are pending.

### 3. Features & UI (Presentation Layer)
The UI is built with a modern, dynamic, and premium aesthetic, focusing on smooth micro-animations and an intuitive user experience.

#### Dashboard (`lib/features/dashboard`)
* **Command Center (`command_center_screen.dart`):** The main hub displaying daily goals, recent activity, and quick access to study sessions.
* **Syllabus Screen (`syllabus_screen.dart`):** A hierarchical view allowing users to navigate through Subjects and Topics.
* **Topic Cards Screen (`topic_cards_screen.dart`):** Displays the status of individual topics (e.g., new, learning, to review).

#### Study Session (`lib/features/study_session`)
* **Exam Setup (`exam_setup_screen.dart`):** Configuration screen for customizing a study/exam session (e.g., number of cards, specific topics).
* **Exam Session (`exam_session_screen.dart`):** The core flashcard interface. It uses a high-performance swipeable card UI powered by `flutter_card_swiper` and maps Isar models to a UI-friendly `CardViewModel`.
* **Session Complete (`session_complete_screen.dart`) & Exam Results (`exam_results_screen.dart`):** Post-session analytics, displaying accuracy, time spent, and mastery progress.
* **Topic Review (`topic_review_screen.dart`):** A dedicated interface for reviewing previously studied topics based on spaced-repetition algorithms.
* **Topic Box Move (`topic_box_move_screen.dart`):** Visual representation of spaced-repetition boxes (e.g., moving a card from Box 1 to Box 2 upon correct recall).

## 🚀 Current Status

### ✅ Completed Milestones
1. **Database Foundation:** Isar schema defined, codegen completed, and pre-built binary loading implemented successfully.
2. **State Management Skeleton:** Riverpod providers are wired up to the Isar database.
3. **Core UI/UX:** The primary user flows (Dashboard -> Subject Selection -> Topic Selection -> Study Session -> Results) are fully built with premium aesthetics (glassmorphism, modern typography, dynamic gradients).
4. **Flashcard Engine:** The swipeable card interface is functional, mapping complex Isar data to the UI seamlessly.

### 🚧 Work In Progress / Next Steps
1. **Spaced-Repetition Algorithm (FSRS/SuperMemo):** While the UI for moving cards between boxes exists, the heavy background computation (offloaded to an isolate) needs to be finalized to schedule the next review dates accurately.
2. **Firebase Integration:** Hooking up the existing Firebase dependencies to enable cross-device synchronization and user authentication (currently mocked/stubbed).
3. **Analytics Integration:** Populating the Command Center's heatmaps and charts (`fl_chart`, `flutter_heatmap_calendar`) with real user study data.
4. **Performance Profiling:** Running the app on physical devices to ensure the 60/120fps mandate is met during intensive rapid-swiping sessions.

## 📂 Directory Structure Highlights
```text
lib/
├── core/
│   ├── models/           # Isar schemas and ViewModels
│   ├── providers/        # Riverpod state managers
│   ├── services/         # DatabaseInitService, SyncService
│   ├── theme/            # App-wide color palettes, text styles
│   └── utils/            # Helpers, extensions
├── features/
│   ├── auth/             # Login/Signup UI
│   ├── dashboard/        # Command Center, Syllabus
│   └── study_session/    # Flashcard UI, Exam Setup, Results
└── main.dart             # App entry point
```
