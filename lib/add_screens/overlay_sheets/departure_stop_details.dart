import 'package:flutter/material.dart';

class ExtraStopDetails extends StatelessWidget {

  const ExtraStopDetails({
    super.key,

  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(alignment: Alignment.topRight, child: CloseButton()),

          Text("Zone"),
          Divider(),
          Text("Connections"),
          Divider(),
        ],
      ),
    );
  }
}