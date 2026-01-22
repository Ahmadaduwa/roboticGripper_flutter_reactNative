# Robotic Gripper Control Application

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.10.3-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)

## 📋 Overview

**Robotic Gripper Control Application** is a comprehensive Flutter-based mobile and desktop application designed to control and monitor industrial robotic grippers. The application provides real-time monitoring, manual control, automated pattern execution, and a powerful Teaching Mode for no-code programming.

### Key Features

- 🎯 **Real-time Dashboard** - Monitor gripper status, force, material detection, and sensor analytics
- 🎮 **Manual Control** - Direct control of gripper angle, force limits, and safety interlocks
- 🤖 **Teaching Mode** - No-code programming interface for creating automated movement patterns
- ⚡ **Auto-Run Mode** - Execute saved patterns with logging and CSV export capabilities
- 📊 **Analytics** - Real-time charts showing confidence levels and system performance
- 🌐 **Offline Support** - Full offline operation with automatic sync when connection is restored
- 🌍 **Multi-language** - Support for English and Thai languages

---

## 🏗️ Architecture

### System Components

```
┌──────────────────────────────────────────────────────────┐
│                   Flutter Application                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │  Dashboard  │  │   Control   │  │  Teaching   │      │
│  │   Screen    │  │   Screen    │  │    Mode     │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
│                                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │  Auto-Run   │  │  Settings   │  │  Providers  │      │
│  │   Screen    │  │   Screen    │  │   (State)   │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
├──────────────────────────────────────────────────────────┤
│                   Services Layer                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ API Service │  │  Database   │  │   Export    │      │
│  │   (HTTP)    │  │  (SQLite)   │  │  Service    │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
└──────────────────────────────────────────────────────────┘
                          │
                          │ HTTP API
                          ▼
┌──────────────────────────────────────────────────────────┐
│              Python Backend (simulation.py)              │
│  • REST API (Flask)                                      │
│  • Robot State Management                               │
│  • Pattern Storage                                       │
│  • Hardware Simulation                                   │
└──────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Framework**: Flutter 3.10.3+ (Dart SDK)
- **State Management**: Provider 6.1.5+
- **Database**: SQLite (sqflite 2.4.2+)
- **Networking**: HTTP 1.6.0+
- **Charts**: FL Chart 1.1.1+
- **Fonts**: Google Fonts 6.3.3+
- **Platform**: Cross-platform (Android, iOS, Windows, Linux, macOS, Web)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.3 or higher
- Dart SDK (included with Flutter)
- Python 3.8+ (for backend simulation)
- Android Studio / VS Code (recommended IDEs)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Ahmadaduwa/roboticGripper_flutter_reactNative.git
   cd roboticGripper/App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the backend simulation** (in a separate terminal)
   ```bash
   cd ../Mock
   python simulation.py
   ```
   The backend will start on `http://localhost:5000`

4. **Run the Flutter application**
   ```bash
   flutter run
   ```

   For specific platforms:
   ```bash
   flutter run -d windows    # Windows
   flutter run -d android    # Android
   flutter run -d chrome     # Web
   ```

### Configuration

By default, the application connects to `http://localhost:5000`. To change the backend URL:

1. Open `lib/services/api_service.dart`
2. Modify the `baseUrl` constant:
   ```dart
   static const String baseUrl = 'http://your-backend-ip:5000';
   ```

---

## 📱 Application Features

### 1. Dashboard Screen

The main screen provides real-time monitoring of the robotic gripper:

- **Status Indicators**
  - System Power Status (On/Off)
  - Safety Interlock Status
  - Connection Status

- **Real-time Metrics**
  - Current Gripper Angle (0-180°)
  - Applied Force (0-10N)
  - Material Detection with AI confidence
  - Joint Positions (J1-J6)

- **Analytics Chart**
  - Material recognition confidence over time
  - Visual trend analysis

### 2. Control Screen

