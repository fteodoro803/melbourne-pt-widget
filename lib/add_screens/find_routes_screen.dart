import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/search_screen.dart';
import 'package:flutter_project/add_screens/widgets/transport_widgets.dart';
import 'package:flutter_project/screen_arguments.dart';
import '../ptv_info_classes/route_info.dart' as pt_route;
import '../ptv_service.dart';
import 'widgets/screen_widgets.dart' as ScreenWidgets;

enum BusFilter {
  metro(name: "Metro", id: "4"),
  regional(name: "Regional", id: "6"),
  skyBus(name: "Skybus", id: "11");

  const BusFilter({
    required this.name,
    required this.id
  });

  final String name;
  final String id;
}

enum VLineFilter {
  one(name: "1", id: "1"),
  five(name: "5", id: "5");

  const VLineFilter({
    required this.name,
    required this.id
  });

  final String name;
  final String id;
}

class FindRoutesScreen extends StatefulWidget {
  final ScreenArguments arguments;

  FindRoutesScreen({
    super.key,
    required this.arguments
  });

  @override
  _FindRoutesScreenState createState() => _FindRoutesScreenState();
}

class _FindRoutesScreenState extends State<FindRoutesScreen> {
  SearchDetails searchDetails = SearchDetails();
  TextEditingController _searchController = TextEditingController();

  Map<String, bool> _transportTypeFilters = {};
  List<pt_route.Route> _allRoutes = [];
  List<pt_route.Route> _filteredRoutes = [];
  List<pt_route.Route> _filteredRoutesBySearch = [];

  PtvService ptvService = PtvService();
  Map<BusFilter, bool> busFilters = {};
  Map<VLineFilter, bool> vLineFilters = {};
  String _selectedRouteType = "all";


  int extractNumericPart(String str) {
    // Extract the numeric part before any non-numeric characters
    final match = RegExp(r'^\d+').firstMatch(str);
    if (match != null) {
      return int.parse(match.group(0)!); // Convert the matched number to an integer
    }
    return 0; // If no numeric part is found, return 0
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_filterBySearch);

    _transportTypeFilters = {
      "all" : true,
      "tram" : false,
      "bus" : false,
      "train" : false,
      "vLine" : false,
    };

    busFilters = {
      BusFilter.metro : true,
      BusFilter.regional: true,
      BusFilter.skyBus: true,
    };

    vLineFilters = {
      VLineFilter.one: true,
      VLineFilter.five: true,
    };

