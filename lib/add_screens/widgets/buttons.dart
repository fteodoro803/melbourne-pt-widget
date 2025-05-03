import 'package:flutter/material.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
        Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_back_ios_new,
        color: Theme.of(context).colorScheme.onSurface,
        size: 25,
      ),
    );
  }
}

class RouteTypeToggleButton extends StatelessWidget {
  const RouteTypeToggleButton({
    super.key,
    required this.isSelected,
    required this.routeType,
    required this.handleRouteTypeToggle
});

  final bool isSelected;
  final String routeType;
  final Function(String transportType) handleRouteTypeToggle;

  @override
  Widget build(BuildContext context) {
    final bool isAll = routeType == "all" ? true : false;

    return ElevatedButton(
      onPressed: () => handleRouteTypeToggle(routeType),
      style: ElevatedButton.styleFrom(
        padding: isAll ? EdgeInsets.symmetric(horizontal: 14) : EdgeInsets.zero,
        backgroundColor: isSelected ?
        Theme.of(context).colorScheme.secondaryContainer :
        Theme.of(context).colorScheme.secondary,
        minimumSize: Size(50, 50),
        shape: isAll ? null : CircleBorder(),
      ),
      child: routeType == "all"
        ? Text(
          "All Transport",
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        )
      : ClipOval(
        child: Image.asset(
          "assets/icons/PTV $routeType Logo.png",
          width: 30,
          height: 30,
          fit: BoxFit.cover,
        ),
      ),
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
      width: 30,
      height: 30,
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

class NearbyStopsButton extends StatelessWidget {
  const NearbyStopsButton({
    super.key,
    required this.isNearbyStopsButtonToggled,
    required this.onPressed,
  });

  final bool isNearbyStopsButtonToggled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: !isNearbyStopsButtonToggled
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
  }
}