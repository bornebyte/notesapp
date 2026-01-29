import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/api_token.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();
  final _domainController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureToken = true;
  bool _obscurePassword = true;
  List<ApiToken> _apiTokens = [];
  final Set<int> _visibleTokens = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadApiTokens();
  }

  Future<void> _loadSettings() async {
    final domain = await _storage.getDomain();
    final token = await _storage.getApiToken();
    setState(() {
      _domainController.text = domain;
      _tokenController.text = token;
    });
  }

  Future<void> _loadApiTokens() async {
    try {
      final tokens = await _apiService.getApiTokens();
      if (mounted) {
        setState(() => _apiTokens = tokens);
      }
    } catch (e) {
      // Ignore errors silently
    }
  }

  @override
  void dispose() {
    _domainController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_domainController.text.trim().isEmpty) {
      _showMessage('Please enter a domain', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _storage.setDomain(_domainController.text.trim());
      if (_tokenController.text.trim().isNotEmpty) {
        await _storage.setApiToken(_tokenController.text.trim());
      }

      _apiService.clearCache();

      final success = await _apiService.testConnection();

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _showMessage('Connection successful!', isError: false);
        } else {
          _showMessage(
            'Connection failed. Please check your domain and API token.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error testing connection: $e', isError: true);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_domainController.text.trim().isEmpty) {
      _showMessage('Domain cannot be empty', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _storage.setDomain(_domainController.text.trim());
      if (_tokenController.text.trim().isNotEmpty) {
        await _storage.setApiToken(_tokenController.text.trim());
      }

      _apiService.clearCache();

      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Settings saved successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error saving settings: $e', isError: true);
      }
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.trim().isEmpty ||
        _passwordController.text.length < 4) {
      _showMessage('Password must be at least 4 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.changePassword(_passwordController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordController.clear();
        });
        _showMessage('Password changed successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error changing password: $e', isError: true);
      }
    }
  }

  Future<void> _createApiToken(String name) async {
    if (name.trim().length < 3) {
      _showMessage('Token name must be at least 3 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _apiService.createApiToken(name.trim());
      if (mounted) {
        setState(() => _isLoading = false);
        _loadApiTokens();
        _showNewTokenDialog(token);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error creating token: $e', isError: true);
      }
    }
  }

  Future<void> _deleteApiToken(int tokenId) async {
    try {
      await _apiService.deleteApiToken(tokenId);
      _loadApiTokens();
      _showMessage('Token revoked successfully', isError: false);
    } catch (e) {
      _showMessage('Error revoking token: $e', isError: true);
    }
  }

  void _showNewTokenDialog(String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.green),
            SizedBox(width: 12),
            Text('API Token Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Save this token now. You won\'t be able to see it again!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: SelectableText(
                token,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                _showMessage('Token copied to clipboard!', isError: false);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Token'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _storage.clearAuth();
      _apiService.clearCache();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildApiConfigSection(),
          const SizedBox(height: 16),
          _buildPasswordSection(),
          const SizedBox(height: 16),
          _buildApiTokensSection(),
          const SizedBox(height: 16),
          _buildThemeSection(),
          const SizedBox(height: 16),
          _buildAccountSection(),
          const SizedBox(height: 16),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildApiConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns),
                const SizedBox(width: 12),
                Text(
                  'API Configuration',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _domainController,
              decoration: InputDecoration(
                labelText: 'Domain URL',
                hintText: 'https://api.example.com',
                prefixIcon: const Icon(Icons.language),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'API Token',
                hintText: 'Enter your API token',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureToken ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureToken = !_obscureToken);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: _obscureToken,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('Test'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock),
                const SizedBox(width: 12),
                Text(
                  'Change Password',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter new password',
                prefixIcon: const Icon(Icons.password),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _changePassword,
              icon: const Icon(Icons.update),
              label: const Text('Update Password'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiTokensSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vpn_key),
                    const SizedBox(width: 12),
                    Text(
                      'API Tokens',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _showCreateTokenDialog(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to use:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'X-API-Token: your_token_here',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_apiTokens.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No API tokens yet'),
                ),
              )
            else
              ..._apiTokens.map((token) => _buildApiTokenCard(token)),
          ],
        ),
      ),
    );
  }

  Widget _buildApiTokenCard(ApiToken token) {
    final isRevoked = token.revoked;
    final isVisible = _visibleTokens.contains(token.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isRevoked
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: ExpansionTile(
        title: Text(
          token.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isRevoked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Created: ${_formatDate(token.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (token.lastUsed != null)
              Text(
                'Last used: ${_formatDate(token.lastUsed!)}',
                style: const TextStyle(fontSize: 12),
              ),
            if (isRevoked)
              const Text(
                'REVOKED',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: !isRevoked
            ? IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _confirmRevokeToken(token),
              )
            : null,
        children: !isRevoked
            ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: SelectableText(
                                isVisible ? token.token : '•' * 32,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              isVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            tooltip: isVisible ? 'Hide token' : 'Show token',
                            onPressed: () {
                              setState(() {
                                if (isVisible) {
                                  _visibleTokens.remove(token.id);
                                } else {
                                  _visibleTokens.add(token.id);
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy token',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: token.token),
                              );
                              _showMessage(
                                'Token copied to clipboard!',
                                isError: false,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use this token in API requests with header: X-API-Token',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  void _showCreateTokenDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create API Token'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Token Name',
            hintText: 'e.g., Postman, Mobile App',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _createApiToken(nameController.text);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmRevokeToken(ApiToken token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Token'),
        content: Text(
          'Are you sure you want to revoke "${token.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteApiToken(token.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 12),
                Text(
                  'Appearance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, provider, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.settings_brightness),
                    ),
                  ],
                  selected: {provider.themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) {
                    provider.setThemeMode(selection.first);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle),
                const SizedBox(width: 12),
                Text(
                  'Account',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clear Cache'),
              subtitle: const Text('Clear all cached data'),
              onTap: () {
                _apiService.clearDataCache();
                _showMessage('Cache cleared!', isError: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info),
                const SizedBox(width: 12),
                Text(
                  'About',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
              trailing: const Icon(Icons.info_outline),
            ),
            ListTile(
              title: const Text('Developer'),
              subtitle: const Text('Notes App'),
              trailing: const Icon(Icons.code),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
