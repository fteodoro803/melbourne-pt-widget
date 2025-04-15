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

class TransportToggleButton extends StatelessWidget {
  const TransportToggleButton({
    super.key,
    required this.isSelected,
    required this.transportType,
    required this.handleTransportToggle
});

  final bool isSelected;
  final String transportType;
  final Function(String transportType) handleTransportToggle;

  @override
  Widget build(BuildContext context) {
    final bool isAll = transportType == "all" ? true : false;

    return ElevatedButton(
      onPressed: () => handleTransportToggle(transportType),
      style: ElevatedButton.styleFrom(
        padding: isAll ? EdgeInsets.symmetric(horizontal: 14) : EdgeInsets.zero,
        backgroundColor: isSelected ?
        Theme.of(context).colorScheme.secondaryContainer :
        Theme.of(context).colorScheme.secondary,
        minimumSize: Size(50, 50),
        shape: isAll ? null : CircleBorder(),
      ),
      child: transportType == "all"
        ? Text(
          "All Transport",
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        )
      : ClipOval(
        child: Image.asset(
          "assets/icons/PTV $transportType Logo.png",
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