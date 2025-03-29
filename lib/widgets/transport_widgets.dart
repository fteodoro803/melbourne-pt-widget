import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:flutter/material.dart';
import '../ptv_info_classes/route_direction_info.dart' as pt_route;
import '../ptv_info_classes/route_info.dart' as pt_route;
import '../time_utils.dart';

class LocationWidget extends StatelessWidget {
  const LocationWidget({
    super.key,
    required this.textField,
    required this.textSize,
  });

  final String textField;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_pin, size: textSize),
        SizedBox(width: 3),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              textField,
              style: TextStyle(fontSize: textSize),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class RouteWidget extends StatelessWidget {
  const RouteWidget({
    super.key,
    required this.route,
    this.direction,
  });

  final pt_route.Route route;
  final pt_route.RouteDirection? direction;


  @override
  Widget build(BuildContext context) {
    String routeType = route.type.type.name;
    return Row(
      children: [
        Image.asset(
          "assets/icons/PTV $routeType Logo.png",
          width: 40,
          height: 40,
        ),
        SizedBox(width: 8),

        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: route.colour != null
                  ? ColourUtils.hexToColour(route.colour!)
                  : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              routeType == "train" ||
                  routeType == "vLine"
                  ? route.name
                  : route.number,
              style: TextStyle(
                fontSize: 20,
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
        SizedBox(width: 10),

        if (routeType != "train" && routeType != "vLine" && direction != null)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                direction?.name ?? "No Data",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class HandleWidget extends StatelessWidget {
  const HandleWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        height: 5,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required bool isSaved,
  }) : _isSaved = isSaved;

  final bool _isSaved;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      height: 40,
      child: Center(
        child: Icon(
          _isSaved ? Icons.star : Icons.star_border,
          size: 30,
          color: _isSaved ? Colors.yellow : null,
        ),
      ),
    );
  }
}

class SaveTransportService {
  static void renderSnackBar(BuildContext context, bool isSaved) {
    floatingSnackBar(
      message: isSaved ? 'Added to Saved Transports.' : 'Removed from Saved Transports.',
      context: context,
      textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      duration: const Duration(milliseconds: 2000),
      backgroundColor: isSaved ? Color(0xFF4E754F) : Color(0xFF7C291F),
    );
  }
}