import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

// Global theme notifier for app-wide theme switching
ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

// Responsive design utilities
class ResponsiveUtils {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;
  
  // Additional breakpoint for very small screens
  static bool isVerySmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isVerySmallScreen(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  // Responsive font sizes
  static double getTitleFontSize(BuildContext context) {
    if (isVerySmallScreen(context)) return 18.0;
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 24.0;
    return 28.0;
  }

  static double getBodyFontSize(BuildContext context) {
    if (isVerySmallScreen(context)) return 13.0;
    if (isMobile(context)) return 14.0;
    if (isTablet(context)) return 16.0;
    return 18.0;
  }

  static double getSmallFontSize(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 14.0;
    return 16.0;
  }

  // Responsive spacing
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }

  // Responsive card padding
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isVerySmallScreen(context)) return const EdgeInsets.all(12.0);
    if (isMobile(context)) return const EdgeInsets.all(16.0);
    if (isTablet(context)) return const EdgeInsets.all(20.0);
    return const EdgeInsets.all(24.0);
  }

  // Responsive button height
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) return 48.0;
    if (isTablet(context)) return 56.0;
    return 64.0;
  }

  // Responsive icon sizes
  static double getIconSize(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 24.0;
    return 28.0;
  }

  // Responsive container max width
  static double getMaxWidth(BuildContext context) {
    if (isVerySmallScreen(context)) return double.infinity;
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 600.0;
    return 800.0;
  }
}

void main() {
  runApp(const ImpactGraphicsApp());
}

class ImpactGraphicsApp extends StatelessWidget {
  const ImpactGraphicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFC62828),
        brightness: Brightness.light,
      ),
      primaryColor: const Color(0xFFC62828),
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      dividerColor: Colors.black12,
      cardColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.06),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF333333)),
        titleTextStyle: TextStyle(
          color: Color(0xFF333333),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFC62828),
        unselectedItemColor: Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
      ),
      fontFamily: 'Roboto',
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B0000),
        brightness: Brightness.dark,
      ),
      primaryColor: const Color(0xFF8B0000),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      dividerColor: Colors.white10,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2A2A2A),
        selectedItemColor: Color(0xFF8B0000),
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      fontFamily: 'Roboto',
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Impact Graphics ZA',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}

class CustomLogo extends StatelessWidget {
  final double size;

