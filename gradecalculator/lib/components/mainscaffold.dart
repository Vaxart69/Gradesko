import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:gradecalculator/components/bottom_nar_bar.dart';
import 'package:gradecalculator/screens/homescreen.dart';
import 'package:gradecalculator/screens/course_screens/add_course.dart';
import 'package:gradecalculator/screens/about_screen/about.dart';



// this is the main scaffold widget that contains the bottom navigation bar and the pages
class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _pages = [
    Homescreen(),
    SizedBox.shrink(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (index == 1) {
      
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AddCourse(),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

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
    } else {
      setState(() {
        _previousIndex = _selectedIndex;
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 350),
        reverse: _selectedIndex < _previousIndex,
        transitionBuilder: (child, animation, secondaryAnimation) {
          bool slideFromRight = _selectedIndex > _previousIndex;
          
          final begin = slideFromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var slideTween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          var fadeTween = Tween(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeIn));

          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}