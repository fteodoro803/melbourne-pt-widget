// widgets/bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/transport.dart';
import 'package:get/get.dart';

import '../../main.dart';
import '../controllers/map_controller.dart';
import '../controllers/nearby_stops_controller.dart';
import '../controllers/search_controller.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../controllers/sheet_navigator_controller.dart';
import '../search_binding.dart';
import '../search_screen.dart';

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
        // if (index == currentIndex) return; // Don't navigate if already on this page

        switch (index) {
          case 0: // Home
          // If returning to home from another screen, maybe we need to update
            if (currentIndex != 0 && updateMainPage != null) {
              // Only refresh data when returning to home
              updateMainPage!();
            }

            Get.offAllNamed('/');
            break;


        // In bottom_navigation_bar.dart, modify the onTap handler for the Search tab:
          case 1: // Search
            print("Bottom navigation: Search tab pressed - reinitializing search screen");

            // Force delete all existing controllers to ensure fresh state
            if (Get.isRegistered<SheetNavigationController>()) {
              Get.delete<SheetNavigationController>(force: true);
            }
            if (Get.isRegistered<search_controller.SearchController>()) {
              Get.delete<search_controller.SearchController>(force: true);
            }
            if (Get.isRegistered<NearbyStopsController>()) {
              Get.delete<NearbyStopsController>(force: true);
            }
            if (Get.isRegistered<MapController>()) {
              Get.delete<MapController>(force: true);
            }

            // Briefly go to home page (invisible to user with no transition)
            Get.offAll(
                    () => const MyHomePage(title: "Demo Home Page"),
                transition: Transition.noTransition,
                duration: Duration.zero
            );

            // Then create new search screen instance
            Future.delayed(Duration(milliseconds: 50), () {
              print("Creating new search screen instance");
              Get.to(
                    () => SearchScreen(
                    searchDetails: SearchDetails(),
                    enableSearch: true
                ),
                preventDuplicates: false, // Allow duplicates
                binding: SearchBinding(searchDetails: SearchDetails()),
              );
            });
            break;

          case 2: // Add
            Navigator.pushNamed(
              context,
              '/selectRouteTypeScreen',
              arguments: ScreenArguments.withTransport(Transport(), updateMainPage!),
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