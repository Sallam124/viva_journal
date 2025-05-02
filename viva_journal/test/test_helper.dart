// test/test_helper.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> testInit() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}