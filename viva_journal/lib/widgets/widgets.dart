import 'package:flutter/material.dart';

/// Global Navigator Key for retrieving context anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Builds a custom text field with styling. The hint text disappears when the field gains focus.
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
      // AnimatedBuilder will rebuild the TextField when focusNode changes.
      child: AnimatedBuilder(
        animation: focusNode,
        builder: (context, child) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: focusNode.hasFocus ? '' : hint,
              hintStyle: const TextStyle(color: Colors.black54),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15, horizontal: 20,
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Builds a password field with a visibility toggle. The hint text disappears when the field gains focus.
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
      // AnimatedBuilder will rebuild the TextField when focusNode changes.
      child: AnimatedBuilder(
        animation: focusNode,
        builder: (context, child) {
          return TextField(
            controller: controller,
            obscureText: obscurePassword,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: focusNode.hasFocus ? '' : hint,
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15, horizontal: 20,
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Wraps a widget in a WillPopScope that prompts the user before exiting.
Widget buildWillPopWrapper({required Widget child}) {
  return WillPopScope(
    onWillPop: _onWillPop,
    child: child,
  );
}

/// Displays an exit confirmation dialog.
Future<bool> _onWillPop() async {
  BuildContext? context = navigatorKey.currentContext;
  if (context == null) return false; // Fallback if context is not found

  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Exit App?'),
      content: const Text('Do you really want to exit?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return shouldExit ?? false;
}

Widget buildDismissKeyboardWrapper({required Widget child}) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      // Check if the context is available before attempting to unfocus
      BuildContext? context = navigatorKey.currentContext;
      if (context != null) {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      }
    },
    child: child,
  );
}

/// A reusable custom text form field widget with styling for form inputs.
/// This widget is designed to be used inside a Form for built-in validation.
class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final VoidCallback? onTap;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black54),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15, horizontal: 20,
            ),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ),
    );
  }
}
