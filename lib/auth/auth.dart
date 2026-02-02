import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:valkyr/home.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isAuthenticating = false;
  bool _biometricAvailable = false;
  bool _isDesktop = false;
  bool _hasStoredPassword = false;
  bool _isSettingPassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _authMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkPlatformAndAuth();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPlatformAndAuth() async {
    // Check if running on desktop
    _isDesktop =
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (_isDesktop) {
      await _checkStoredPassword();
    } else {
      await _checkBiometricAvailability();
    }
  }

  Future<void> _checkStoredPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString('password_hash');

      setState(() {
        _hasStoredPassword = storedHash != null;
        if (!_hasStoredPassword) {
          _authMessage = 'Create a password to secure your vault';
          _isSettingPassword = true;
        } else {
          _authMessage = 'Welcome back';
        }
      });
    } catch (e) {
      setState(() {
        _authMessage = 'Error checking password: $e';
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      if (kIsWeb) {
        setState(() {
          _biometricAvailable = false;
          _authMessage = 'Biometric authentication unavailable on web';
        });
        return;
      }

      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      setState(() {
        _biometricAvailable = canAuth && isDeviceSupported;
        if (_biometricAvailable) {
          _authMessage = 'Unlock to continue';
        } else {
          _authMessage = 'Biometric authentication unavailable';
        }
      });
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
        _authMessage = 'Unable to check biometric availability';
      });
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _setPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showError('Please enter a password');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final hashedPassword = _hashPassword(password);
      await prefs.setString('password_hash', hashedPassword);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError('Failed to save password: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _verifyPassword() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString('password_hash');
      final enteredHash = _hashPassword(password);

      if (storedHash == enteredHash) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        _showError('Incorrect password');
      }
    } catch (e) {
      _showError('Authentication error: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _authenticateBiometric() async {
    setState(() => _isAuthenticating = true);

    try {
      if (kIsWeb || !_biometricAvailable) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError('Authentication error: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.colorScheme.errorContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _skipAuthentication() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Widget _buildPasswordForm(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Password field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: theme.textTheme.bodyLarge,
          autofocus: !_isSettingPassword,
          decoration: InputDecoration(
            labelText: _isSettingPassword ? 'Create password' : 'Password',
            hintText: 'Enter password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onFieldSubmitted: (_) {
            if (!_isSettingPassword) {
              _verifyPassword();
            }
          },
        ),

        // Confirm password field (only when setting)
        if (_isSettingPassword) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              hintText: 'Re-enter password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onFieldSubmitted: (_) => _setPassword(),
          ),
          const SizedBox(height: 8),
          Text(
            'Password must be at least 6 characters',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Submit button
        FilledButton(
          onPressed: _isAuthenticating
              ? null
              : (_isSettingPassword ? _setPassword : _verifyPassword),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isAuthenticating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isSettingPassword ? 'Create password' : 'Unlock'),
        ),
      ],
    );
  }

  Widget _buildBiometricButton(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _isAuthenticating ? null : _authenticateBiometric,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isAuthenticating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unlock with biometrics'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // App icon with Material You style
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App name
                    Text(
                      'Valkyr',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle/Message
                    Text(
                      _authMessage.isNotEmpty
                          ? _authMessage
                          : 'Your secure password manager',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Authentication form card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _isDesktop
                            ? _buildPasswordForm(theme)
                            : _biometricAvailable
                            ? _buildBiometricButton(theme)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Icon(
                                    Icons.lock_open_outlined,
                                    size: 48,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No authentication required',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton(
                                    onPressed: _skipAuthentication,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Continue'),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
