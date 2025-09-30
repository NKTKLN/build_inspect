import 'package:build_inspect/pages/login_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:universal_html/html.dart' as html;

class PhaseCardPage extends StatefulWidget {
  final int phaseId;

  const PhaseCardPage({super.key, required this.phaseId});

  @override
  State<PhaseCardPage> createState() => _PhaseCardPageState();
}

class _PhaseCardPageState extends State<PhaseCardPage> {
  final phasesBox = Hive.box('phases');
  final defectsBox = Hive.box('defects');
  final usersBox = Hive.box('users');

  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? phase;
  String searchQuery = "";
  String sortBy = "date"; // date | name

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPhase();
  }

  void _loadCurrentUser() {
    final cookies = html.document.cookie ?? '';
    final cookieMap = {
      for (var c in cookies.split(';'))
        if (c.contains('=')) c.split('=')[0].trim(): c.split('=')[1].trim(),
    };
    final email = cookieMap['current_user_email'];

    if (email != null && usersBox.containsKey(email)) {
      setState(() {
        currentUser = Map<String, dynamic>.from(usersBox.get(email));
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      });
    }
  }

  void _loadPhase() {
    setState(() {
      phase = Map<String, dynamic>.from(phasesBox.getAt(widget.phaseId));
    });
  }

  void _editPhaseDialog() {
    final nameController = TextEditingController(text: phase?['name']);
    final descController = TextEditingController(text: phase?['description']);
    final statusOptions = [
      'Не выполнен',
      'В процессе',
      'На проверке',
      'Завершен',
    ];
    final priorityOptions = ['Низкий', 'Средний', 'Высокий'];
    String status = phase?['status'] ?? 'Не выполнен';
    String priority = phase?['priority'] ?? 'Низкий';
    DateTime? deadline = phase?['deadline'] != null
        ? DateTime.tryParse(phase!['deadline'])
        : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Редактировать этап"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Название"),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Описание"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: "Статус"),
                      items: statusOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => status = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: "Приоритет"),
                      items: priorityOptions
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Дедлайн: ${deadline != null ? "${deadline!.day}.${deadline!.month}.${deadline!.year}" : "—"}",
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: deadline ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                deadline = picked;
                              });
                            }
                          },
                          child: const Text("Выбрать"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Отмена"),
                ),
                ElevatedButton(
                  onPressed: () {
                    phase?['name'] = nameController.text.trim();
                    phase?['description'] = descController.text.trim();
                    phase?['status'] = status;
                    phase?['priority'] = priority;
                    phase?['deadline'] = deadline?.toIso8601String();
                    phasesBox.putAt(widget.phaseId, phase!);
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text("Сохранить"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _createDefectDialog() {
    final nameController = TextEditingController();
    DateTime? deadline;
    String status = "Открыт";
    String priority = "Низкий";

    final statusOptions = ['Открыт', 'В процессе', 'Закрыт'];
    final priorityOptions = ['Низкий', 'Средний', 'Высокий'];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Создать дефект"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Название"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: "Статус"),
                  items: statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) status = value;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: "Приоритет"),
                  items: priorityOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) priority = value;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Дедлайн: ${deadline != null ? "${deadline!.day}.${deadline!.month}.${deadline!.year}" : "—"}",
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            deadline = picked;
                          });
                        }
                      },
                      child: const Text("Выбрать"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  defectsBox.add({
                    'name': name,
                    'phase_id': widget.phaseId,
                    'status': status,
                    'priority': priority,
                    'deadline': deadline?.toIso8601String(),
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  setState(() {});
                }
                Navigator.pop(ctx);
              },
              child: const Text("Создать"),
            ),
          ],
        );
      },
    );
  }

  Widget buildCharts(List<Map<String, dynamic>> defects) {
    Map<String, int> defectsByDate = {};
    for (var d in defects) {
      if (d['created_at'] != null) {
        final date = DateTime.tryParse(d['created_at']!)!;
        final key = "${date.year}-${date.month}-${date.day}";
        defectsByDate[key] = (defectsByDate[key] ?? 0) + 1;
      }
    }
    final sortedDates = defectsByDate.keys.toList()..sort();

    List<FlSpot> timeSpots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      timeSpots.add(
        FlSpot(i.toDouble(), defectsByDate[sortedDates[i]]!.toDouble()),
      );
    }

    Map<String, int> defectsByStatus = {};
    for (var d in defects) {
      final status = d['status'] ?? 'Открыт';
      defectsByStatus[status] = (defectsByStatus[status] ?? 0) + 1;
    }

    Map<String, int> defectsByPriority = {};
    for (var d in defects) {
      final priority = d['priority'] ?? 'Низкий';
      defectsByPriority[priority] = (defectsByPriority[priority] ?? 0) + 1;
    }

    return Column(
      children: [
        // График по времени
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < sortedDates.length) {
                        return Text(
                          sortedDates[value.toInt()]
                              .split('-')
                              .sublist(1)
                              .join('.'),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: timeSpots,
                  isCurved: true,
                  barWidth: 3,
                  color: Colors.blue,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final keys = defectsByStatus.keys.toList();
                            if (value.toInt() >= 0 &&
                                value.toInt() < keys.length) {
                              return Text(
                                keys[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    barGroups: List.generate(defectsByStatus.length, (i) {
                      final key = defectsByStatus.keys.toList()[i];
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: defectsByStatus[key]!.toDouble(),
                            color: Colors.orange,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final keys = defectsByPriority.keys.toList();
                            if (value.toInt() >= 0 &&
                                value.toInt() < keys.length) {
                              return Text(
                                keys[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    barGroups: List.generate(defectsByPriority.length, (i) {
                      final key = defectsByPriority.keys.toList()[i];
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: defectsByPriority[key]!.toDouble(),
                            color: Colors.red,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (phase == null || currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<Map<String, dynamic>> phaseDefects = [];
    for (int i = 0; i < defectsBox.length; i++) {
      final defect = Map<String, dynamic>.from(defectsBox.getAt(i));
      if (defect['phase_id'] == widget.phaseId) {
        defect['id'] = i;
        phaseDefects.add(defect);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Этап: ${phase?['name'] ?? ''}"),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey[400],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: currentUser?['role'] == 'Менеджер'
          ? FloatingActionButton(
              onPressed: _createDefectDialog,
              backgroundColor: Colors.red[400],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phase?['name'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              phase?['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  "Статус: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(phase?['status'] ?? 'Не выполнен'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Приоритет: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(phase?['priority'] ?? 'Низкий'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Дедлайн: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(phase?['deadline']?.substring(0, 10) ?? '—'),
              ],
            ),
            const SizedBox(height: 10),
            if (currentUser?['role'] == 'Менеджер')
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _editPhaseDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text("Редактировать этап"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      phasesBox.deleteAt(widget.phaseId);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text("Удалить"),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Text(
              "Графики дефектов",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buildCharts(phaseDefects),
            const SizedBox(height: 24),
            const Text(
              "Дефекты этапа",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: ValueListenableBuilder(
                valueListenable: defectsBox.listenable(),
                builder: (context, Box box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text("Нет дефектов"));
                  }

                  List<Map<String, dynamic>> phaseDefects = [];
                  for (int i = 0; i < box.length; i++) {
                    final defect = Map<String, dynamic>.from(box.getAt(i));
                    if (defect['phase_id'] == widget.phaseId) {
                      defect['id'] = i;
                      phaseDefects.add(defect);
                    }
                  }

                  if (searchQuery.isNotEmpty) {
                    phaseDefects = phaseDefects.where((d) {
                      return (d['name'] ?? '').toLowerCase().contains(
                            searchQuery,
                          ) ||
                          (d['status'] ?? '').toLowerCase().contains(
                            searchQuery,
                          );
                    }).toList();
                  }

                  if (sortBy == "name") {
                    phaseDefects.sort(
                      (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''),
                    );
                  } else {
                    phaseDefects.sort(
                      (a, b) => (b['created_at'] ?? '').compareTo(
                        a['created_at'] ?? '',
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.white),
                        dataRowColor: WidgetStateProperty.all(Colors.white),
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        columns: const [
                          DataColumn(label: Text("Название")),
                          DataColumn(label: Text("Дедлайн")),
                          DataColumn(label: Text("Дата создания")),
                          DataColumn(label: Text("Статус")),
                          DataColumn(label: Text("Приоритет")),
                        ],
                        rows: phaseDefects.map((defect) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(defect['name'] ?? ''),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/defect',
                                  arguments: defect["id"],
                                ),
                              ),
                              DataCell(
                                Text(defect['deadline'] ?? '—'),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/defect',
                                  arguments: defect["id"],
                                ),
                              ),
                              DataCell(
                                Text(defect['created_at'] ?? '—'),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/defect',
                                  arguments: defect["id"],
                                ),
                              ),
                              DataCell(
                                Text(defect['status'] ?? 'Открыт'),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/defect',
                                  arguments: defect["id"],
                                ),
                              ),
                              DataCell(
                                Text(defect['priority'] ?? 'Низкий'),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/defect',
                                  arguments: defect["id"],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
