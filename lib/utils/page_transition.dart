import 'package:flutter/material.dart';
import 'dart:math'; // ייבוא ספריית math לשימוש בפונקציית sin

class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // התאמת אנימציית מעבר לפי הרוט שהוגדר
    if (route.settings.name == '/note') {
      // אנימציית זום לפתיחת פתק
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        ),
      );
    } else if (route.settings.name == '/settings') {
      // אנימציית החלקה מימין לשמאל להגדרות
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    } else if (route.settings.name == '/search') {
      // אנימציית החלקה מלמעלה למטה לחיפוש
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, -0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    } else {
      // אנימציית ברירת מחדל - החלקה מימין קלה עם דעיכה
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    }
  }
}

// מחלקה עבור אנימציות רענון
class RefreshAnimation extends StatefulWidget {
  final Widget child;
  final bool animate;

  const RefreshAnimation({
    super.key,
    required this.child,
    this.animate = false,
  });

  @override
  State<RefreshAnimation> createState() => _RefreshAnimationState();
}

class _RefreshAnimationState extends State<RefreshAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        }
      });

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RefreshAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

// אנימציית רטט קלה להדגשת אלמנטים
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  final double shakeOffset;
  final double shakeDuration;

  const ShakeWidget({
    super.key,
    required this.child,
    this.shake = false,
    this.shakeOffset = 5.0,
    this.shakeDuration = 300,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.shakeDuration.toInt()),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.shake) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final sineValue =
            sin(4 * pi * _animation.value); // שימוש בpi במקום ערך מספרי
        return Transform.translate(
          offset: Offset(sineValue * widget.shakeOffset, 0.0),
          child: widget.child,
        );
      },
    );
  }
}
