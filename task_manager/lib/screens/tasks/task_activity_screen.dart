import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/extra_service.dart';

class TaskActivityScreen extends StatefulWidget {
  final Task task;
  const TaskActivityScreen({super.key, required this.task});

  @override
  State<TaskActivityScreen> createState() => _TaskActivityScreenState();
}

class _TaskActivityScreenState extends State<TaskActivityScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExtraService.taskActivities(widget.task.id);
  }

  void _reload() => setState(() => _future = ExtraService.taskActivities(widget.task.id));

  String _label(String action) {
    const labels = {
      'created': 'Tạo công việc',
      'updated': 'Cập nhật công việc',
      'assigned': 'Giao công việc',
      'unassigned': 'Hủy giao việc',
      'assignee_updated': 'Cập nhật người phụ trách',
      'shared': 'Chia sẻ công việc',
      'deleted': 'Xóa công việc',
      'deadline_reminder_sent': 'Gửi nhắc hạn',
    };
    return labels[action] ?? action;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch sử hoạt động'), actions: [
      IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
    ]),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Không tải được lịch sử: ${snapshot.error}', textAlign: TextAlign.center),
          TextButton(onPressed: _reload, child: const Text('Thử lại')),
        ])));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('Chưa có hoạt động nào.'));
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final user = item['userId'];
              final name = user is Map ? user['fullName']?.toString() ?? 'Người dùng' : 'Người dùng';
              final date = DateTime.tryParse(item['createdAt']?.toString() ?? '');
              final details = item['details'] is Map ? (item['details'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(' • ') : '';
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.history)),
                title: Text(_label(item['action']?.toString() ?? '')),
                subtitle: Text('$name${details.isEmpty ? '' : '\n$details'}'),
                isThreeLine: details.isNotEmpty,
                trailing: date == null ? null : Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 11)),
              );
            },
          ),
        );
      },
    ),
  );
}
