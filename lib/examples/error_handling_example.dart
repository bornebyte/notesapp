import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Example widget showing how to handle API errors properly
class ErrorHandlingExample extends StatefulWidget {
  const ErrorHandlingExample({super.key});

  @override
  State<ErrorHandlingExample> createState() => _ErrorHandlingExampleState();
}

class _ErrorHandlingExampleState extends State<ErrorHandlingExample> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _errorType;

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      final result = await _apiService.login('testuser', 'testpass');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Login successful! Token: ${result['token'] ?? 'none'}';
          _errorType = 'success';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          _errorType = e.type ?? 'unknown';
        });

        // Show different UI based on error type
        if (e.type == 'network') {
          _showRetryDialog('No Internet', e.message);
        } else if (e.type == 'auth') {
          _showErrorSnackBar(e.message, canRetry: false);
        } else if (e.type == 'domain') {
          _showSettingsDialog('Domain Error', e.message);
        } else {
          _showErrorSnackBar(e.message, canRetry: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unexpected error: $e';
          _errorType = 'unknown';
        });
      }
    }
  }

  void _showRetryDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _testLogin(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to settings
              // Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message, {required bool canRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: canRetry
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _testLogin,
              )
            : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Color _getErrorColor() {
    switch (_errorType) {
      case 'success':
        return Colors.green;
      case 'network':
        return Colors.orange;
      case 'auth':
        return Colors.red;
      case 'domain':
        return Colors.purple;
      case 'server':
        return Colors.deepOrange;
      case 'timeout':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getErrorIcon() {
    switch (_errorType) {
      case 'success':
        return Icons.check_circle;
      case 'network':
        return Icons.wifi_off;
      case 'auth':
        return Icons.lock;
      case 'domain':
        return Icons.language;
      case 'server':
        return Icons.error;
      case 'timeout':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Handling Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This demonstrates how API errors are handled:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Error types list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildErrorType('Network', Icons.wifi_off, Colors.orange),
                    _buildErrorType('Auth', Icons.lock, Colors.red),
                    _buildErrorType('Domain', Icons.language, Colors.purple),
                    _buildErrorType('Server', Icons.error, Colors.deepOrange),
                    _buildErrorType('Timeout', Icons.access_time, Colors.amber),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test button
            FilledButton.icon(
              onPressed: _isLoading ? null : _testLogin,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Testing...' : 'Test Login'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),

            const SizedBox(height: 24),

            // Result display
            if (_errorMessage != null)
              Card(
                color: _getErrorColor().withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(_getErrorIcon(), color: _getErrorColor()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type: ${_errorType ?? 'unknown'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getErrorColor(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_errorMessage!),
                          ],
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

  Widget _buildErrorType(String name, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
