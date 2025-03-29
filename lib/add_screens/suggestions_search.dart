import 'dart:async';
import 'package:flutter/material.dart';
import '../google_service.dart';

const Duration DEBOUNCE_DURATION = Duration(milliseconds: 500);

class SuggestionsSearch extends StatefulWidget {
  const SuggestionsSearch({super.key,});

  @override
  State<SuggestionsSearch> createState() => _SuggestionsSearchState();
}

class _SuggestionsSearchState extends State<SuggestionsSearch> {
  GoogleService googleService = GoogleService();
  String? _currentQuery;    // Query currently being searched for

  // The most recent options retrieved from Google Autocomplete API
  late Iterable<String> _lastOptions = <String>[];

  late final _Debouncable<Iterable<String>?, String> _debouncedSearch;

  // Calls remote API
  Future<Iterable<String>?> _search(String query) async {
    _currentQuery = query;

    // Early exit of current query is null or empty
    if (_currentQuery == null || _currentQuery!.isEmpty) {
      return null;
    }
    final Iterable<String> options = await googleService.fetchSuggestions(_currentQuery!);

    // If another search happened after this one, reset
    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;
    return options;
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<Iterable<String>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {

          final Iterable<String>? options = await _debouncedSearch(textEditingValue.text);
          if (options == null) {
            return _lastOptions;
          }
          _lastOptions = options;
          return options;
        },
      onSelected: (String selection) {
          debugPrint("(suggestion_search.dart) -- Selected $selection");
      },

      // Appearance of the Searchbar
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: "Search...",
            filled: true,
            fillColor: Colors.grey[99], // Change background color
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black87), // Change border color
            ),
          ),
          style: TextStyle(color: Colors.white), // Change text color
          // onSubmitted: ,
        );
      },

      // Appearance of Suggestions Dropdown
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft, // Align it properly
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade800,
            child: SizedBox(
              width: 300, // Adjust width as needed
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options.map((String option) {
                  return ListTile(
                    title: Text(option, style: TextStyle(color: Colors.white)),
                    onTap: () => onSelected(option),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },    );
  }
}

typedef _Debouncable<S,T> = Future<S?> Function(T parameter);

// Returns a new function that is a debounced version of the g iven function
// Original function will only be called after no calls have been made for a given Duration
_Debouncable<S,T> _debounce<S,T>(_Debouncable<S?,T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer?.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } on _CancelException {
      return null;
    }
    return function(parameter);
  };
}

class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(DEBOUNCE_DURATION, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// Exception indicating Timer was cancelled
class _CancelException implements Exception {
  const _CancelException();
}