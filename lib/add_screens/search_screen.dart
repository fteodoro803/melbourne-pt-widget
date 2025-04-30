import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/sheet_ui/route_details_sheet.dart';
import 'package:flutter_project/add_screens/sheet_ui/sheet_navigator_widget.dart';
import 'package:flutter_project/add_screens/sheet_ui/stop_details_sheet.dart';
import 'package:flutter_project/add_screens/sheet_ui/trip_details_sheet.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'controllers/map_controller.dart';
import 'controllers/nearby_stops_controller.dart';
import 'controllers/search_controller.dart' as search_controller;
import 'controllers/sheet_navigator_controller.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/screen_widgets.dart';
import 'widgets/suggestions_search.dart';
import 'sheet_ui/departure_details_sheet.dart';
import 'sheet_ui/nearby_stops_sheet.dart';

// todo: fix forward/backward navigation between pages; fix camera view when first rendering marker/trip path

class SearchScreen extends StatefulWidget {
  final bool enableSearch;
  final search_controller.SearchDetails searchDetails;

  const SearchScreen({
    super.key,
    required this.enableSearch,
    required this.searchDetails,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  final sheetNavigationController = Get.put(SheetNavigationController());
  final searchController = Get.put(search_controller.SearchController());
  final mapController = Get.put(MapController());
  final nearbyStopsController = Get.put(NearbyStopsController());

  @override
  void initState() {
    super.initState();
    // print("search_screen.dart --> INITIALIZING STATE");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchController.setDetails(widget.searchDetails);

      if (!widget.enableSearch) {
        if (widget.searchDetails.trip != null) {
          sheetNavigationController.initialSheetSize = 0.5;
          searchController.pushTrip(widget.searchDetails.trip!);
        } else {
          sheetNavigationController.initialSheetSize = 0.4;
          searchController.pushRoute();
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
      // Use direct controller references instead of Get.find
      if (Get.isRegistered<SheetNavigationController>()) {
        final controller = Get.find<SheetNavigationController>();
        Get.delete<SheetNavigationController>(force: true);
        // print("SheetNavigationController deleted in SearchScreen dispose");
      }

      if (Get.isRegistered<search_controller.SearchController>()) {
        Get.delete<search_controller.SearchController>(force: true);
        // print("SearchController deleted in SearchScreen dispose");
      }

      if (Get.isRegistered<NearbyStopsController>()) {
        Get.delete<NearbyStopsController>(force: true);
        // print("NearbyStopsController deleted in SearchScreen dispose");
      }

      if (Get.isRegistered<MapController>()) {
        Get.delete<MapController>(force: true);
        // print("MapController deleted in SearchScreen dispose");
      }
    } catch (e) {
      // print("Error during controller disposal: $e");
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
                    onTap: searchController.handleBackButton,
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
          if (searchController.showSheet.value) _buildSheets(),
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
          route: searchController.details.value.route!,
          scrollController: scroll,
        ),
        'Stop Details': (ctx, scroll) => StopDetailsSheet(
          route: searchController.details.value.route!,
          stop: searchController.details.value.stop!,
          scrollController: scroll,
        ),
        'Trip Details': (ctx, scroll) => TripDetailsSheet(
          trip: searchController.details.value.trip!,
          disruptions: null,
          scrollController: scroll,
        ),
        'Departure Details': (ctx, scroll) => DepartureDetailsSheet(
          trip: searchController.details.value.trip!,
          departure: searchController.details.value.departure!,
          scrollController: scroll,
        ),
      },
    );
  }
}