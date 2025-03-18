//
//  MediumWidgetView.swift
//  Runner
//
//  Created by Nicole Penrose on 17/3/2025.
//

import SwiftUI

struct SystemMediumWidgetView: View {
    var entry: Provider.Entry
    var showFirstFourEntries: Bool = false
    
    var body: some View {
        let transportsToShow = showFirstFourEntries ? entry.transports.prefix(4) : entry.transports.prefix(2)
        
        ForEach(Array(transportsToShow.enumerated()), id: \.element.uniqueID) { index, transport in
            VStack(alignment: .leading, spacing: 3) {
                let departures = transport.departures.prefix(3) // First 3 departures
                let departureList = departures.map { $0.scheduledDepartureTime ?? "Null" }
                let departureText = departureList.joined(separator: " | ")
                
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        // Location of stop
                        HStack {
                            Image(systemName: "location")
                                .resizable()
                                .frame(width: 9.0, height: 9.0)
                                .padding(.trailing, -4)
                            
                            Text("\(transport.stop.name)")
                                .fontWeight(.medium)
                                .font(.caption2)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                        }
                        // Route number and direction
                        HStack {
                            let imageString = TransportTypeUtils.transportType(from: transport.routeType.name)
                            let (routeColor, routeTextColor) = TransportTypeUtils.routeColor(from: transport.routeType.name)
                            
                            Image("\(imageString)")
                                .resizable()
                                .frame(width: 24.0, height: 24.0)
                            
                            // Train and V Line design
                            if transport.routeType.name == "Train" || transport.routeType.name == "V Line" {
                                Text("\(transport.direction.name)")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(routeTextColor)
                                    .padding(.horizontal, 7.0)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(routeColor))
                                    .lineLimit(1)
                            }
                            
                            // Tram, bus, and skybus design
                            else {
                                Text("\(transport.route.number)")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(routeTextColor)
                                    .padding(.horizontal, 7.0)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(routeColor))
                                    .lineLimit(1)
                                Text("To \(transport.direction.name)")
                                    .font(.caption2)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        
                        // First 3 departures
                        Text(departureText)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    // Time until first departure
                    if !departureList.isEmpty, let firstDeparture = departureList.first, let timeDifference = TimeUtils.timeDifference(from: firstDeparture) {
                        
                        // Arriving in the next hour
                        if timeDifference.minutes > 0 && timeDifference.minutes < 60 {
                            Text("\(timeDifference.minutes) min")
                                .font(.body)
                                .fontWeight(.regular)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, 4.0)
                                .padding(.vertical, 1.0)
                                .background(RoundedRectangle(cornerRadius: 9).fill(Color(hue: 0.314, saturation: 0.216, brightness: 0.903)))
                        }
                        
                        // Arriving now
                        else if timeDifference.minutes == 0 {
                            Text("Now")
                                .font(.body)
                                .fontWeight(.regular)
                                .foregroundColor(Color(hue: 0.324, saturation: 0.671, brightness: 0.656))
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, 4.0)
                                .padding(.vertical, 1.0)
                                .background(RoundedRectangle(cornerRadius: 9).fill(Color(hue: 0.314, saturation: 0.216, brightness: 0.903)))
                        }
                    }
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Conditionally add divider if current entry is not final entry
            if index < transportsToShow.count - 1 {
                Divider()
            }
        }
    }
}
