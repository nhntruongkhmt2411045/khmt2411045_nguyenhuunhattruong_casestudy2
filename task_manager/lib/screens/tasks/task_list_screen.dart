
import 'package:flutter/material.dart';

import 'widgets/task_card.dart';
import 'create_task_screen.dart';
import 'task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // Dữ liệu mẫu tạm thời. Bước sau sẽ thay bằng dữ liệu từ API.
  final List<Map<String, String>> _dummyTasks = [
    {
      'id': '1',
      'title': 'Thiết kế Database',
      'description':
      'Viết schema MongoDB cho Collection tasks gồm các trường: title, description, status...',
      'status': 'completed',
      'priority': 'high',
    },
    {
      'id': '2',
      'title': 'Xây dựng API Backend',
      'description': 'Code Node.js CRUD cho Tasks và test bằng Postman.',
      'status': 'in_progress',
      'priority': 'high',
    },
    {
      'id': '3',
      'title': 'Ráp UI danh sách công việc',
      'description':
      'Tạo TaskCard và hiển thị lên TaskListScreen trong Flutter.',
      'status': 'todo',
      'priority': 'medium',
    },
  ];

  Future<void> _openCreateTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTaskScreen(),
      ),
    );

    // Sau này sẽ tải lại danh sách công việc từ API tại đây.
  }

  void _openTaskDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách công việc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Tìm kiếm',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng tìm kiếm sẽ được bổ sung sau.'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc công việc',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng lọc sẽ được bổ sung sau.'),
                ),
              );
            },
          ),
        ],
      ),
      body: _dummyTasks.isEmpty
          ? const Center(
        child: Text('Chưa có công việc nào.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dummyTasks.length,
        itemBuilder: (context, index) {
          final task = _dummyTasks[index];

          return TaskCard(
            title: task['title'] ?? '',
            description: task['description'] ?? '',
            status: task['status'] ?? 'todo',
            priority: task['priority'] ?? 'medium',
            onTap: _openTaskDetail,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTask,
        tooltip: 'Thêm công việc',
        child: const Icon(Icons.add),
      ),
    );
  }
}
