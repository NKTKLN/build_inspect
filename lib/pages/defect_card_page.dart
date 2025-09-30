import 'package:build_inspect/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:universal_html/html.dart' as html;

class DefectPage extends StatefulWidget {
  final int defectId;

  const DefectPage({super.key, required this.defectId});

  @override
  State<DefectPage> createState() => _DefectPageState();
}

class _DefectPageState extends State<DefectPage> {
  final defectsBox = Hive.box('defects');
  final commentsBox = Hive.box('comments');
  final logsBox = Hive.box('logs');
  final usersBox = Hive.box('users');

  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? defect;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDefect();
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

  void _loadDefect() {
    setState(() {
      defect = Map<String, dynamic>.from(defectsBox.getAt(widget.defectId));
    });
  }

  void _editDefectDialog() {
    final nameController = TextEditingController(text: defect?['name']);
    String status = defect?['status'] ?? 'Открыт';
    String priority = defect?['priority'] ?? 'Низкий';
    DateTime? deadline = defect?['deadline'] != null
        ? DateTime.tryParse(defect!['deadline'])
        : null;

    final statusOptions = ['Открыт', 'В процессе', 'Закрыт'];
    final priorityOptions = ['Низкий', 'Средний', 'Высокий'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Редактировать дефект"),
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
                        if (value != null) setDialogState(() => status = value);
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
                        if (value != null) setDialogState(() => priority = value);
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
                    logsBox.add({
                      'defect_id': widget.defectId,
                      'timestamp': DateTime.now().toIso8601String(),
                      'changes': {
                        'name': {'old': defect?['name'], 'new': nameController.text},
                        'status': {'old': defect?['status'], 'new': status},
                        'priority': {'old': defect?['priority'], 'new': priority},
                        'deadline': {'old': defect?['deadline'], 'new': deadline?.toIso8601String()},
                      },
                      'user': currentUser?['email'],
                    });

                    defect?['name'] = nameController.text.trim();
                    defect?['status'] = status;
                    defect?['priority'] = priority;
                    defect?['deadline'] = deadline?.toIso8601String();
                    defectsBox.putAt(widget.defectId, defect!);
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

  Future<void> _addComment() async {
    if (commentController.text.trim().isEmpty) return;

    await commentsBox.add({
      'defect_id': widget.defectId,
      'user': currentUser?['email'],
      'comment': commentController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    commentController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (defect == null || currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<Map<String, dynamic>> defectComments = [];
    for (int i = 0; i < commentsBox.length; i++) {
      final c = Map<String, dynamic>.from(commentsBox.getAt(i));
      if (c['defect_id'] == widget.defectId) defectComments.add(c);
    }

    List<Map<String, dynamic>> defectLogs = [];
    for (int i = 0; i < logsBox.length; i++) {
      final l = Map<String, dynamic>.from(logsBox.getAt(i));
      if (l['defect_id'] == widget.defectId) defectLogs.add(l);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Дефект: ${defect?['name'] ?? ''}"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 2,
        shadowColor: Colors.grey[400],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(defect?['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [const Text("Статус: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(defect?['status'] ?? 'Открыт')]),
            const SizedBox(height: 8),
            Row(children: [const Text("Приоритет: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(defect?['priority'] ?? 'Низкий')]),
            const SizedBox(height: 8),
            Row(children: [const Text("Дедлайн: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(defect?['deadline']?.substring(0, 10) ?? '—')]),
            const SizedBox(height: 24),

            if (currentUser?['role'] == 'Менеджер' || currentUser?['role'] == 'Инженер')
              Row(
                children: [
                  ElevatedButton.icon(onPressed: _editDefectDialog, icon: const Icon(Icons.edit), label: const Text("Редактировать")),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      defectsBox.deleteAt(widget.defectId);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text("Удалить"),
                  ),
                ],
              ),

            const SizedBox(height: 24),
            const Text("Комментарии", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Container(
              height: 500,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: defectComments.length,
                  itemBuilder: (context, index) {
                    final c = defectComments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(c['comment'] ?? ''),
                        subtitle: Text("От: ${c['user']}  |  ${c['timestamp'].substring(0, 16)}"),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: "Добавить комментарий",
                suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
              ),
            ),

            const SizedBox(height: 24),
            const Text("Логи изменений", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...defectLogs.map((l) => ListTile(
                  title: Text("Изменения от ${l['user']}"),
                  subtitle: Text("${l['timestamp'].substring(0, 16)}\n${l['changes']}"),
                )),
          ],
        ),
      ),
    );
  }
}
