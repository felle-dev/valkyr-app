import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:fassword/home.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
    _checkPlatformAndAuth();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          _authMessage = 'Set up a password to secure your password manager';
          _isSettingPassword = true;
        } else {
          _authMessage = 'Enter your password to continue';
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
          _authMessage = 'Biometric authentication is not available on web';
        });
        return;
      }

      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      setState(() {
        _biometricAvailable = canAuth && isDeviceSupported;
        if (!_biometricAvailable) {
          _authMessage =
              'Biometric authentication is not available on this device';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _skipAuthentication() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Widget _buildPasswordForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: _isSettingPassword ? 'Create Password' : 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) {
            if (_isSettingPassword) {
              // Focus on confirm password field
            } else {
              _verifyPassword();
            }
          },
        ),
        if (_isSettingPassword) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _setPassword(),
          ),
        ],
        const SizedBox(height: 24),
        if (_isAuthenticating)
          CircularProgressIndicator(color: colorScheme.primary)
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSettingPassword ? _setPassword : _verifyPassword,
              icon: Icon(
                _isSettingPassword ? Icons.check : Icons.arrow_forward,
              ),
              label: Text(_isSettingPassword ? 'Set Password' : 'Continue'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24.0 : 48.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 450,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: isSmallScreen ? 48 : 64,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  Text(
                    'Fassword',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your secure password manager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (_authMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _authMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // Desktop: Show password form
                  if (_isDesktop)
                    _buildPasswordForm()
                  // Mobile: Show biometric or skip
                  else if (_biometricAvailable)
                    _isAuthenticating
                        ? CircularProgressIndicator(color: colorScheme.primary)
                        : SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: _authenticateBiometric,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Authenticate'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _skipAuthentication,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
