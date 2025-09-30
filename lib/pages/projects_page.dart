import 'package:build_inspect/pages/login_page.dart';
import 'package:build_inspect/pages/project_card_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:universal_html/html.dart' as html;

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final projectsBox = Hive.box('projects');
  final usersBox = Hive.box('users');

  Map<String, dynamic>? currentUser;
  String searchQuery = "";
  String sortBy = "date"; // date | name

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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

  void _createProjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final selectedUsers = <String>[];

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
        return AlertDialog(
          title: const Text("Создать проект"),
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
                  title: const Text("Выберите участников"),
                  buttonText: const Text("Добавить пользователей"),
                  confirmText: const Text("Готово"),
                  cancelText: const Text("Отмена"),
                  onConfirm: (values) {
                    selectedUsers.clear();
                    selectedUsers.addAll(values);
                  },
                  chipDisplay: MultiSelectChipDisplay(
                    onTap: (value) {
                      setState(() {
                        selectedUsers.remove(value);
                      });
                    },
                  ),
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
                final desc = descController.text.trim();
                if (name.isNotEmpty) {
                  projectsBox.add({
                    'name': name,
                    'description': desc,
                    'users': selectedUsers.toList(),
                    'created_by': currentUser?['email'],
                    'created_at': DateTime.now().toIso8601String(),
                    'deadline': null,
                    'status': "Не выполнен",
                    'priority': "Низкий",
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
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isManager = currentUser?['role'] == 'Менеджер';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Проекты",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey[400],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: isManager
          ? FloatingActionButton(
              onPressed: _createProjectDialog,
              backgroundColor: Colors.blue[400],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        child: Column(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: "Поиск по имени...",
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    DropdownButton<String>(
                      value: sortBy,
                      items: const [
                        DropdownMenuItem(value: "date", child: Text("По дате")),
                        DropdownMenuItem(
                          value: "name",
                          child: Text("По имени"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          sortBy = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: projectsBox.listenable(),
                builder: (context, Box box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text("Нет проектов"));
                  }

                  List<Map<String, dynamic>> projects = [];
                  for (int i = 0; i < box.length; i++) {
                    final project = Map<String, dynamic>.from(box.getAt(i));
                    project['id'] = i;
                    projects.add(project);
                  }

                  if (searchQuery.isNotEmpty) {
                    projects = projects
                        .where(
                          (p) =>
                              (p['name'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery) ||
                              (p['description'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery),
                        )
                        .toList();
                  }

                  if (sortBy == "name") {
                    projects.sort(
                      (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''),
                    );
                  } else {
                    projects.sort(
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
                          DataColumn(label: Text("Статус")),
                          DataColumn(label: Text("Приоритет")),
                        ],
                        rows: projects.map((project) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(project['name'] ?? ''),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/project',
                                  arguments: project["id"],
                                ),
                              ),
                              DataCell(
                                Text(project['deadline'] ?? '—'),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/project',
                                  arguments: project["id"],
                                ),
                              ),
                              DataCell(
                                Text(project['status'] ?? 'Не выполнен'),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/project',
                                  arguments: project["id"],
                                ),
                              ),
                              DataCell(
                                Text(project['priority'] ?? 'Низкий'),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/project',
                                  arguments: project["id"],
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
