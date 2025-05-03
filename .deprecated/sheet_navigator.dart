import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/widgets/buttons.dart';

class SheetNavigator extends StatefulWidget {
  final Map<String, Widget Function(BuildContext, ScrollController)> sheets;
  final String initialSheet;
  final DraggableScrollableController? controller;
  final void Function(String)? onSheetChanged;
  final void Function(bool) handleSheetExpansion;

  const SheetNavigator({
    super.key,
    required this.sheets,
    required this.initialSheet,
    this.controller,
    this.onSheetChanged,
    required this.handleSheetExpansion,
  });

  @override
  State<SheetNavigator> createState() => SheetNavigatorState();
}

class SheetNavigatorState extends State<SheetNavigator> {
  late String _currentSheet;
  final List<String> _sheetHistory = [];
  final Map<String, double> _scrollPositions = {};
  late DraggableScrollableController _controller;
  bool _isSheetFullyExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentSheet = widget.initialSheet;
    _controller = widget.controller ?? DraggableScrollableController();

    _controller.addListener(() {
      if (_controller.size >= 0.75 && !_isSheetFullyExpanded) {
        setState(() {
          _isSheetFullyExpanded = true;
          _controller.jumpTo(1.0);
          widget.handleSheetExpansion(true);
        });
      } else if (_controller.size < 0.95 && _isSheetFullyExpanded) {
        setState(() {
          _isSheetFullyExpanded = false;
          _controller.jumpTo(0.6);
          widget.handleSheetExpansion(false);
        });
      }
    });
  }

  void pushSheet(String newSheet) {
    if (_currentSheet != newSheet) {
      _scrollPositions[_currentSheet] = _controller.size;
      _sheetHistory.add(_currentSheet);
      setState(() {
        _currentSheet = newSheet;
      });
      widget.onSheetChanged?.call(newSheet);
      _animateToSavedPosition(newSheet);
    }
  }

  void popSheet() {
    if (_sheetHistory.isNotEmpty) {
      final previous = _sheetHistory.removeLast();
      _scrollPositions[_currentSheet] = _controller.size;
      setState(() {
        _currentSheet = previous;
      });
      widget.onSheetChanged?.call(previous);
      _animateToSavedPosition(previous);
    }
  }

  void animateSheetTo(double size, {int delayMs = 100}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_controller.isAttached) {
        _controller.animateTo(size,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    });
  }

  void _animateToSavedPosition(String sheet) {
    final targetSize = _scrollPositions[sheet] ?? 0.6;
    if (_controller.isAttached) {
      _controller.animateTo(
        targetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.6,
      minChildSize: 0.15,
      maxChildSize: 1.0,
      expand: true,
      shouldCloseOnMinExtent: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 7,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: _isSheetFullyExpanded
            ? Column(
              children: [
                const SizedBox(height: 50),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => popSheet(),
                    ),
                    Expanded(
                      child: Text(
                        _currentSheet,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.location_pin),
                      onPressed: () => _controller.jumpTo(0.6),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(child: widget.sheets[_currentSheet]!(context, scrollController)),
              ],
            )
            : Column(
              children: [
                HandleWidget(),
                Expanded(child: widget.sheets[_currentSheet]!(context, scrollController))
              ]
          ),
        );
      },
    );
  }

  DraggableScrollableController get controller => _controller;
  String get currentSheet => _currentSheet;
  List<String> get sheetHistory => List.unmodifiable(_sheetHistory);
  bool get isExpanded => _isSheetFullyExpanded;
}
