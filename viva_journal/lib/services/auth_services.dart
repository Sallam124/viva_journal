import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  // Initialize Firebase in your app (Make sure Firebase is initialized before using it)
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Sign-up function with email, password, and username
  Future<void> signUp(String email, String password, String username) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the Firebase user ID
      String uid = userCredential.user!.uid;

      // Store the username in Firestore under 'users' collection with UID as document ID
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        // Add other user details if necessary, e.g., registration date, etc.
        'created_at': FieldValue.serverTimestamp(),
      });

      print('User signed up and username added successfully.');
    } catch (e) {
      print('Error during sign-up: $e');
    }
  }

  // Log in with email and password
  Future<UserCredential?> logIn(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User logged in successfully.');
      return userCredential;
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  // Get the current logged-in user
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Sign-out user
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    print('User signed out successfully.');
  }

  // Example of checking if the user is signed in
  bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }
}