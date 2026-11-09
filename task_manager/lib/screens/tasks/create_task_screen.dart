
import 'package:flutter/material.dart';
import '../../models/task.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? task;

  const CreateTaskScreen({super.key, this.task});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String status = 'Chưa thực hiện';
  String priority = 'Trung bình';
  DateTime? startDate;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();

    final task = widget.task;
    if (task != null) {
      titleController.text = task.title;
      descriptionController.text = task.description;
      status = task.status;
      priority = task.priority;
      startDate = task.startDate;
      dueDate = task.dueDate;
    }
  }

  Future<void> selectDate(bool isStart) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (isStart ? startDate : dueDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        if (isStart) {
          startDate = selected;
        } else {
          dueDate = selected;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void saveTask() {
    if (!_formKey.currentState!.validate()) return;

    if (startDate != null &&
        dueDate != null &&
        dueDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hạn hoàn thành phải sau ngày bắt đầu')),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      status: status,
      priority: priority,
      startDate: startDate,
      dueDate: dueDate,
      creator: widget.task?.creator ?? 'current_user',
      assignee: widget.task?.assignee ?? '',
      sharedWith: widget.task?.sharedWith ?? [],
      createdAt: widget.task?.createdAt,
    );

    Navigator.pop(context, task);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(widget.task == null ? 'Tạo công việc' : 'Sửa công việc'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Thông tin công việc',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text('Tên công việc *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Nhập tên công việc',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên công việc';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),
            const Text('Mô tả'),
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập mô tả công việc...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 18),
            const Text('Trạng thái'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              items: ['Chưa thực hiện', 'Đang thực hiện', 'Hoàn thành']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => status = value);
              },
            ),

            const SizedBox(height: 18),
            const Text('Độ ưu tiên'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              items: ['Thấp', 'Trung bình', 'Cao']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => priority = value);
              },
            ),

            const SizedBox(height: 18),
            const Text('Ngày bắt đầu'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => selectDate(true),
              icon: const Icon(Icons.calendar_month),
              label: Text(formatDate(startDate)),
            ),

            const SizedBox(height: 12),
            const Text('Hạn hoàn thành'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => selectDate(false),
              icon: const Icon(Icons.event),
              label: Text(formatDate(dueDate)),
            ),

            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF315EFB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.task == null ? 'Tạo công việc' : 'Lưu thay đổi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
