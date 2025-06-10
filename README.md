# History Quiz App

A comprehensive and interactive History Quiz application built with Flutter that transforms learning history into an engaging experience. This modern, feature-rich application combines educational content with gamification elements to make history learning both fun and effective. The app supports multiple platforms and offers a rich set of features for both online and offline learning.

## 🌟 Key Features

### Core Functionality
- 📚 Extensive quiz database covering various historical periods
- 🎯 Multiple quiz formats (MCQ, True/False, Match the Pairs)
- 🎨 Dynamic difficulty levels (Easy, Medium, Hard)
- 💯 Instant feedback and detailed explanations
- 📊 Comprehensive performance analytics

### User Experience
- 🎨 Dynamic theme support with light/dark modes
- 🌍 Multi-language support
- 👤 Personalized user profiles
- 📈 Progress tracking and achievements
- 🏆 Leaderboards and rankings

### Technical Features
- 💾 Offline mode with local data persistence
- 🔄 Background sync capabilities
- 🔔 Smart notifications system
- 📸 Image-based questions with camera integration
- 📍 Location-based historical facts
- 🔄 Shake-to-refresh functionality
- 📱 Responsive design for all screen sizes

## 🛠 Technical Architecture

### Tech Stack
- **Framework**: Flutter 3.x
- **Programming Language**: Dart 3.x
- **Database**: SQLite (sqflite)
- **State Management**: Provider
- **Local Storage**: Shared Preferences
- **API Integration**: REST APIs
- **Testing**: Unit Tests, Widget Tests, Integration Tests

### Project Structure
```
lib/
├── controllers/          # Business logic and state management
│   ├── auth/            # Authentication logic
│   ├── quiz/            # Quiz management
│   └── user/            # User data management
├── models/              # Data models and entities
│   ├── quiz/            # Quiz-related models
│   ├── user/            # User-related models
│   └── analytics/       # Analytics models
├── screens/             # UI screens and pages
│   ├── auth/            # Authentication screens
│   ├── quiz/            # Quiz-related screens
│   ├── profile/         # User profile screens
│   └── settings/        # App settings screens
├── services/            # External services integration
│   ├── api/            # API services
│   ├── database/       # Local database services
│   ├── analytics/      # Analytics services
│   └── notifications/  # Notification services
├── theme/              # Theme configuration
│   ├── colors.dart
│   └── typography.dart
├── utils/              # Utility functions and constants
│   ├── constants/
│   ├── helpers/
│   └── validators/
├── widgets/            # Reusable UI components
│   ├── common/
│   ├── quiz/
│   └── profile/
└── main.dart           # Application entry point
```

## 🚀 Getting Started

### System Requirements
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS development)
- Minimum 4GB RAM
- 10GB free storage space

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/historyquizapp.git
   cd historyquizapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   - Create a `.env` file in the root directory
   - Add necessary API keys and configurations

4. **Run the app**
   ```bash
   # Development
   flutter run --debug

   # Production
   flutter run --release
   ```

### Building for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## 📱 Platform-Specific Features

### Android
- Material Design 3.0 components
- Android 13 themed icons
- Quick Settings tile support
- Widget support

### iOS
- Native iOS UI components
- iCloud backup support
- ShareSheet integration
- Haptic feedback

### Web
- Progressive Web App (PWA) support
- Responsive design
- Keyboard shortcuts
- Local storage optimization

## 🔒 Security Features

- End-to-end encryption for user data
- Secure local storage
- API key protection
- Input validation and sanitization
- Regular security updates

## 📊 Performance Optimization

- Lazy loading of images and assets
- Efficient state management
- Cached network images
- Minimized app size
- Background processing for heavy tasks

## 🧪 Testing

### Unit Tests
```bash
flutter test test/unit/
```

### Widget Tests
```bash
flutter test test/widget/
```

### Integration Tests
```bash
flutter test integration_test/
```

## 📦 Dependencies

### Core Dependencies
- `provider: ^6.1.5` - State management
- `sqflite: ^2.3.2` - Local database
- `http: ^1.4.0` - Network requests
- `shared_preferences: ^2.5.3` - Local storage

### Feature-specific Dependencies
- `camera: ^0.10.5+9` - Camera functionality
- `geolocator: ^14.0.1` - Location services
- `flutter_local_notifications: ^17.2.1` - Notifications
- `sensors_plus: ^4.0.2` - Device sensors

### Development Dependencies
- `flutter_test: sdk: flutter` - Testing framework
- `build_runner: ^2.4.8` - Code generation
- `mockito: ^5.4.4` - Mocking for tests

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow Flutter's official style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the excellent framework
- All contributors and package maintainers
- The open-source community
- Our beta testers and early adopters

## 📞 Support

For support, please:
- Open an issue on GitHub
- Join our Discord community
- Email us at support@historyquizapp.com

## 📚 Additional Resources

- [Official Documentation](https://docs.historyquizapp.com)
- [API Reference](https://api.historyquizapp.com)
- [Contributing Guide](CONTRIBUTING.md)
- [Change Log](CHANGELOG.md)

---

Built with ❤️ using Flutter
