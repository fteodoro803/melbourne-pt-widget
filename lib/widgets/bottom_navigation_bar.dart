// widgets/bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/transport.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  // Optional callback to update main page, only used when necessary
  final VoidCallback? updateMainPage;

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    this.updateMainPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; // Don't navigate if already on this page

        switch (index) {
          case 0: // Home
          // If returning to home from another screen, maybe we need to update
            if (currentIndex != 0 && updateMainPage != null) {
              // Only refresh data when returning to home
              updateMainPage!();
            }

            // Clear the stack and go home
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
                  (route) => false,
            );
            break;

          case 1: // Search
          // No need to update data when going to search
            Navigator.pushNamed(
              context,
              '/searchScreen',
              arguments: ScreenArguments.withSearchDetails(
                  Transport(),
                  updateMainPage!,
                  SearchDetails([], [], [], TextEditingController())
              ),
            );
            break;

          case 2: // Add
            Navigator.pushNamed(
              context,
              '/selectRouteTypeScreen',
              arguments: ScreenArguments(Transport(), updateMainPage!),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Add',
        ),
      ],
    );
  }
}