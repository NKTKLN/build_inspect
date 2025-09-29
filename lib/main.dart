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
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/register',
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
