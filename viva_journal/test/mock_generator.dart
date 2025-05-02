// test/mocks/mock_generator.dart
@GenerateMocks([
  SharedPreferences,
], customMocks: [
  MockSpec<FirebaseAuth>(as: #MockFirebaseAuth),
  MockSpec<User>(as: #MockFirebaseUser),
])
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {}