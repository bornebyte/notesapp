import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/target_date.dart';
import '../services/api_service.dart';

class TargetsScreen extends StatefulWidget {
  const TargetsScreen({super.key});

  @override
  State<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen> {
  final ApiService _apiService = ApiService();
  List<TargetDate> _targets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets({bool useCache = true}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final targets = await _apiService.getTargetDates(useCache: useCache);
      if (mounted) {
        setState(() {
          _targets = targets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTarget(int id) async {
    try {
      await _apiService.deleteTargetDate(id);
      await _loadTargets(useCache: false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Target deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Targets & Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTargets(useCache: false),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadTargets(useCache: false),
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTargetDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Target'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              onPressed: () => _loadTargets(useCache: false),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_targets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No targets yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _targets.length,
      itemBuilder: (context, index) => _buildTargetCard(_targets[index]),
    );
  }

  Widget _buildTargetCard(TargetDate target) {
    final progress = (target.progressPercentage ?? 0) / 100;
    final isOverdue = target.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    target.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (target.shareId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share,
                          size: 14,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Shared',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showTargetDialog(target: target);
                    } else if (value == 'delete' && target.id != null) {
                      _confirmDelete(target);
                    } else if (value == 'share' && target.id != null) {
                      await _generateShareId(target);
                    } else if (value == 'copy_share' &&
                        target.shareId != null) {
                      _copyShareId(target.shareId!);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (target.shareId == null)
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 20, color: Colors.blue),
                            SizedBox(width: 12),
                            Text(
                              'Generate Share ID',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'copy_share',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20, color: Colors.blue),
                            SizedBox(width: 12),
                            Text(
                              'Copy Share ID',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (target.description != null &&
                target.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                target.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverdue
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Date',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      DateFormat('MMM d, y').format(target.targetDate!),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'OVERDUE',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${target.progressPercentage}% Complete',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _formatTimeRemaining(target),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Time breakdown
            if (!isOverdue &&
                (target.days != null || target.months != null)) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (target.months != null && target.months! > 0)
                    _buildTimeChip(
                      '${target.months}',
                      'Months',
                      Icons.calendar_month,
                    ),
                  if (target.days != null)
                    _buildTimeChip(
                      '${target.days! % 30}',
                      'Days',
                      Icons.calendar_today,
                    ),
                  if (target.hours != null && target.days! < 7)
                    _buildTimeChip(
                      '${target.hours}',
                      'Hours',
                      Icons.access_time,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(TargetDate target) {
    if (target.isOverdue) return 'Overdue';

    if (target.months != null && target.months! > 0) {
      return '${target.months} months';
    } else if (target.days != null && target.days! > 0) {
      return '${target.days} days';
    } else if (target.hours != null) {
      return '${target.hours} hours';
    } else {
      return 'Soon';
    }
  }

  void _confirmDelete(TargetDate target) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: Text('Are you sure you want to delete "${target.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (target.id != null) _deleteTarget(target.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateShareId(TargetDate target) async {
    try {
      // Generate a random share ID and update the target
      final shareId = DateTime.now().millisecondsSinceEpoch.toString();
      final updatedTarget = TargetDate(
        title: target.title,
        description: target.description,
        date: target.date,
        shareId: shareId,
      );

      await _apiService.updateTargetDate(target.id!, updatedTarget);
      await _loadTargets(useCache: false);

      if (mounted) {
        _copyShareId(shareId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _copyShareId(String shareId) {
    Clipboard.setData(ClipboardData(text: shareId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Share ID copied to clipboard!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(shareId, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showTargetDialog({TargetDate? target}) {
    final titleController = TextEditingController(text: target?.title ?? '');
    final descriptionController = TextEditingController(
      text: target?.description ?? '',
    );
    DateTime? selectedDate = target?.targetDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(target == null ? 'New Target' : 'Edit Target'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Complete project',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDate != null
                        ? DateFormat('MMM d, y').format(selectedDate!)
                        : 'Select target date',
                  ),
                  trailing: const Icon(Icons.edit),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          selectedDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }
                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a target date'),
                    ),
                  );
                  return;
                }

                try {
                  final newTarget = TargetDate(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    date: selectedDate!.toIso8601String(),
                  );

                  if (target == null) {
                    await _apiService.createTargetDate(newTarget);
                  } else if (target.id != null) {
                    await _apiService.updateTargetDate(target.id!, newTarget);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadTargets(useCache: false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          target == null ? 'Target created' : 'Target updated',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(target == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
