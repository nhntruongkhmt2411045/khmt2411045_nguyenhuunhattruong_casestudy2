
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/extra_service.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  late Future<List<Map<String, dynamic>>> _load;

  @override
  void initState() {
    super.initState();
    _load = _loadStats();
  }

  // E1 + E2: Tải dữ liệu thống kê
  Future<List<Map<String, dynamic>>> _loadStats() async {
    return Future.wait([
      ExtraService.taskStats(),
      ExtraService.assignmentStats(),
      ExtraService.deadlineStats(),
      ExtraService.assignmentDetailStats(),
    ]);
  }

  Future<void> _refresh() async {
    final future = _loadStats();
    setState(() => _load = future);
    await future;
  }

  int _number(dynamic value) => (value as num? ?? 0).toInt();

  // Thẻ chỉ số
  Widget _metric(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Biểu đồ tròn E1
  Widget _statusChart(Map<String, dynamic> stats) {
    final todo = _number(stats['todo']);
    final progress = _number(stats['in_progress']);
    final completed = _number(stats['completed']);
    final total = todo + progress + completed;

    final items = [
      ('Chưa thực hiện', todo, Colors.orange),
      ('Đang thực hiện', progress, Colors.blue),
      ('Hoàn thành', completed, Colors.green),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tỷ lệ trạng thái công việc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (total == 0)
              const SizedBox(
                height: 180,
                child: Center(
                  child: Text('Chưa có dữ liệu công việc'),
                ),
              )
            else
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 38,
                          sections: items
                              .where((item) => item.$2 > 0)
                              .map(
                                (item) => PieChartSectionData(
                              value: item.$2.toDouble(),
                              color: item.$3,
                              title:
                              '${(item.$2 * 100 / total).round()}%',
                              radius: 48,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: item.$3,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    item.$1,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                Text(
                                  '${item.$2}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Biểu đồ cột E1
  Widget _barChart(Map<String, dynamic> stats) {
    final values = [
      _number(stats['todo']),
      _number(stats['in_progress']),
      _number(stats['completed']),
    ];

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue == 0 ? 5.0 : (maxValue * 1.25 + 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 20),
              child: Text(
                'Số lượng công việc theo trạng thái',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          const labels = [
                            'Chưa làm',
                            'Đang làm',
                            'Xong',
                          ];
                          final index = value.toInt();

                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(3, (index) {
                    final colors = [
                      Colors.orange,
                      Colors.blue,
                      Colors.green,
                    ];

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index].toDouble(),
                          color: colors[index],
                          width: 28,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cảnh báo thời hạn E1
  Widget _deadlineCard(Map<String, dynamic> deadlines) {
    final overdueTasks =
        deadlines['overdueTasks'] as List? ?? [];
    final dueSoonTasks =
        deadlines['dueSoonTasks'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cảnh báo thời hạn'),
        Row(
          children: [
            _metric(
              'Quá hạn',
              '${_number(deadlines['overdue'])}',
              Icons.warning_amber,
              Colors.red,
            ),
            _metric(
              'Sắp đến hạn',
              '${_number(deadlines['dueSoon'])}',
              Icons.schedule,
              Colors.orange,
            ),
          ],
        ),
        if (overdueTasks.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Công việc quá hạn gần đây',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...overdueTasks.map((task) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.error_outline,
                color: Colors.red,
              ),
              title: Text(task['title']?.toString() ?? ''),
              subtitle: Text('Hạn: ${task['dueDate'] ?? ''}'),
            );
          }),
        ],
        if (dueSoonTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Công việc sắp đến hạn',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...dueSoonTasks.map((task) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.schedule,
                color: Colors.orange,
              ),
              title: Text(task['title']?.toString() ?? ''),
              subtitle: Text('Hạn: ${task['dueDate'] ?? ''}'),
            );
          }),
        ],
      ],
    );
  }

  // E2: Một chỉ số trạng thái
  Widget _statusItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  // E2: Thống kê chi tiết công việc được giao / phụ trách
  Widget _assignmentDetailCard(
      String title,
      Map<String, dynamic> data,
      IconData icon,
      Color color,
      ) {
    final todo = _number(data['todo']);
    final progress = _number(data['in_progress']);
    final completed = _number(data['completed']);
    final total = _number(data['total']);
    final rate = _number(data['completionRate']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng công việc'),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : rate / 100,
                minHeight: 9,
                color: color,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tỷ lệ hoàn thành: $rate%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _statusItem(
                    'Chưa làm',
                    todo,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _statusItem(
                    'Đang làm',
                    progress,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _statusItem(
                    'Hoàn thành',
                    completed,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tổng quan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load,
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
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Không tải được thống kê\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.length < 4) {
            return const Center(
              child: Text('Dữ liệu thống kê không đầy đủ'),
            );
          }

          final stats = snapshot.data![0];
          final assignments = snapshot.data![1];
          final deadlines = snapshot.data![2];
          final assignmentDetails = snapshot.data![3];

          final assignedDetails = Map<String, dynamic>.from(
            assignmentDetails['assigned'] ?? {},
          );

          final responsibleDetails = Map<String, dynamic>.from(
            assignmentDetails['responsible'] ?? {},
          );

          final total = _number(stats['total']);
          final completed = _number(stats['completed']);
          final rate = _number(stats['completionRate']);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Tình hình công việc',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Theo dõi tiến độ và hiệu suất công việc của bạn.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),

                // Tổng quan E1
                Row(
                  children: [
                    _metric(
                      'Tổng công việc',
                      '$total',
                      Icons.checklist,
                      Colors.blue,
                    ),
                    _metric(
                      'Hoàn thành',
                      '$completed',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tiến độ hoàn thành',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : rate / 100,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đã hoàn thành $rate%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Biểu đồ E1
                _sectionTitle('Biểu đồ thống kê'),
                _statusChart(stats),
                const SizedBox(height: 12),
                _barChart(stats),

                // Hạn công việc E1
                _deadlineCard(deadlines),

                // Phân công E1
                _sectionTitle('Phân công & phụ trách'),
                Row(
                  children: [
                    _metric(
                      'Đã tạo',
                      '${_number(assignments['created'])}',
                      Icons.create_outlined,
                      Colors.teal,
                    ),
                    _metric(
                      'Được giao',
                      '${_number(assignments['assigned'])}',
                      Icons.assignment_ind_outlined,
                      Colors.blue,
                    ),
                    _metric(
                      'Phụ trách chính',
                      '${_number(assignments['primary'])}',
                      Icons.star_outline,
                      Colors.orange,
                    ),
                  ],
                ),

                // Thống kê chi tiết E2
                const SizedBox(height: 12),
                _sectionTitle('Thống kê chi tiết công việc'),

                _assignmentDetailCard(
                  'Công việc được giao cho bạn',
                  assignedDetails,
                  Icons.assignment_ind_outlined,
                  Colors.blue,
                ),

                _assignmentDetailCard(
                  'Công việc bạn phụ trách chính',
                  responsibleDetails,
                  Icons.star_outline,
                  Colors.orange,
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
