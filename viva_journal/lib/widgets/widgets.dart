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
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
                icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                onPressed: togglePasswordVisibility,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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

/// Wraps a widget in a GestureDetector that dismisses the keyboard when tapping outside input fields.
Widget buildDismissKeyboardWrapper({required Widget child}) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      // Dismiss the keyboard by unfocusing the current FocusNode.
      FocusScopeNode currentFocus = FocusScope.of(navigatorKey.currentContext!);
      if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
        currentFocus.unfocus();
      }
    },
    child: child,
  );
}

/// A reusable custom text form field widget with styling for form inputs.
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
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ),
    );
  }
}

/// A reusable custom elevated button widget with styling.
class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomElevatedButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
class HoverableIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final double hoverScale;
  final EdgeInsets padding;

  const HoverableIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.hoverScale = 1.2,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  @override
  State<HoverableIconButton> createState() => _HoverableIconButtonState();
}

class _HoverableIconButtonState extends State<HoverableIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _hovering ? widget.hoverScale : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: widget.padding,
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
