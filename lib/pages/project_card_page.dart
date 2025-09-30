import 'package:build_inspect/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:universal_html/html.dart' as html;

class ProjectCardPage extends StatefulWidget {
  final int projectId;

  const ProjectCardPage({super.key, required this.projectId});

  @override
  State<ProjectCardPage> createState() => _ProjectCardPageState();
}

class _ProjectCardPageState extends State<ProjectCardPage>
    with SingleTickerProviderStateMixin {
  final projectsBox = Hive.box('projects');
  final phasesBox = Hive.box('phases');
  final usersBox = Hive.box('users');

  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? project;
  String searchQuery = "";
  String sortBy = "date"; // date | name

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadProject();
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

  void _loadProject() {
    setState(() {
      project = Map<String, dynamic>.from(projectsBox.getAt(widget.projectId));
    });
  }

  void _editProjectDialog() {
    final nameController = TextEditingController(text: project?['name']);
    final descController = TextEditingController(text: project?['description']);
    final selectedUsers = List<String>.from(project?['users'] ?? []);
    final statusOptions = ['Не выполнен', 'В процессе', 'Завершен'];
    final priorityOptions = ['Низкий', 'Средний', 'Высокий'];
    String status = project?['status'] ?? 'Не выполнен';
    String priority = project?['priority'] ?? 'Низкий';
    DateTime? deadline = project?['deadline'] != null
        ? DateTime.tryParse(project!['deadline'])
        : null;

    // Все пользователи кроме текущего
    final allUsers = usersBox.keys
        .map((key) => Map<String, dynamic>.from(usersBox.get(key)))
        .where((user) => user['email'] != currentUser?['email'])
        .toList();

    final items = allUsers
        .map(
          (user) => MultiSelectItem<String>(
            user['email'],
            "${user['name']} ${user['surname']} (${user['role']})",
          ),
        )
        .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Редактировать проект"),
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
                    MultiSelectDialogField<String>(
                      items: items,
                      searchable: true,
                      title: const Text("Участники проекта"),
                      buttonText: const Text("Добавить/удалить пользователей"),
                      confirmText: const Text("Готово"),
                      cancelText: const Text("Отмена"),
                      initialValue: selectedUsers,
                      onConfirm: (values) {
                        setDialogState(() {
                          selectedUsers.clear();
                          selectedUsers.addAll(values);
                        });
                      },
                      chipDisplay: MultiSelectChipDisplay(
                        onTap: (value) {
                          setDialogState(() {
                            selectedUsers.remove(value);
                          });
                        },
                      ),
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
                          setDialogState(() {
                            priority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Дедлайн
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
                    project?['name'] = nameController.text.trim();
                    project?['description'] = descController.text.trim();
                    project?['users'] = selectedUsers;
                    project?['status'] = status;
                    project?['priority'] = priority;
                    project?['deadline'] = deadline?.toIso8601String();
                    projectsBox.putAt(widget.projectId, project!);
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

  void _createPhaseDialog() {
    final nameController = TextEditingController();
    DateTime? deadline;
    String status = "Не выполнен";
    String priority = "Низкий";

    final statusOptions = ['Не выполнен', 'В процессе', 'Завершен'];
    final priorityOptions = ['Низкий', 'Средний', 'Высокий'];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Создать этап"),
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
                  phasesBox.add({
                    'name': name,
                    'project_id': widget.projectId,
                    'status': status,
                    'priority': priority,
                    'deadline': deadline?.toIso8601String(),
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  setState(() {});
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
              ),
              child: const Text("Создать"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (project == null || currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Проект: ${project?['name'] ?? ''}"),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey[400],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: currentUser?['role'] == 'Менеджер'
          ? FloatingActionButton(
              onPressed: _createPhaseDialog,
              backgroundColor: Colors.blue[400],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project?['name'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              project?['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Статус: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      project?['status'] ?? 'Не выполнен',
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Приоритет: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      project?['priority'] ?? 'Низкий',
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Дедлайн: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      project?['deadline'] != null
                          ? project!['deadline']!.substring(0, 10)
                          : '—',
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (currentUser?['role'] == 'Менеджер')
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _editProjectDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text("Редактировать проект"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Удалить проект"),
                              content: const Text(
                                "Вы уверены, что хотите удалить этот проект?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Отмена"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    projectsBox.deleteAt(widget.projectId);
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Удалить"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text("Удалить проект"),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Этапы проекта",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: phasesBox.listenable(),
                builder: (context, Box box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text("Нет этапов"));
                  }

                  List<Map<String, dynamic>> projectPhases = [];
                  for (int i = 0; i < box.length; i++) {
                    final phase = Map<String, dynamic>.from(box.getAt(i));
                    if (phase['project_id'] == widget.projectId) {
                      phase['id'] = i;
                      projectPhases.add(phase);
                    }
                  }
                  if (searchQuery.isNotEmpty) {
                    projectPhases = projectPhases
                        .where(
                          (p) =>
                              (p['name'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery) ||
                              (p['status'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery),
                        )
                        .toList();
                  }
                  if (sortBy == "name") {
                    projectPhases.sort(
                      (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''),
                    );
                  } else {
                    projectPhases.sort(
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
                        rows: projectPhases.map((phase) {
                          return DataRow(
                            cells: [
                              DataCell(Text(phase['name'] ?? ''), onTap: () {}),
                              DataCell(
                                Text(phase['deadline'] ?? '—'),
                                onTap: () {},
                              ),
                              DataCell(
                                Text(phase['created_at'] ?? '—'),
                                onTap: () {},
                              ),
                              DataCell(
                                Text(phase['status'] ?? 'Не выполнен'),
                                onTap: () {},
                              ),
                              DataCell(
                                Text(phase['priority'] ?? 'Низкий'),
                                onTap: () {},
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
