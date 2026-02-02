import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:valkyr/service/services.dart';
import 'package:valkyr/model/models.dart';
import 'package:valkyr/page/password_detail.dart';
import 'package:valkyr/page/password_screen.dart';
import 'dart:convert';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SortOption { newest, oldest, alphabetical, reverseAlphabetical }

class _HomeScreenState extends State<HomeScreen> {
  final SecureStorageService _storage = SecureStorageService();
  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  SortOption _currentSort = SortOption.newest;

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

  final List<Color> _passwordColors = [
    Colors.teal,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.green,
    Colors.pink,
    Colors.red,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.deepOrange,
    Colors.lightGreen,
  ];

  Color _getColorForEntry(String id) {
    final hash = id.hashCode;
    return _passwordColors[hash.abs() % _passwordColors.length];
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
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_currentSort) {
      case SortOption.newest:
        _filteredPasswords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.oldest:
        _filteredPasswords.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.alphabetical:
        _filteredPasswords.sort(
          (a, b) => a.website.toLowerCase().compareTo(b.website.toLowerCase()),
        );
        break;
      case SortOption.reverseAlphabetical:
        _filteredPasswords.sort(
          (a, b) => b.website.toLowerCase().compareTo(a.website.toLowerCase()),
        );
        break;
    }
  }

  void _changeSortOption(SortOption option) {
    setState(() {
      _currentSort = option;
      _applySorting();
    });
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
      case SortOption.alphabetical:
        return 'A to Z';
      case SortOption.reverseAlphabetical:
        return 'Z to A';
    }
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return Icons.arrow_downward;
      case SortOption.oldest:
        return Icons.arrow_upward;
      case SortOption.alphabetical:
        return Icons.sort_by_alpha;
      case SortOption.reverseAlphabetical:
        return Icons.sort_by_alpha;
    }
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

  Future<void> _exportPasswords() async {
    try {
      final jsonData = _passwords
          .map(
            (p) => {
              'id': p.id,
              'website': p.website,
              'username': p.username,
              'password': p.password,
              'notes': p.notes,
            },
          )
          .toList();

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(
              Icons.check_circle_outline,
              color: Theme.of(ctx).colorScheme.primary,
              size: 48,
            ),
            title: const Text('Export Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exported ${_passwords.length} passwords to clipboard.'),
                const SizedBox(height: 12),
                Text(
                  'Paste it into a text file to save your backup.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Export failed: $e');
      }
    }
  }

  Future<void> _importPasswords() async {
    final textController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.download_outlined,
          color: Theme.of(ctx).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Import Passwords'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your backup JSON here:',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: '[{"id":"...","website":"..."}]',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final List<dynamic> jsonData = json.decode(result);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(ctx).colorScheme.primary,
            size: 48,
          ),
          title: const Text('Import Passwords'),
          content: Text(
            'This will import ${jsonData.length} passwords. Duplicate entries will be skipped. Continue?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      int imported = 0;
      for (var item in jsonData) {
        final id = item['id'] as String;

        if (_passwords.any((p) => p.id == id)) continue;

        _passwords.add(
          PasswordEntry(
            id: id,
            website: item['website'] as String,
            username: item['username'] as String,
            password: item['password'] as String,
            notes: (item['notes'] as String?) ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        imported++;
      }

      await _storage.savePasswords(_passwords);
      _loadPasswords();

      if (mounted) {
        _showSnackBar('Imported $imported passwords successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Import failed: Invalid JSON format');
      }
    }
  }

  Future<void> _deletePassword(PasswordEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: const Text('Delete Password'),
        content: Text(
          'Are you sure you want to delete the password for ${entry.website}?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        _showSnackBar('Password deleted');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shield_outlined,
            color: theme.colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        title: const Text('About Valkyr'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A secure and elegant password manager for all your credentials.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.1.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your data is encrypted and stored securely on your device.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(context);
              showLicensePage(
                context: context,
                applicationName: 'Valkyr',
                applicationVersion: '1.1.0',
              );
            },
            child: const Text('Licenses'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar.large(
            title: const Text('Valkyr'),
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_outlined),
                onPressed: _exportPasswords,
                tooltip: 'Export',
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: _importPasswords,
                tooltip: 'Import',
              ),
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: _changeSortOption,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: SortOption.newest,
                    child: Row(
                      children: [
                        Icon(_getSortIcon(SortOption.newest)),
                        const SizedBox(width: 12),
                        Text(_getSortLabel(SortOption.newest)),
                        if (_currentSort == SortOption.newest)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 18),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SortOption.oldest,
                    child: Row(
                      children: [
                        Icon(_getSortIcon(SortOption.oldest)),
                        const SizedBox(width: 12),
                        Text(_getSortLabel(SortOption.oldest)),
                        if (_currentSort == SortOption.oldest)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 18),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SortOption.alphabetical,
                    child: Row(
                      children: [
                        Icon(_getSortIcon(SortOption.alphabetical)),
                        const SizedBox(width: 12),
                        Text(_getSortLabel(SortOption.alphabetical)),
                        if (_currentSort == SortOption.alphabetical)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 18),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SortOption.reverseAlphabetical,
                    child: Row(
                      children: [
                        Icon(_getSortIcon(SortOption.reverseAlphabetical)),
                        const SizedBox(width: 12),
                        Text(_getSortLabel(SortOption.reverseAlphabetical)),
                        if (_currentSort == SortOption.reverseAlphabetical)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 18),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'about') {
                    _showAboutDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Text('About'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search passwords',
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.search),
                ),
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
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(
                  theme.colorScheme.surfaceContainerHighest,
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredPasswords.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(
                            0.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_open_outlined,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No passwords yet'
                            : 'No results found',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Start by adding your first password'
                            : 'Try a different search term',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = _filteredPasswords[index];
                  return _buildPasswordCard(entry, theme);
                }, childCount: _filteredPasswords.length),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditPassword(),
        icon: const Icon(Icons.add),
        label: const Text('Add Password'),
        elevation: 2,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPasswordCard(PasswordEntry entry, ThemeData theme) {
    final initial = entry.website.isNotEmpty
        ? entry.website[0].toUpperCase()
        : '?';
    final entryColor = _getColorForEntry(entry.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
        child: Container(
          decoration: BoxDecoration(color: entryColor.withOpacity(0.12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(48),
            onTap: () => _showPasswordDetails(entry),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: entryColor,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.website,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.username,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Menu button
                  Container(
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showPasswordMenu(context, entry, theme),
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

  void _showPasswordMenu(
    BuildContext context,
    PasswordEntry entry,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _addOrEditPassword(entry);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _deletePassword(entry);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPasswordDetails(PasswordEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
