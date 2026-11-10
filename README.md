# UniNotes AI - Scholastic AI Study App (Flutter)

A modern, pixel-perfect Flutter frontend prototype for **UniNotes AI**, built according to the **"Academic Precision"** design system and the provided UI mockups.

---

## 🎨 Color Palette & Design System

The app implements Material 3 with the exact color scheme extracted from the designs:

| Color Role | Hex Code | Purpose |
| :--- | :--- | :--- |
| **Soft Creamy White** | `#FAFAEF` | Paper-adjacent base canvas reducing ocular fatigue |
| **Royal Blue** | `#004AAD` | Institutional authority, primary actions, active tabs, highlights |
| **Light Blue** | `#AFD2FA` | Secondary containers, passive filters, interactive chips |
| **Warm Gold** | `#B9915E` | Machine intelligence, Gemini badges, audio waveforms, AI summaries |
| **Deep Slate** | `#1E293B` | Maximum legibility for body text, notes, and transcripts |
| **Slate Grey** | `#64748B` | Timestamps, secondary metadata, inactive icons |
| **Border / Outline** | `#E6E8E2` | Hairline dividers and subtle container borders |

---

## 📱 The 5 Core Screens

### 1. Home / Semesters Dashboard (`home_semesters_screen.dart`)

- **Header**: UniNotes AI brand mark, "✨ Gemini" badge, notification bell, user profile avatar.
- **Greeting**: "Welcome back, Alex! 👋" with academic subhead (*Spring 2025 • Computer Science B.S.*) and student portrait.
- **Global Search**: Search bar for PDFs, subjects, and AI lectures with filter settings.
- **Scholastic Quick Stats**: 8 Active Subjects, 42 AI Lectures, 128 PDFs Saved.
- **Timeline Progression**:
  - **Semester 3 (In Progress)**: Ambient radial glow, syllabus completion progress (68%), subject pills, and *Live Synced* indicator.
  - **Semester 4 (Upcoming)**: Early preparation view.
  - **Semester 2 & 1 (Completed)**: GPA badges (3.9 & 3.8) and archived lecture files.
- **Gemini Study Tip**: Ambient study motivation card.
- **Actions**: View switch (List/Grid) and floating `+ Add Semester` button with sheet.

### 2. Semester Subjects Screen (`semester_subjects_screen.dart`)

- **Navigation Context**: Back arrow, "Semester 3" headline, and degree context.
- **Term Ribbon**: 18 Credit Hours, 48 Total PDFs, 26 AI Lectures pills.
- **Filter Chips**: Dynamic filtering between *All Subjects*, *Active This Week*, and *Has New AI Notes*.
- **Subject Feed**:
  - `CS101`: Programming Fundamentals (Live recording pulse, Dr. Marcus Vance).
  - `MATH201`: Calculus & Analytical Geometry (Exam Prep badge, Prof. Elena Rostova).
  - `EE204`: Digital Logic Design (Dr. Kevin Zhao).
  - `CS202`: Data Structures & Algorithms (*Core* badge, Prof. Anita Sharma).
- **Exam Preparation Tip Card**: Gemini quiz generation prompt.
- **Action**: Floating `+ Add Subject` button.

### 3. Subject Workspace (`subject_workspace_screen.dart`)

- **Hero Subject Snapshot**: Lab diagram, professor tag (*Prof. Vance Evans • Hall 402*), syllabus progress bar.
- **Dual Tab Control**: Segmented pill switch between **AI Lectures (12)** and **PDF Notes (16)**.
- **Action Launch Banner**:
  - **Record Class Lecture**: Royal Blue card with pulsing mic icon and Gemini 1.5 Pro badge.
  - **Upload PDF**: Secondary container with file picker simulator.
- **AI Lectures Feed**:
  - *Lecture 14: AVL Trees & Balance Factors* with audio waveform visualizer and key takeaway snippet.
  - *Lecture 13: Binary Search Trees & Deletion* with practice flashcard count.
- **PDF Handouts Feed**: Week 7 slides, Assignment 3 problem set, and Exam study guide with download/share actions.
- **DSA Topic Mastery Progress**: Interactive knowledge graph widget.

### 4. Live 2-Hour Voice Recorder Screen (`recorder_screen.dart`)

- **Session Header**: Classroom hall context (*CS202 • Hall B3 • Mic Active*).
- **Studio Hub**:
  - Blinking `REC LIVE` indicator, SD card storage, and battery level (84%).
  - **High-Visibility Timer**: Real-time ticking stopwatch (`01:42:21 / 02:00:00`) with *17m left* warning.
  - **Animated Audio Waveform**: 24 animated vertical bars alternating in Royal Blue and Warm Gold.
  - **Gemini Live Indexing Ticker**: Rotating live speech transcript auto-indexed from Prof. Vance's lecture.
