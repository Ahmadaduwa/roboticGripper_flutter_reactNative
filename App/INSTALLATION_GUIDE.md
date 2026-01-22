# Installation Guide
## Robotic Gripper Control Application v1.0.0

Complete installation and deployment guide for all supported platforms.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Setup](#development-setup)
3. [Platform-Specific Installation](#platform-specific-installation)
4. [Backend Setup](#backend-setup)
5. [Configuration](#configuration)
6. [Building from Source](#building-from-source)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### For End Users (Pre-built Binaries)

#### Android
- Android device running Android 5.0 (API 21) or higher
- Minimum 100MB free storage
- Internet connection (for backend communication)

#### iOS
- iOS device running iOS 12.0 or higher
- Minimum 100MB free storage
- Internet connection (for backend communication)

#### Windows
- Windows 10 or higher (64-bit)
- Minimum 200MB free storage
- Internet connection (for backend communication)

#### macOS
- macOS 10.14 (Mojave) or higher
- Minimum 200MB free storage
- Internet connection (for backend communication)

#### Linux
- Ubuntu 18.04 or higher (or compatible distribution)
- GTK 3.0 or higher
- Minimum 200MB free storage
- Internet connection (for backend communication)

### For Developers (Building from Source)

- Flutter SDK 3.10.3 or higher
- Git
- Platform-specific build tools (see [Building from Source](#building-from-source))

---

## Development Setup

### 1. Install Flutter

#### Windows

1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add to PATH:
   ```
   C:\src\flutter\bin
   ```
4. Verify installation:
   ```bash
   flutter doctor
   ```

#### macOS

1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/macos
2. Extract to desired location
3. Add to PATH in `~/.zshrc` or `~/.bash_profile`:
   ```bash
   export PATH="$PATH:`pwd`/flutter/bin"
   ```
4. Verify installation:
   ```bash
   flutter doctor
   ```

#### Linux

1. Download Flutter SDK:
   ```bash
   cd ~
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.10.3-stable.tar.xz
   tar xf flutter_linux_3.10.3-stable.tar.xz
   ```
2. Add to PATH in `~/.bashrc`:
   ```bash
   export PATH="$PATH:$HOME/flutter/bin"
   ```
3. Verify installation:
   ```bash
   flutter doctor
   ```

### 2. Clone Repository

```bash
git clone https://github.com/Ahmadaduwa/roboticGripper_flutter_reactNative.git
cd roboticGripper/App
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Verify Setup

```bash
flutter doctor -v
```

Resolve any issues indicated by flutter doctor.

---

## Platform-Specific Installation

### Android

#### Prerequisites for Building

- Android Studio or Android SDK Command-line Tools
- Android SDK Platform API 21 or higher
- Java Development Kit (JDK) 11 or higher

#### Installation Steps (End Users)

1. **Download APK**
   - Download `robotic_gripper_app.apk` from releases

2. **Enable Installation from Unknown Sources**
   - Go to `Settings` > `Security` > `Unknown Sources`
   - Enable "Install unknown apps" for your browser/file manager

3. **Install APK**
   - Open downloaded APK file
   - Tap "Install"
   - Wait for installation to complete

4. **Grant Permissions**
   - When prompted, allow necessary permissions:
     - Storage (for CSV export)
     - Internet (for backend communication)

5. **Launch App**
   - Find "Robotic Gripper" in app drawer
   - Tap to launch

#### Building from Source

```bash
# Connect Android device or start emulator
flutter devices

# Build and install debug version
flutter run -d <device-id>

# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

**Output locations:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

---

### iOS

#### Prerequisites for Building

- macOS with Xcode 12.0 or higher
- iOS device or simulator
- Apple Developer account (for device deployment)
- CocoaPods

#### Installation Steps (End Users)

**Option 1: App Store (if published)**
1. Open App Store
2. Search "Robotic Gripper"
3. Tap "Get" and install

**Option 2: TestFlight (Beta)**
1. Install TestFlight from App Store
2. Open TestFlight invite link
3. Install app through TestFlight

**Option 3: Enterprise Distribution**
1. Download IPA file
2. Install via iTunes or Apple Configurator

#### Building from Source

```bash
# Navigate to iOS directory
cd ios

# Install CocoaPods dependencies
pod install

# Return to project root
cd ..

# Build for iOS simulator
flutter build ios --simulator

# Build for iOS device (requires signing)
flutter build ios --release

# Open in Xcode for further configuration
open ios/Runner.xcworkspace
```

**Signing:**
1. Open Xcode project
2. Select "Runner" target
3. Go to "Signing & Capabilities"
4. Select your development team
5. Ensure provisioning profile is valid

---

### Windows

#### Prerequisites for Building

- Visual Studio 2019 or higher with "Desktop development with C++" workload
- Windows 10 SDK

#### Installation Steps (End Users)

1. **Download Installer**
   - Download `robotic_gripper_setup.exe` from releases

2. **Run Installer**
   - Double-click installer
   - Follow installation wizard
   - Choose installation directory
   - Create desktop shortcut (optional)

3. **Launch App**
   - Use Start Menu shortcut
   - Or double-click desktop icon

**Manual Installation (Portable):**
1. Download `robotic_gripper_windows.zip`
2. Extract to desired location
3. Run `robotic_gripper_app.exe`

#### Building from Source

```bash
# Enable Windows desktop support
flutter config --enable-windows-desktop

# Build release version
flutter build windows --release

# Run debug version
flutter run -d windows
```

**Output location:**
- `build/windows/runner/Release/`

**Creating Installer (Optional):**
1. Install Inno Setup or NSIS
2. Use provided installer script
3. Build installer package

---

### macOS

#### Prerequisites for Building

- macOS 10.14 or higher
- Xcode 12.0 or higher
- CocoaPods

#### Installation Steps (End Users)

1. **Download DMG**
   - Download `RoboticGripper.dmg` from releases

2. **Install Application**
   - Open DMG file
   - Drag "Robotic Gripper" to Applications folder
   - Eject DMG

3. **Launch App**
   - Open from Applications folder
   - If blocked by Gatekeeper:
     - Right-click app
     - Select "Open"
     - Confirm opening

#### Building from Source

```bash
# Enable macOS desktop support
flutter config --enable-macos-desktop

# Navigate to macOS directory
cd macos

# Install CocoaPods dependencies
pod install

# Return to project root
cd ..

# Build release version
flutter build macos --release

# Run debug version
flutter run -d macos
```

**Output location:**
- `build/macos/Build/Products/Release/robotic_gripper_app.app`

**Code Signing:**
1. Open `macos/Runner.xcworkspace` in Xcode
2. Select "Runner" target
3. Configure signing certificate
4. Build for release

---

### Linux

#### Prerequisites for Building

- Ubuntu 18.04 or higher (or compatible distribution)
- Clang
- CMake
- GTK 3.0
- Ninja build

**Install build dependencies (Ubuntu/Debian):**

```bash
sudo apt-get update
sudo apt-get install -y \
  clang cmake ninja-build \
  pkg-config libgtk-3-dev \
  liblzma-dev
```

#### Installation Steps (End Users)

**Option 1: Snap Package (if available)**
```bash
sudo snap install robotic-gripper
```

**Option 2: AppImage**
1. Download `RoboticGripper.AppImage`
2. Make executable:
   ```bash
   chmod +x RoboticGripper.AppImage
   ```
3. Run:
   ```bash
   ./RoboticGripper.AppImage
   ```

**Option 3: Debian Package**
```bash
sudo dpkg -i robotic-gripper_1.0.0_amd64.deb
sudo apt-get install -f  # Fix dependencies if needed
```

#### Building from Source

```bash
# Enable Linux desktop support
flutter config --enable-linux-desktop

# Build release version
flutter build linux --release

# Run debug version
flutter run -d linux
```

**Output location:**
- `build/linux/x64/release/bundle/`

**Creating Packages:**

**AppImage:**
```bash
# Use provided appimage-builder.yml
appimage-builder --recipe appimage-builder.yml
```

**Debian Package:**
```bash
# Use provided debian packaging scripts
./scripts/build-deb.sh
```

---

### Web

#### Prerequisites for Building

- Modern web browser (Chrome, Firefox, Safari, Edge)
- Web server (for hosting)

#### Deployment Steps

1. **Build Web Version**
   ```bash
   flutter build web --release
   ```

2. **Output Location**
   - Built files in: `build/web/`

3. **Deploy to Web Server**
   
   **Option 1: GitHub Pages**
   ```bash
   # Copy build/web/* to gh-pages branch
   git checkout -b gh-pages
   cp -r build/web/* .
   git add .
   git commit -m "Deploy web app"
   git push origin gh-pages
   ```

   **Option 2: Firebase Hosting**
   ```bash
   firebase init hosting
   # Select build/web as public directory
   firebase deploy
   ```

   **Option 3: Traditional Web Server**
   ```bash
   # Copy to web server document root
   scp -r build/web/* user@server:/var/www/html/
   ```

4. **Access Application**
   - Open browser and navigate to deployment URL

**Note:** Ensure backend is accessible from web client (CORS configuration may be needed).

---

## Backend Setup

The application requires a Python backend for robot control and data management.

### Prerequisites

- Python 3.8 or higher
- pip (Python package installer)

### Installation Steps

1. **Navigate to Backend Directory**
   ```bash
   cd ../Mock
   ```

2. **Install Python Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

   **Required packages:**
   - Flask (web framework)
   - Flask-CORS (cross-origin support)
   - Additional packages as listed in requirements.txt

3. **Run Backend Server**
   ```bash
   python simulation.py
   ```

4. **Verify Backend Running**
   - You should see:
     ```
     * Running on http://127.0.0.1:5000/ (Press CTRL+C to quit)
     Backend running on http://localhost:5000
     ```

### Backend Configuration

**Change Port (Optional):**

Edit `simulation.py`:
```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

Change `port=5000` to desired port.

**Network Access:**

To allow network access from other devices:
- Backend already uses `host='0.0.0.0'`
- Configure firewall to allow port 5000
- Use IP address instead of localhost in app

**Example:**
- Backend IP: `192.168.1.100`
- App Backend URL: `http://192.168.1.100:5000`

---

## Configuration

### App Configuration

#### Backend URL

**Method 1: Settings Screen**
1. Open app
2. Go to Settings tab
3. Enter Backend URL: `http://<ip>:5000`
4. Tap Save
5. Restart app

**Method 2: Source Code (Before Building)**

Edit `lib/services/api_service.dart`:
```dart
class ApiService {
  static const String baseUrl = 'http://192.168.1.100:5000';
  // ...
}
```

#### Language

**Via Settings:**
1. Open app
2. Go to Settings
3. Select language (English / ภาษาไทย)

**Default Language (Source Code):**

Edit `lib/providers/localization_provider.dart`:
```dart
class LocalizationProvider extends ChangeNotifier {
  String _currentLanguage = 'en'; // or 'th'
  // ...
}
```

### Database

Database is automatically created on first run.

**Location:**
- Android: `/data/data/com.example.robotic_gripper_app/databases/`
- iOS: App sandbox Documents directory
- Windows: `%APPDATA%\robotic_gripper_app\`
- macOS: `~/Library/Application Support/robotic_gripper_app/`
- Linux: `~/.local/share/robotic_gripper_app/`

**Reset Database:**
1. Use Settings > Clear Local Database
2. Or delete database file manually

---

## Building from Source

### Complete Build Process

1. **Clone Repository**
   ```bash
   git clone https://github.com/Ahmadaduwa/roboticGripper_flutter_reactNative.git
   cd roboticGripper/App
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run Code Generation (if needed)**
   ```bash
   flutter pub run build_runner build
   ```

4. **Verify Configuration**
   - Check `pubspec.yaml` version
   - Verify `lib/services/api_service.dart` backend URL

5. **Build for Target Platform**

   **Android:**
   ```bash
   flutter build apk --release
   # or
   flutter build appbundle --release
   ```

   **iOS:**
   ```bash
   flutter build ios --release
   ```

   **Windows:**
   ```bash
   flutter build windows --release
   ```

   **macOS:**
   ```bash
   flutter build macos --release
   ```

   **Linux:**
   ```bash
   flutter build linux --release
   ```

   **Web:**
   ```bash
   flutter build web --release
   ```

6. **Locate Build Artifacts**
   - See platform-specific sections above for output locations

---

## Troubleshooting

### Common Issues

#### Flutter doctor shows issues

**Problem:** `flutter doctor` reports problems

**Solution:**
1. Follow recommendations from `flutter doctor -v`
2. Install missing dependencies
3. Configure IDE plugins
4. Accept Android licenses: `flutter doctor --android-licenses`

#### Build fails with dependency errors

**Problem:** Package dependency conflicts

**Solution:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

#### Cannot connect to backend

**Problem:** App shows connection error

**Solution:**
1. Verify `simulation.py` is running
2. Check backend URL in app settings
3. Verify firewall allows port 5000
4. Test backend: `curl http://localhost:5000/api/ping`
5. Check network connectivity

#### Android build fails

**Problem:** Gradle build errors

**Solution:**
1. Update Android SDK: `sdkmanager --update`
2. Check `minSdkVersion` in `android/app/build.gradle`
3. Clean build: `cd android && ./gradlew clean && cd ..`
4. Check Java version: `java -version` (should be 11+)

#### iOS build fails

**Problem:** CocoaPods or signing errors

**Solution:**
1. Update CocoaPods: `sudo gem install cocoapods`
2. Clean pods:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   ```
3. Open Xcode and configure signing

#### Windows build fails

**Problem:** Visual Studio errors

**Solution:**
1. Verify Visual Studio C++ Desktop workload installed
2. Update Windows SDK
3. Run as Administrator if needed

#### Linux build fails

**Problem:** Missing libraries

**Solution:**
```bash
sudo apt-get install -y \
  clang cmake ninja-build \
  pkg-config libgtk-3-dev \
  liblzma-dev libblkid-dev
```

#### App crashes on launch

**Problem:** Runtime crash

**Solution:**
1. Check logs:
   - Android: `adb logcat`
   - iOS: Xcode Console
   - Desktop: Terminal output
2. Verify all dependencies installed
3. Clear app data and restart
4. Reinstall app

#### Cannot save patterns

**Problem:** Database write errors

**Solution:**
1. Check storage permissions (mobile)
2. Verify sufficient disk space
3. Clear app cache
4. Reset database via Settings

---

## Post-Installation

### First Run Checklist

1. ✅ App launches successfully
2. ✅ Backend connection established (or continue offline)
3. ✅ Dashboard displays data
4. ✅ Can navigate between screens
5. ✅ Language selection works
6. ✅ Can create and save patterns
7. ✅ Can execute patterns
8. ✅ CSV export works (if applicable)

### Recommended Settings

1. **Set Backend URL** (if not localhost)
2. **Choose preferred language**
3. **Test basic gripper control**
4. **Create a test pattern**
5. **Verify logging works**

---

## Updating

### Updating the App

**Mobile (Android/iOS):**
- Download new version
- Install over existing (data preserved)

**Desktop:**
- Download new version
- Install to same location
- Data automatically migrated

### Updating the Backend

```bash
cd Mock
git pull
pip install -r requirements.txt --upgrade
python simulation.py
```

---

## Uninstallation

### Android
1. Settings > Apps > Robotic Gripper
2. Tap Uninstall
3. Confirm

### iOS
1. Long-press app icon
2. Tap "Remove App"
3. Select "Delete App"

### Windows
1. Settings > Apps > Robotic Gripper
2. Click Uninstall
3. Follow wizard

### macOS
1. Open Applications folder
2. Drag "Robotic Gripper" to Trash
3. Empty Trash

### Linux
```bash
# Snap
sudo snap remove robotic-gripper

# Debian package
sudo apt-get remove robotic-gripper
```

**Note:** Database files are not automatically removed. Delete manually if needed.

---

## Support

For installation issues:
1. Review this guide
2. Check [README.md](README.md)
3. Review [USER_MANUAL.md](USER_MANUAL.md)
4. Contact development team

---

**Last Updated**: January 22, 2026  
**Version**: 1.0.0  
**Platforms**: Android, iOS, Windows, macOS, Linux, Web
