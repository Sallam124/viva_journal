import 'package:flutter/material.dart';

/// ✅ Global Navigator Key for retrieving context anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ✅ Builds a custom text field with styling
Widget buildTextField(
    TextEditingController controller,
    String hint,
    FocusNode focusNode,
    BuildContext context,
    void Function() onTap,
    ) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    ),
  );
}

/// ✅ Builds a password field with a visibility toggle
Widget buildPasswordField(
    TextEditingController controller,
    String hint,
    FocusNode focusNode,
    BuildContext context,
    void Function() onTap,
    bool obscurePassword,
    void Function() togglePasswordVisibility,
    ) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscurePassword,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          filled: false,
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54,
            ),
            onPressed: togglePasswordVisibility,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    ),
  );
}

/// ✅ Wrapper to show exit confirmation when back button is pressed
Widget buildWillPopWrapper({required Widget child}) {
  return WillPopScope(
    onWillPop: _onWillPop, // ✅ Uses the function below
    child: child,
  );
}

/// ✅ Function that shows exit confirmation dialog
Future<bool> _onWillPop() async {
  // ✅ Get the current context from the global navigation key
  BuildContext? context = navigatorKey.currentContext;

  if (context == null) return false; // Fallback if context is not found

  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Exit App?'),
      content: const Text('Do you really want to exit?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // ❌ Don't exit
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true), // ✅ Exit app
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return shouldExit ?? false; // ✅ Only exit if confirmed
}
