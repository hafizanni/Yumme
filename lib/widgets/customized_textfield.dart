import 'package:flutter/material.dart';

class CustomizedTextfield extends StatelessWidget {
  final TextEditingController myController;
  final String? hintText;
  final bool? isPassword;
  final Widget? suffixIcon; // 👈 Add this line

  const CustomizedTextfield({
    Key? key,
    required this.myController,
    this.hintText,
    this.isPassword = false,
    this.suffixIcon, // 👈 Accept it in the constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: myController,
        obscureText: isPassword ?? false,
        keyboardType: isPassword! ? TextInputType.visiblePassword : TextInputType.emailAddress,
        enableSuggestions: !(isPassword ?? false),
        autocorrect: !(isPassword ?? false),
        decoration: InputDecoration(
          hintText: hintText,
          fillColor: const Color(0xffE8ECF4),
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xffE8ECF4), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xffE8ECF4), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: suffixIcon, // 👈 Apply it here
        ),
      ),
    );
  }
}
