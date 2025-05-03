// @dart=2.12
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  SharedPreferences,
])
void main() {} // Required empty function