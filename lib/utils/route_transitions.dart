import 'package:material_ui/material_ui.dart';

/// Flutter's page transitions for each platform, except that Android draws
/// the page itself as it comes in. Since Flutter 3.50 its default animates a
/// picture of the page's first frame for the whole 450 ms, and a chat, whose
/// messages arrive a frame later, showed "No messages yet" all that time.
final appPageTransitions = PageTransitionsTheme(
  builders: {
    ...const PageTransitionsTheme().builders,
    TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(
      allowSnapshotting: false,
    ),
  },
);

Route<T> buildQuickSwitchRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
