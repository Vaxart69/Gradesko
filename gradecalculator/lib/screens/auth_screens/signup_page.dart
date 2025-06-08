// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradecalculator/components/mainscaffold.dart';
import 'package:gradecalculator/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:gradecalculator/components/customsnackbar.dart'; 

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>(); 
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = false;
    _isConfirmPasswordVisible = false;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF6200EE)),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Form(
              
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * 0.05),
                  Text(
                    "Create new\naccount",
                    style: GoogleFonts.poppins(
                      fontSize: size.height * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: height * 0.02),

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          label: "First Name",
                          controller: firstNameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: width * 0.05),
                      Expanded(
                        child: CustomTextFormField(
                          label: "Last Name",
                          controller: lastNameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  CustomTextFormField(
                    label: "Username",
                    controller: usernameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),

                  CustomTextFormField(
                    label: "Email",
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),

                  CustomTextFormField(
                    label: "Password",
                    controller: passwordController,
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),

                  CustomTextFormField(
                    label: "Confirm Password",
                    controller: confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Confirm password is required';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: size.height * 0.06),

                  SizedBox(
                    width: size.width * 0.8,
                    height: size.height * 0.06,
                    child: ElevatedButton(
                      onPressed: () async {
                        
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        String email = emailController.text.trim();
                        String password = passwordController.text.trim();
                        String firstName = firstNameController.text.trim();
                        String lastName = lastNameController.text.trim();
                        String username = usernameController.text.trim();

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );

                        String? result = await context
                            .read<AuthProvider>()
                            .signUp(
                              email: email,
                              password: password,
                              firstName: firstName,
                              lastName: lastName,
                              username: username,
                            );

                        if (context.mounted) Navigator.pop(context);

                        if (result != null) {
                          showCustomSnackbar(
                            context,
                            result,
                            duration: const Duration(seconds: 2),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const MainScaffold(),
                              transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6200EE),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.poppins(
                          fontSize: size.height * 0.020,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon; 

  const CustomTextFormField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.suffixIcon, 
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.02),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: size.height * 0.018,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: size.height * 0.016,
          ),
          suffixIcon: suffixIcon,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6200EE), width: 2),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFCF6C79), width: 2),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFCF6C79), width: 2),
          ),
          errorStyle: GoogleFonts.poppins(
            color: const Color(0xFFCF6C79),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