Manual control interface for direct gripper operation:

- **Gripper Control**
  - Angle slider (0-180°)
  - Real-time angle display
  - Smooth control with haptic feedback

- **Force Management**
  - Maximum force limit setting (0-10N)
  - Safety thresholds
  - Visual indicators

- **Safety Features**
  - Emergency stop button
  - Safety interlock switch
  - Status indicators

### 3. Teaching Mode

Revolutionary no-code programming interface:

#### Features
- **Pattern Creation** - Create, name, and describe movement sequences
- **Step Recording** - Add grip, release, wait, and movement steps
- **Visual Editor** - Drag-to-reorder steps with visual preview
- **Test Execution** - Run patterns before saving
- **Pattern Library** - Save and manage multiple patterns
- **Offline Storage** - Patterns saved locally in SQLite database

#### Supported Actions
- **GRIP** - Close gripper to specified angle
- **RELEASE** - Open gripper to specified angle
- **WAIT** - Pause execution for specified duration
- **MOVE JOINTS** - (Future) Multi-axis movement

#### Workflow
1. Create new pattern with name and description
2. Add steps using action buttons
3. Preview and test the sequence
4. Save pattern to library
5. Execute from Auto-Run screen

See [TEACHING_MODE_DOCUMENTATION.md](TEACHING_MODE_DOCUMENTATION.md) for detailed documentation.

### 4. Auto-Run Screen

Execute saved patterns with advanced logging:

- **Pattern Execution**
  - Select from saved patterns
  - One-click execution
  - Real-time progress tracking
  - Step-by-step visualization

- **Logging System**
  - Automatic CSV log generation
  - Timestamp tracking
  - Success/failure recording
  - Pattern details logging

- **Log Management**
  - View execution history
  - Download logs as CSV
  - Delete old logs
  - Export data for analysis

### 5. Settings Screen

Customize application behavior:

- **Language Selection**
  - English
  - Thai (ภาษาไทย)

- **Backend Configuration**
  - API endpoint URL
  - Connection timeout settings
  - Retry configurations

- **Data Management**
  - Clear local database
  - Reset to defaults
  - Sync with backend

---

## 🗂️ Project Structure

```
lib/
├── main.dart                      # Application entry point
├── models/                        # Data models
│   ├── pattern.dart              # Pattern model with steps
│   └── pattern_step.dart         # Individual step model
├── providers/                     # State management
│   ├── robot_provider.dart       # Robot state & real-time data
│   ├── teaching_provider.dart    # Teaching mode state
│   └── localization_provider.dart # Language management
├── screens/                       # UI screens
│   ├── main_layout.dart          # Bottom navigation layout
│   ├── dashboard_screen.dart     # Main dashboard
│   ├── control_screen.dart       # Manual control
│   ├── teaching_screen.dart      # Teaching mode UI
│   ├── auto_run_screen.dart      # Pattern execution
│   └── settings_screen.dart      # Configuration
├── services/                      # Business logic
│   ├── api_service.dart          # Backend HTTP API
│   ├── database_service.dart     # SQLite operations
│   └── export_service.dart       # CSV export
└── widgets/                       # Reusable UI components
    ├── status_card.dart          # Dashboard cards
    ├── control_slider.dart       # Custom sliders
    └── pattern_step_card.dart    # Step display cards
```

---

## 🔌 API Integration

### Backend Endpoints

The application communicates with the Python backend via REST API:

#### Robot Control
- `GET /api/robot/status` - Get current robot state
- `POST /api/robot/gripper` - Control gripper (angle, force, power)

#### Pattern Management
- `GET /api/patterns` - List all saved patterns
- `GET /api/patterns/{id}` - Get specific pattern with steps
- `POST /api/patterns` - Create new pattern
- `DELETE /api/patterns/{id}` - Delete pattern

