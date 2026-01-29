import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class ApiConfigScreen extends StatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  State<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends State<ApiConfigScreen> {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();
  final _domainController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final domain = await _storage.getDomain();
    final token = await _storage.getApiToken();
    setState(() {
      _domainController.text = domain;
      _tokenController.text = token;
    });
  }

  @override
  void dispose() {
    _domainController.dispose();
    _tokenController.dispose();
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
        // Give user time to see the success message before going back
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate settings were saved
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error saving settings: $e', isError: true);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('API Configuration'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Icon and Title
                  Icon(Icons.dns, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Configure API Settings',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your domain and API token to connect',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Domain Field
                  TextField(
                    controller: _domainController,
                    decoration: InputDecoration(
                      labelText: 'Domain URL',
                      hintText: 'https://api.example.com',
                      prefixIcon: const Icon(Icons.language),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Enter your API server URL',
                    ),
                    keyboardType: TextInputType.url,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // API Token Field
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'API Token',
                      hintText: 'Enter your API token',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureToken
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscureToken = !_obscureToken);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Your authentication token',
                    ),
                    obscureText: _obscureToken,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _testConnection,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_find),
                          label: const Text('Test'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _saveSettings,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Use the Test button to verify your connection before saving',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
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
