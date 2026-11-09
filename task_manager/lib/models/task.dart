
class Task {
  final String id;
  String title;
  String description;
  String status;
  String priority;
  DateTime? startDate;
  DateTime? dueDate;
  String creator;
  String assignee;
  List<String> sharedWith;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'Chưa thực hiện',
    this.priority = 'Trung bình',
    this.startDate,
    this.dueDate,
    required this.creator,
    this.assignee = '',
    this.sharedWith = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
