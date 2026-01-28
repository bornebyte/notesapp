import 'package:flutter/material.dart' hide Notification;
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ApiService _apiService = ApiService();
  List<Notification> _allNotifications = [];
  List<FilterOption> _filters = [];
  String _selectedFilter = '*';
  bool _isInitialLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  List<Notification> get _filteredNotifications {
    if (_selectedFilter == '*') {
      return _allNotifications;
    }
    return _allNotifications
        .where((n) => n.category == _selectedFilter)
        .toList();
  }

  Future<void> _loadNotifications({bool useCache = true}) async {
    // Clear error on refresh
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }

    try {
      final result = await _apiService.getNotifications(useCache: useCache);
      if (mounted) {
        setState(() {
          _allNotifications = result['notifications'] as List<Notification>;
          _filters = result['filters'] as List<FilterOption>;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitialLoad = false;
        });
      }
    }
  }

  void _handleFilterChange(String? filter) {
    if (filter == null || filter == _selectedFilter) return;

    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadNotifications(useCache: false),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter dropdown
          if (_filters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Filter: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      underline: const SizedBox(),
                      items: _filters.map((filter) {
                        return DropdownMenuItem<String>(
                          value: filter.category,
                          child: Text(filter.label),
                        );
                      }).toList(),
                      onChanged: _handleFilterChange,
                    ),
                  ),
                ],
              ),
            ),
          // Notifications list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadNotifications(useCache: false),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoad && _allNotifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _allNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadNotifications(useCache: false),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == '*'
                  ? 'Your inbox is empty'
                  : 'No notifications in this category',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) =>
          _buildNotificationCard(_filteredNotifications[index]),
    );
  }

  Widget _buildNotificationCard(Notification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(notification.category),
          child: Icon(
            _getCategoryIcon(notification.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAtDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (notification.label != null &&
                    notification.label!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        notification.category,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.label!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCategoryColor(notification.category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _formatDate(notification.createdAtDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showNotificationDialog(notification),
      ),
    );
  }

  void _showNotificationDialog(Notification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notification.label != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      notification.category,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    notification.label!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getCategoryColor(notification.category),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              Text(
                'Received: ${_formatDateFull(notification.createdAtDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'error':
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
        return Colors.blue;
      case 'shareidcreated':
        return Colors.teal;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'error':
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'info':
        return Icons.info;
      case 'shareidcreated':
        return Icons.share;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('h:mm a').format(date);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _formatDateFull(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM d, y h:mm a').format(date);
  }
}
