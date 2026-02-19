import 'package:flutter/material.dart';

import '../motion/motion_profile.dart';
import 'ambient_background.dart';

class MotionScaffold extends StatelessWidget {
  const MotionScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
    this.useAmbientBackground = true,
    this.safeAreaBody = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;
  final bool useAmbientBackground;
  final bool safeAreaBody;

  @override
  Widget build(BuildContext context) {
    final profile = context.motionProfile;
    final showAmbient = useAmbientBackground && !profile.reduceMotion;
    final content = safeAreaBody ? SafeArea(child: body) : body;

    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: showAmbient
          ? Stack(
              fit: StackFit.expand,
              children: [
                const AmbientBackground(),
                Positioned.fill(child: content),
              ],
            )
          : content,
    );
  }
}