  const CustomLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image is not found
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B6B6B),
              ),
              child: const Icon(Icons.brush, size: 50, color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate login process
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Navigate to dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
            child: Form(
              key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                    // Logo and Title Section
                    Column(
                      children: [
                        SizedBox(
                          height: ResponsiveUtils.isVerySmallScreen(context)
                              ? 20
                              : isMobile
                              ? 32
                              : isTablet
                              ? 48
                              : 64,
                        ),
                        CustomLogo(
                          size: ResponsiveUtils.isVerySmallScreen(context)
                              ? 60
                              : isMobile
                              ? 80
                              : isTablet
                              ? 100
                              : 120,
                        ),
                        SizedBox(
                          height: ResponsiveUtils.isVerySmallScreen(context)
                              ? 12
                              : isMobile
                              ? 16
                              : isTablet
                              ? 24
                              : 32,
                        ),
                        Text(
                          'Impact Graphics ZA',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getTitleFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Professional Graphics & Design Services',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),

                                            SizedBox(
                          height: ResponsiveUtils.isVerySmallScreen(context)
                              ? 20
                              : isMobile
                              ? 32
                              : isTablet
                              ? 48
                              : 64,
                        ),

                    // Login Form
                Container(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveUtils.getMaxWidth(context),
                        ),
                        margin: isTablet || isDesktop
                            ? const EdgeInsets.symmetric(horizontal: 20)
                            : EdgeInsets.zero,
                        padding: ResponsiveUtils.getCardPadding(context),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black12,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to your account',
                            style: TextStyle(
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(
                            height: isMobile
                                ? 16
                                : isTablet
                                ? 24
                                : 32,
                          ),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                            color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                                size: ResponsiveUtils.getIconSize(context),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white30
                                      : Colors.black12,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white30
                                      : Colors.black12,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8B0000),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                            vertical: isMobile ? 12 : isTablet ? 16 : 20,
                          ),
                          isDense: isMobile,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                              ),
                              prefixIcon: Icon(
                                Icons.lock,
                            color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                                size: ResponsiveUtils.getIconSize(context),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                              color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                  size: ResponsiveUtils.getIconSize(context),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white30
                                      : Colors.black12,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white30
                                      : Colors.black12,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8B0000),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                            vertical: isMobile ? 12 : isTablet ? 16 : 20,
                          ),
                          isDense: isMobile,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Handle forgot password
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: const Color(0xFF8B0000),
                              fontSize: ResponsiveUtils.getSmallFontSize(context),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                        height: isMobile ? 48 : isTablet ? 56 : 64,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B0000),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                  width: ResponsiveUtils.getIconSize(context),
                                  height: ResponsiveUtils.getIconSize(context),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: TextStyle(
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Divider
                          Row(
                            children: [
                          const Expanded(child: Divider(color: Colors.white30)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 16 : 24,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.white70,
                                fontSize: ResponsiveUtils.getSmallFontSize(context),
                                    ),
                                  ),
                                ),
                          const Expanded(child: Divider(color: Colors.white30)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Continue as Guest
                          SizedBox(
                            width: double.infinity,
                            height: ResponsiveUtils.getButtonHeight(context),
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                      builder: (context) => const DashboardScreen(),
                                        ),
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Continue as Guest',
                                style: TextStyle(
                              fontSize: ResponsiveUtils.getBodyFontSize(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Social Login Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Handle Google login
                                    },
                                    icon: Icon(
                                      FontAwesomeIcons.google,
                                      size: ResponsiveUtils.getIconSize(context) - 4,
                                    ),
                                    label: Text(
                                      'Google',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white30),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 16 : 20,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 16 : 24),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Handle Facebook login
                                    },
                                    icon: Icon(
                                      FontAwesomeIcons.facebook,
                                      size: ResponsiveUtils.getIconSize(context) - 4,
                                    ),
                                    label: Text(
                                      'Facebook',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white30),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 16 : 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          SizedBox(
                        height: isMobile ? 24 : isTablet ? 32 : 40,
                          ),

                          // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.white70,
                              fontSize: ResponsiveUtils.getBodyFontSize(context),
                                  ),
                                ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: const Color(0xFF8B0000),
                                    fontWeight: FontWeight.bold,
                                fontSize: ResponsiveUtils.getBodyFontSize(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                  height: isMobile ? 24 : isTablet ? 40 : 48,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() {
        _isLoading = true;
      });

      // Simulate sign up process
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Navigate to dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      });
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and Title Section
                Column(
                  children: [
                    SizedBox(
                      height: isMobile
                          ? 20
                          : isTablet
                          ? 40
                          : 60,
                    ),
                    CustomLogo(
                      size: isMobile
                          ? 80
                          : isTablet
                          ? 100
                          : 120,
                    ),
                    SizedBox(
                      height: isMobile
                          ? 20
                          : isTablet
                          ? 30
                          : 40,
                    ),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getTitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Impact Graphics ZA today',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                SizedBox(
                  height: isMobile
                      ? 30
                      : isTablet
                      ? 40
                      : 50,
                ),

                // Sign Up Form
                Container(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveUtils.getMaxWidth(context),
                  ),
                  margin: isTablet || isDesktop
                      ? const EdgeInsets.symmetric(horizontal: 20)
                      : EdgeInsets.zero,
                  padding: ResponsiveUtils.getCardPadding(context),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black12,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Name Fields Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white30,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white30,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF8B0000),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1A1A1A),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white30,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white30,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF8B0000),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1A1A1A),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Colors.white70,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8B0000),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.white70,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8B0000),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.white70,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8B0000),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (!RegExp(
                            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
                          ).hasMatch(value)) {
                            return 'Password must contain uppercase, lowercase & number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.white70,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8B0000),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Terms and Conditions
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF8B0000),
                            checkColor: Colors.white,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreeToTerms = !_agreeToTerms;
                                });
                              },
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: TextStyle(
                                        color: Color(0xFF8B0000),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Color(0xFF8B0000),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white30)),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  ResponsiveUtils.getSpacing(context) * 2,
                            ),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: ResponsiveUtils.getSmallFontSize(
                                  context,
                                ),
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white30)),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Social Sign Up Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Handle Google sign up
                              },
                              icon: const Icon(
                                FontAwesomeIcons.google,
                                size: 18,
                              ),
                              label: const Text('Google'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Handle Facebook sign up
                              },
                              icon: const Icon(
                                FontAwesomeIcons.facebook,
                                size: 18,
                              ),
                              label: const Text('Facebook'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFF8B0000),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final List<UpdateItem> _updates = [
    UpdateItem(
      id: '1',
      title: 'Project Status Update',
      message: 'Your logo design project has been completed and is ready for review.',
      type: UpdateType.project,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    UpdateItem(
      id: '2',
      title: 'New Service Available',
      message: 'We\'ve added 3D modeling services to our portfolio. Check it out!',
      type: UpdateType.service,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    UpdateItem(
      id: '3',
      title: 'Payment Received',
      message: 'Payment of R2,500 has been received for your recent project.',
      type: UpdateType.payment,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: _updates.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Updates title with mark all read button
                Padding(
                  padding: ResponsiveUtils.getScreenPadding(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Updates',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.mark_email_read,
                          size: ResponsiveUtils.getIconSize(context),
                        ),
                        onPressed: () {
                          setState(() {
                            for (var update in _updates) {
                              update.isRead = true;
                            }
                          });
                        },
                        tooltip: 'Mark all as read',
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ],
                  ),
                ),
                // Updates list
                Expanded(
                  child: ListView.builder(
                    padding: ResponsiveUtils.getScreenPadding(context),
                    itemCount: _updates.length,
                    itemBuilder: (context, index) {
                      final update = _updates[index];
                      return _buildUpdateCard(update);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUpdateCard(UpdateItem update) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context) * 2),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.white10)
            : Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            update.isRead = true;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: ResponsiveUtils.getCardPadding(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Update type icon
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context)),
                decoration: BoxDecoration(
                  color: _getUpdateTypeColor(update.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getUpdateTypeIcon(update.type),
                  color: _getUpdateTypeColor(update.type),
                  size: ResponsiveUtils.getIconSize(context),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(context) * 2),

              // Update content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            update.title,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getBodyFontSize(context),
                              fontWeight: update.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (!update.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B0000),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context)),
                    Text(
                      update.message,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context) * 1.5),
                    Text(
                      _formatTimestamp(update.timestamp),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getSmallFontSize(context) - 2,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context) * 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: ResponsiveUtils.getIconSize(context) * 3,
              color: const Color(0xFF8B0000),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context) * 3),
          Text(
            'No Updates Yet',
            style: TextStyle(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          Text(
            'You\'ll see all your updates and notifications here',
            style: TextStyle(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getUpdateTypeColor(UpdateType type) {
    switch (type) {
      case UpdateType.project:
        return const Color(0xFF8B0000);
      case UpdateType.service:
        return Colors.blue;
      case UpdateType.payment:
        return Colors.green;
      case UpdateType.system:
        return Colors.orange;
      case UpdateType.loyalty:
        return const Color(0xFFFFD700);
    }
  }

  IconData _getUpdateTypeIcon(UpdateType type) {
    switch (type) {
      case UpdateType.project:
        return Icons.work;
      case UpdateType.service:
        return Icons.add_circle;
      case UpdateType.payment:
        return Icons.payment;
      case UpdateType.system:
        return Icons.system_update;
      case UpdateType.loyalty:
        return Icons.star;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

enum UpdateType { project, service, payment, system, loyalty }

class UpdateItem {
  final String id;
  final String title;
  final String message;
  final UpdateType type;
  final DateTime timestamp;
  bool isRead;

  UpdateItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<CartItem> _cartItems = [
    CartItem(
      id: '1',
      name: 'Logo Design Package',
      description: 'Professional logo design with 3 revisions',
      price: 299.00,
      quantity: 1,
      image: 'assets/images/logo.png',
    ),
    CartItem(
      id: '2',
      name: 'Business Card Design',
      description: 'Custom business card design',
      price: 99.00,
      quantity: 1,
      image: 'assets/images/logo.png',
    ),
  ];

  double get _totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _updateQuantity(String id, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        final item = _cartItems.firstWhere((item) => item.id == id);
        item.quantity = newQuantity;
      });
    }
  }

  void _removeItem(String id) {
    setState(() {
      _cartItems.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: ResponsiveUtils.getScreenPadding(context),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
                _buildCheckoutSection(),
              ],
            ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF8B0000).withOpacity(0.1),
            ),
            child: const Icon(
              Icons.brush,
              color: Color(0xFF8B0000),
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'R${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B0000),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _updateQuantity(item.id, item.quantity - 1),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: const Color(0xFF8B0000),
                        ),
                        Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _updateQuantity(item.id, item.quantity + 1),
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFF8B0000),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeItem(item.id),
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              Text(
                'R${_totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B0000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proceeding to checkout...'),
                    backgroundColor: Color(0xFF8B0000),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some services to get started',
            style: TextStyle(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to services
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Browse Services',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final String id;
  final String name;
  final String description;
  final double price;
  int quantity;
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.image,
  });
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      type: TransactionType.credit,
      amount: 2500.00,
      description: 'Payment received for Logo Design',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '2',
      type: TransactionType.debit,
      amount: 299.00,
      description: 'Gold Tier subscription',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Transaction(
      id: '3',
      type: TransactionType.credit,
      amount: 1500.00,
      description: 'Payment received for Business Cards',
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  double get _balance {
    return _transactions.fold(0, (sum, transaction) {
      return sum + (transaction.type == TransactionType.credit ? transaction.amount : -transaction.amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Wallet',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B0000), Color(0xFFB22222)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B0000).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'R${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle withdraw
                        },
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text('Withdraw'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8B0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle add funds
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Funds'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8B0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getTitleFontSize(context),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all transactions
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF8B0000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildTransactionItem(transaction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: transaction.type == TransactionType.credit
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.type == TransactionType.credit
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: transaction.type == TransactionType.credit
                  ? Colors.green
                  : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.date),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.type == TransactionType.credit ? '+' : '-'}R${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              fontWeight: FontWeight.bold,
              color: transaction.type == TransactionType.credit
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });
}

enum TransactionType { credit, debit }

class ServiceHubScreen extends StatefulWidget {
  const ServiceHubScreen({super.key});

  @override
  State<ServiceHubScreen> createState() => _ServiceHubScreenState();
}

class _ServiceHubScreenState extends State<ServiceHubScreen> {
  final PageController _packagePageController = PageController(initialPage: 1); // Start with Growth (index 1)
  int _currentPackagePage = 1;

  final List<MarketingPackage> _marketingPackages = [
    MarketingPackage(
      id: '1',
      name: 'Starter',
      icon: '⭐',
      price: 1500.00,
      originalPrice: 500.00,
      period: 'month',
      isPopular: false,
      features: [
        'Basic Social Media Management',
        '5 Graphic Designs/month',
        'Content Creation',
        'Monthly Analytics Report',
        'Email Support',
      ],
      color: const Color(0xFF8B0000),
    ),
    MarketingPackage(
      id: '2',
      name: 'Growth',
      icon: '🚀',
      price: 3000.00,
      originalPrice: 800.00,
      period: 'month',
      isPopular: true,
      features: [
        'Advanced Social Media Management',
        '10 Graphic Designs/month',
        'Content Strategy',
        'Basic SEO',
        'Weekly Analytics Report',
        'Priority Support',
      ],
      color: const Color(0xFF8B0000),
    ),
    MarketingPackage(
      id: '3',
      name: 'Premium',
      icon: '👑',
      price: 5000.00,
      originalPrice: 1499.00,
      period: 'month',
      isPopular: false,
      features: [
        'Full Social Media Management',
        'Unlimited Graphic Designs',
        'Comprehensive Content Strategy',
        'Advanced SEO',
        'Website Maintenance',
        '24/7 Support',
        'Monthly Strategy Session',
      ],
      color: const Color(0xFF8B0000),
    ),
  ];

  final List<ServiceCategory> _serviceCategories = [
    ServiceCategory(
      id: '1',
      name: 'Graphic Design',
      description: 'Professional graphic design services',
      icon: Icons.brush,
      color: const Color(0xFF8B0000),
      services: [
        Service(
          id: '1',
          name: 'Logo Design',
          description: 'Custom logo design with 3 revisions',
          price: 299.00,
          duration: '3-5 days',
          features: ['3 revisions', 'Source files', 'Multiple formats', 'Brand guidelines'],
        ),
        Service(
          id: '2',
          name: 'Business Card Design',
          description: 'Professional business card design',
          price: 99.00,
          duration: '1-2 days',
          features: ['Print-ready files', 'Multiple designs', 'Quick turnaround'],
        ),
        Service(
          id: '3',
          name: 'Brochure Design',
          description: 'Marketing brochure and flyer design',
          price: 199.00,
          duration: '2-3 days',
          features: ['Print-ready files', 'Multiple layouts', 'Professional design'],
        ),
      ],
    ),
    ServiceCategory(
      id: '2',
      name: 'Digital Marketing',
      description: 'Comprehensive digital marketing solutions',
      icon: Icons.trending_up,
      color: const Color(0xFF2196F3),
      services: [
        Service(
          id: '4',
          name: 'Social Media Management',
          description: 'Complete social media management',
          price: 599.00,
          duration: 'Ongoing',
          features: ['Content creation', 'Daily posting', 'Analytics reports', 'Engagement management'],
        ),
        Service(
          id: '5',
          name: 'Google Ads Campaign',
          description: 'Professional Google Ads management',
          price: 399.00,
          duration: 'Ongoing',
          features: ['Campaign setup', 'Keyword research', 'Performance tracking', 'Monthly reports'],
        ),
      ],
    ),
    ServiceCategory(
      id: '3',
      name: 'Web Development',
      description: 'Modern web development services',
      icon: Icons.web,
      color: const Color(0xFF4CAF50),
      services: [
        Service(
          id: '6',
          name: 'Website Design',
          description: 'Custom website design and development',
          price: 1299.00,
          duration: '2-3 weeks',
          features: ['Responsive design', 'SEO optimized', 'Content management', 'Hosting setup'],
        ),
        Service(
          id: '7',
          name: 'E-commerce Website',
          description: 'Online store development',
          price: 1999.00,
          duration: '3-4 weeks',
          features: ['Payment integration', 'Inventory management', 'Order tracking', 'Admin panel'],
        ),
      ],
    ),
    ServiceCategory(
      id: '4',
      name: 'Print Services',
      description: 'Professional printing and production',
      icon: Icons.print,
      color: const Color(0xFFFF9800),
      services: [
        Service(
          id: '8',
          name: 'Business Cards Printing',
          description: 'High-quality business card printing',
          price: 149.00,
          duration: '3-5 days',
          features: ['Premium paper', 'UV coating', 'Quick turnaround', 'Free delivery'],
        ),
        Service(
          id: '9',
          name: 'Banner Printing',
          description: 'Large format banner printing',
          price: 299.00,
          duration: '1-2 days',
          features: ['High resolution', 'Weather resistant', 'Various sizes', 'Installation available'],
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _packagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Service Hub',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getTitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional graphics and design solutions for your business',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Marketing Packages Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Marketing Packages Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B0000).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '📦',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Marketing Packages',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the best plan for your business growth',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Package Cards - Swipeable
                  SizedBox(
                    height: 450,
                    child: PageView.builder(
                      controller: _packagePageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPackagePage = index;
                        });
                      },
                      itemCount: _marketingPackages.length,
                      itemBuilder: (context, index) {
                        final package = _marketingPackages[index];
                        final isActive = index == _currentPackagePage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(
                            horizontal: isActive ? 16 : 32,
                            vertical: isActive ? 20 : 40,
                          ),
                          child: _buildPackageCard(package, isActive),
                        );
                      },
                    ),
                  ),
                  
                  // Page Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_marketingPackages.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentPackagePage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentPackagePage
                                ? const Color(0xFF8B0000)
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  // Get Started Button
                  Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _selectPackage(_marketingPackages[_currentPackagePage]);
                        },
                        icon: const Text('🚀', style: TextStyle(fontSize: 18)),
                        label: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.black12,
                thickness: 1,
              ),
            ),
            
            // Service Categories Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Individual Services',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            
            // Service Categories
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _serviceCategories.length,
              itemBuilder: (context, index) {
                final category = _serviceCategories[index];
                return _buildServiceCategory(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategory(ServiceCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Services List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: category.services.length,
            itemBuilder: (context, index) {
              final service = category.services[index];
              return _buildServiceItem(service, category.color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Service service, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${service.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                  Text(
                    service.duration,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getSmallFontSize(context),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Features
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: service.features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getSmallFontSize(context) - 2,
                    color: categoryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Handle view details
                    _showServiceDetails(service);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: categoryColor,
                    side: BorderSide(color: categoryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle add to cart
                    _addToCart(service);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showServiceDetails(Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getTitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getSmallFontSize(context),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              'R${service.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getTitleFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8B0000),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getSmallFontSize(context),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              service.duration,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getBodyFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'What\'s Included',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...service.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getBodyFontSize(context),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _addToCart(service);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Service service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${service.name} added to cart'),
        backgroundColor: const Color(0xFF8B0000),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to cart
          },
        ),
      ),
    );
  }

  Widget _buildPackageCard(MarketingPackage package, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: package.isPopular
              ? const Color(0xFF8B0000)
              : const Color(0xFF8B0000).withOpacity(0.3),
          width: package.isPopular ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isActive ? 0.25 : 0.15),
            blurRadius: isActive ? 25 : 15,
            offset: Offset(0, isActive ? 12 : 8),
            spreadRadius: isActive ? 2 : 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : Colors.white,
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFF8F9FA),
          ],
        ),
      ),
      child: Column(
        children: [
          // Popular Badge
          if (package.isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B0000).withOpacity(0.9),
                    const Color(0xFFB22222).withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B0000).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Most Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.getSmallFontSize(context),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Package Name
                  Text(
                    package.name,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getTitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: package.isPopular
                          ? const Color(0xFF8B0000)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Pricing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF8B0000).withOpacity(0.1),
                          const Color(0xFF8B0000).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8B0000).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'R${package.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B0000),
                          ),
                        ),
                        Text(
                          'Setup Fee',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getSmallFontSize(context),
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R${package.originalPrice.toStringAsFixed(0)}/${package.period}',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          'Ongoing',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getSmallFontSize(context),
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Features List
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: package.features.map((feature) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white70
                                        : Colors.black54,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPackage(MarketingPackage package) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Select ${package.name}',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'ve selected the ${package.name} package with R${package.price.toStringAsFixed(0)} setup fee and R${package.originalPrice.toStringAsFixed(0)}/${package.period} ongoing.',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This package includes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...package.features.take(3).map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Color(0xFF4CAF50), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              if (package.features.length > 3)
                Text(
                  '... and ${package.features.length - 3} more features',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${package.name} package added to cart'),
                    backgroundColor: const Color(0xFF8B0000),
                    action: SnackBarAction(
                      label: 'View Cart',
                      textColor: Colors.white,
                      onPressed: () {
                        // Navigate to cart
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<Service> services;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.services,
  });
}

class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final String duration;
  final List<String> features;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.features,
  });
}

