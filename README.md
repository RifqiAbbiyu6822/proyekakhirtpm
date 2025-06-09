# History Quiz App

A modern and interactive History Quiz application built with Flutter that offers an engaging way to learn history through quizzes. The app features dynamic themes, user profiles, and various interactive elements to enhance the learning experience.

## Features

- 📱 Cross-platform support (iOS, Android, Web, Desktop)
- 🎨 Dynamic theme support
- 📝 Interactive history quizzes
- 👤 User profiles and progress tracking
- 🔔 Local notifications
- 📸 Camera integration
- 📍 Location-based features
- 🔄 Shake to refresh functionality
- 📊 Progress tracking and statistics
- 💾 Local data persistence
- 🌐 Online/Offline support

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Database**: SQLite (sqflite)
- **State Management**: Provider
- **Storage**: Shared Preferences
- **APIs & Services**:
  - Camera
  - Geolocation
  - Local Notifications
  - Sensors
  - Device Info
  - URL Launcher

## Project Structure

```
lib/
├── controllers/    # Business logic and state management
├── models/         # Data models
├── screens/        # UI screens
├── services/       # External services and API calls
├── theme/          # Theme configuration
├── utils/          # Utility functions and constants
├── widgets/        # Reusable UI components
└── main.dart       # Application entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS development)

### Installation

1. Clone the repository:
```bash
git clone [repository-url]
```

2. Navigate to the project directory:
```bash
cd historyquizapp
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Required Permissions

The app requires the following permissions:

- Camera access
- Location services
- Storage access
- Internet access
- Notification permissions

## Dependencies

Key packages used in this project:

- `http`: ^1.4.0 - For network requests
- `provider`: ^6.1.5 - State management
- `sqflite`: ^2.3.2 - Local database
- `shared_preferences`: ^2.5.3 - Local storage
- `geolocator`: ^14.0.1 - Location services
- `camera`: ^0.10.5+9 - Camera functionality
- `flutter_local_notifications`: ^17.2.1 - Local notifications
- `sensors_plus`: ^4.0.2 - Device sensors access

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors and package maintainers
- The open-source community

---

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
