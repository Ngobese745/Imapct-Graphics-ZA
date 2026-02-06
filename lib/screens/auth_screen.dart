import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import '../main.dart' show GuestScreen; // Only import GuestScreen
import 'dashboard_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final authService = context.read<AuthService>();
      bool success = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Check if email is admin email
          final email = _emailController.text.toLowerCase();
          if (email.endsWith('@impactgraphicsza.co.za')) {
            // Navigate to admin dashboard for admin emails
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    const DashboardScreen(), // Replace with AdminDashboardScreen when available
              ),
            );
          } else {
            // Navigate to regular dashboard for other users
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B0000), // Dark red
            const Color(0xFF5C0000), // Darker red
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A0000) // Very dark red for dark mode
                : const Color(0xFF3A0000), // Dark red for light mode
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLandscape
                ? _buildLandscapeLayout()
                : _buildPortraitLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      children: [
        // Left Panel - Logo and Branding
        Expanded(
          flex: isMobile ? 1 : 2,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(size: isMobile ? 80 : 120),
                SizedBox(height: isMobile ? 12 : 20),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 6 : 10),
                Text(
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 16 : 24),
                // Additional branding content for landscape
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.login,
                        color: const Color(0xFFFFD700),
                        size: isMobile ? 24 : 32,
                      ),
                      SizedBox(height: isMobile ? 6 : 10),
                      Text(
                        'Access Your Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isMobile ? 3 : 5),
                      Text(
                        'Manage your projects and client relationships',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isMobile ? 12 : 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Panel - Login Form
        Expanded(
          flex: isMobile ? 3 : 2,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Center(
              child: SingleChildScrollView(
                child: Form(key: _formKey, child: _buildLoginForm()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo and Title Section
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: isMobile
                      ? 30
                      : isTablet
                      ? 50
                      : 70,
                ),
                _buildLogo(
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
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: isMobile
                        ? 24
                        : isTablet
                        ? 28
                        : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
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

            // Login Form
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo({double size = 120}) {
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
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8B0000),
          ),
          child: const Icon(Icons.brush, size: 50, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : (isTablet ? 600.0 : 800.0),
          ),
          margin: (isTablet) && !isLandscape
              ? const EdgeInsets.symmetric(horizontal: 20)
              : EdgeInsets.zero,
          padding: EdgeInsets.all(
            isMobile
                ? 16
                : isTablet
                ? 20
                : 24,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.lerp(
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                const Color(0xFF8B0000).withOpacity(0.6),
                _glowAnimation.value,
              )!,
              width: 1.5 + (_glowAnimation.value * 0.5),
            ),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.4,
                ),
                Colors.white.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.02 : 0.2,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(
                  0xFF8B0000,
                ).withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 20 + (_glowAnimation.value * 10),
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: isLandscape ? 20 : (isMobile ? 24 : 28),
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
                  fontSize: isLandscape ? 14 : (isMobile ? 16 : 18),
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: isLandscape ? 16 : (isMobile ? 16 : 24)),

              // Error message
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  if (authService.error != null) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        authService.error!,
                        style: TextStyle(color: Colors.red[300]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
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
                    fontSize: isLandscape ? 14 : (isMobile ? 14 : 16),
                  ),
                  prefixIcon: Icon(
                    Icons.email,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                    size: isLandscape ? 18 : (isMobile ? 20 : 24),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
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
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isLandscape ? 12 : (isMobile ? 12 : 16),
                  ),
                  isDense: isLandscape || isMobile,
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

              SizedBox(height: isLandscape ? 16 : 24),

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
                    fontSize: isLandscape ? 14 : (isMobile ? 14 : 16),
                  ),
                  prefixIcon: Icon(
                    Icons.lock,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                    size: isLandscape ? 18 : (isMobile ? 20 : 24),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      size: isLandscape ? 18 : (isMobile ? 20 : 24),
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
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
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
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isLandscape ? 12 : (isMobile ? 12 : 16),
                  ),
                  isDense: isLandscape || isMobile,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forgot password feature coming soon!'),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: const Color(0xFF8B0000),
                      fontSize: isLandscape ? 12 : (isMobile ? 12 : 14),
                    ),
                  ),
                ),
              ),

              SizedBox(height: isLandscape ? 12 : 12),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: isLandscape ? 44 : (isMobile ? 48 : 56),
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
                          width: isLandscape ? 18 : (isMobile ? 20 : 24),
                          height: isLandscape ? 18 : (isMobile ? 20 : 24),
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
                            fontSize: isLandscape ? 16 : (isMobile ? 16 : 18),
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
                      horizontal: isLandscape ? 12 : (isMobile ? 16 : 24),
                    ),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isLandscape ? 12 : (isMobile ? 12 : 14),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white30)),
                ],
              ),

              SizedBox(height: isLandscape ? 12 : 16),

              // Continue as Guest
              SizedBox(
                width: double.infinity,
                height: isLandscape ? 44 : (isMobile ? 48 : 56),
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const GuestScreen(),
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
                      fontSize: isLandscape ? 14 : (isMobile ? 16 : 18),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: isLandscape ? 12 : 16),

              // Social Login Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              // Handle Google login
                              final authService = context.read<AuthService>();
                              final success = await authService
                                  .signInWithGoogle();

                              if (success && mounted) {
                                // Navigate to dashboard
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DashboardScreen(),
                                  ),
                                );
                              } else if (!success && mounted) {
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      authService.error ??
                                          'Google sign in failed',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      icon: Icon(
                        FontAwesomeIcons.google,
                        size: isLandscape ? 16 : (isMobile ? 18 : 20),
                      ),
                      label: Text(
                        'Google',
                        style: TextStyle(
                          fontSize: isLandscape ? 12 : (isMobile ? 14 : 16),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isLandscape ? 12 : (isMobile ? 12 : 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isLandscape ? 16 : (isMobile ? 24 : 32)),

              // Sign Up Link
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isLandscape ? 12 : (isMobile ? 14 : 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: const Color(0xFF8B0000),
                        fontWeight: FontWeight.bold,
                        fontSize: isLandscape ? 12 : (isMobile ? 14 : 16),
                      ),
                    ),
                  ),
                ],
              ),
              // Add extra bottom padding for Android
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }
}