class MarketingPackage {
  final String id;
  final String name;
  final String icon;
  final double price;
  final double originalPrice;
  final String period;
  final bool isPopular;
  final List<String> features;
  final Color color;

  MarketingPackage({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.originalPrice,
    required this.period,
    required this.isPopular,
    required this.features,
    required this.color,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFF9F9F9),
      drawer: _buildDrawer(),
      body: _currentIndex == 0
          ? ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, themeMode, child) {
                return SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      // Header Section (scrolls with content)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: ResponsiveUtils.getScreenPadding(context),
                          child: Column(
                            children: [
                              // Top Row with Menu, Profile, and Refresh
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Profile Picture
                                  Container(
                                    width: isMobile
                                        ? 32
                                        : isTablet
                                        ? 40
                                        : 48,
                                    height: isMobile
                                        ? 32
                                        : isTablet
                                        ? 40
                                        : 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF8B0000),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: isMobile
                                          ? 18
                                          : isTablet
                                          ? 22
                                          : 24,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        ResponsiveUtils.getSpacing(context) *
                                        1.5,
                                  ),
                                  // Profile Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Colane Ngobese',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize:
                                                ResponsiveUtils.getBodyFontSize(
                                                  context,
                                                ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Silver Tier • Client',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white70
                                                : const Color(0xFF666666),
                                            fontSize:
                                                ResponsiveUtils.getSmallFontSize(
                                                  context,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Theme Switcher Button
                                  IconButton(
                                    icon: Icon(
                                      themeMode == ThemeMode.dark
                                          ? Icons.light_mode
                                          : Icons.dark_mode,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                      size: ResponsiveUtils.getIconSize(
                                        context,
                                      ),
                                    ),
                                    onPressed: () {
                                      themeModeNotifier.value =
                                          themeMode == ThemeMode.dark
                                          ? ThemeMode.light
                                          : ThemeMode.dark;
                                    },
                                  ),
                                  SizedBox(
                                    width: ResponsiveUtils.getSpacing(context),
                                  ),
                                  // Hamburger Menu moved to right
                                  IconButton(
                                    icon: Icon(
                                      Icons.menu,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                      size: ResponsiveUtils.getIconSize(
                                        context,
                                      ),
                                    ),
                                    onPressed: () {
                                      _scaffoldKey.currentState?.openDrawer();
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ResponsiveUtils.getSpacing(context),
                              ),
                              // Summary Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Total Projects',
                                      value: '2',
                                      icon: Icons.track_changes,
                                    ),
                                  ),
                                  SizedBox(
                                    width: ResponsiveUtils.getSpacing(context),
                                  ),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Services Used',
                                      value: '1',
                                      icon: Icons.network_check,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Main Content
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Services Section
                              _buildSectionTitle('Services'),
                              const SizedBox(height: 16),
                              _buildMarketingServiceCard(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSmallServiceCard(
                                      'Leasing',
                                      'Gadgets & Equipment',
                                      Icons.phone_android,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSmallServiceCard(
                                      'Development',
                                      'Apps & Websites',
                                      Icons.grid_view,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSmallServiceCard(
                                      'My Orders',
                                      'Track & Manage',
                                      Icons.receipt_long,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              // Updates & Activity Section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle('Updates & Activity'),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _currentIndex = 1;
                                      });
                                    },
                                    child: const Text(
                                      'View All',
                                      style: TextStyle(
                                        color: Color(0xFF8B0000),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildActivityCard(
                                'Order #ORD-20250719-9012',
                                'Order status updated to Pending',
                                'status_update',
                              ),
                              const SizedBox(height: 12),
                              _buildActivityCard(
                                'Update',
                                'Your Gold Tier invoice (#INV-20250719-415) for R299 has been generated. Please p...',
                                'auto_response',
                              ),
                              const SizedBox(height: 12),
                              _buildActivityCard(
                                'Update',
                                'Your Gold Tier membership is now active. Your first payment of R299 is due in 7 ...',
                                'auto_response',
                              ),
                              const SizedBox(height: 32),
                              // Personal Dashboard Section with background
                              _buildPersonalDashboardSection(),
                              const SizedBox(height: 20),
                              // Resources & Docs and Chat Support cards (outside Personal Dashboard)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSupportCard(
                                      'Resources & Docs',
                                      'Everything you\'ve received from us',
                                      Icons.description,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSupportCard(
                                      'Chat Support',
                                      'Get Help & Feedback',
                                      Icons.chat_bubble,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Referral Card
                              _buildReferralCard(),
                              const SizedBox(height: 16),
                              // Gold Tier Trial Card
                              _buildGoldTierCard(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : _currentIndex == 1
              ? const UpdatesScreen()
          : _currentIndex == 2
                  ? const CartScreen()
          : _currentIndex == 3
                      ? const WalletScreen()
          : const SizedBox.shrink(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.white10)
            : Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFC62828), size: 16),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666),
                fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
            fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
      fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget _buildMarketingServiceCard() {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ServiceHubScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF8B0000),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Marketing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Branding & Campaigns', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Your preferred service • 2 active projects', 
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallServiceCard(String title, String subtitle, IconData icon) {
    return Container(
        height: 75,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Theme.of(context).brightness == Brightness.dark
              ? Border.all(color: Colors.white10)
              : Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFC62828).withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
              child: Icon(icon, color: const Color(0xFFC62828), size: 16),
            ),
            const SizedBox(height: 4),
          Text(title, style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
            fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 1),
          Text(subtitle, style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666),
            fontSize: 8), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String header, String content, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.white10)
            : Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(header, style: const TextStyle(color: Color(0xFFC62828), fontSize: 14, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : const Color(0xFFC62828).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(label, style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666),
                  fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
            fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: isDark ? Colors.white70 : const Color(0xFF666666),
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Updates'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }

  Widget _buildPersonalDashboardSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF2B2B2B), const Color(0xFF1F1F1F)]
              : [Colors.white, const Color(0xFFF8F9FA)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.white10)
            : Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
          blurRadius: 12, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Dashboard', style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
            fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryCard(title: 'Active Projects', value: '2', icon: Icons.work)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(title: 'Wallet', value: 'R3000.00', icon: Icons.account_balance_wallet)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loyalty Points', style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666),
                fontSize: 14, fontWeight: FontWeight.w500)),
              Text('60 / 2,000', style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
                fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(String title, String subtitle, IconData icon) {
    return Container(
      height: 80, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.white10)
            : Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFC62828).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFFC62828), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
                  fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666),
                  fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard() {
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFB22222), Color(0xFF8B0000)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.10),
          blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.share, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                Text('Silver Tier Referrals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                Text('Share your code & earn exclusive discounts', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2))),
                child: const Text('EARN UP TO 15% OFF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, color: Colors.white, size: 22),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildGoldTierCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 1),
        boxShadow: [BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
          blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFD700), shape: BoxShape.circle),
                child: const Icon(Icons.star, color: Colors.black, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 4),
                    Text('Gold Tier Trial', style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFFD700) : const Color(0xFF333333),
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(12)),
                child: const Text('TRIAL ACTIVE', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildBenefitItem('10% discount on all services'),
              const SizedBox(height: 8),
              _buildBenefitItem('Priority support & faster response'),
              const SizedBox(height: 8),
              _buildBenefitItem('Exclusive access to premium features'),
              const SizedBox(height: 8),
              _buildBenefitItem('Double loyalty points on every purchase'),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const Text('Free Trial - 7 Days', style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Payment of R299 due after trial • Enjoy premium benefits!', 
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                    fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.workspace_premium, color: Colors.black, size: 18),
              label: const Text('PAY NOW', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF333333),
          fontSize: 13))),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06)),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.4),
                Colors.white.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.02 : 0.2),
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, themeMode, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          gradient: LinearGradient(colors: [const Color(0xFF8B0000).withOpacity(0.2), Colors.transparent],
                            begin: Alignment.topLeft, end: Alignment.bottomRight)),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8B0000)),
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Colane Ngobese', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                      Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF8B0000).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Silver Tier', style: TextStyle(color: Color(0xFF8B0000), fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            _buildSectionLabel('Browse'),
                            const SizedBox(height: 6),
                            _buildDrawerItem(icon: Icons.grid_view, label: 'Services', onTap: () {
                                Navigator.of(context).pop();
                                setState(() => _currentIndex = 0);
                            }),
                            _buildDrawerItem(icon: Icons.notifications, label: 'Updates', onTap: () {
                                Navigator.of(context).pop();
                                setState(() => _currentIndex = 1);
                            }),
                            _buildDrawerItem(icon: Icons.shopping_cart, label: 'Cart', onTap: () {
                                Navigator.of(context).pop();
                                setState(() => _currentIndex = 2);
                            }),
                            _buildDrawerItem(icon: Icons.account_balance_wallet, label: 'Wallet', onTap: () {
                                Navigator.of(context).pop();
                                setState(() => _currentIndex = 3);
                            }),
                            const SizedBox(height: 14),
                            _buildSectionLabel('Support'),
                            const SizedBox(height: 8),
                            _buildDrawerItem(icon: Icons.description, label: 'Resources & Docs', onTap: () => Navigator.of(context).pop()),
                            _buildDrawerItem(icon: Icons.chat_bubble, label: 'Chat Support', onTap: () => Navigator.of(context).pop()),
                            const SizedBox(height: 14),
                            _buildSectionLabel('Preferences'),
                            const SizedBox(height: 6),
                            _buildDrawerItem(
                              icon: themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                              label: themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                              trailing: Switch(
                                value: themeMode == ThemeMode.dark ? false : true,
                                activeColor: const Color(0xFF8B0000),
                                onChanged: (value) => themeModeNotifier.value = value ? ThemeMode.light : ThemeMode.dark,
                              ),
                              onTap: () => themeModeNotifier.value = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String label, required VoidCallback onTap, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: trailing,
      onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}