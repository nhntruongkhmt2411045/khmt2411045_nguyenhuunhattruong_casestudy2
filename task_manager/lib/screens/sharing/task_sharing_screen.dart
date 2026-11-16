import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class TaskSharingScreen extends StatefulWidget {
  final Task task;
  const TaskSharingScreen({super.key, required this.task});

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  final _search = TextEditingController();
  List<TaskShare> _shares = [];
  List<Map<String, dynamic>> _results = [];
  String _permission = 'view';
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await TaskService.getTaskShares(widget.task.id);
      if (mounted) setState(() => _shares = items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tải được danh sách chia sẻ: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchUsers(String value) async {
    if (value.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    try {
      final users = await TaskService.searchUsers(value.trim());
      if (mounted) setState(() => _results = users);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _share(Map<String, dynamic> user) async {
    final id = user['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _working = true);
    try {
      await TaskService.shareTask(widget.task.id, id, permission: _permission);
      _search.clear();
      _results = [];
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chia sẻ công việc')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể chia sẻ: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _changePermission(TaskShare share, String permission) async {
    try {
      await TaskService.updateTaskShare(widget.task.id, share.userId, permission);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể đổi quyền: $e')));
    }
  }

  Future<void> _remove(TaskShare share) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Thu hồi chia sẻ'),
      content: Text('Bạn có chắc muốn thu hồi quyền của ${share.fullName.isEmpty ? share.email : share.fullName}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Thu hồi')),
      ],
    ));
    if (ok != true) return;
    try {
      await TaskService.removeTaskShare(widget.task.id, share.userId);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể thu hồi: $e')));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chia sẻ & phân quyền')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Thêm người được chia sẻ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(controller: _search, onChanged: _searchUsers, decoration: const InputDecoration(labelText: 'Tìm theo tên hoặc email', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _permission,
          decoration: const InputDecoration(labelText: 'Quyền truy cập', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'view', child: Text('Viewer – Chỉ xem')),
            DropdownMenuItem(value: 'edit', child: Text('Editor – Được chỉnh sửa')),
          ],
          onChanged: (value) => setState(() => _permission = value ?? 'view'),
        ),
        if (_working) const LinearProgressIndicator(),
        ..._results.map((user) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
          title: Text(user['fullName']?.toString() ?? ''),
          subtitle: Text(user['email']?.toString() ?? ''),
          trailing: IconButton(onPressed: _working ? null : () => _share(user), icon: const Icon(Icons.share, color: Colors.blue)),
        )),
        const Divider(height: 32),
        Text('Đang chia sẻ (${_shares.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        if (_shares.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Chưa chia sẻ công việc này cho ai.', textAlign: TextAlign.center)),
        ..._shares.map((share) => Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(share.fullName.isEmpty ? share.email : share.fullName),
            subtitle: Text(share.email),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view' || value == 'edit') _changePermission(share, value);
                if (value == 'remove') _remove(share);
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(value: 'view', checked: share.permission == 'view', child: const Text('Viewer – Chỉ xem')),
                CheckedPopupMenuItem(value: 'edit', checked: share.permission == 'edit', child: const Text('Editor – Chỉnh sửa')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'remove', child: Text('Thu hồi quyền', style: TextStyle(color: Colors.red))),
              ],
              child: Chip(label: Text(share.permission == 'edit' ? 'Editor' : 'Viewer')),
            ),
          ),
        )),
      ],
    ),
  );
}
