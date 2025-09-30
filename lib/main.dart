import 'package:build_inspect/pages/phase_card_page.dart';
import 'package:build_inspect/pages/project_card_page.dart';
import 'package:build_inspect/pages/projects_page.dart';
import 'package:flutter/material.dart';
import 'package:build_inspect/pages/login_page.dart';
import 'package:build_inspect/pages/register_page.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();

  await Hive.openBox('users');
  await Hive.openBox('projects');
  await Hive.openBox('phases');
  await Hive.openBox('defects');
  await Hive.openBox('attachments');
  await Hive.openBox('comments');
  await Hive.openBox('defect_history');
  await Hive.openBox('reports');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildInspect',
      initialRoute: '/login',
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/projects': (context) => const ProjectsPage(),
        '/project': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return ProjectCardPage(projectId: args);
        },
        '/phase': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return PhaseCardPage(phaseId: args);
        },
      },
    );
  }
}
