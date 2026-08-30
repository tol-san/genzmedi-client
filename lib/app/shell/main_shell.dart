import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/shell/bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isBottomNavVisible = true;

  void _handleHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    const swipeThreshold = 250.0;
    final currentIndex = widget.navigationShell.currentIndex;

    if (velocity < -swipeThreshold) {
      // Swiped Left -> go to next branch (Home -> Shorts -> Create -> Discover -> Profile)
      if (currentIndex < 4) {
        widget.navigationShell.goBranch(
          currentIndex + 1,
          initialLocation: false,
        );
      }
    } else if (velocity > swipeThreshold) {
      // Swiped Right -> go to previous branch (Profile -> Discover -> Create -> Shorts -> Home)
      if (currentIndex > 0) {
        widget.navigationShell.goBranch(
          currentIndex - 1,
          initialLocation: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 56.0;

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isBottomNavVisible) {
              setState(() => _isBottomNavVisible = false);
            }
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isBottomNavVisible) {
              setState(() => _isBottomNavVisible = true);
            }
          }
          return false;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _handleHorizontalSwipe,
          child: widget.navigationShell,
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        height: _isBottomNavVisible ? (navBarHeight + bottomPadding) : 0.0,
        child: Wrap(
          children: [
            GenZBottomNavBar(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: (index) {
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
