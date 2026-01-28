# Notes App - Flutter

A beautiful, feature-rich notes application for Flutter that syncs with your Next.js backend.

## Features

### ✨ Welcome & Authentication
- **Animated Welcome Screen** with your profile photo from `assets/images/me.jpg`
- **Login Screen** with API token authentication
- Smooth transitions and animations
- Theme toggle support

### 📊 Dashboard
- **Beautiful Stats Overview** with cards showing:
  - Total notes count
  - Favorite notes count
  - Notes created this week
  - Unread notifications
- **Time-based Greeting** (Good morning/afternoon/evening)
- **Quick Actions** for creating notes, viewing favorites, and accessing trash
- **Recent Activity Timeline** showing your latest actions
- **Pull-to-refresh** functionality
- **Bottom Navigation Bar** for easy navigation between Dashboard, Notes, and Settings

### 📝 Notes
- **Single-column List View** (no more 2-column grid!)
- **Beautiful Note Cards** with:
  - Title and body preview
  - Category badges
  - Favorite star indicators
  - Relative timestamps (e.g., "2h ago", "3d ago")
- **Advanced Search** with real-time filtering
- **Multiple Views**:
  - All Notes tab
  - Favorites tab
  - Categories tab with note counts
- **Sorting Options**:
  - Recently Updated
  - Recently Created
  - Title (A-Z)
- **Note Editor** with:
  - Simple, distraction-free interface
  - Title and body fields
  - Category support
  - Auto-save indicators
  - Unsaved changes warning

### 🎨 UI/UX Improvements
- **Material Design 3** with modern components
- **Beautiful gradient backgrounds** on welcome and login screens
- **Smooth animations** throughout the app
- **Dark/Light theme support** with toggle in settings
- **Responsive design** for different screen sizes
- **Toast notifications** for user feedback
- **Consistent spacing and typography**

### ⚙️ Settings
- Theme mode toggle (Light/Dark/System)
- Clean, organized settings interface
- Easy access from bottom navigation

## Technical Stack

- **Framework**: Flutter 3.9.2+
- **State Management**: Provider pattern
- **HTTP Client**: http ^1.2.0
- **Local Storage**: shared_preferences ^2.2.2
- **Charts**: fl_chart ^0.69.0
- **Date Formatting**: intl ^0.19.0
- **Toast Notifications**: fluttertoast ^8.2.4

## Backend Integration

- **API Base URL**: https://notes.shubham-shah.com.np
- **Authentication**: X-API-Token header
- **Endpoints**:
  - `GET /api/notes` - Get all notes
  - `GET /api/notes/favorites` - Get favorite notes
  - `GET /api/notes/trash` - Get trashed notes
  - `GET /api/notes/search?q=query` - Search notes
  - `POST /api/notes` - Create note
  - `PUT /api/notes/:id` - Update note
  - `DELETE /api/notes/:id` - Delete note
  - `PATCH /api/notes/:id/favorite` - Toggle favorite
  - `PATCH /api/notes/:id/trash` - Toggle trash
  - `GET /api/dashboard/stats` - Get dashboard statistics
  - `GET /api/notifications` - Get notifications

## Platforms Supported

✅ Android  
✅ Linux  
✅ Windows  
✅ iOS (ready)  
✅ Web (ready)

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Add Your Profile Image**:
   - Place your photo at `assets/images/me.jpg`
   - Or update the path in `welcome_screen.dart`

3. **Configure API Token**:
   - Update the token in `login_screen.dart` (currently pre-filled)
   - Or enter it during login

4. **Build for Your Platform**:
   ```bash
   # For Linux
   flutter build linux --release
   
   # For Android
   flutter build apk --release
   
   # For Windows
   flutter build windows --release
   ```

5. **Run the App**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── note.dart               # Note data model
├── providers/
│   ├── notes_provider.dart     # Notes state management
│   └── theme_provider.dart     # Theme state management
├── screens/
│   ├── welcome_screen.dart     # Animated welcome screen
│   ├── login_screen.dart       # API token login
│   ├── dashboard_screen.dart   # Main dashboard with stats
│   ├── notes_screen.dart       # Notes list view
│   └── note_editor_screen.dart # Note create/edit
├── services/
│   ├── api_service.dart        # HTTP API client
│   └── storage_service.dart    # Local storage
├── utils/
│   └── theme.dart              # Theme configuration
└── widgets/
    └── note_card.dart          # Note card widget
```

## Key Improvements Over Original Design

1. ✅ **Added welcome screen** with photo
2. ✅ **Added login screen** for authentication
3. ✅ **Created beautiful dashboard** with stats and activity
4. ✅ **Changed notes view to single column** (no more grid)
5. ✅ **Improved UI design** with gradients, animations, and better spacing
6. ✅ **Added responsive design** for all screens
7. ✅ **Integrated all backend features** from web app

## Notes

- The app uses **Material Design 3** for a modern look and feel
- All screens are **fully responsive** and work across platforms
- **Animations** are smooth and enhance the user experience
- **Error handling** is implemented for all API calls
- **Loading states** provide feedback during operations

## Future Enhancements

- Add charts for note creation trends (fl_chart integration)
- Implement notification center
- Add inbox/messages feature
- Include targets/goals tracking
- Add productivity metrics
- Implement offline support with local database
- Add note sharing functionality
- Implement rich text editing

---

Built with ❤️ using Flutter
