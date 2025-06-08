import 'package:flutter/material.dart';

// this is the bottom navigation bar widget

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    const purple = Color(0xFF6200EE);

    return Container(
      height: height * 0.065,
      margin: EdgeInsets.only(
        bottom: height * 0.03,
        left: width * 0.04,
        right: width * 0.04,
      ),
      padding: EdgeInsets.symmetric(vertical: height * 0.01),
      decoration: BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.circular(width * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: width * 0.02,
            offset: Offset(0, height * 0.002),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: selectedIndex == 0 ? Colors.white : Colors.white54,
              size: width * 0.065,
            ),
            onPressed: () => onTabSelected(0),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: width * 0.10,
              minHeight: width * 0.10,
            ),
          ),
          Container(
            width: width * 0.11,
            height: width * 0.11,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(width * 0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: width * 0.035,
                  offset: Offset(0, height * 0.008),
                ),
              ],
            ),
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: width * 0.07,
                ),
                onPressed: () => onTabSelected(1),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: width * 0.10,
                  minHeight: width * 0.10,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.info,
              color: selectedIndex == 2 ? Colors.white : Colors.white54,
              size: width * 0.065,
            ),
            onPressed: () => onTabSelected(2),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: width * 0.10,
              minHeight: width * 0.10,
            ),
          ),
        ],
      ),
    );
  }
}
