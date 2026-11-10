
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import 'create_task_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Task> tasks = [];
  final searchController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  String? currentUserId;

  String searchText = '';
  String selectedTab = 'Tất cả';
  String statusFilter = 'Tất cả';
  String priorityFilter = 'Tất cả';
  String sortBy = 'Ngày tạo';

  final tabs = [
    'Tất cả',
    'Tôi tạo',
    'Được giao',
    'Được chia sẻ',
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Tải danh sách công việc từ API
  Future<void> _loadTasks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Lấy danh sách công việc trước
      final loadedTasks = await TaskService.getTasks();

      if (!mounted) return;

      setState(() {
        tasks
          ..clear()
          ..addAll(loadedTasks);
        isLoading = false;
      });

      // Lấy thông tin người dùng riêng
      try {
        final profile = await AuthService().getProfile();
        final userData = profile?['user'] ?? profile;

        if (userData is Map && mounted) {
          setState(() {
            currentUserId =
                (userData['_id'] ?? userData['id'])?.toString();
          });
        }
      } catch (e) {
        debugPrint('Lỗi lấy thông tin người dùng: $e');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      debugPrint('Lỗi tải công việc: $e');
    }
  }

  // Tạo công việc mới
  Future<void> openCreateTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateTaskScreen(),
      ),
    );

    if (result == null || !mounted) return;

    try {
      await TaskService.createTask(result);
      await _loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo công việc thành công'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo công việc: $e'),
        ),
      );
    }
  }

  // Chỉnh sửa công việc
  Future<void> editTask(Task task) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(task: task),
      ),
    );

    if (result == null || !mounted) return;

    try {
      await TaskService.updateTask(result);
      await _loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật công việc thành công'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật công việc: $e'),
        ),
      );
    }
  }

  // Xóa công việc
  Future<void> deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text(
          'Bạn có chắc muốn xóa "${task.title}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await TaskService.deleteTask(task.id);
      await _loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa công việc thành công'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa công việc: $e'),
        ),
      );
    }
  }

  // Kiểm tra công việc theo tab
  bool _matchesTab(Task task) {
    if (selectedTab == 'Tất cả') return true;

    if (currentUserId == null || currentUserId!.isEmpty) {
      return false;
    }

    if (selectedTab == 'Tôi tạo') {
      return task.creator == currentUserId;
    }

    if (selectedTab == 'Được giao') {
      return task.assigneeIds.contains(currentUserId) ||
          task.assignee == currentUserId;
    }

    if (selectedTab == 'Được chia sẻ') {
      return task.sharedWith.contains(currentUserId) ||
          task.shares.any(
                (share) => share.userId == currentUserId,
          );
    }

    return true;
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

  // Lọc và sắp xếp công việc
  List<Task> get filteredTasks {
    List<Task> result = tasks.where((task) {
      final matchesSearch = task.title
          .toLowerCase()
          .contains(searchText.toLowerCase());

      final matchesStatus =
          statusFilter == 'Tất cả' ||
              task.status == statusFilter;

      final matchesPriority =
          priorityFilter == 'Tất cả' ||
              task.priority == priorityFilter;

      final matchesTab = _matchesTab(task);

      return matchesSearch &&
          matchesStatus &&
          matchesPriority &&
          matchesTab;
    }).toList();

    if (sortBy == 'Ngày tạo') {
      result.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
      );
    } else if (sortBy == 'Hạn hoàn thành') {
      result.sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;

        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      const priorityOrder = {
        'Cao': 0,
        'Trung bình': 1,
        'Thấp': 2,
      };

      result.sort(
            (a, b) =>
            (priorityOrder[a.priority] ?? 3)
                .compareTo(priorityOrder[b.priority] ?? 3),
      );
    }

    return result;
  }

  // Bộ lọc
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: options
            .map(
              (e) => DropdownMenuItem(
            value: e,
            child: Text(
              e,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Thẻ công việc
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
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _badge(
                    task.status,
                    getStatusColor(task.status),
                  ),
                  _badge(
                    'Ưu tiên ${task.priority}',
                    getPriorityColor(task.priority),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hạn: ${formatDate(task.dueDate)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
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

  // Nhãn trạng thái và ưu tiên
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
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
    final visibleTasks = filteredTasks;

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
            onPressed: isLoading ? null : _loadTasks,
            icon: const Icon(
              Icons.refresh,
              color: Colors.blue,
            ),
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
                            setState(() {
                              selectedTab = tab;
                            });
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
                    setState(() {
                      searchText = value;
                    });
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
                          setState(() {
                            statusFilter = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(width: 10),

                    buildFilter(
                      'Ưu tiên',
                      priorityFilter,
                      [
                        'Tất cả',
                        'Thấp',
                        'Trung bình',
                        'Cao',
                      ],
                          (value) {
                        if (value != null) {
                          setState(() {
                            priorityFilter = value;
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                buildFilter(
                  'Sắp xếp theo',
                  sortBy,
                  [
                    'Ngày tạo',
                    'Hạn hoàn thành',
                    'Độ ưu tiên',
                  ],
                      (value) {
                    if (value != null) {
                      setState(() {
                        sortBy = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading && tasks.isEmpty
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : errorMessage != null && tasks.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadTasks,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
                : visibleTasks.isEmpty
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
                  const Text(
                    'Nhấn "Tạo công việc" để bắt đầu',
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  90,
                ),
                itemCount: visibleTasks.length,
                itemBuilder: (context, index) {
                  return buildTaskCard(
                    visibleTasks[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
