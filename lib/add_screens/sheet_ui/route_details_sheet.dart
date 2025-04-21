import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/widgets/transport_widgets.dart';
import 'package:get/get.dart';
import '../controllers/route_details_controller.dart';
import '../controllers/search_controller.dart' as search_controller;
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../widgets/sticky_header_delegate.dart';

class RouteDetailsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final searchController = Get.find<search_controller.SearchController>();
  final RouteDetailsController routeDetailsController = Get.put(RouteDetailsController());

  RouteDetailsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final searchDetails = searchController.details.value;
      final route = searchDetails.route;
      final suburbStops = routeDetailsController.suburbStops;

// Handle scroll request if stopToScrollTo is set
      if (routeDetailsController.stopToScrollTo.value != null) {
        // Use Future.delayed to ensure the UI has been built
        Future.delayed(Duration(milliseconds: 100), () {
          final stop = routeDetailsController.stopToScrollTo.value!;
          final key = routeDetailsController.getKeyForStop(stop);
          if (key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.5, // Center the item
            );
            routeDetailsController.stopToScrollTo.value = null; // Clear after scrolling
          }
        });
      }

      if (suburbStops.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return CustomScrollView(
        controller: scrollController,
        slivers: [
          // Pinned route + direction header
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyHeaderDelegate(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: EdgeInsets.fromLTRB(12, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RouteWidget(route: route!, scrollable: false),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4),
                      title: AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) => SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.2, 0), end: Offset(0, 0),
                          ).animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "To: ${routeDetailsController.direction}",
                            key: ValueKey(routeDetailsController.direction), // important!
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      trailing: Obx(() {
                        final isReversed = routeDetailsController.directionReversed.value;
                        return AnimatedRotation(
                          turns: isReversed ? 0.5 : 0.0,
                          duration: Duration(milliseconds: 300),
                          child: Icon(Icons.compare_arrows),
                        );
                      }),
                      onTap: () {
                        routeDetailsController.changeDirection();
                      },
                    ),

                  ],
                ),
              ),
              height: 95, // Adjust depending on actual header height
            ),
          ),

          // Suburb sticky headers + stops
          ...suburbStops.map((suburb) {
            return SliverStickyHeader(
              header: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  suburb.suburb,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                    final stop = suburb.stops[index];
                    return Column(
                      children: [
                        ListTile(
                          key: routeDetailsController.getKeyForStop(stop),
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                          title: Text(stop.name, style: TextStyle(fontSize: 15)),
                          trailing: Icon(Icons.keyboard_arrow_right),
                          onTap: () async {
                            searchController.setRoute(route);
                            searchController.pushStop(stop);
                          },
                        ),
                        if (index < suburb.stops.length - 1)
                          Divider(
                            height: 1,
                            thickness: 0.7,
                            indent: 16,
                            endIndent: 16,
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                          ),
                      ],
                    );
                  },
                  childCount: suburb.stops.length,
                ),
              ),

            );
          }).toList(),
        ],
      );
    });
  }
}