- **Studio Tools**:
  - Bookmark Key Moment (tap to save timestamp; increments count).
  - Whiteboard Snapshot (camera snap simulator).
- **Bottom Control Deck**:
  - Primary CTA: `Finish & Explain with Gemini ➔`
  - Secondary: `Pause/Resume REC` and `Mute/Unmute Mic`.

### 5. Gemini AI Explanation Screen (`gemini_explanation_screen.dart`)

- **Top Context**: CS 210 tag, share button, and interactive bookmark toggle.
- **Header**: Lecture 14 headline, professor metadata, duration tag.
- **Mini Lecture Audio Player**:
  - Interactive playback scrubber bar with position indicator (`01:14:20 / 01:54:10`).
  - Rewind 10s, Play/Pause toggle, Forward 10s.
  - Playback speed chips (`1x`, `1.25x`, `1.5x`, `2x`).
- **1. Quick Summary Card (Gemini 1.5 Pro)**:
  - 3-sentence takeaway in light blue container with instant recall indicator.
  - High exam probability concept highlight.
- **Visual Blackboard Slide**: OCR-synced chalkboard diagram showing BST to AVL transformation.
- **2. Step-by-Step Breakdown**:
  - Milestone 1: Why BSTs Degrade to O(n) (monospace code visualization).
  - Milestone 2: Balance Factor Invariant (`BF = Height(L) - Height(R)`).
  - Milestone 3: Single vs. Double Rotations (ASCII diagram + comparison pills).
- **3. Exam Prep Q&A**: Accordion collapsible cards with timestamp replay jump buttons (`Replay at 42:15`).
- **Interactive AI Assistant**: "Ask Gemini follow-up question" interactive bottom sheet.
- **Bottom Action Bar**: "Saved to CS 210" toggle + "Export as PDF" with compilation animation.

---

## 🔄 Complete Navigation Flow

You can tap through the entire workflow end-to-end:

```
Semesters Dashboard
    └── Tap "Semester 3"
          └── Semester Subjects Screen
                └── Tap "CS202 Data Structures & Algorithms"
                      └── Subject Workspace Screen
                            └── Tap "Record Class Lecture" (or Bottom Bar Mic)
                                  └── Live 2-Hour Recorder Screen
                                        └── Tap "Finish & Explain with Gemini"
                                              └── Gemini AI Explanation Screen
```

*(Also, inside the Workspace screen, tapping "View AI Notes" on Lecture 14 opens the Gemini Explanation screen directly).*

---

## 🚀 Setup & How to Run

### 1. Configure Gemini API Key

Open [`lib/services/gemini_service.dart`](file:///d:/Uni%20Notes/lib/services/gemini_service.dart#L11) and paste your Google AI Studio API key:

```dart
static const String geminiApiKey = 'YOUR_API_KEY_HERE';
```

*(Note: If left as `'YOUR_API_KEY_HERE'`, the app automatically uses the bundled high-yield academic syllabus fallback so testing never fails even without a key).*

### 2. Platform Permissions (Microphone & Storage)

If compiling for Android or iOS, ensure microphone permissions are present:

- **Android** (`android/app/src/main/AndroidManifest.xml` inside `<manifest>`):

  ```xml
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
  <uses-permission android:name="android.permission.INTERNET" />
  ```

- **iOS** (`ios/Runner/Info.plist` inside `<dict>`):

  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>UniNotes AI needs microphone access to record class lectures.</string>
  ```

### 3. Google Drive Backup Configuration
The app uses `google_sign_in` and `googleapis` (Drive API v3) with `drive.DriveApi.driveFileScope` (`https://www.googleapis.com/auth/drive.file`).
- Files are saved to a dedicated **`UniNotes Backup`** folder on the user's Google Drive.
- To enable real Google Sign-In on mobile devices:
  - Add your SHA-1 fingerprint and package name in your Google Cloud Console / Firebase Project.
  - Enable **Google Drive API** in your Google Cloud project.
  - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
- *(Note: If testing on an emulator or desktop without OAuth credentials registered, tap the **"Test with Demo Google Account"** button in the Drive Backup sheet to preview the full backup flow).*

### 4. Terminal Run Commands

```bash
# 1. Navigate to project root
cd "d:\Uni Notes"

# 2. If platform folders (android/ios/windows) are not generated yet:
flutter create . --platforms=android,ios,windows,web

# 3. Fetch dependencies (including google_sign_in, googleapis, and http)
flutter pub get

# 4. Run the app
flutter run
```
