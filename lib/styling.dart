import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class Styling {
  Color backgroundColor = Color.fromARGB(255, 11, 19, 68);
  Color primaryColor = Color.fromARGB(255, 0, 188, 253);
  Color secondaryColor = Color.fromARGB(255, 170, 81, 255);
  Color textColor = Color.fromARGB(255, 3, 185, 253);

  InputDecoration textInputDecoration() {
    return InputDecoration(
      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w300),
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: styling.primaryColor, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: styling.primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: styling.primaryColor, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: styling.primaryColor, width: 2.0),
      ),
    );
  }

  InputDecoration gradientInputDecoration() {
    return InputDecoration(
      hintStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.transparent,
      counter: null,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget gradientInputField({
    required TextEditingController controller,
    required String hintText,
    TextStyle? style,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        margin: EdgeInsets.all(2), // Creates the border thickness
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          style: style ?? TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: hintText,

            hintStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }
}
