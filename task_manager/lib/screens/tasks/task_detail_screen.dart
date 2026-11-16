
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

  bool _updatingStatus = false;
  String? _selectedStatus;

  final List<String> _statuses = [
    'Chưa thực hiện',
    'Đang thực hiện',
    'Hoàn thành',
  ];

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
      _selectedStatus = null;
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

  // Đổi trạng thái và lưu xuống MongoDB
  Future<void> _changeStatus(String? status) async {
    if (status == null || _updatingStatus) return;

    setState(() {
      _updatingStatus = true;
    });

    try {
      await TaskService.updateTaskStatus(
        widget.taskId,
        status,
      );

      if (!mounted) return;

      setState(() {
        _selectedStatus = null;
        _future = TaskService.getTaskById(widget.taskId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật trạng thái thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _selectedStatus = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể đổi trạng thái: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingStatus = false;
        });
      }
    }
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

          final currentStatus = _selectedStatus ?? task.status;

          final validStatus = _statuses.contains(currentStatus)
              ? currentStatus
              : _statuses.first;

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

              const SizedBox(height: 24),

              const Text(
                'Cập nhật trạng thái',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: validStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sync),
                  labelText: 'Chọn trạng thái',
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: _updatingStatus
                    ? null
                    : (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _updatingStatus ||
                          validStatus == task.status
                      ? null
                      : () => _changeStatus(validStatus),
                  icon: _updatingStatus
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _updatingStatus
                        ? 'Đang cập nhật...'
                        : 'Lưu trạng thái',
                  ),
                ),
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
