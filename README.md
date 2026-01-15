# 🤖 Robotic Gripper Control System

A complete AIoT (AI + IoT) solution for controlling and monitoring a robotic gripper arm with real-time sensor feedback, pattern teaching, and automated execution capabilities.

## 📱 Project Overview

This project consists of three main components:

1. **Flutter Mobile App** - Primary mobile interface with advanced features
2. **React Native Mobile App** - Alternative mobile interface
3. **Python Backend/Simulation** - FastAPI-based backend with hardware simulation

## ✨ Features

### 📊 Dashboard
- Real-time force sensor monitoring with live gauge
- Historical force data visualization with interactive charts
- Material detection confidence display
- System status indicators

### 🎮 Manual Control
- Direct gripper angle control (0-180°)
- Adjustable maximum force limits
- Real-time sensor feedback
- Safety interlock switch

### 🎯 Teaching Mode
- Record custom movement patterns
- Add grip, release, position, and wait actions
- Edit and reorder sequence steps
- Test patterns before saving
- Pattern synchronization with backend
- Stop sequence execution

### ⚡ Auto Run
- Execute saved patterns automatically
- Configure cycle count and force limits
- Real-time execution monitoring
- CSV data logging for each run
- Download execution logs directly to device
- View and manage execution history

### ⚙️ Settings
- Multi-language support (English/Thai)
- Configurable API endpoint
- Connection testing

## 🏗️ Architecture

```
roboticGripper/
├── App/                    # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── providers/     # State management
│   │   ├── screens/       # UI screens
│   │   ├── services/      # API & database services
│   │   └── widgets/       # Reusable components
│   └── android/
│
├── App_React/             # React Native Mobile Application
│   ├── src/
│   │   ├── api/          # API client
│   │   ├── features/     # Context providers
│   │   ├── navigation/   # Navigation setup
│   │   ├── screens/      # UI screens
│   │   └── theme/        # Styling
│   └── App.js
│
└── Mock/                  # Python Backend & Simulation
    ├── simulation.py     # FastAPI backend
    └── logs/             # Execution logs storage
```

## 🛠️ Technology Stack

### Flutter App
- **Framework**: Flutter 3.10+
- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **Charts**: fl_chart
- **HTTP Client**: http package
- **Fonts**: Google Fonts (Outfit, Zilla Slab)

### React Native App
- **Framework**: React Native (Expo)
- **State Management**: Context API
- **HTTP Client**: Axios
- **Navigation**: React Navigation
- **Icons**: lucide-react-native

### Backend
- **Framework**: FastAPI (Python)
- **Database**: SQLite with SQLModel ORM
- **CORS**: Enabled for mobile app access
- **Features**: RESTful API, WebSocket support, hardware simulation

## 🚀 Getting Started

### Prerequisites

- **Flutter**: Flutter SDK 3.10 or higher
- **React Native**: Node.js 18+, npm/yarn
- **Python**: Python 3.8 or higher
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)

### Backend Setup

1. **Navigate to Mock directory**:
   ```bash
   cd Mock
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install fastapi uvicorn sqlmodel
   ```

4. **Run the backend**:
   ```bash
   python simulation.py
   ```

   The backend will start on `http://localhost:8000`

### Flutter App Setup

1. **Navigate to App directory**:
   ```bash
   cd App
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Update API endpoint** (if needed):
   - For Android Emulator: `http://10.0.2.2:8000`
   - For Physical Device: `http://YOUR_LOCAL_IP:8000`
   - Can be configured in Settings screen

4. **Run the app**:
   ```bash
   flutter run
   ```

### React Native App Setup

1. **Navigate to App_React directory**:
   ```bash
   cd App_React
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start Metro bundler**:
   ```bash
   npx expo start
   ```

4. **Run on device/emulator**:
   - Press `a` for Android
   - Press `i` for iOS (macOS only)

## 📡 API Endpoints

### Health & Data
- `GET /health` - Backend health check
- `GET /data` - Get current sensor data

### Manual Control
- `POST /api/robot/gripper` - Send gripper commands

### Patterns
- `GET /api/patterns` - List all patterns
- `GET /api/patterns/{id}` - Get specific pattern
- `DELETE /api/patterns/{id}` - Delete pattern
- `GET /api/sync/patterns` - Sync all patterns
- `POST /api/sync/patterns` - Save patterns to backend

### Teaching Mode
- `POST /api/teach/execute-sequence` - Execute pattern sequence
- `POST /api/teach/stop` - Stop current execution

### Auto Run
- `POST /auto-run/start` - Start automated execution
- `POST /auto-run/stop` - Stop auto run

### Logs & History
- `GET /api/history` - Get execution history
- `DELETE /api/history/{id}` - Delete history record
- `GET /api/logs/download/{filename}` - Download CSV log file

## 🎨 UI/UX Design

### Design System
- **Primary Color**: Deep Blue (#0D47A1, #0047AB)
- **Success**: Green (#00E676)
- **Danger**: Red (#EF5350)
- **Background**: Light Gray (#F5F5F5, #F5F7FA)
- **Typography**: Outfit (main), Zilla Slab (headers)

### Platform Consistency
Both Flutter and React Native apps share:
- Consistent color scheme
- Similar navigation patterns
- Unified iconography
- Responsive layouts
- Bilingual support (EN/TH)

## 📱 Permissions

### Android
- `INTERNET` - API communication
- `WRITE_EXTERNAL_STORAGE` - CSV download
- `READ_EXTERNAL_STORAGE` - File access

### iOS
- Network access for API calls

## 🔧 Configuration

### Backend Configuration
Edit `simulation.py`:
```python
# Change port
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Mobile App Configuration
Both apps support runtime API URL configuration via Settings screen.

## 📝 Data Persistence

### Flutter
- **Local Database**: SQLite for offline pattern storage
- **Shared Preferences**: Settings and language preference
- **Auto-sync**: Patterns sync with backend on launch

### React Native
- **AsyncStorage**: Settings and language preference
- **Real-time**: Direct backend communication

### Backend
- **SQLite Database**: Stores patterns, steps, and execution history
- **CSV Logs**: Execution data saved in `logs/` directory

## 🌐 Localization

Both apps support:
- **English (ENG)**
- **Thai (TH)**

Language selection is persisted and synchronized across app sessions.

## 🐛 Troubleshooting

### "Cannot connect to backend"
- Ensure backend is running on `http://localhost:8000`
- For Android emulator, use `http://10.0.2.2:8000`
- For physical device, use your computer's local IP
- Check firewall settings

### "Storage permission denied" (Flutter)
- Grant storage permission in device settings
- Required for CSV download feature

### "Component name is null" (url_launcher)
- Fixed by implementing direct HTTP download
- Files are saved to device Downloads folder

## 🤝 Contributing

This project is part of a robotic gripper control system development. Contributions, issues, and feature requests are welcome!

## 📄 License

This project is available for educational and research purposes.

## 👥 Authors

Developed as an AIoT system for robotic gripper control with dual-platform mobile support.

## 🙏 Acknowledgments

- Flutter team for the amazing cross-platform framework
- FastAPI for the modern Python web framework
- React Native community for mobile development tools
- All open-source contributors whose libraries made this possible

---

**Status**: ✅ Active Development

**Last Updated**: January 2026
