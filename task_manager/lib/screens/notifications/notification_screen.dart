import 'package:flutter/material.dart';
import '../../services/extra_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}
class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = ExtraService.notifications(); }
  void _reload() => setState(() => _future = ExtraService.notifications());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thông báo'), actions: [TextButton(onPressed: () async { try { await ExtraService.markAllRead(); _reload(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }, child: const Text('Đọc tất cả'))]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Text('Không tải được thông báo: ${snap.error}'));
      final items = snap.data ?? [];
      if (items.isEmpty) return const Center(child: Text('Bạn chưa có thông báo nào'));
      return RefreshIndicator(onRefresh: () async => _reload(), child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) {
        final n = items[i]; final task = n['taskId']; final title = n['title']?.toString() ?? 'Thông báo';
        return Card(child: ListTile(leading: CircleAvatar(backgroundColor: n['isRead'] == true ? Colors.grey.shade200 : Colors.blue.shade100, child: const Icon(Icons.notifications_outlined)), title: Text(title, style: TextStyle(fontWeight: n['isRead'] == true ? FontWeight.normal : FontWeight.bold)), subtitle: Text('${n['message'] ?? ''}\n${n['createdAt'] ?? ''}'), isThreeLine: true, trailing: n['isRead'] == true ? null : const Icon(Icons.circle, size: 9, color: Colors.blue), onTap: () async { if (n['isRead'] != true) await ExtraService.markRead(n['_id'].toString()); if (mounted) _reload(); if (task is Map && task['_id'] != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Công việc: ${task['title'] ?? ''}'))); }));
      }));
    }),
  );
}
