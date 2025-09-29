import 'package:build_inspect/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String? selectedUserRoleValue;
  final usersBox = Hive.box('users');

  void register() {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;
    final role = selectedUserRoleValue;

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        role == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Заполните все поля")));
      return;
    }

    final nameRegex = RegExp(r'^[a-zA-Zа-яА-Я]{2,}$');
    if (!nameRegex.hasMatch(name) || !nameRegex.hasMatch(surname)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Имя и фамилия должны содержать только буквы и минимум 2 символа",
          ),
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Введите корректную почту")));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пароль должен быть не менее 6 символов")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Пароли не совпадают")));
      return;
    }

    if (usersBox.containsKey(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пользователь уже существует")),
      );
      return;
    }

    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    usersBox.put(email, {
      'name': name,
      'surname': surname,
      'email': email,
      'password_hash': passwordHash,
      'role': role,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Регистрация успешна")));
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: .5),
                  spreadRadius: 0.5,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Регистрация",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Имя"),
                      ),
                    ),
                    const SizedBox(width: 30),
                    Flexible(
                      child: TextField(
                        controller: surnameController,
                        decoration: const InputDecoration(labelText: "Фамилия"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Почта"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Пароль"),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(
                    labelText: "Подтвердите пароль",
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedUserRoleValue,
                  hint: const Text("Выберите роль пользователя"),
                  items: <String>['Инженер', 'Менеджер', 'Наблюдатель'].map((
                    String option,
                  ) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedUserRoleValue = newValue;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    backgroundColor: Colors.blue[400],
                  ),
                  child: const Text(
                    "Зарегистрироваться",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const LoginPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: const Text(
                    "Уже есть аккаунт? Войти",
                    style: TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