#### Teaching Mode
- `POST /api/teach/record` - Record new step
- `GET /api/teach/buffer` - Get current recording buffer
- `POST /api/teach/save` - Save current buffer as pattern
- `POST /api/teach/execute` - Test execute buffer
- `DELETE /api/teach/buffer/clear` - Clear recording buffer

See backend documentation for complete API specifications.

---

## 💾 Database Schema

Local SQLite database for offline operation:

### Tables

#### patterns
```sql
CREATE TABLE patterns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### pattern_steps
```sql
CREATE TABLE pattern_steps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pattern_id INTEGER NOT NULL,
  step_order INTEGER NOT NULL,
  action_type TEXT NOT NULL,
  params TEXT NOT NULL,  -- JSON string
  created_at TEXT NOT NULL,
  FOREIGN KEY (pattern_id) REFERENCES patterns (id) ON DELETE CASCADE
);
```

### Indexes
- `idx_steps_pattern_id` on `pattern_steps(pattern_id)`
- `idx_steps_order` on `pattern_steps(pattern_id, step_order)`

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/api_service_test.dart
```

### Test Coverage

- Unit tests for services and providers
- Widget tests for UI components
- Integration tests for complete workflows

---

## 📦 Building for Production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
flutter build ios --release
```

Then use Xcode to create archive and upload to App Store.

### Windows

```bash
flutter build windows --release
```

Output: `build/windows/runner/Release/`

### Linux

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

### macOS

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/`

### Web

```bash
flutter build web --release
```

Output: `build/web/`

---

## 🐛 Troubleshooting

### Cannot connect to backend

**Problem**: App shows "Cannot connect to simulation" error

**Solutions**:
1. Ensure `simulation.py` is running on port 5000
2. Check that backend URL in `api_service.dart` is correct
3. Verify firewall settings allow connections
4. Use "Continue Offline" to work without backend

### Database errors

**Problem**: SQLite errors or data not saving

**Solutions**:
1. Clear app data and restart
2. Update to latest Flutter version
3. Check storage permissions (mobile platforms)
4. Use Settings > Clear Database to reset

### Build failures

**Problem**: Flutter build fails

**Solutions**:
1. Run `flutter clean` then `flutter pub get`
2. Update Flutter: `flutter upgrade`
3. Check minimum SDK versions in platform-specific configs
4. Delete `build/` folder and rebuild

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Dart style guide
- Use `flutter analyze` before committing
- Write meaningful commit messages
- Add tests for new features

---

## 📄 License

This project is proprietary software developed for industrial robotic gripper control.

---

## 👥 Authors

- **Developer** - Initial work and implementation
- **Project Team** - Ahmadaduwa/roboticGripper_flutter_reactNative

---

## 📞 Support

For support, questions, or feature requests:

- Open an issue on GitHub
- Check existing documentation in `/docs`
- Review [TEACHING_MODE_DOCUMENTATION.md](TEACHING_MODE_DOCUMENTATION.md)
- Read [TEACHING_MODE_QUICK_START.md](TEACHING_MODE_QUICK_START.md)

---

## 🗺️ Roadmap

### Version 1.x
- [x] Real-time dashboard
- [x] Manual control interface
- [x] Teaching mode with pattern recording
- [x] Auto-run with logging
- [x] Multi-language support
- [x] Offline operation

### Version 2.0 (Planned)
- [ ] Advanced analytics dashboard
- [ ] Cloud sync for patterns
- [ ] Multi-robot support
- [ ] Enhanced AI material detection
- [ ] Voice control integration
- [ ] Augmented Reality preview
- [ ] Pattern marketplace

---

## 📊 Version History

### v1.0.0 (2026-01-22)
- Initial production release
- Full Teaching Mode implementation
- Complete offline support
- Multi-platform deployment
- Comprehensive documentation
- Bilingual interface (EN/TH)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Provider package for state management
- FL Chart for beautiful visualizations
- Google Fonts for typography
- Open source community

---

**⚡ Built with Flutter - One codebase, everywhere**

