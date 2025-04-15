import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/widgets/transport_widgets.dart';
import 'package:get/get.dart';
import '../controllers/route_details_controller.dart';
import '../controllers/search_controller.dart' as search_controller;


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

      if (suburbStops.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
          padding: EdgeInsets.all(16),
          controller: scrollController,
          physics: ClampingScrollPhysics(),
          children: [
            RouteWidget(route: route!, scrollable: false,),
            SizedBox(height: 4),
            ListTile(
                title: Text("To: ${routeDetailsController.direction}",
                    style: TextStyle(fontSize: 18)),
                trailing: GestureDetector(
                    child: Icon(Icons.compare_arrows),
                    onTap: () {
                      routeDetailsController.changeDirection();
                    }
                )
            ),
            // Text(_route.name, style: TextStyle(fontSize: 18)),
            Divider(),

            Card(
              color: Theme
                  .of(context)
                  .colorScheme
                  .surfaceContainerHigh,
              margin: EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: suburbStops.map((suburb) {
                  return Column(
                      children: [
                        Container(
                          color: Theme
                              .of(context)
                              .colorScheme
                              .secondaryContainer, // You can use any color here
                          child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              title: Text(
                                suburb.suburb,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500
                                ),
                              ),
                              trailing: GestureDetector(
                                child: !suburb.isExpanded
                                    ? Icon(
                                    Icons.keyboard_arrow_down_sharp, size: 30)
                                    : Icon(
                                    Icons.keyboard_arrow_up_sharp, size: 30),
                                onTap: () {
                                  routeDetailsController.setExpanded(suburb);
                                },
                              )
                          ),
                        ),
                        if (suburb.isExpanded)
                          ...suburb.stops.map((stop) {
                            return ListTile(
                                visualDensity: VisualDensity(
                                    horizontal: -4, vertical: -4),
                                dense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 5),
                                title: Text(
                                    stop.name, style: TextStyle(fontSize: 15)),
                                trailing: Icon(Icons.keyboard_arrow_right),
                                onTap: () async {
                                  searchController.setRoute(route);
                                  searchController.pushStop(stop);
                                }
                            );
                          }),
                      ]
                  );
                }).toList(),
              ),
            ),
          ]
      );
    });
  }
}