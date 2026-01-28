# Notes App - Flutter Client

A beautiful, cross-platform notes application built with Flutter that connects to your Next.js notes backend API.

## Features

✅ **Complete CRUD Operations**
- Create, read, update, and delete notes
- Real-time sync with your Next.js backend

✅ **Rich Note Management**
- Add titles, content, and categories
- Mark notes as favorites
- Move notes to trash
- Permanent deletion

✅ **Beautiful UI/UX**
- Material Design 3
- Grid and list view modes
- Dark and light themes
- Smooth animations and transitions
- Responsive layout

✅ **Search & Filter**
- Real-time search across titles, content, and categories
- Filter by categories
- Sort by date (created/updated) or title
- Favorite notes always appear first

✅ **Cross-Platform Support**
- ✅ Android
- ✅ Linux
- ✅ Windows
- iOS (untested but should work)
- macOS (untested but should work)
- Web (untested but should work)

## Setup

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- For Android: Android Studio and SDK
- For Linux: GTK development libraries
- For Windows: Visual Studio 2022

### Installation

1. **Clone the repository**
```bash
cd /path/to/notesapp
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API endpoint** (if needed)

The app is already configured to use:
- Base URL: `https://notes.shubham-shah.com.np`
- API Token: Pre-configured

If you want to use a different backend, edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'YOUR_API_URL';
static const String apiToken = 'YOUR_API_TOKEN';
```

4. **Run the app**

For Linux:
```bash
flutter run -d linux
```

For Android:
```bash
flutter run -d android
```

For Windows:
```bash
flutter run -d windows
```

### Building Release Versions

**Linux**
```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

**Android APK**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Windows**
```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── note.dart            # Note data model
├── providers/
│   ├── notes_provider.dart  # Notes state management
│   └── theme_provider.dart  # Theme state management
├── screens/
│   ├── home_screen.dart     # Main notes list screen
│   └── note_editor_screen.dart # Note create/edit screen
├── services/
│   ├── api_service.dart     # API integration
│   └── storage_service.dart # Local storage
├── utils/
│   └── theme.dart           # Theme configuration
└── widgets/
    └── note_card.dart       # Note card widget
```

## Usage

### Creating a Note
1. Tap the "+ New Note" button
2. Enter a title (required)
3. Optionally add a category
4. Write your content
5. Tap the checkmark to save

### Editing a Note
1. Tap on any note card
2. Make your changes
3. Tap the checkmark to save

### Managing Notes
- **Favorite**: Tap the menu (⋮) → Add to Favorites
- **Move to Trash**: Tap the menu (⋮) → Move to Trash
- **Delete Permanently**: Tap the menu (⋮) → Delete Permanently

### Search & Filter
- Use the search bar to find notes
- Search works across titles, content, and categories
- Results update in real-time as you type

### View Modes
- Toggle between Grid and List views using the view icon in the app bar
- Your preference is automatically saved

### Dark Mode
- Toggle dark/light theme using the theme icon in the app bar
- Or use system theme (default)

## License

This project is open source and available under the MIT License.

---

Built with ❤️ using Flutter
