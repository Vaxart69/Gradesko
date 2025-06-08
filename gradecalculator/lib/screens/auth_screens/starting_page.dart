import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradecalculator/components/mainscaffold.dart';
import 'package:gradecalculator/providers/auth_provider.dart';
import 'package:gradecalculator/components/customsnackbar.dart'; 

import 'package:gradecalculator/screens/auth_screens/login_page.dart';
import 'package:gradecalculator/screens/auth_screens/signup_page.dart';
import 'package:provider/provider.dart';

class StartingPage extends StatefulWidget {
  const StartingPage({super.key});

  @override
  State<StartingPage> createState() => _StartingPageState();
}

class _StartingPageState extends State<StartingPage> {
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _startAnimation = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.15),
                      
                      Center(
                        child: Image.asset(
                              'assets/logo.png',
                              height: size.height * 0.3,
                            )
                            .animate(target: _startAnimation ? 1 : 0)
                            .fadeIn(duration: 350.ms, delay: 300.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 350.ms,
                              curve: Curves.easeOut,
                            ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      Center(
                        child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: size.height * 0.039,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Track.",
                                    style: TextStyle(color: Color(0xFFFFFFFF)),
                                  ),
                                  TextSpan(text: " "),
                                  TextSpan(
                                    text: "Calculate.",
                                    style: TextStyle(color: Color(0xFF6200EE)),
                                  ),
                                  TextSpan(text: " "),
                                  TextSpan(
                                    text: "\nPredict.",
                                    style: TextStyle(color: Color(0xFFFFFFFF)),
                                  ),
                                ],
                              ),
                            )
                            .animate(target: _startAnimation ? 1 : 0)
                            .fadeIn(duration: 350.ms, delay: 300.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 350.ms,
                              curve: Curves.easeOut,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            TweenAnimationBuilder(
              tween: Tween<Offset>(
                begin: Offset(0, 1),
                end: _startAnimation ? Offset(0, 0) : Offset(0, 1),
              ),
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) {
                return Opacity(
                  opacity: 1 - offset.dy,
                  child: Transform.translate(
                    offset: Offset(0, offset.dy * size.height * 0.32),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: size.height * 0.32,
                decoration: BoxDecoration(
                  color: Color(0x08FFFFFF),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(size.width * 0.18),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                   
                    SizedBox(
                      width: size.width * 0.8,
                      height: size.height * 0.06,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const LoginPage(),
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6200EE),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          "Log In",
                          style: GoogleFonts.poppins(
                            fontSize: size.height * 0.020,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.020),
                    
                    SizedBox(
                      width: size.width * 0.8,
                      height: size.height * 0.06,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final result =
                                await context
                                    .read<AuthProvider>()
                                    .signInWithGoogle();

                            if (mounted) {
                              if (result == null) {
                             
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const MainScaffold(),
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
                              } else if (result != "Sign-in cancelled by user") {
                                
                                showCustomSnackbar(
                                  context,
                                  result,
                                  duration: const Duration(seconds: 2),
                                );
                              }
                            
                            }
                          } catch (e) {
                            if (mounted) {
                              showCustomSnackbar(
                                context,
                                'Error: $e',
                                duration: const Duration(seconds: 2),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFFFFF),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/google_icon.png',
                              height: size.height * 0.040,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Sign in with Google",
                              style: GoogleFonts.poppins(
                                fontSize: size.height * 0.020,
                                color: Color(0xFF050505),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.050),

                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: size.height * 0.015,
                          color: Colors.white,
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: "Create an account",
                            style: GoogleFonts.poppins(
                              color: Color(0xFF6200EE),
                              fontWeight: FontWeight.normal,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => const SignupPage(),
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
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
