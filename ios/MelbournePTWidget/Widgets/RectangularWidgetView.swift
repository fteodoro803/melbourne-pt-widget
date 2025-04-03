//
//  RectangularWidgetView.swift
//  Runner
//
//  Created by Nicole Penrose on 17/3/2025.
//

import SwiftUI

struct AccessoryRectangularWidgetView: View {
    var entry: Provider.Entry
        
    var body: some View {
        
        if entry.transports.isEmpty {
            Text("No transport routes to show.")
                .fontWeight(.semibold)
                .font(.caption2)
        }
        
        if let firstTransport = entry.transports.first {
            
            // Design for accessoryRectangular
            VStack(alignment: .leading, spacing: 3) {
                
                // Location of stop
                HStack(spacing: 2) {
                    Image(systemName: "location")
                        .resizable()
                        .frame(width: 9.0, height: 9.0)
                        .padding(.trailing, 2)
                    Text("\(firstTransport.stop.name)")
                        .font(.caption2)
                        .lineLimit(1)
                }
                
                // Route number and direction
                HStack(spacing: 2) {
                    
                    WidgetUtils.transportTypeImage(transportType: firstTransport.routeType.name, imageSize: 15, small: true)
                    
                    // Train and V Line direction => "To [destination]"
                    if firstTransport.routeType.name == "train" || firstTransport.routeType.name == "vLine" {
                        Text("To")
                            .font(.caption2)
                            .lineLimit(1)
                        Text("\(firstTransport.direction.name)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }
                    
                    // Tram and bus route number and direction => "[#] to [Direction]
                    else {
                        Text("\(firstTransport.route.number)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        Text("to \(firstTransport.direction.name)")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                
                let departures = firstTransport.departures.prefix(2)
                let departureText = departures.map { $0.scheduledDepartureTime ?? "Null" }
                
                // Cases:
                // Now and in 15 min
                // In 15 min and 20 min
                // In 15 min and at 4:54pm
                // At 4:45pm and 5:24pm
                // Now and at 5:24pm
                
                // Time remaining until next 2 departures, if applicable
                HStack(spacing: 2) {
                    if let timeDifference1 = TimeUtils.timeDifference(estimatedTime: departureText[0], scheduledTime: nil) {
                        let minutes1 = timeDifference1.minutes
                        // Case 1: first departure is now
                        if minutes1 == 0 {
                            Text("Now")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        // Case 2: first departure is in the next hour
                        else if minutes1 > 0 && minutes1 < 60 {
                            Text("In")
                                .font(.caption2)
                                .fontWeight(.regular)
                            Text("\(minutes1) min")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        // Case 3: first departure is more than an hour away
                        else {
                            Text("At")
                                .font(.caption2)
                                .fontWeight(.regular)
                            Text("\(departureText[0])")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        
                        // If second departure exists
                        if let timeDifference2 = TimeUtils.timeDifference(estimatedTime: departureText[1], scheduledTime: nil) {
                            let minutes2 = timeDifference2.minutes
                            
                            Text("and")
                                .font(.caption2)
                                .fontWeight(.regular)
                            
                            // Case 1: second departure is in the next hour
                            if minutes2 > 0 && minutes2 < 60 {
                                
                                // First departure is now
                                if minutes1 == 0 {
                                    Text("in")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                
                                Text("\(minutes2) min")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            
                            // Case 2: second departure is more than an hour away
                            else {
                                if minutes1 > 0 && minutes1 < 60 {
                                    Text("at")
                                        .font(.caption2)
                                        .fontWeight(.regular)
                                }
                                Text("\(departureText[1])")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
    }
}
