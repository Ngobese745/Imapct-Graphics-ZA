# Impact Graphics ZA - Flutter App

A professional cross-platform mobile application for Impact Graphics ZA, a leading graphics and design company in South Africa.

## Features

- **Home Screen**: Beautiful hero section with company branding and service previews
- **Services**: Comprehensive list of graphic design services offered
- **Portfolio**: Showcase of previous work and projects
- **Contact**: Contact information, social media links, and contact form
- **Modern UI**: Material Design 3 with dark red accent color (#8B0000)
- **Cross-platform**: Works on iOS, Android, Web, Windows, macOS, and Linux

## Screenshots

The app features a modern, professional design with:
- Gradient hero section with company branding
- Service cards with icons and descriptions
- Portfolio grid layout
- Contact form with social media integration
- Bottom navigation for easy navigation

## Getting Started

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator (for iOS development)
- Android Emulator (for Android development)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd impact_graphics_za
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

#### Desktop
```bash
flutter build windows --release  # Windows
flutter build macos --release    # macOS
flutter build linux --release    # Linux
```

## Project Structure

```
lib/
├── main.dart              # Main app entry point
├── screens/               # App screens (if organized)
│   ├── home_screen.dart
│   ├── services_screen.dart
│   ├── portfolio_screen.dart
│   └── contact_screen.dart
└── widgets/               # Reusable widgets (if organized)
    └── custom_widgets.dart

assets/
├── images/               # Image assets
└── icons/               # Icon assets
```

## Dependencies

- `flutter`: Core Flutter framework
- `cupertino_icons`: iOS-style icons
- `url_launcher`: For opening URLs and launching external apps
- `font_awesome_flutter`: Font Awesome icons
- `cached_network_image`: For efficient image loading and caching
- `flutter_staggered_grid_view`: For advanced grid layouts

## Customization

### Colors
The app uses a dark red accent color (#8B0000) throughout. To change the color scheme:

1. Update the `primaryColor` in `main.dart`
2. Update the `Color(0xFF8B0000)` instances throughout the code
3. Update the `colorScheme` seed color

### Content
- Update company information in the contact section
- Replace placeholder content with actual services and portfolio items
- Add real images to the assets folder
- Update social media links

### Styling
- Modify the theme in `main.dart` for global styling changes
- Update individual widget styles for specific components
- Customize the gradient colors in the hero section

## Features to Add

- [ ] Image gallery for portfolio items
- [ ] Push notifications
- [ ] Offline support
- [ ] User authentication
- [ ] Admin panel for content management
- [ ] Analytics integration
- [ ] Multi-language support
- [ ] Dark mode toggle

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Impact Graphics ZA
- Email: info@impactgraphics.co.za
- Phone: +27 123 456 789
- Address: Johannesburg, South Africa

## Support

For support and questions, please contact the development team or create an issue in the repository.
