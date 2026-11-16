
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';

class ShareTaskScreen extends StatefulWidget {
final String taskId;

const ShareTaskScreen({
super.key,
required this.taskId,
});

@override
State<ShareTaskScreen> createState() => _ShareTaskScreenState();
}

class _ShareTaskScreenState extends State<ShareTaskScreen> {
final TextEditingController _searchController = TextEditingController();

List<Map<String, dynamic>> _users = [];
List<TaskShare> _shares = [];

String _newPermission = 'view';
bool _searching = false;
bool _sharing = false;
bool _loadingShares = true;

@override
void initState() {
super.initState();
_loadShares();
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(message)),
);
}

Future<void> _loadShares() async {
if (mounted) {
setState(() => _loadingShares = true);
}

try {
final result = await TaskService.getTaskShares(widget.taskId);

if (!mounted) return;

setState(() {
_shares = result;
_loadingShares = false;
});
} catch (e) {
if (!mounted) return;

setState(() => _loadingShares = false);
_showMessage('Không tải được danh sách chia sẻ: $e');
}
}

Future<void> _searchUsers() async {
final keyword = _searchController.text.trim();

if (keyword.length < 2) {
_showMessage('Vui lòng nhập ít nhất 2 ký tự để tìm kiếm');
return;
}

setState(() {
_searching = true;
_users = [];
});

try {
final result = await TaskService.searchUsers(keyword);

if (!mounted) return;

setState(() {
_users = result;
_searching = false;
});

if (result.isEmpty) {
_showMessage('Không tìm thấy người dùng phù hợp');
}
} catch (e) {
if (!mounted) return;

setState(() => _searching = false);
_showMessage('Lỗi tìm kiếm người dùng: $e');
}
}

Future<void> _shareWithUser(Map<String, dynamic> user) async {
final userId = user['_id']?.toString() ?? '';

if (userId.isEmpty) {
_showMessage('Không xác định được ID người dùng');
return;
}

setState(() => _sharing = true);

try {
await TaskService.shareTask(
widget.taskId,
userId,
permission: _newPermission,
);

if (!mounted) return;

_showMessage('Chia sẻ công việc thành công');

setState(() {
_users.removeWhere(
(item) => item['_id']?.toString() == userId,
);
});

await _loadShares();
} catch (e) {
if (mounted) {
_showMessage('Không thể chia sẻ công việc: $e');
}
} finally {
if (mounted) {
setState(() => _sharing = false);
}
}
}

Future<void> _updatePermission(
TaskShare share,
String permission,
) async {
try {
await TaskService.updateTaskShare(
widget.taskId,
share.userId,
permission,
);

_showMessage('Cập nhật quyền thành công');
await _loadShares();
} catch (e) {
_showMessage('Không thể cập nhật quyền: $e');
}
}

Future<void> _removeShare(TaskShare share) async {
final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Thu hồi chia sẻ'),
content: Text(
'Bạn có chắc muốn thu hồi quyền của '
'${share.fullName.isNotEmpty ? share.fullName : share.email} không?',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Hủy'),
),
FilledButton(
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('Thu hồi'),
),
],
),
);

if (confirmed != true) return;

try {
await TaskService.removeTaskShare(
widget.taskId,
share.userId,
);

_showMessage('Đã thu hồi quyền chia sẻ');
await _loadShares();
} catch (e) {
_showMessage('Không thể thu hồi chia sẻ: $e');
}
}

String _permissionName(String permission) {
return permission == 'edit'
? 'Người chỉnh sửa (Editor)'
    : 'Người xem (Viewer)';
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Chia sẻ công việc'),
),
body: RefreshIndicator(
onRefresh: _loadShares,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
const Text(
'Tìm người dùng',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 12),

TextField(
controller: _searchController,
textInputAction: TextInputAction.search,
onSubmitted: (_) => _searchUsers(),
decoration: InputDecoration(
hintText: 'Nhập tên hoặc email người dùng',
prefixIcon: const Icon(Icons.search),
border: const OutlineInputBorder(),
suffixIcon: IconButton(
tooltip: 'Tìm kiếm',
onPressed: _searching ? null : _searchUsers,
icon: const Icon(Icons.arrow_forward),
),
),
),

const SizedBox(height: 12),

DropdownButtonFormField<String>(
value: _newPermission,
decoration: const InputDecoration(
labelText: 'Quyền khi chia sẻ',
border: OutlineInputBorder(),
),
items: const [
DropdownMenuItem(
value: 'view',
child: Text('Người xem (Viewer)'),
),
DropdownMenuItem(
value: 'edit',
child: Text('Người chỉnh sửa (Editor)'),
),
],
onChanged: _sharing
? null
    : (value) {
if (value != null) {
setState(() => _newPermission = value);
}
},
),

const SizedBox(height: 12),

if (_searching)
const Center(
child: Padding(
padding: EdgeInsets.all(16),
child: CircularProgressIndicator(),
),
),

..._users.map((user) {
final name = user['fullName']?.toString() ?? 'Người dùng';
final email = user['email']?.toString() ?? '';

return Card(
child: ListTile(
leading: const CircleAvatar(
child: Icon(Icons.person),
),
title: Text(name),
subtitle: Text(email),
trailing: IconButton(
tooltip: 'Chia sẻ',
onPressed: _sharing
? null
    : () => _shareWithUser(user),
icon: const Icon(
Icons.person_add_alt_1,
color: Colors.deepPurple,
),
),
),
);
}),

const Divider(height: 32),

Row(
children: [
const Expanded(
child: Text(
'Danh sách đã chia sẻ',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
),
IconButton(
tooltip: 'Tải lại',
onPressed: _loadShares,
icon: const Icon(Icons.refresh),
),
],
),

if (_loadingShares)
const Center(
child: Padding(
padding: EdgeInsets.all(20),
child: CircularProgressIndicator(),
),
)
else if (_shares.isEmpty)
const Padding(
padding: EdgeInsets.all(20),
child: Text(
'Chưa chia sẻ công việc cho ai.',
textAlign: TextAlign.center,
),
)
else
..._shares.map((share) {
final displayName = share.fullName.isNotEmpty
? share.fullName
    : 'Người dùng';

return Card(
child: Padding(
padding: const EdgeInsets.all(12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const CircleAvatar(
child: Icon(Icons.person_outline),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
displayName,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
Text(
share.email.isNotEmpty
? share.email
    : share.userId,
style: const TextStyle(fontSize: 12),
),
],
),
),
IconButton(
tooltip: 'Thu hồi chia sẻ',
onPressed: () => _removeShare(share),
icon: const Icon(
Icons.delete_outline,
color: Colors.red,
),
),
],
),

const SizedBox(height: 8),

DropdownButtonFormField<String>(
value: share.permission,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'Quyền truy cập',
border: OutlineInputBorder(),
isDense: true,
),
items: const [
DropdownMenuItem(
value: 'view',
child: Text('Người xem (Viewer)'),
),
DropdownMenuItem(
value: 'edit',
child: Text('Người chỉnh sửa (Editor)'),
),
],
onChanged: (value) {
if (value != null &&
value != share.permission) {
_updatePermission(share, value);
}
},
),

const SizedBox(height: 4),
Text(
'Hiện tại: ${_permissionName(share.permission)}',
style: const TextStyle(
color: Colors.deepPurple,
fontSize: 12,
),
),
],
),
),
);
}),
],
),
),
);
}
}
