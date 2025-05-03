import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/widgets/trip_info_widgets.dart';
import 'package:get/get.dart';

import '../../domain/route.dart' as pt_route;
import '../../domain/stop.dart';
import '../controllers/nearby_stops_controller.dart';
import '../overlay_sheets/distance_filter.dart';
import '../utility/trip_utils.dart';
import 'buttons.dart' as screen_widgets;

class ExpandedStopWidget extends StatelessWidget {
  const ExpandedStopWidget({
    super.key,
    required this.stopName,
    required this.distance,
  });

  final String stopName;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.location_pin, size: 20),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                stopName,
                style: TextStyle(fontSize: 16, height: 1.1, fontWeight: FontWeight.w700),

              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.directions_walk, size: 20),
            SizedBox(width: 4),
            Text("${distance?.round()}m", style: TextStyle(fontSize: 16)),
          ],
        )
      ],);
  }
}

class UnexpandedStopWidget extends StatelessWidget {
  const UnexpandedStopWidget({
    super.key,
    required this.stopName,
    required this.routes,
    required this.routeType,
  });

  final String stopName;
  final List<pt_route.Route> routes;
  final String routeType;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LocationWidget(textField: stopName, textSize: 16, scrollable: false),
        SizedBox(height: 2),
        Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 6,
              children: routes.map((route) {

                String? routeLabel = TripUtils.getLabel(route, routeType);

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: route.colour != null
                        ? ColourUtils.hexToColour(route.colour!)
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    routeLabel ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: route.textColour != null
                          ? ColourUtils.hexToColour(route.textColour!)
                          : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],);
  }
}

class ExpandedStopRoutesWidget extends StatelessWidget {
  const ExpandedStopRoutesWidget({
    super.key,
    required this.routes,
    required this.routeType,
    required this.onStopTapped,
    required this.stop,
  });

  final List<pt_route.Route> routes;
  final String routeType;
  final Function(Stop, pt_route.Route) onStopTapped;
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: routes.length,
        itemBuilder: (context, routeIndex) {

          final route = routes[routeIndex];
          String? routeLabel = TripUtils.getLabel(route, routeType);
          String? routeName = TripUtils.getName(route, routeType);

          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            trailing: Icon(Icons.keyboard_arrow_right_outlined),
            leading: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: route.colour != null
                    ? ColourUtils.hexToColour(route.colour!)
                    : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 280, // Limit the width to a maximum, or you can adjust the value
                ),
                child: Text(
                  routeLabel!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: route.textColour != null
                        ? ColourUtils.hexToColour(route.textColour!)
                        : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            title: routeName != null
                ? Text(
                  routeName,
                  style: TextStyle(height: 1.2),
                )
                : null,
            onTap: ()  {
              onStopTapped(stop, route);
            },
          );
        }
    );
  }
}

class RouteTypeButtons extends StatelessWidget {
  const RouteTypeButtons({super.key});

  NearbyStopsController get nearbyController => Get.find<NearbyStopsController>();

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.start,
      children: nearbyController.routeTypeFilters.keys.map((routeType) {
        final isSelected = nearbyController.routeTypeFilters[routeType] ?? false;
        return screen_widgets.RouteTypeToggleButton(
            isSelected: isSelected,
            routeType: routeType,
            handleRouteTypeToggle: (routeType) {
              nearbyController.toggleRouteType(routeType);
            }
        );
      }).toList(),
    );
  }
}

class ToggleFilterChips extends StatelessWidget {
  const ToggleFilterChips({super.key});

  NearbyStopsController get nearbyController => Get.find<NearbyStopsController>();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5.0,
      children:
      ToggleableFilter.values.map((ToggleableFilter result) {
        return FilterChip(
            label: Text(result.name),
            selected: nearbyController.filters.contains(result),
            onSelected: (bool selected) {
              if (selected) {
                nearbyController.filters.add(result);
              } else {
                nearbyController.filters.remove(result);
              }
            }
        );
      }).toList(),
    );
  }
}

class DistanceFilterChip extends StatelessWidget {
  const DistanceFilterChip({super.key});

  NearbyStopsController get nearbyController => Get.find<NearbyStopsController>();

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(Icons.keyboard_arrow_down_sharp),
      label: Text('Within ${nearbyController.selectedDistance.value}${nearbyController.selectedUnit.value}'),
      onPressed: () async {
        await showModalBottomSheet(
            constraints: BoxConstraints(maxHeight: 500),
            context: context,
            builder: (BuildContext context) {
              return DistanceFilterSheet(
                  selectedDistance: nearbyController.selectedDistance.value,
                  selectedUnit: nearbyController.selectedUnit.value,
                  onConfirmPressed: (distance, unit) {
                    nearbyController.updateDistance(distance, unit);
                  }
              );
            });
      },
    );
  }
}