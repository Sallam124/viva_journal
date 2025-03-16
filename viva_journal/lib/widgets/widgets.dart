import 'package:flutter/material.dart';

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

Widget buildPasswordField(
    TextEditingController controller,
    String hint,
    bool isPassword,
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
        obscureText: isPassword ? obscurePassword : obscurePassword,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        onChanged: (text) {
          // Optional: You can use this to clear error messages when typing
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          filled: false,
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              isPassword
                  ? (obscurePassword ? Icons.visibility_off : Icons.visibility)
                  : (obscurePassword ? Icons.visibility_off : Icons.visibility),
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
