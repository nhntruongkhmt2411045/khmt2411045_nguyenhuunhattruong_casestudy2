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
  List<String> assigneeIds;

  // Giữ danh sách ID để tương thích với code cũ.
  List<String> sharedWith;

  // Thông tin chi tiết người được chia sẻ.
  List<TaskShare> shares;

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
    this.assigneeIds = const [],
    this.sharedWith = const [],
    this.shares = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Chuyển trạng thái từ Backend sang tiếng Việt.
  static String statusFromApi(dynamic value) {
    switch (value?.toString()) {
      case 'todo':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      default:
        return value?.toString() ?? 'Chưa thực hiện';
    }
  }

  // Chuyển trạng thái từ tiếng Việt sang Backend.
  static String statusToApi(String value) {
    switch (value) {
      case 'Chưa thực hiện':
        return 'todo';
      case 'Đang thực hiện':
        return 'in_progress';
      case 'Hoàn thành':
        return 'completed';
      default:
        return value;
    }
  }

  // Chuyển độ ưu tiên từ Backend sang tiếng Việt.
  static String priorityFromApi(dynamic value) {
    switch (value?.toString()) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return value?.toString() ?? 'Trung bình';
    }
  }

  // Chuyển độ ưu tiên từ tiếng Việt sang Backend.
  static String priorityToApi(String value) {
    switch (value) {
      case 'Thấp':
        return 'low';
      case 'Trung bình':
        return 'medium';
      case 'Cao':
        return 'high';
      default:
        return value;
    }
  }

  // Đọc dữ liệu từ Backend.
  factory Task.fromJson(Map<String, dynamic> json) {
    final creatorData = json['createdBy'];
    final assigneeData = json['primaryAssigneeId'];
    final rawAssignees = json['assigneeIds'] as List? ?? [];

    final parsedAssigneeIds = rawAssignees.map((item) {
      if (item is Map) {
        return item['_id']?.toString() ?? '';
      }
      return item.toString();
    }).where((id) => id.isNotEmpty).toSet().toList();

    final primaryAssigneeId = assigneeData is Map
        ? assigneeData['_id']?.toString() ?? ''
        : assigneeData?.toString() ?? '';

    if (primaryAssigneeId.isNotEmpty &&
        !parsedAssigneeIds.contains(primaryAssigneeId)) {
      parsedAssigneeIds.add(primaryAssigneeId);
    }

    final rawShares = json['sharedWith'] as List? ?? [];

    final parsedShares = rawShares
        .whereType<Map>()
        .map((item) => TaskShare.fromJson(
      Map<String, dynamic>.from(item),
    ))
        .toList();

    final sharedIds = parsedShares
        .map((share) => share.userId)
        .where((id) => id.isNotEmpty)
        .toList();

    return Task(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: statusFromApi(json['status']),
      priority: priorityFromApi(json['priority']),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
      creator: creatorData is Map
          ? creatorData['_id']?.toString() ?? ''
          : creatorData?.toString() ?? '',
      assignee: primaryAssigneeId,
      assigneeIds: parsedAssigneeIds,
      sharedWith: sharedIds,
      shares: parsedShares,
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );
  }

  // Chuyển dữ liệu sang Backend.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': statusToApi(status),
      'priority': priorityToApi(priority),
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}

// Thông tin người được chia sẻ công việc.
class TaskShare {
  final String userId;
  final String fullName;
  final String email;
  final String permission;
  final DateTime? sharedAt;

  const TaskShare({
    required this.userId,
    this.fullName = '',
    this.email = '',
    this.permission = 'view',
    this.sharedAt,
  });

  factory TaskShare.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];

    return TaskShare(
      userId: user is Map
          ? user['_id']?.toString() ?? ''
          : user?.toString() ?? '',
      fullName: user is Map
          ? user['fullName']?.toString() ?? ''
          : '',
      email: user is Map
          ? user['email']?.toString() ?? ''
          : '',
      permission: json['permission']?.toString() ?? 'view',
      sharedAt: json['sharedAt'] != null
          ? DateTime.tryParse(json['sharedAt'].toString())
          : null,
    );
  }
}