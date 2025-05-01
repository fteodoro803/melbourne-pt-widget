import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/sheet_ui/route_details_sheet.dart';
import 'package:flutter_project/add_screens/sheet_ui/sheet_navigator_widget.dart';
import 'package:flutter_project/add_screens/sheet_ui/stop_details_sheet.dart';
import 'package:flutter_project/add_screens/sheet_ui/trip_details_sheet.dart';
import 'package:flutter_project/add_screens/controllers/navigation_service.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/route.dart' as pt_route;
import '../domain/trip.dart';
import 'controllers/map_controller.dart';
import 'controllers/nearby_stops_controller.dart';
import 'controllers/sheet_controller.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/screen_widgets.dart';
import 'widgets/suggestions_search.dart';
import 'sheet_ui/departure_details_sheet.dart';
import 'sheet_ui/nearby_stops_sheet.dart';

// todo: fix forward/backward navigation between pages; fix camera view when first rendering marker/trip path

class SearchScreen extends StatefulWidget {
  final bool enableSearch;
  final pt_route.Route? route;
  final Trip? trip;

  const SearchScreen({
    super.key,
    required this.enableSearch,
    this.route,
    this.trip,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  final sheetNavigationController = Get.put(SheetController());
  final mapController = Get.put(MapController());
  final nearbyStopsController = Get.put(NearbyStopsController());
  final NavigationService navigationService = Get.put(NavigationService());

  @override
  void initState() {
    super.initState();
    // print("search_screen.dart --> INITIALIZING STATE");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // searchController.setDetails(widget.searchDetails);

      if (!widget.enableSearch) {
        if (widget.trip != null) {
          sheetNavigationController.initialSheetSize = 0.5;
          navigationService.navigateToTrip(widget.trip!, null, null);
        } else {
          sheetNavigationController.initialSheetSize = 0.4;
          navigationService.navigateToRoute(widget.route!);
        }
      } else {
        sheetNavigationController.initialSheetSize = 0.4;
      }
    });
  }

  @override
  void dispose() {
    // print("search_screen.dart --> RUNNING DISPOSE");

    try {
      if (Get.isRegistered<SheetController>()) {
        Get.delete<SheetController>(force: true);
      }

      if (Get.isRegistered<NearbyStopsController>()) {
        Get.delete<NearbyStopsController>(force: true);
      }

      if (Get.isRegistered<MapController>()) {
        Get.delete<MapController>(force: true);
      }

      if (Get.isRegistered<NavigationService>()) {
        Get.delete<NavigationService>(force: true);
      }
    } catch (e) {
      print("Error during controller disposal: $e");
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Obx (() => Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController.setController(controller);
              },
              onLongPress: widget.enableSearch ? mapController.onLocationSelected : null,
              onCameraMove: mapController.onCameraMove,
              initialCameraPosition: CameraPosition(
                  target: mapController.currentPosition.value,
                  zoom: mapController.currentZoom.value),
              markers: mapController.markers.value,
              polylines: mapController.polylines.value,
              circles: mapController.circles.value,
            ),
          ),
          CustomInfoWindow(
            controller: mapController.customInfoWindowController,
            height: 36,
            width: 360,
            offset: 15,
          ),
          Column(
            children: [
              SizedBox(height: 60),
              Row(
                children: [
                  SizedBox(width: 18),
                  GestureDetector(
                    onTap: navigationService.handleBackNavigation,
                    child: BackButtonWidget(),
                  ),
                  SizedBox(width: 10),
                  if (widget.enableSearch == true)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: SuggestionsSearch(onLocationSelected: mapController.onLocationSelected),
                    ),
                ],
              ),
              Obx(() {
                if (sheetNavigationController.currentSheet.value == 'Nearby Stops') {
                  return ElevatedButton(
                    onPressed: () async {
                      if (mapController.isNearbyStopsButtonToggled.value) {
                        mapController.hideNearbyStopMarkers();
                      } else {
                        mapController.initialiseNearbyStopMarkers();
                        mapController.showNearbyStopMarkers();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: !mapController.isNearbyStopsButtonToggled.value
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.primaryContainer,
                      minimumSize: Size(40, 40),
                    ),
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_pin),
                          Icon(Icons.tram),
                        ],
                      ),
                    ),
                  );
                } else {
                  return SizedBox.shrink(); // Hide the button
                }
              }),
            ],
          ),
          if (navigationService.showSheet.value) _buildSheets(),
        ],
      )),
      bottomNavigationBar: BottomNavigation(
        currentIndex: widget.enableSearch ? 1 : 0,
        updateMainPage: null,
      ),
    );
  }

  Widget _buildSheets() {
    // Get sheet navigation controller
    return SheetNavigatorWidget(
      controller: sheetNavigationController,
      sheets: {
        'Nearby Stops': (ctx, scroll) => NearbyStopsSheet(
          scrollController: scroll,
        ),
        'Route Details': (ctx, scroll) => RouteDetailsSheet(
          scrollController: scroll,
        ),
        'Stop Details': (ctx, scroll) => StopDetailsSheet(
          scrollController: scroll,
        ),
        'Trip Details': (ctx, scroll) => TripDetailsSheet(
          scrollController: scroll,
        ),
        'Departure Details': (ctx, scroll) => DepartureDetailsSheet(
          scrollController: scroll,
        ),
      },
    );
  }
}