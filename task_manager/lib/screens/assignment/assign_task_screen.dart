import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final Task task;
  const AssignTaskScreen({super.key, required this.task});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _search = TextEditingController();
  final Set<String> _selected = {};
  final Map<String, Map<String, dynamic>> _users = {};
  String? _primaryId;
  bool _loading = true;
  bool _saving = false;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    try {
      final data = await TaskService.getAssignees(widget.task.id);
      final list = data['assignees'] as List? ?? [];
      for (final item in list) {
        if (item is Map) {
          final user = Map<String, dynamic>.from(item);
          final id = user['_id']?.toString() ?? '';
          if (id.isNotEmpty) {
            _selected.add(id);
            _users[id] = user;
          }
        }
      }
      final primary = data['primaryAssignee'];
      _primaryId = primary is Map ? primary['_id']?.toString() : primary?.toString();
      if (_primaryId != null && _primaryId!.isNotEmpty) _selected.add(_primaryId!);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchUsers(String value) async {
    if (value.trim().length < 2) {
      setState(() => _users.removeWhere((id, user) => !_selected.contains(id)));
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await TaskService.searchUsers(value.trim());
      if (!mounted) return;
      setState(() {
        for (final user in results) {
          final id = user['_id']?.toString() ?? '';
          if (id.isNotEmpty) _users[id] = user;
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tìm được người dùng: $e')));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _save() async {
    if (_primaryId != null && !_selected.contains(_primaryId)) {
      setState(() => _primaryId = null);
    }
    setState(() => _saving = true);
    try {
      await TaskService.setAssignees(widget.task.id, _selected.toList(), primaryAssigneeId: _primaryId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể lưu phân công: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _users.entries.toList()
      ..sort((a, b) => (a.value['fullName'] ?? '').toString().compareTo((b.value['fullName'] ?? '').toString()));
    return Scaffold(
      appBar: AppBar(title: const Text('Giao công việc')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _search,
                  onChanged: _searchUsers,
                  decoration: InputDecoration(
                    labelText: 'Tìm theo tên hoặc email',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: Text('Chọn người được giao và đánh dấu người phụ trách chính.', style: TextStyle(color: Colors.grey)))),
              Expanded(child: shown.isEmpty
                  ? const Center(child: Text('Nhập ít nhất 2 ký tự để tìm người dùng'))
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, index) {
                        final entry = shown[index];
                        final id = entry.key;
                        final user = entry.value;
                        final selected = _selected.contains(id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              _selected.add(id);
                            } else {
                              _selected.remove(id);
                              if (_primaryId == id) _primaryId = null;
                            }
                          }),
                          title: Text(user['fullName']?.toString() ?? 'Người dùng'),
                          subtitle: Text(user['email']?.toString() ?? ''),
                          secondary: IconButton(
                            tooltip: 'Chọn làm phụ trách chính',
                            onPressed: selected ? () => setState(() => _primaryId = id) : null,
                            icon: Icon(_primaryId == id ? Icons.star : Icons.star_border, color: _primaryId == id ? Colors.orange : Colors.grey),
                          ),
                        );
                      },
                    )),
              SafeArea(child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                  label: Text(_saving ? 'Đang lưu...' : 'Lưu phân công (${_selected.length})'),
                )),
              )),
            ]),
    );
  }
}
