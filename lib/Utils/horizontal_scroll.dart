import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Enables click-and-drag scrolling with a mouse (Flutter's default
/// ScrollBehavior only treats touch/stylus/trackpad as drag devices, so a
/// horizontal list can't be dragged with a mouse on web/desktop without
/// this). Applied app-wide via MaterialApp.scrollBehavior.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

/// Lets a horizontal-only scrollable respond to a vertical mouse wheel by
/// translating the wheel's vertical delta into horizontal scroll movement -
/// otherwise a normal mouse wheel does nothing over a horizontal ListView,
/// since Scrollable only applies the wheel delta matching its own axis.
class HorizontalWheelScroll extends StatelessWidget {
  final ScrollController controller;
  final Widget child;

  const HorizontalWheelScroll({super.key, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent || !controller.hasClients) return;
        final delta = event.scrollDelta.dy.abs() > event.scrollDelta.dx.abs() ? event.scrollDelta.dy : event.scrollDelta.dx;
        final target = (controller.offset + delta).clamp(0.0, controller.position.maxScrollExtent);
        controller.jumpTo(target);
      },
      child: child,
    );
  }
}
