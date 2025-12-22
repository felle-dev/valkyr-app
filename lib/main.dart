import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

void main() {
  runApp(const FasswordApp());
}

// ==================== MODELS ====================

class PasswordEntry {
  String id;
  String website;
  String username;
  String password;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  PasswordEntry({
    required this.id,
    required this.website,
    required this.username,
    required this.password,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'website': website,
    'username': username,
    'password': password,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
    id: json['id'],
    website: json['website'],
    username: json['username'],
    password: json['password'],
    notes: json['notes'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

// ==================== SERVICES ====================

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  final String _passwordsKey = 'encrypted_passwords';

  Future<void> savePasswords(List<PasswordEntry> passwords) async {
    final jsonData = jsonEncode(passwords.map((p) => p.toJson()).toList());
    await _storage.write(key: _passwordsKey, value: jsonData);
  }

  Future<List<PasswordEntry>> getPasswords() async {
    final jsonData = await _storage.read(key: _passwordsKey);
    if (jsonData == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonData);
    return decoded.map((p) => PasswordEntry.fromJson(p)).toList();
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

// ==================== GLASSY CARD WIDGET ====================

class GlassyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GlassyCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(20);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
              borderRadius: effectiveBorderRadius,
            ),
            child: Material(
              color: Colors.transparent,
              child: onTap != null
                  ? InkWell(
                      onTap: onTap,
                      borderRadius: effectiveBorderRadius,
                      child: Padding(
                        padding: padding ?? EdgeInsets.zero,
                        child: child,
                      ),
                    )
                  : Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== MAIN APP ====================

class FasswordApp extends StatelessWidget {
  const FasswordApp({Key? key}) : super(key: key);

  ThemeData _buildThemeData(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Outfit',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'NoyhR'),
        displayMedium: TextStyle(fontFamily: 'NoyhR'),
        displaySmall: TextStyle(fontFamily: 'NoyhR'),
        headlineLarge: TextStyle(fontFamily: 'NoyhR'),
        headlineMedium: TextStyle(fontFamily: 'NoyhR'),
        headlineSmall: TextStyle(fontFamily: 'NoyhR'),
        titleLarge: TextStyle(fontFamily: 'NoyhR'),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarBrightness: brightness == Brightness.light
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer.withOpacity(0.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest.withOpacity(0.7),
        ),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Fassword',
          theme: _buildThemeData(lightColorScheme, Brightness.light),
          darkTheme: _buildThemeData(darkColorScheme, Brightness.dark),
          themeMode: ThemeMode.system,
          home: const AuthScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// ==================== AUTH SCREEN ====================

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _biometricAvailable = false;
  String _authMessage = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
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

  Future<void> _authenticate() async {
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
          biometricOnly: false,
        ),
      );

      if (authenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Authentication error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _skipAuthentication() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Fassword',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your secure password manager',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 64),
              if (_isAuthenticating)
                CircularProgressIndicator(color: colorScheme.primary)
              else if (_biometricAvailable)
                FilledButton.tonalIcon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Authenticate'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                )
              else ...[
                FilledButton.icon(
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
                if (_authMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _authMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HOME SCREEN ====================

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SecureStorageService _storage = SecureStorageService();
  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
    _searchController.addListener(_filterPasswords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPasswords() async {
    setState(() => _isLoading = true);
    final passwords = await _storage.getPasswords();
    setState(() {
      _passwords = passwords;
      _filteredPasswords = passwords;
      _isLoading = false;
    });
  }

  void _filterPasswords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPasswords = _passwords
          .where(
            (p) =>
                p.website.toLowerCase().contains(query) ||
                p.username.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  Future<void> _addOrEditPassword([PasswordEntry? entry]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditPasswordScreen(entry: entry)),
    );

    if (result != null) {
      if (entry == null) {
        _passwords.add(result);
      } else {
        final index = _passwords.indexWhere((p) => p.id == entry.id);
        if (index != -1) _passwords[index] = result;
      }
      await _storage.savePasswords(_passwords);
      _loadPasswords();
    }
  }

  Future<void> _deletePassword(PasswordEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Delete Password'),
        content: Text(
          'Are you sure you want to delete the password for ${entry.website}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _passwords.removeWhere((p) => p.id == entry.id);
      await _storage.savePasswords(_passwords);
      _loadPasswords();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fassword'),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.7),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Fassword',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.lock_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
                children: [const Text('A secure and simple password manager.')],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 56),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search passwords',
              leading: const Icon(Icons.search),
              trailing: _searchController.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                    ]
                  : null,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPasswords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primaryContainer.withOpacity(
                              0.3,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No passwords saved'
                              : 'No results found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (_searchController.text.isEmpty) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _addOrEditPassword(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Password'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredPasswords.length,
                    itemBuilder: (ctx, i) {
                      final entry = _filteredPasswords[i];
                      final initial = entry.website.isNotEmpty
                          ? entry.website[0].toUpperCase()
                          : '?';

                      return GlassyCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        onTap: () => _showPasswordDetails(entry),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primaryContainer,
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.website,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.username,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: colorScheme.error,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _addOrEditPassword(entry);
                                } else if (value == 'delete') {
                                  _deletePassword(entry);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditPassword(),
        icon: const Icon(Icons.add),
        label: const Text('Add Password'),
      ),
    );
  }

  void _showPasswordDetails(PasswordEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PasswordDetailsSheet(
        entry: entry,
        onEdit: () {
          Navigator.pop(ctx);
          _addOrEditPassword(entry);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deletePassword(entry);
        },
      ),
    );
  }
}

// ==================== PASSWORD DETAILS SHEET ====================

class PasswordDetailsSheet extends StatefulWidget {
  final PasswordEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PasswordDetailsSheet({
    Key? key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<PasswordDetailsSheet> createState() => _PasswordDetailsSheetState();
}

class _PasswordDetailsSheetState extends State<PasswordDetailsSheet> {
  bool _showPassword = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = widget.entry.website.isNotEmpty
        ? widget.entry.website[0].toUpperCase()
        : '?';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.entry.website,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                _buildDetailCard(
                  context,
                  icon: Icons.person_outline,
                  label: 'Username',
                  value: widget.entry.username,
                  onCopy: () =>
                      _copyToClipboard(widget.entry.username, 'Username'),
                ),
                const SizedBox(height: 12),
                _buildDetailCard(
                  context,
                  icon: Icons.lock_outline,
                  label: 'Password',
                  value: _showPassword ? widget.entry.password : '••••••••••••',
                  onCopy: () =>
                      _copyToClipboard(widget.entry.password, 'Password'),
                  trailing: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                if (widget.entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    context,
                    icon: Icons.notes_outlined,
                    label: 'Notes',
                    value: widget.entry.notes,
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Created: ${_formatDate(widget.entry.createdAt)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Updated: ${_formatDate(widget.entry.updatedAt)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onDelete,
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        label: Text(
                          'Delete',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onCopy != null)
                IconButton.filledTonal(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: onCopy,
                  tooltip: 'Copy',
                ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== ADD/EDIT PASSWORD SCREEN ====================

class AddEditPasswordScreen extends StatefulWidget {
  final PasswordEntry? entry;

  const AddEditPasswordScreen({Key? key, this.entry}) : super(key: key);

  @override
  State<AddEditPasswordScreen> createState() => _AddEditPasswordScreenState();
}

class _AddEditPasswordScreenState extends State<AddEditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _websiteController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _notesController;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _websiteController = TextEditingController(
      text: widget.entry?.website ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.entry?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.entry?.password ?? '',
    );
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
  }

  @override
  void dispose() {
    _websiteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generatePassword({
    int length = 16,
    bool useUppercase = true,
    bool useLowercase = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    String chars = '';
    if (useLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (useUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (useNumbers) chars += '0123456789';
    if (useSymbols) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void _useGeneratedPassword() {
    setState(() {
      _passwordController.text = _generatePassword();
      _showPassword = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Strong password generated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id:
            widget.entry?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        website: _websiteController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        notes: _notesController.text.trim(),
        createdAt: widget.entry?.createdAt ?? now,
        updatedAt: now,
      );
      Navigator.pop(context, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.entry != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Password' : 'Add Password'),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.7),
              ),
            ),
          ),
        ),
        actions: [
          FilledButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 72,
            16,
            16,
          ),
          children: [
            GlassyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCOUNT DETAILS',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website / Application',
                      hintText: 'example.com',
                      prefixIcon: Icon(Icons.language),
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? 'Website is required'
                        : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username / Email',
                      hintText: 'user@example.com',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? 'Username is required'
                        : null,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PASSWORD',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _useGeneratedPassword,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Generate'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Password is required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTES (OPTIONAL)',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Add any additional information...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