     getRoutes();
  }

  Future<void> getRoutes() async {
    List<pt_route.Route> routes = await ptvService.searchRoutes();

    // Sort the list
    routes.sort((a, b) {
      // First, check if `number` is empty
      if (a.number.isEmpty && b.number.isEmpty) {
        // If both numbers are empty, sort by name
        return a.name.compareTo(b.name);
      } else if (a.number.isEmpty) {
        // If a's number is empty, consider it "larger" for sorting purposes
        return 1;  // You can also return -1 if you want the empty numbers to come first
      } else if (b.number.isEmpty) {
        // If b's number is empty, consider it "larger" for sorting purposes
        return -1; // You can also return 1 if you want the empty numbers to come last
      } else {
        // Otherwise, sort based on the numeric part of `number`
        int numA = extractNumericPart(a.number);
        int numB = extractNumericPart(b.number);

        // Compare the numeric values
        if (numA != numB) {
          return numA.compareTo(numB);
        } else {
          // If numbers are the same, sort by name
          return a.name.compareTo(b.name);
        }
      }
    });

    setState(() {
      _allRoutes = routes;
      _filteredRoutes = routes;
      _filteredRoutesBySearch = routes;
    });
  }

  String _getGTFSIdPrefix(String gtfsId) {
    List<String> gtfsIdComponents = gtfsId.split('-');
    return gtfsIdComponents[0];
  }

  Future<void> _filterByType(String routeType) async {
    bool wasSelected = _transportTypeFilters[routeType]!;
    String newTransportToggled;
    if (wasSelected) {
      newTransportToggled = "all";
    }
    else {
      newTransportToggled = routeType;
    }

    _filteredRoutes = newTransportToggled != "all"
      ? _allRoutes.where((r) => r.type.name == newTransportToggled).toList()
      : _allRoutes;
    _filterByGTFS(newTransportToggled);
    _filterBySearch();
    _selectedRouteType = newTransportToggled;

    setState(() {
      for (var entry in _transportTypeFilters.entries) {
        String type = entry.key;
        if (type == newTransportToggled) {
          _transportTypeFilters[type] = true;
        }
        else {
          _transportTypeFilters[type] = false;
        }
      }
    });
  }

  void _filterByGTFS(String routeType) {
    List<pt_route.Route> filteredRoutes = [];

    if (routeType == "bus") {
      for (var route in _allRoutes) {
        String gtfsIdPrefix = _getGTFSIdPrefix(route.gtfsId);

        for (var filter in busFilters.entries) {
          if (filter.value && gtfsIdPrefix == filter.key.id) {
            filteredRoutes.add(route);
            break;
          }
        }
      }
    }

    else if (routeType == "vLine") {
      for (var route in _allRoutes) {
        String gtfsIdPrefix = _getGTFSIdPrefix(route.gtfsId);

        for (var filter in vLineFilters.entries) {
          if (filter.value && gtfsIdPrefix == filter.key.id) {
            filteredRoutes.add(route);
            break;
          }
        }
      }
    }
    else {
      filteredRoutes = _filteredRoutes;
    }

    setState(() {
      _filteredRoutes = filteredRoutes;
      _filterBySearch();
    });
  }

  void _filterBySearch() {
    String searchTerm = _searchController.text.toLowerCase(); // Convert to lowercase for case-insensitive search
    setState(() {
      _filteredRoutesBySearch = _filteredRoutes.where((route) {
        return route.name.toLowerCase().contains(searchTerm) ||
            (route.number.isNotEmpty && route.number.toLowerCase().contains(searchTerm));
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Find Routes"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Divider(),
          SizedBox(height: 8),
          SearchBar(
            controller: _searchController,
            hintText: "Search...",
            leading: Icon(Icons.search),

            constraints: BoxConstraints(maxWidth: 350, minHeight: 50)
          ),
          SizedBox(height: 12),
          Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            children: _transportTypeFilters.keys.map((transportType) {
              final isSelected = _transportTypeFilters[transportType] ?? false;
              return ScreenWidgets.TransportToggleButton(
                isSelected: isSelected,
                transportType: transportType,
                handleTransportToggle: _filterByType,
              );
            }).toList(),
          ),
          SizedBox(height: 4),
          Divider(),
          if (_transportTypeFilters['bus'] == true)
            Row(
              children: [
                SizedBox(width: 16),
                Icon(Icons.filter_list_alt, color: Color(0xFF334b50), size: 28),
                SizedBox(width: 6),
                Wrap(
                  spacing: 5.0,
                  children: busFilters.entries.map((MapEntry<BusFilter,bool> filter) {
                    return FilterChip(
                        label: Text(filter.key.name),
                        selected: filter.value,
                        onSelected: (bool selected) {
                          setState(() {
                            busFilters[filter.key] = !busFilters[filter.key]!;
                            _filterByGTFS("bus");
                          });
                        }
                    );
                  }).toList(),
                ),
              ],
            ),
          if (_transportTypeFilters['vLine'] == true)...[
            Row(
              children: [
                SizedBox(width: 16),
                Icon(Icons.filter_list_alt, color: Color(0xFF334b50), size: 28),
                SizedBox(width: 6),
                Wrap(
                  spacing: 5.0,
                  children: vLineFilters.entries.map((MapEntry<VLineFilter,bool> filter) {
                    return FilterChip(
                      label: Text(filter.key.name),
                      selected: filter.value,
                      onSelected: (bool selected) {
                        setState(() {
                          vLineFilters[filter.key] = !vLineFilters[filter.key]!;
                          _filterByGTFS("vLine");
                        });
                      }
                    );
                  }).toList(),
                ),
              ],
            ),
          ],

          if (!(_selectedRouteType == "all" && _searchController.text == ""))...[
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRoutesBySearch.length,
                itemBuilder: (context, index) {

                  final route = _filteredRoutesBySearch[index];
                  final routeType = route.type.name;

                  return Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: RouteLabelContainer(route: route),
                      title: routeType != "train"
                        ? Text(
                            route.name,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.3
                            )
                          )
                        : null,
                      subtitle: routeType != "tram" && routeType != "train" ? Text(route.gtfsId) : null,
                      trailing: Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchScreen(arguments: widget.arguments, searchDetails: SearchDetails.withRoute(route))
                          ),
                        );
                      },
                    )
                  );
                }
              ),
            )
          ]
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
              child: Text(
                "Find routes by selecting a route type, or searching by route name, number, direction, etc.",
                style: TextStyle(
                  fontSize: 16
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ]
      ),
      // bottomNavigationBar: BottomNavigation(
      // currentIndex: 2,
      // updateMainPage: null,
      // ),
    );
  }
}