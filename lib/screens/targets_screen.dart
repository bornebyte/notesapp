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
    final daysDiff = target.daysDifference ?? 0;
    final isOverdue = daysDiff < 0;

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
                    target.message,
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
                    if (value == 'delete' && target.id != null) {
                      _confirmDelete(target);
                    } else if (value == 'share' && target.id != null) {
                      await _generateShareId(target);
                    } else if (value == 'copy_share' &&
                        target.shareId != null) {
                      _copyShareId(target.shareId!);
                    }
                  },
                  itemBuilder: (context) => [
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
            const SizedBox(height: 16),

            // Date and time remaining
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
                      target.targetDate != null
                          ? DateFormat('MMM d, y').format(target.targetDate!)
                          : 'No date set',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverdue ? 'Past Due' : 'Time Remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatTimeRemaining(daysDiff),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isOverdue
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time breakdown
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _buildTimeBreakdown(daysDiff),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(
    String value,
    String label,
    IconData icon, {
    bool isNegative = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isNegative
            ? Colors.red.shade100
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isNegative
                ? Colors.red.shade900
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isNegative
                  ? Colors.red.shade900
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeBreakdown(int daysDiff) {
    final isNegative = daysDiff < 0;
    final absDays = daysDiff.abs();
    final chips = <Widget>[];

    if (absDays >= 365) {
      final years = absDays ~/ 365;
      chips.add(
        _buildTimeChip(
          '${isNegative ? "-" : ""}$years',
          years == 1 ? 'Year' : 'Years',
          Icons.calendar_today,
          isNegative: isNegative,
        ),
      );
    }

    if (absDays >= 30) {
      final months = (absDays % 365) ~/ 30;
      if (months > 0) {
        chips.add(
          _buildTimeChip(
            '${isNegative ? "-" : ""}$months',
            months == 1 ? 'Month' : 'Months',
            Icons.calendar_month,
            isNegative: isNegative,
          ),
        );
      }
    }

    if (absDays >= 7) {
      final weeks = (absDays % 30) ~/ 7;
      if (weeks > 0) {
        chips.add(
          _buildTimeChip(
            '${isNegative ? "-" : ""}$weeks',
            weeks == 1 ? 'Week' : 'Weeks',
            Icons.calendar_view_week,
            isNegative: isNegative,
          ),
        );
      }
    }

    final days = absDays % 7;
    if (days > 0 || chips.isEmpty) {
      chips.add(
        _buildTimeChip(
          '${isNegative ? "-" : ""}$days',
          days == 1 ? 'Day' : 'Days',
          Icons.today,
          isNegative: isNegative,
        ),
      );
    }

    return chips;
  }

  String _formatTimeRemaining(int daysDiff) {
    if (daysDiff == 0) return 'Today';

    final isNegative = daysDiff < 0;
    final absDays = daysDiff.abs();
    final prefix = isNegative ? '-' : '';

    if (absDays >= 365) {
      final years = absDays ~/ 365;
      return '$prefix$years ${years == 1 ? "year" : "years"}';
    } else if (absDays >= 30) {
      final months = absDays ~/ 30;
      return '$prefix$months ${months == 1 ? "month" : "months"}';
    } else if (absDays >= 7) {
      final weeks = absDays ~/ 7;
      return '$prefix$weeks ${weeks == 1 ? "week" : "weeks"}';
    } else {
      return '$prefix$absDays ${absDays == 1 ? "day" : "days"}';
    }
  }

  void _confirmDelete(TargetDate target) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: Text('Are you sure you want to delete "${target.message}"?'),
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
      final shareId = await _apiService.generateShareId(target.id!);
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

  void _showTargetDialog() {
    final messageController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Target'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Complete project',
                    border: OutlineInputBorder(),
                  ),
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
                      firstDate: DateTime(2000),
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
                if (messageController.text.trim().isEmpty) {
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
                  // Format date as MM/DD/YYYY
                  final formattedDate =
                      '${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.year}';

                  final newTarget = TargetDate(
                    message: messageController.text.trim(),
                    date: formattedDate,
                  );

                  await _apiService.createTargetDate(newTarget);

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadTargets(useCache: false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Target created')),
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
