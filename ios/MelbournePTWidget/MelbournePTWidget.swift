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
        print(flutterData)
        
        // No data case
        if flutterData == "No Data from Flutter" {
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
            route: Route(number: "19"),
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
            route: Route(number: "19"),
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
            SystemMediumWidgetView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularWidgetView(entry: entry)
        default:
            Text("Default")
        }
//    var body: some View {
//        ForEach(entry.transports, id: \.uniqueID) { transport in
//            
////            // DESIGN 1
////            HStack {
////                Image(systemName: "tram.fill")
////                    .resizable(resizingMode: .tile)
////                    .frame(width: /*@START_MENU_TOKEN@*/30.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/30.0/*@END_MENU_TOKEN@*/)
////                
////                Spacer()
////                
////                VStack {
////                    // Transport Information
////                    Text("\(transport.routeType.name) \(transport.route.number) to \(transport.direction.name)")
////                    Text("from \(transport.stop.name)")
////                    
////                    let departures = transport.departures.prefix(3) // First 3 departures
////                    let departureText = departures.map{$0.scheduledDepartureTime ?? "Null"}
////                    let departureString = departureText.joined(separator: " | ")
////                    Text(departureString)
////                }
////            }
//            
//            // DESIGN 2
//            HStack {
//                Text("\(transport.routeType.name)\n\(transport.route.number)")
//                
//                Spacer()
//                
//                VStack {
//                    // Transport Information
//                    Text("to \(transport.direction.name)")
//                    Text("from \(transport.stop.name)")
//                    
//                    let departures = transport.departures.prefix(3) // First 3 departures
//                    let departureText = departures.map{$0.scheduledDepartureTime ?? "Null"}
//                    let departureString = departureText.joined(separator: " | ")
//                    Text(departureString)
//                }
//            }
//            
//            Divider()
//        }
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
                        stop: Stop(name: "Melb Central"),
                        route: Route(number: "19"),
                        direction: Direction(name: "Flinders Street Station"),
                        departures: [
                            Departure(
                                estimatedDepartureTime: "4:15pm",
                                scheduledDepartureTime: "4:16pm"
                            ),
                            Departure(
                                estimatedDepartureTime: "4:30pm",
                                scheduledDepartureTime: "4:35pm"
                            ),
                            Departure(
                                estimatedDepartureTime: nil,
                                scheduledDepartureTime: "4:50pm"
                            )
                        ]
                    ),
                    Transport(
                        uniqueID: "id2",
                        routeType: RouteType(name: "Tram"),
                        stop: Stop(name: "Melb Central"),
                        route: Route(number: "19"),
                        direction: Direction(name: "Flinders Street Station"),
                        departures: [
                            Departure(
                                estimatedDepartureTime: "4:15pm",
                                scheduledDepartureTime: "4:16pm"
                            ),
                            Departure(
                                estimatedDepartureTime: "4:30pm",
                                scheduledDepartureTime: "4:35pm"
                            ),
                            Departure(
                                estimatedDepartureTime: nil,
                                scheduledDepartureTime: "4:50pm"
                            )
                        ]
                    )
                ] // array of Departures
    )
    SimpleEntry(date: .now,
                transports: [
                    Transport(
                        uniqueID: "id2",
                        routeType: RouteType(name: "Bus"),
                        stop: Stop(name: "Melb Central"),
                        route: Route(number: "1"),
                        direction: Direction(name: "Toorak"),
                        departures: [
                            Departure(
                                estimatedDepartureTime: "14:15",
                                scheduledDepartureTime: "14:16"
                            ),
                            Departure(
                                estimatedDepartureTime: "14:30",
                                scheduledDepartureTime: "14:35"
                            ),
                            Departure(
                                estimatedDepartureTime: nil,
                                scheduledDepartureTime: "14:50"
                            )
                        ]
                    )
                ] // array of Departures
    )
}
