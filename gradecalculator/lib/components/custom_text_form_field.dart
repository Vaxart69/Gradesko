import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// this is the custom text form field I used mostly in the app

class CustField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const CustField({
    super.key,
    required this.label,
    required this.hintText,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: Colors.black54) : null,
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: Colors.black.withOpacity(0.3),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF121212), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFCF6C79), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFCF6C79), width: 2),
            ),
            errorStyle: GoogleFonts.poppins(
              color: const Color(0xFFCF6C79),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
