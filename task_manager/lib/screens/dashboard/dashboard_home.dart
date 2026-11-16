import 'package:flutter/material.dart';
import '../../services/extra_service.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}
class _DashboardHomeState extends State<DashboardHome> {
  late Future<List<Map<String, dynamic>>> _load;
  @override
  void initState() { super.initState(); _load = _loadStats(); }
  Future<List<Map<String, dynamic>>> _loadStats() async => Future.wait([ExtraService.taskStats(), ExtraService.assignmentStats(), ExtraService.deadlineStats()]);
  void _refresh() => setState(() => _load = _loadStats());
  Widget _metric(String label, String value, IconData icon, Color color) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(label, style: TextStyle(color: Colors.grey.shade700))]))));
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Tổng quan', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]), body: FutureBuilder<List<Map<String, dynamic>>>(future: _load, builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 48), const SizedBox(height: 12), Text('Không tải được thống kê\n${snap.error}', textAlign: TextAlign.center), TextButton(onPressed: _refresh, child: const Text('Thử lại'))])));
    final s = snap.data![0], a = snap.data![1], d = snap.data![2];
    final total = (s['total'] as num? ?? 0).toInt(); final rate = (s['completionRate'] as num? ?? 0).toInt();
    return RefreshIndicator(onRefresh: () async => _refresh(), child: ListView(padding: const EdgeInsets.all(16), children: [const Text('Tình hình công việc', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text('Thống kê các công việc bạn có quyền xem.', style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 16), Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Tổng quan trạng thái', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row(children: [_metric('Tổng công việc', '$total', Icons.checklist, Colors.blue), _metric('Hoàn thành', '${s['completed'] ?? 0}', Icons.check_circle_outline, Colors.green)]), const SizedBox(height: 8), LinearProgressIndicator(value: total == 0 ? 0 : rate / 100, minHeight: 9), const SizedBox(height: 10), Text('Tỷ lệ hoàn thành: $rate%', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text('Chưa thực hiện: ${s['todo'] ?? 0}  •  Đang làm: ${s['in_progress'] ?? 0}')]))), const SizedBox(height: 12), const Text('Cảnh báo thời hạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Row(children: [_metric('Quá hạn', '${d['overdue'] ?? 0}', Icons.warning_amber, Colors.red), _metric('Sắp đến hạn', '${d['dueSoon'] ?? 0}', Icons.schedule, Colors.orange)]), const SizedBox(height: 12), const Text('Phân công & phụ trách', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Row(children: [_metric('Đã tạo', '${a['created'] ?? 0}', Icons.create_outlined, Colors.teal), _metric('Được giao', '${a['assigned'] ?? 0}', Icons.assignment_ind_outlined, Colors.blue), _metric('Phụ trách chính', '${a['primary'] ?? 0}', Icons.star_outline, Colors.orange)]), const SizedBox(height: 12), const Text('Công việc quá hạn gần đây', style: TextStyle(fontWeight: FontWeight.bold)), ...((d['overdueTasks'] as List? ?? []).map((t) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.error_outline, color: Colors.red), title: Text(t['title']?.toString() ?? ''), subtitle: Text('Hạn: ${t['dueDate'] ?? ''}')))), ]));
  }));
}
