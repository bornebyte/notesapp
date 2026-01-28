# Notes App - Major Update

## ✅ What's New

### 1. **Password-Based Authentication**
- **Login Screen Updated**: Now uses username/password instead of just API token
- **API Endpoint**: `/api/auth` for password authentication
- **Auto-save Token**: If the API returns a token on login, it's automatically saved
- **Better UX**: More intuitive login flow with proper form validation

### 2. **Settings for API Configuration**
- **Domain Configuration**: Change your API domain at any time
- **API Token Management**: Update your X-API-Token from settings
- **Test Connection**: Built-in tool to test if your domain and token are working
- **Reset to Defaults**: Quick reset button to restore default domain/token
- **Logout Functionality**: Clear authentication and return to login

### 3. **Comprehensive Error Handling**
All API calls now handle these scenarios:
- ❌ **Network Errors**: "No internet connection. Please check your network."
- ❌ **Invalid Domain**: "API endpoint not found. Please check your domain settings."
- ❌ **Invalid Token**: "Invalid credentials or API token. Please check your settings."
- ❌ **Server Errors** (500, 502, 503): "Server error. Please try again later."
- ❌ **Timeout**: "Request timeout. Please check your connection."
- ❌ **Invalid Response**: "Invalid response from server."

### 4. **UI Improvements**
- **Icon Sizes Fixed**: All dashboard icons are now properly sized (reduced from oversized)
  - Welcome card icon: 60 → 40
  - Stat card icons: 28 → 24
  - Quick action icons: 32 → 24
- **Better Visual Balance**: Icons no longer dominate the interface
- **Consistent Sizing**: All icons follow Material Design guidelines

## 🔧 Technical Changes

### API Service (`lib/services/api_service.dart`)
```dart
// New features:
- login(username, password) - Password-based authentication
- testConnection() - Test if domain and token work
- Configurable baseUrl and apiToken from storage
- Comprehensive error handling with ApiException
- All methods include timeout handling (10 seconds)
- Proper error types: 'network', 'auth', 'domain', 'server', 'timeout'
```

### Storage Service (`lib/services/storage_service.dart`)
```dart
// New stored values:
- Domain (default: https://notes.shubham-shah.com.np)
- API Token (default: your current token)
- Authentication state
- Methods: getDomain(), setDomain(), getApiToken(), setApiToken()
- clearAuth() for logout
```

### Login Screen (`lib/screens/login_screen.dart`)
```dart
// Updated to:
- Use username + password fields
- Call /api/auth endpoint
- Display error messages from API
- Save token if returned by API
- Show loading state during authentication
```

### Settings Screen (`lib/screens/settings_screen.dart`) - NEW!
```dart
// Features:
- Theme toggle (Light/Dark/System)
- Domain configuration with validation
- API Token configuration with visibility toggle
- Test Connection button
- Save settings button
- Reset to defaults
- Logout functionality
- About section with version info
```

## 📱 How Configuration Works

### Changing Domain:
1. Go to **Settings** tab (bottom navigation)
2. Scroll to **API Configuration** section
3. Edit the **Domain** field (e.g., `https://your-domain.com`)
4. Click **Test Connection** to verify
5. Click **Save** to apply

### Changing API Token:
1. Go to **Settings** tab
2. Scroll to **API Configuration** section
3. Edit the **API Token** field (show/hide with eye icon)
4. Click **Test Connection** to verify
5. Click **Save** to apply

### Testing Connection:
- Click the **Test Connection** button in settings
- App will try to fetch notes from `/api/notes`
- Shows green success message if connection works
- Shows red error message with details if it fails

## 🛡️ Error Scenarios Handled

| Scenario | Detection | User Message | Type |
|----------|-----------|--------------|------|
| No Internet | SocketException | "No internet connection. Please check your network." | `network` |
| Wrong Domain | 404 | "API endpoint not found. Please check your domain settings." | `domain` |
| Invalid Token | 401/403 | "Invalid credentials or API token. Please check your settings." | `auth` |
| Server Down | 500/502/503 | "Server error. Please try again later." | `server` |
| Slow Network | Timeout (10s) | "Request timeout. Please check your connection." | `timeout` |
| Invalid JSON | FormatException | "Invalid response from server." | `format` |

## 🎯 User Flows

### First Time Login:
1. Welcome Screen (3 seconds)
2. Login Screen
3. Enter username + password
4. App calls `/api/auth`
5. Token saved automatically
6. Navigate to Dashboard

### Configuration Change:
1. Settings → API Configuration
2. Change domain/token
3. Test Connection
4. Save
5. API Service cache cleared
6. All future requests use new settings

### Error Recovery:
1. API call fails
2. ApiException thrown with specific message
3. UI shows error in SnackBar/dialog
4. User can retry or fix settings
5. Settings screen provides tools to fix

## 📦 Files Modified/Created

### Modified:
- `lib/services/api_service.dart` - Added login, error handling, configurable domain/token
- `lib/services/storage_service.dart` - Added domain/token/auth storage
- `lib/screens/login_screen.dart` - Changed to password auth
- `lib/screens/dashboard_screen.dart` - Fixed icon sizes, uses SettingsScreen

### Created:
- `lib/screens/settings_screen.dart` - New comprehensive settings page

## 🚀 Build Status

✅ Flutter analyze: Only 1 minor warning in test file
✅ Linux build: Successful
✅ All API calls: Error handling implemented
✅ Icon sizes: All fixed

## 💡 Usage Examples

### Handling API Errors in UI:
```dart
try {
  await _apiService.login(username, password);
  // Success
} on ApiException catch (e) {
  // Show user-friendly error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```

### Changing Configuration:
```dart
// Save new domain
await _storage.setDomain('https://new-domain.com');
_apiService.clearCache(); // Important!

// Test if it works
final works = await _apiService.testConnection();
```

## 📝 Notes

- All API calls now have **10-second timeouts**
- Domain and token are **cached** for performance
- Cache is **cleared** when settings change
- **Logout** clears token but keeps domain
- **Reset to Defaults** restores original domain and token
- Settings are **persisted** using SharedPreferences
- Error messages are **user-friendly** and actionable

---

## 🎨 UI Changes Summary

| Element | Before | After |
|---------|--------|-------|
| Welcome card icon | 60px | 40px |
| Stat card icons | 28px | 24px |
| Quick action icons | 32px | 24px |
| Login method | API Token only | Username + Password |
| Settings | Inline in dashboard | Dedicated screen |
| Error handling | Generic exceptions | Specific ApiException |
| Domain/Token | Hardcoded | User configurable |

---

Built with ❤️ - Now with better error handling and configuration!
