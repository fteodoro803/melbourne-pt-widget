//
//  MelbournePTWidget.swift
//  MelbournePTWidget
//
//  Created by fteodoro803 on 25/2/2025.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    // Retrieves data from Flutter app
    private func getDataFromFlutter() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.melbournePTWidget")
        let flutterData = userDefaults?.string(forKey: "data_from_flutter") ?? "No Data from Flutter"
        var transportsList: [Transport] = []
        
        // Print raw data for debugging
        print("Raw Flutter Data:")
        print(flutterData)
        
        // No data retrieved case
        if flutterData == "No Data retrieved from Flutter" {
            print("No Data retrieved from Flutter")
            return SimpleEntry(date: Date(), transports: [])
        }
        
        // Empty JSON Case
        if flutterData == "[]" {
            print("flutter data == []")
            return SimpleEntry(date: Date(), transports: [])
        }
        
        // Parse JSON Data
        guard let data = flutterData.data(using: .utf8) else {
            print("Could not convert string to data")
            return SimpleEntry(date: Date(), transports: [])
        }
        
        let decoder = JSONDecoder()
        do {
            transportsList = try decoder.decode([Transport].self, from: data)
            print("Transports JSON:")
            
            for transport in transportsList {
                print("ID: \(transport.uniqueID)")
                print("Route Type Name: \(transport.routeType.name)")
                print("Stop Name: \(transport.stop.name)")
                print("Direction ID: \(transport.direction.name)")
                for departure in transport.departures {
                    print("Scheduled Departure Time: \(departure.scheduledDepartureTime ?? "No scheduled departure")")
//                    print("Estimated Departure Time: \(departure.estimatedDepartureTime ?? "No estimated departure")")
                }
                
            }
        }
        catch {
            print("Error decoding JSON: \(error)")
            // Detailed error logging
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
               let prettyPrintedString = String(data: jsonData, encoding: .utf8) {
                print("JSON structure received: \(prettyPrintedString)")
            }
        }
        
        return SimpleEntry(date: Date(), transports: transportsList)
    }
    
    // Preview in Widget Gallery
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), transports: [Transport(
            uniqueID: "placeholder",
            routeType: RouteType(name: "tram"),
            stop: Stop(name: "Melb Central"),
            route: Route(number: "19", colour: "FBD872", textColour: "FFFFFF"),
            direction: Direction(name: "Flinders"),
            departures: []  // Empty array of Departures
            )]
        )
    }

    // Widget Gallery/Selection preview
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), transports: [Transport(
            uniqueID: "snapshot",
            routeType: RouteType(name: "tram"),
            stop: Stop(name: "Melb Central"),
            route: Route(number: "19", colour: "FBD872", textColour: "FFFFFF"),
            direction: Direction(name: "Flinders"),
            departures: []  // Empty array of Departures
            )])
    }
    
    // Actual Widget on Home Screen
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = getDataFromFlutter()

        return Timeline(entries: [entry], policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

// Widget Data Structure
struct SimpleEntry: TimelineEntry {
    let date: Date
    let transports: [Transport]
}
	
// Appearance of Widget
struct MelbournePTWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            SystemSmallWidgetView(entry: entry)
        case .systemMedium:
            SystemMediumWidgetView(entry: entry, showFirstFourEntries: false)
        case .accessoryRectangular:
            AccessoryRectangularWidgetView(entry: entry)
        case .systemLarge:
            SystemMediumWidgetView(entry: entry, showFirstFourEntries: true)
        default:
            Text("Default")
        }
    }
}

