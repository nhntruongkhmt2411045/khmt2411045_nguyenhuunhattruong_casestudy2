
import 'package:flutter/material.dart';
import '../../models/task.dart';
import 'create_task_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Task> tasks = [];

  final searchController = TextEditingController();

  String searchText = '';
  String selectedTab = 'Tất cả';
  String statusFilter = 'Tất cả';
  String priorityFilter = 'Tất cả';
  String sortBy = 'Ngày tạo';

  final tabs = ['Tất cả', 'Tôi tạo', 'Được giao', 'Được chia sẻ'];

  Future<void> openCreateTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateTaskScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        tasks.add(result);
      });
    }
  }

  Future<void> editTask(Task task) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(task: task),
      ),
    );

    if (result != null) {
      setState(() {
        final index = tasks.indexWhere((e) => e.id == task.id);
        if (index != -1) tasks[index] = result;
      });
    }
  }

  void deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text('Bạn có chắc muốn xóa "${task.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tasks.removeWhere((e) => e.id == task.id);
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return Colors.green;
      case 'Đang thực hiện':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'Cao':
        return Colors.red;
      case 'Trung bình':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Chưa đặt hạn';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<Task> get filteredTasks {
    List<Task> result = tasks.where((task) {
      final matchesSearch =
      task.title.toLowerCase().contains(searchText.toLowerCase());

      final matchesStatus =
          statusFilter == 'Tất cả' || task.status == statusFilter;

      final matchesPriority =
          priorityFilter == 'Tất cả' || task.priority == priorityFilter;

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();

    if (sortBy == 'Ngày tạo') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sortBy == 'Hạn hoàn thành') {
      result.sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      const priorityOrder = {'Cao': 0, 'Trung bình': 1, 'Thấp': 2};
      result.sort((a, b) =>
          priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!));
    }

    return result;
  }

  Widget buildFilter(
      String label,
      String value,
      List<String> options,
      Function(String?) onChanged,
      ) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: options
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, overflow: TextOverflow.ellipsis),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildTaskCard(Task task) {
    return Card(
      elevation: 1,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => editTask(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') editTask(task);
                      if (value == 'delete') deleteTask(task);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Chỉnh sửa'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa công việc'),
                      ),
                    ],
                  ),
                ],
              ),

              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _badge(task.status, getStatusColor(task.status)),
                  _badge(
                    'Ưu tiên ${task.priority}',
                    getPriorityColor(task.priority),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Hạn: ${formatDate(task.dueDate)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => deleteTask(task),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Danh sách công việc',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới danh sách',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh, color: Colors.blue),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateTask,
        backgroundColor: const Color(0xFF315EFB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo công việc'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng số: ${tasks.length} công việc',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: tabs.map((tab) {
                      final selected = selectedTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tab),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => selectedTab = tab);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên công việc...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => searchText = value);
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    buildFilter(
                      'Trạng thái',
                      statusFilter,
                      [
                        'Tất cả',
                        'Chưa thực hiện',
                        'Đang thực hiện',
                        'Hoàn thành',
                      ],
                          (value) {
                        if (value != null) {
                          setState(() => statusFilter = value);
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    buildFilter(
                      'Ưu tiên',
                      priorityFilter,
                      ['Tất cả', 'Thấp', 'Trung bình', 'Cao'],
                          (value) {
                        if (value != null) {
                          setState(() => priorityFilter = value);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                buildFilter(
                  'Sắp xếp theo',
                  sortBy,
                  ['Ngày tạo', 'Hạn hoàn thành', 'Độ ưu tiên'],
                      (value) {
                    if (value != null) {
                      setState(() => sortBy = value);
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 65,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có công việc nào',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Nhấn "Tạo công việc" để bắt đầu'),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) =>
                  buildTaskCard(filteredTasks[index]),
            ),
          ),
        ],
      ),
    );
  }
}
