# Create README.md file with the documentation
@'
# 📱 Eye Care Reminder App - Technical Documentation

## 📋 Overview
A Flutter app with Android native components that sends **eye care reminders** every 20 minutes using the 20-20-20 rule (look 20 feet away for 20 seconds after 20 minutes of screen time).

## 🏗️ Architecture

### 🔄 How It Works
1. **Flutter UI** → User clicks "Start Monitoring"
2. **Android Service** → Starts foreground service to stay alive
3. **Screen Detection** → Service listens for screen ON/OFF events
4. **WorkManager** → Schedules notifications for 20 minutes later
5. **Notification** → Shows reminder when time expires

### 📁 File Structure
android/app/src/main/kotlin/com/example/screen_time_reminder/
├── MainActivity.kt # Flutter ↔ Android bridge
├── EyeCareWorker.kt # Shows notifications (WorkManager)
└── EyeCareService.kt # Runs in background, detects screen


## ⚙️ Core Components

### 1. **EyeCareService.kt** (Foreground Service)
- **Purpose**: Keeps app running when minimized/killed
- **Key Features**:
    - Starts as foreground service with persistent notification
    - Listens for `SCREEN_ON`/`SCREEN_OFF` broadcasts
    - Triggers notification scheduling when screen turns ON
    - Cancels notifications when screen turns OFF
    - Works reliably even when app is killed

### 2. **EyeCareWorker.kt** (WorkManager Worker)
- **Purpose**: Shows notifications at scheduled times
- **Key Features**:
    - Uses Android'\''s WorkManager for reliable scheduling
    - Shows notification after 20-minute delay
    - Creates notification channel for Android 8+
    - Works across app restarts and device reboots
    - Battery-optimized by Android system

### 3. **MainActivity.kt** (Flutter Bridge)
- **Purpose**: Communication between Flutter and Android
- **Key Features**:
    - `startService()`: Starts the monitoring service
    - `stopService()`: Stops monitoring
    - `checkStatus()`: Checks if monitoring is active
    - Handles Android 13+ notification permissions

## 🔧 Key Implementation Details

### ⚡ Why This Architecture?
| Problem | Solution | Benefit |
|---------|----------|---------|
| App killed → No notifications | Foreground Service | Always runs |
| Need precise 20-minute timing | WorkManager | Reliable scheduling |
| Stop when screen off | Screen detection | Battery efficient |
| Android 13+ permissions | Runtime requests | Modern compliance |

### 🕒 Timing Logic
- **Screen ON** → Schedule notification for 20 minutes later
- **Screen OFF** → Cancel all pending notifications
- **Notification shows** → User takes 20-second break
- **Cycle repeats** → New 20-minute timer starts automatically

### 🔐 Permissions Required
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

🚀 Setup & Usage
From Flutter:
dart
// Start monitoring
await methodChannel.invokeMethod('startService');
// Stop monitoring  
await methodChannel.invokeMethod('stopService');
// Check status
bool isActive = await methodChannel.invokeMethod('checkStatus');

Testing Checklist:
✅ Grant notification permission (Android 13+)
✅ App shows "Eye Care Monitor" persistent notification
✅ Wait 20 minutes with screen ON
✅ Notification appears: "Look 20 feet away for 20 seconds"
✅ Screen OFF cancels pending notifications
✅ Screen ON restarts the timer

⚠️ Important Notes
For Developers:
Minimum Android: API 21 (Android 5.0)
Target/Compile SDK: 33 (Android 13)
WorkManager Version: 2.8.1
Testing: Test on real device for accurate timing

For Users:
App must run at least once after install
Grant notification permission when prompted
Keep "Eye Care Monitor" notification visible (required by Android)
Works best with screen ON for 20+ minutes continuously

📊 Flow Diagram
User Action → Flutter → Android Service → Screen Event → WorkManager → Notification
    ↓           ↓           ↓               ↓              ↓            ↓
[Start App] → [Start] → [Foreground] → [SCREEN_ON] → [Schedule 20min] → [🔔 Show]
[Stop App]  → [Stop]  → [Destroy]    → [SCREEN_OFF] → [Cancel All]    → [✖️ Stop]

Maintained by: Dildar Hussain
Last Updated: $(Get-Date -Format "2026-01-06")
Version: 1.0.0