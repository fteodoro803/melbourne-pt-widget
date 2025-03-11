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
        
        // Parse JSON Data
        let data = Data(flutterData.utf8)
//        print("Data: \(flutterData)")
        
        let decoder = JSONDecoder()
        do {
            let transports = try decoder.decode([Transport].self, from: data)
            
            for transport in transports {
                print("Route Type Name: \(transport.routeType.name)")
                print("Stop Name: \(transport.stop.name)")
                print("Direction ID: \(transport.direction.name)")
                for departure in transport.departures {
                    print("Scheduled Departure Time: \(departure.scheduledDepartureTime ?? "No scheduled departure")")
//                    print("Estimated Departure Time: \(departure.estimatedDepartureTime ?? "No estimated departure")")
                }
                transportsList.append(transport)
                
            }
        }
        catch {
            print("Error decoding JSON: \(error)")
        }
        
        return SimpleEntry(date: Date(), transports: transportsList)
    }
    
    // Preview in Widget Gallery
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), transports: [Transport(
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
    
    var body: some View {
        ForEach(entry.transports, id: \.uniqueID) { transport in
            
            HStack {
                Image(systemName: "tram.fill")
                    .resizable(capInsets: EdgeInsets(top: 30.0, leading: 30.0, bottom: 30.0, trailing: 30.0))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: /*@START_MENU_TOKEN@*/30.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/30.0/*@END_MENU_TOKEN@*/)
                
                Spacer()
                
                VStack {
                    // Transport Information
                    Text("\(transport.routeType.name) \(transport.route.number) to \(transport.direction.name)")
                    Text("from \(transport.stop.name)")
                    
                    let departures = transport.departures.prefix(3) // First 3 departures
                    let departureText = departures.map{$0.scheduledDepartureTime ?? "Null"}
                    let departureString = departureText.joined(separator: " | ")
                    Text(departureString)
                }
            }
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
                transports: [Transport(
                    routeType: RouteType(name: "Tram"),
                    stop: Stop(name: "Melb Central"),
                    route: Route(number: "19"),
                    direction: Direction(name: "Flinders"),
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
                    ]  // array of Departures
                )]
    )
    SimpleEntry(date: .now,
                transports: [Transport(
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
                    ]  // array of Departures
                )]
    )
}
