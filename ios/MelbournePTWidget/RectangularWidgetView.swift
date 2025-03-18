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
                    
                    let imageString = TransportTypeUtils.transportTypeSmall(from: firstTransport.routeType.name)
                    Image("\(imageString)")
                        .resizable()
                        .frame(width: 15.0, height: 15.0)
                        .padding(.trailing, 2)
                    
                    // Train and V Line direction => "To [destination]"
                    if firstTransport.routeType.name == "Train" || firstTransport.routeType.name == "V Line" {
                        Text("To")
                            .font(.caption2)
                            .lineLimit(1)
                        Text("\(firstTransport.direction.name)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }
                    
                    // Tram, bus, and skybus route number and direction => "[#] to [Direction]
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
                    if let timeDifference1 = TimeUtils.timeDifference(from: departureText[0]) {
                        
                        // Case 1: first departure is now
                        if timeDifference1.minutes == 0 {
                            Text("Now")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        // Case 2: first departure is in the next hour
                        else if timeDifference1.minutes > 0 && timeDifference1.minutes < 60 {
                            Text("In")
                                .font(.caption2)
                                .fontWeight(.regular)
                            Text("\(timeDifference1.minutes) min")
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
                        if let timeDifference2 = TimeUtils.timeDifference(from: departureText[1]) {
                            Text("and")
                                .font(.caption2)
                                .fontWeight(.regular)
                            
                            // Case 1: second departure is in the next hour
                            if timeDifference2.minutes > 0 && timeDifference2.minutes < 60 {
                                
                                // First departure is now
                                if timeDifference1.minutes == 0 {
                                    Text("in")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                
                                Text("\(timeDifference2.minutes) min")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            
                            // Case 2: second departure is more than an hour away
                            else {
                                if timeDifference1.minutes > 0 && timeDifference1.minutes < 60 {
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
