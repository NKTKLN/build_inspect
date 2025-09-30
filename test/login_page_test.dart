import 'package:build_inspect/pages/login_page.dart';
import 'package:build_inspect/pages/projects_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:hive_test/hive_test.dart';

class MockUsersBox extends Mock implements Box {}

void main() {
  late MockUsersBox mockUsersBox;

  setUp(() {
    mockUsersBox = MockUsersBox();
  });

  setUpAll(() async {
    await setUpTestHive();
    await Hive.openBox('users');
    await Hive.openBox('projects');
  });

  Future<void> pumpLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(usersBox: mockUsersBox),
      ),
    );
    await tester.pump();
  }

  testWidgets('Показать SnackBar если поля пустые', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.text("Войти"));
    await tester.pump();

    expect(find.text("Заполните все поля"), findsOneWidget);
  });

  testWidgets('Показать SnackBar если пользователь не найден', (tester) async {
    when(() => mockUsersBox.get(any())).thenReturn(null);

    await pumpLoginPage(tester);

    await tester.enterText(find.byType(TextField).at(0), "test@test.com");
    await tester.enterText(find.byType(TextField).at(1), "password");
    await tester.tap(find.text("Войти"));
    await tester.pump();

    expect(find.text("Пользователь не найден"), findsOneWidget);
  });

  testWidgets('Показать SnackBar если пароль неверный', (tester) async {
    final wrongHash = sha256.convert(utf8.encode("otherpass")).toString();
    when(() => mockUsersBox.get("test@test.com")).thenReturn({
      "name": "User",
      "password_hash": wrongHash,
    });

    await pumpLoginPage(tester);

    await tester.enterText(find.byType(TextField).at(0), "test@test.com");
    await tester.enterText(find.byType(TextField).at(1), "password");
    await tester.tap(find.text("Войти"));
    await tester.pump();

    expect(find.text("Неверный пароль"), findsOneWidget);
  });

  testWidgets('Успешный логин открывает ProjectsPage', (tester) async {
    final correctHash = sha256.convert(utf8.encode("password")).toString();
    when(() => mockUsersBox.get("test@test.com")).thenReturn({
      "name": "User",
      "password_hash": correctHash,
    });

    await pumpLoginPage(tester);

    await tester.enterText(find.byType(TextField).at(0), "test@test.com");
    await tester.enterText(find.byType(TextField).at(1), "password");
    await tester.tap(find.text("Войти"));
    await tester.pumpAndSettle();

    expect(find.text("Добро пожаловать, User!"), findsOneWidget);
  });
}