// Main Widget Configuration
struct MelbournePTWidget: Widget {
    let kind: String = "MelbournePTWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            MelbournePTWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

#Preview(as: .systemMedium) {
    MelbournePTWidget()
} timeline: {
    SimpleEntry(date: .now,
                transports: [
                    Transport(
                        uniqueID: "id1",
                        routeType: RouteType(name: "Tram"),
                        stop: Stop(name: "Melbourne Central Station"),
                        route: Route(number: "59", colour: "00653A", textColour: "FFFFFF"),
                        direction: Direction(name: "Airport West"),
                        departures: [
                            Departure(
                                estimatedDepartureTime: "7:45pm",
                                scheduledDepartureTime: "7:46pm",
                                hasLowFloor: nil
                            ),
                            Departure(
                                estimatedDepartureTime: "7:49pm",
                                scheduledDepartureTime: "7:49pm",
                                hasLowFloor: true
                            ),
                            Departure(
                                estimatedDepartureTime: nil,
                                scheduledDepartureTime: "6:53pm",
                                hasLowFloor: false
                            )
                        ]
                    ),
                    Transport(
                        uniqueID: "id2",
                        routeType: RouteType(name: "Bus"),
                        stop: Stop(name: "Hope St/Melville Rd"),
                        route: Route(number: "517", colour: "FF8200", textColour: "FFFFFF"),
                        direction: Direction(name: "Mooney Ponds"),
                        departures: [
                            Departure(
                                estimatedDepartureTime: "3:15pm",
                                scheduledDepartureTime: "3:16pm",
                                hasLowFloor: true
                            ),
                            Departure(
                                estimatedDepartureTime: "3:30pm",
                                scheduledDepartureTime: "3:35pm",
                                hasLowFloor: false
                            ),
                            Departure(
                                estimatedDepartureTime: nil,
                                scheduledDepartureTime: "3:50pm",
                                hasLowFloor: true
                            )
                        ]
                    ),
                    Transport(
                        uniqueID: "id3",
                        routeType: RouteType(name: "VLine"),
                        stop: Stop(name: "Southern Cross Station"),
                        route: Route(number: "", colour: "D92B26", textColour: "FFFFFF"),
                        direction: Direction(name: "Geelong"),
                        departures: [
                            Departure(
                                estimatedDepartureTime: "4:15pm",
                                scheduledDepartureTime: "4:16pm",
                                hasLowFloor: false
                            ),
                            Departure(
                                estimatedDepartureTime: "4:30pm",
                                scheduledDepartureTime: "4:35pm",
                                hasLowFloor: false
                            ),
                            Departure(
                                estimatedDepartureTime: nil,
                                scheduledDepartureTime: "4:50pm",
                                hasLowFloor: true
                            )
                        ]
                    ),
                    Transport(
                        uniqueID: "id4",
                        routeType: RouteType(name: "Train"),
                        stop: Stop(name: "Royal Park Station"),
                        route: Route(number: "", colour: "FFBE00", textColour: "000000"),
                        direction: Direction(name: "Upfield"),
                        departures: [
                            Departure(
                                estimatedDepartureTime: "3:15pm",
                                scheduledDepartureTime: "3:16pm",
                                hasLowFloor: true
                            ),
                            Departure(
                                estimatedDepartureTime: "3:30pm",
                                scheduledDepartureTime: "3:35pm",
                                hasLowFloor: true
                            ),
                            Departure(
                                estimatedDepartureTime: nil,
                                scheduledDepartureTime: "3:50pm",
                                hasLowFloor: false
                            )
                        ]
                    )
                ] // array of Departures
    )
    SimpleEntry(date: .now,
                transports: [
                    Transport(
                        uniqueID: "id1",
                        routeType: RouteType(name: "Train"),
                        stop: Stop(name: "Melbourne Central Station"),
                        route: Route(number: "", colour: "FFBE00", textColour: "FFFFFF"),
                        direction: Direction(name: "Upfield"),
                        departures: [
                            Departure(
                                estimatedDepartureTime: "5:47pm",
                                scheduledDepartureTime: "5:47pm",
                                hasLowFloor: true
                            ),
                            Departure(
                                estimatedDepartureTime: "8:30pm",
                                scheduledDepartureTime: "8:35pm",
                                hasLowFloor: true
                            ),
                            Departure(
                                estimatedDepartureTime: nil,
                                scheduledDepartureTime: "9:50pm",
                                hasLowFloor: true
                            )
                        ]
                    )
                ] // array of Departures
    )
}
