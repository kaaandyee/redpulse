// lib/utilities/transitions/flow_transition.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Flow3DPageRoute extends PageRouteBuilder {
  final Widget page;

  Flow3DPageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 800),
    reverseTransitionDuration: const Duration(milliseconds: 800),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = 0.0;
      var end = 1.0;
      var curve = Curves.easeInOutCubicEmphasized;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateY(math.pi * (1 - offsetAnimation.value))
          ..scale(0.8 + 0.2 * offsetAnimation.value),
        child: Opacity(
          opacity: animation.value,
          child: child,
        ),
      );
    },
  );
}