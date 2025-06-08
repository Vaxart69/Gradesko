import 'package:flutter/material.dart';

// Animated custom snackbar widget
class CustomSnackbar extends StatefulWidget {
  final String text;
  final Duration duration;

  const CustomSnackbar({super.key, required this.text, required this.duration});

  @override
  State<CustomSnackbar> createState() => _CustomSnackbarState();
}

class _CustomSnackbarState extends State<CustomSnackbar>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 10), () {
      if (mounted) setState(() => _opacity = 1.0);
    });

    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _opacity = 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double minSide = size.width < size.height ? size.width : size.height;
    return Center(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: minSide * 0.6,
            height: minSide * 0.6,
            padding: EdgeInsets.all(minSide * 0.06),
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withOpacity(0.92),
              borderRadius: BorderRadius.circular(minSide * 0.08),
            ),
            child: Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: minSide * 0.045,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showCustomSnackbar(
  BuildContext context,
  String text, {
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (_) => CustomSnackbar(text: text, duration: duration),
  );

  overlay.insert(entry);
  Future.delayed(duration, entry.remove);
}
