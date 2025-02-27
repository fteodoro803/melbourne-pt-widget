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
        
        print("GETTING DATA FROM FLUTTER")
        
        // Parse JSON Data
        let data = Data(flutterData.utf8)
        
        let decoder = JSONDecoder()
        do {
            let transports = try decoder.decode([Transport].self, from: data)
            
            for transport in transports {
                print("Route Type Name: \(transport.routeType.name)")
                print("Stop Name: \(transport.stop.name)")
                print("Direction ID: \(transport.direction.direction)")
                for departure in transport.departure {
                    print("Scheduled Departure Time: \(departure.scheduledDeparture ?? "No scheduled departure")")
                    print("Estimated Departure Time: \(departure.estimatedDeparture ?? "No estimated departure")")
                }
                return SimpleEntry(date: Date(), jsonData: flutterData, transport: transport)

            }
        }
        catch {
            print("Error decoding JSON: \(error)")
        }
        
        return SimpleEntry(date: Date(), jsonData: flutterData, transport: nil)
    }
    
    // Preview in Widget Gallery
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), jsonData: "1", transport: Transport(
            routeType: RouteType(name: "tram"),
            stop: Stop(name: "Melb Central"),
            route: Route(number: "19"),
            direction: Direction(direction: "Flinders"),
            departure: []  // Empty array of Departures
            ))
    }

    // Widget Gallery/Selection preview
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), jsonData: "2", transport: Transport(
            routeType: RouteType(name: "tram"),
            stop: Stop(name: "Melb Central"),
            route: Route(number: "19"),
            direction: Direction(direction: "Flinders"),
            departure: []  // Empty array of Departures
            ))
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
    let jsonData: String
    let transport: Transport?
}
	
// Appearance of Widget
struct MelbournePTWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Text:")
            Text(entry.jsonData)
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

#Preview(as: .systemSmall) {
    MelbournePTWidget()
} timeline: {
    SimpleEntry(date: .now, jsonData: "1",
                transport: Transport(
                    routeType: RouteType(name: "tram"),
                    stop: Stop(name: "Melb Central"),
                    route: Route(number: "19"),
                    direction: Direction(direction: "Flinders"),
                    departure: []  // Empty array of Departures
                )
    )
    SimpleEntry(date: .now, jsonData: "2",
                transport: Transport(
                    routeType: RouteType(name: "bus"),
                    stop: Stop(name: "Melb Central"),
                    route: Route(number: "1"),
                    direction: Direction(direction: "Toorak"),
                    departure: []  // Empty array of Departures
                )
    )
}
