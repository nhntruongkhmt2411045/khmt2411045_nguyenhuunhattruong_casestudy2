
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import 'task_activity_screen.dart';
import 'share_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
final String taskId;

const TaskDetailScreen({
super.key,
required this.taskId,
});

@override
State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
late Future<Task> _future;

@override
void initState() {
super.initState();
_future = TaskService.getTaskById(widget.taskId);
}

String _date(DateTime? value) {
if (value == null) return 'Chưa thiết lập';

return '${value.day.toString().padLeft(2, '0')}/'
'${value.month.toString().padLeft(2, '0')}/'
'${value.year}';
}

void _reload() {
setState(() {
_future = TaskService.getTaskById(widget.taskId);
});
}

Future<void> _openShare() async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ShareTaskScreen(taskId: widget.taskId),
),
);

if (!mounted) return;
_reload();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Chi tiết công việc'),
actions: [
IconButton(
tooltip: 'Chia sẻ công việc',
icon: const Icon(Icons.share),
onPressed: _openShare,
),
],
),
body: FutureBuilder<Task>(
future: _future,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'Không tải được công việc: ${snapshot.error}',
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
TextButton(
onPressed: _reload,
child: const Text('Thử lại'),
),
],
),
),
);
}

if (!snapshot.hasData) {
return const Center(
child: Text('Không tìm thấy công việc'),
);
}

final task = snapshot.data!;

return ListView(
padding: const EdgeInsets.all(20),
children: [
Text(
task.title,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 16),

Wrap(
spacing: 8,
children: [
Chip(label: Text(task.status)),
Chip(label: Text('Ưu tiên ${task.priority}')),
],
),

const SizedBox(height: 20),

const Text(
'Mô tả',
style: TextStyle(fontWeight: FontWeight.bold),
),
const SizedBox(height: 6),

Text(
task.description.isEmpty
? 'Không có mô tả.'
    : task.description,
),

const Divider(height: 32),

_info(
'Ngày bắt đầu',
_date(task.startDate),
Icons.play_circle_outline,
),

_info(
'Hạn hoàn thành',
_date(task.dueDate),
Icons.event,
),

_info(
'Người tạo',
task.creator,
Icons.person_outline,
),

_info(
'Người phụ trách chính',
task.assignee.isEmpty
? 'Chưa phân công'
    : task.assignee,
Icons.assignment_ind_outlined,
),

_info(
'Số người được giao',
'${task.assigneeIds.length}',
Icons.groups_outlined,
),

_info(
'Số người được chia sẻ',
'${task.sharedWith.length}',
Icons.share_outlined,
),

const SizedBox(height: 20),

OutlinedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => TaskActivityScreen(task: task),
),
);
},
icon: const Icon(Icons.history),
label: const Text('Xem lịch sử hoạt động'),
),

const SizedBox(height: 12),

ElevatedButton.icon(
onPressed: _openShare,
icon: const Icon(Icons.share),
label: const Text('Chia sẻ công việc'),
),
],
);
},
),
);
}

Widget _info(String label, String value, IconData icon) {
return ListTile(
contentPadding: EdgeInsets.zero,
leading: Icon(icon),
title: Text(
label,
style: const TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
subtitle: Text(
value,
style: const TextStyle(fontSize: 15),
),
);
}
}
