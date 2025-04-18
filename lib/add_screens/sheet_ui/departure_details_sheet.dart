
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../controllers/departure_details_controller.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../utility/time_utils.dart';
import '../widgets/transport_widgets.dart';

class DepartureDetailsSheet extends StatelessWidget {
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();
  final ScrollController scrollController;
  final DepartureDetailsController departureDetailsController = Get.put(DepartureDetailsController());

  DepartureDetailsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      final searchDetails = searchController.details.value;
      final departure = searchDetails.departure!;
      final String estimatedDepartureTime = departure.estimatedDepartureTime ?? departure.scheduledDepartureTime ?? "No Data";
      final DepartureStatus status = TransportUtils.getDepartureStatus(
        departure.scheduledDepartureTime,
        departure.estimatedDepartureTime,
      );
      Map<String, int>? timeToDeparture = TimeUtils.timeDifference(estimatedDepartureTime);


      String timeString = "At ${TimeUtils.trimTime(estimatedDepartureTime)}";
      if (timeToDeparture!['days']! < 0 || timeToDeparture['hours']! < 0) {
        timeString = "Departed ${TimeUtils.trimTime(estimatedDepartureTime)}";
      }
      else if (timeToDeparture['days'] == 0 && timeToDeparture['hours'] == 0) {
        if (timeToDeparture['minutes'] == 0) {
          timeString = "Departing now";
        }
        else if (timeToDeparture['minutes']! < 0) {
          timeString = "${timeToDeparture['minutes']!.abs()} min ago";
        }
        else {
          timeString = "In ${timeToDeparture['minutes']!} min";
        }
      }

      // Add listener to the ItemPositionsListener
      departureDetailsController.itemPositionsListener.itemPositions.addListener(() {
        final firstVisibleItem = departureDetailsController.itemPositionsListener.itemPositions.value.isNotEmpty
            ? departureDetailsController.itemPositionsListener.itemPositions.value.first
            : null;

        if (firstVisibleItem != null) {
          if (firstVisibleItem.index == 0 && firstVisibleItem.itemLeadingEdge > 0) {
            scrollController.jumpTo(0);
          }
        }
      });

      return CustomScrollView(
        controller: scrollController,
        physics: ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Route and stop details
                      Flexible(
                        fit: FlexFit.tight,
                        child: Column(
                          children: [
                            LocationWidget(textField: searchDetails.transport!.stop!.name, textSize: 18, scrollable: true),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: Color(0xFF717171),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(searchDetails.transport!.direction!.name, style: TextStyle(fontSize: 16, height: 1.1), overflow: TextOverflow.ellipsis, maxLines: 2),
                                      SizedBox(height: 8),
                                      RouteWidget(route: searchDetails.route!, scrollable: true),
                                      SizedBox(height: 4)
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),

                                Card(
                                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                    elevation: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 2),
                                          Container(
                                            padding: EdgeInsets.symmetric(vertical: 1, horizontal: 6),
                                            decoration: BoxDecoration(

                                                color: ColourUtils.getColorForStatus(status.status),
                                                borderRadius: BorderRadius.circular(8)
                                            ),
                                            child: Text(
                                              timeString,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 2.0),
                                            child: Text("Scheduled: ${departure.scheduledDepartureTime}", style: TextStyle(fontSize: 13)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 2.0),
                                            child: Text(
                                              "Estimated: ${departure.estimatedDepartureTime ?? 'N/A'}",
                                              style: TextStyle(
                                                  color: ColourUtils.getColorForStatus(status.status),
                                                  fontSize: 13
                                              ),),
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Divider(),
                ],
              ),
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: true,
            fillOverscroll: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ScrollablePositionedList.builder(
                itemScrollController: departureDetailsController.itemScrollController,
                itemPositionsListener: departureDetailsController.itemPositionsListener,
                shrinkWrap: true,
                padding: const EdgeInsets.all(0.0),
                itemCount: departureDetailsController.pattern.length,
                itemBuilder: (context, index) {
                  final stopDeparture = departureDetailsController.pattern[index];
                  final stopName = stopDeparture.stopName;
                  final departureTime = stopDeparture.scheduledDepartureTime!;

                  final timeDifference = TimeUtils.timeDifference(departureTime);

                  return Card(
                    color: index == departureDetailsController.currentStopIndex.value ? Theme.of(context).colorScheme.surfaceContainerHigh : null,
                    margin: const EdgeInsets.symmetric(vertical: 2.0),
                    elevation: 1,
                    child: ListTile(
                      leading: SizedBox(
                        width: 55,
                        child: Text(TimeUtils.trimTime(departureTime), style: TextStyle(fontSize: 12),),
                      ),
                      title: Row(
                        children: [
                          Container(
                            width: 5, // Width of the vertical line
                            color: timeDifference!['minutes']! >= 0 && timeDifference['hours']! >= 0 ? Colors.green : Colors.grey, // Color of the vertical line
                            height: 60, // Adjust the height of the vertical line
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Text(stopName!, overflow: TextOverflow.ellipsis, maxLines: 2,)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });

  }
}
