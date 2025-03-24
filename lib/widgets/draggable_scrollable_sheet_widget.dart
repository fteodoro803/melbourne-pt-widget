import 'package:flutter/material.dart';

class DraggableScrollableSheetWidget extends StatefulWidget {

  final Widget child;
  const DraggableScrollableSheetWidget({super.key, required this.child});

  @override
  State<DraggableScrollableSheetWidget> createState() => _DraggableScrollableSheetWidgetState();
}
class _DraggableScrollableSheetWidgetState extends State<DraggableScrollableSheetWidget> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  red: 0,
                  green: 0,
                  blue: 0,
                  alpha: 0.1,
                ),
                spreadRadius: 1,
                blurRadius: 7,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}