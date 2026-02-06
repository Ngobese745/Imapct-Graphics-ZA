# Firebase Authentication Setup for Web App

This guide explains how to set up Firebase Authentication for the Impact Graphics ZA web application.

## Prerequisites

1. Firebase project is already configured
2. Web app is registered in Firebase Console
3. Firebase configuration is properly set up

## Firebase Console Setup

### 1. Enable Authentication Methods

1. Go to [Firebase Console](https://console.firebase.google.com/project/impact-graphics-za-266ef/authentication)
2. Navigate to **Authentication** > **Sign-in method**
3. Enable the following providers:

#### Email/Password Authentication
- Click on **Email/Password**
- Toggle **Enable**
- Click **Save**

#### Google Authentication
- Click on **Google**
- Toggle **Enable**
- Add your **Project support email**
- Click **Save**

#### Facebook Authentication (Optional)
- Click on **Facebook**
- Toggle **Enable**
- Add your **App ID** and **App secret**
- Click **Save**

### 2. Configure Authorized Domains

1. In Firebase Console, go to **Authentication** > **Settings**
2. Under **Authorized domains**, add your web app domain:
   - For development: `localhost`
   - For production: `your-domain.com`

### 3. Configure OAuth Redirect Domains

1. In Firebase Console, go to **Authentication** > **Settings**
2. Under **Authorized domains**, ensure your domain is listed
3. For Google Sign-In, the redirect domain will be automatically configured

## Web App Configuration

### 1. Firebase Configuration

The Firebase configuration is already set up in `web/index.html`:

```html
<script type="module">
  import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
  import { getAuth } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";
  
  const firebaseConfig = {
    apiKey: "AIzaSyB9SJ5mONEvTyNoJE0r0a5jhYpsii6WVFk",
    authDomain: "impact-graphics-za-266ef.firebaseapp.com",
    projectId: "impact-graphics-za-266ef",
    storageBucket: "impact-graphics-za-266ef.firebasestorage.app",
    messagingSenderId: "884752435887",
    appId: "1:884752435887:web:b4b282e00a7aa9e652e25a",
    measurementId: "G-TNXEBV03ZJ"
  };
  
  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
</script>
```

### 2. Authentication Service

The authentication service (`lib/services/auth_service.dart`) handles:
- Email/password authentication
- Google Sign-In
- Facebook Sign-In (when configured)
- User profile management
- Error handling

### 3. Web-Specific Configuration

The web authentication configuration (`lib/services/web_auth_config.dart`) provides:
- Web-specific provider configurations
- Popup-based authentication
- Web-specific error messages
- Authentication persistence settings

## Testing Authentication

### 1. Local Development

1. Run the web app locally:
   ```bash
   flutter run -d chrome
   ```

2. Test authentication methods:
   - Email/password sign up and sign in
   - Google Sign-In
   - Facebook Sign-In (if configured)

### 2. Production Testing

1. Deploy the web app to your hosting provider
2. Ensure your domain is added to Firebase authorized domains
3. Test all authentication methods in production

## Troubleshooting

### Common Issues

#### 1. Popup Blocked
- **Issue**: Browser blocks authentication popup
- **Solution**: Allow pop-ups for your domain

#### 2. Domain Not Authorized
- **Issue**: "Domain not authorized" error
- **Solution**: Add your domain to Firebase authorized domains

#### 3. Google Sign-In Not Working
- **Issue**: Google Sign-In fails
- **Solution**: 
  - Ensure Google provider is enabled in Firebase Console
  - Check that your domain is authorized
  - Verify OAuth client configuration

#### 4. Facebook Sign-In Not Working
- **Issue**: Facebook Sign-In fails
- **Solution**:
  - Ensure Facebook provider is enabled in Firebase Console
  - Verify Facebook App ID and App Secret
  - Add your domain to Facebook App settings

### Debug Information

The authentication service provides detailed logging:
- Check browser console for authentication logs
- Look for Firebase authentication events
- Monitor network requests for authentication calls

## Security Considerations

### 1. API Key Security
- The Firebase API key is safe to expose in client-side code
- Firebase security rules protect your data
- Use Firebase Security Rules to control access

### 2. Authentication State
- Authentication state is persisted in the browser
- Users remain signed in across browser sessions
- Sign out clears authentication state

### 3. Error Handling
- Authentication errors are handled gracefully
- User-friendly error messages are displayed
- Failed authentication attempts are logged

## Deployment Checklist

Before deploying to production:

- [ ] Enable all required authentication providers in Firebase Console
- [ ] Add production domain to authorized domains
- [ ] Configure OAuth redirect domains
- [ ] Test all authentication methods
- [ ] Verify error handling works correctly
- [ ] Check authentication persistence
- [ ] Test sign out functionality

## Support

If you encounter issues with Firebase Authentication:

1. Check Firebase Console for configuration issues
2. Review browser console for error messages
3. Verify domain authorization settings
4. Test with different browsers
5. Check Firebase documentation for troubleshooting

## Additional Resources

- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [Firebase Web Setup Guide](https://firebase.google.com/docs/web/setup)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Flutter Firebase Documentation](https://firebase.flutter.dev/)
