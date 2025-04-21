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
                    print("Departure Time: \(departure.departureTime)")
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
            route: Route(label: "19", colour: "FBD872", textColour: "FFFFFF"),
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
            route: Route(label: "19", colour: "FBD872", textColour: "FFFFFF"),
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
                        routeType: RouteType(name: "tram"),
                        stop: Stop(name: "Melbourne Central Station"),
                        route: Route(
                            label: "59",
                            colour: "00653A",
                            textColour: "FFFFFF"
                        ),
                        direction: Direction(name: "Airport West"),
                        departures: [
                            Departure(
                                departureTime: "4:45pm",
                                hasLowFloor: true,
                                platformNumber: nil,
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "4:49pm",
                                hasLowFloor: true,
                                platformNumber: nil,
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "4:35pm",
                                hasLowFloor: true,
                                platformNumber: nil,
                                statusColour: "",
                                timeString: ""
                            )
                        ]
                    ),
                    Transport(
                        uniqueID: "id2",
                        routeType: RouteType(name: "bus"),
                        stop: Stop(name: "Hope St/Melville Rd"),
                        route: Route(label: "517", colour: "FF8200", textColour: "FFFFFF"),
                        direction: Direction(name: "Mooney Ponds"),
                        departures: [
                            Departure(
                                departureTime: "3:15pm",
                                hasLowFloor: true,
                                platformNumber: nil,
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "3:30pm",
                                hasLowFloor: false,
                                platformNumber: nil,
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "3:50pm",
                                hasLowFloor: true,
                                platformNumber: nil,
                                statusColour: "",
                                timeString: ""
                            )
                        ]
                    ),
                    Transport(
                        uniqueID: "id3",
                        routeType: RouteType(name: "vLine"),
                        stop: Stop(name: "Southern Cross Station"),
                        route: Route(label: "", colour: "D92B26", textColour: "FFFFFF"),
                        direction: Direction(name: "Geelong"),
                        departures: [
                            Departure(
                                departureTime: "4:15pm",
                                hasLowFloor: false,
                                platformNumber: nil,
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "4:30pm",
                                hasLowFloor: false,
                                platformNumber: "2",
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "4:45pm",
                                hasLowFloor: true,
                                platformNumber: "4",
                                statusColour: "",
                                timeString: ""
                            )
                        ]
                    ),
                    Transport(
                        uniqueID: "id4",
                        routeType: RouteType(name: "train"),
                        stop: Stop(name: "Royal Park Station"),
                        route: Route(label: "", colour: "FFBE00", textColour: "000000"),
                        direction: Direction(name: "Upfield"),
                        departures: [
                            Departure(
                                departureTime: "3:15pm",
                                hasLowFloor: true,
                                platformNumber: "6",
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "3:30pm",
                                hasLowFloor: true,
                                platformNumber: "1",
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "3:30pm",
                                hasLowFloor: false,
                                platformNumber: "3",
                                statusColour: "",
                                timeString: ""
                            )
                        ]
                    )
                ] // array of Departures
    )
    SimpleEntry(date: .now,
                transports: [
                    Transport(
                        uniqueID: "id1",
                        routeType: RouteType(name: "train"),
                        stop: Stop(name: "Melbourne Central Station"),
                        route: Route(label: "", colour: "FFBE00", textColour: "FFFFFF"),
                        direction: Direction(name: "Upfield"),
                        departures: [
                            Departure(
                                departureTime: "5:47pm",
                                hasLowFloor: true,
                                platformNumber: "3",
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "8:30pm",
                                hasLowFloor: true,
                                platformNumber: "3",
                                statusColour: "",
                                timeString: ""
                            ),
                            Departure(
                                departureTime: "3:30pm",
                                hasLowFloor: true,
                                platformNumber: "3",
                                statusColour: "",
                                timeString: ""
                            )
                        ]
                    )
                ] // array of Departures
    )
}
