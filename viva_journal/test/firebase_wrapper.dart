import 'package:firebase_core/firebase_core.dart';
import 'package:viva_journal/firebase_options.dart';

class FirebaseWrapper {
  Future<FirebaseApp> initializeFirebase() {
    return Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}
