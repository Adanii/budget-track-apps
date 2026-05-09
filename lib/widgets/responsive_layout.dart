import 'package:flutter/material.dart';
import 'package:fin_track/core/constants.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxWebWidth),
        child: child,
      ),
    );
  }
}
