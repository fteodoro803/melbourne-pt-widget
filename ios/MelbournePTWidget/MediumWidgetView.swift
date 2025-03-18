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
        
        if transportsToShow.isEmpty {
            Text("No transport routes to show.")
                .fontWeight(.semibold)
                .font(.title3)
                .multilineTextAlignment(.center)
        }
        ForEach(Array(transportsToShow.enumerated()), id: \.element.uniqueID) { index, transport in
            VStack(alignment: .leading, spacing: 3) {
                let departures = transport.departures.prefix(3) // First 3 departures
                
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
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(routeTextColor)
                                    .padding(.horizontal, 7.0)
                                    .padding(.vertical, 1.0)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(routeColor))
                                    .lineLimit(1)
                            }
                            
                            // Tram, bus, and skybus design
                            else {
                                if transport.routeType.name == "Skybus" {
                                    Text("\(transport.route.number)")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(routeTextColor)
                                        .padding(.horizontal, 7.0)
                                        .padding(.vertical, 1.0)
                                        .background(RoundedRectangle(cornerRadius: 3).fill(routeColor))
                                        .lineLimit(1)
                                }
                                else {
                                    Text("\(transport.route.number)")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(routeTextColor)
                                        .padding(.horizontal, 7.0)
                                        .background(RoundedRectangle(cornerRadius: 3).fill(routeColor))
                                        .lineLimit(1)
                                }
                                Text("To \(transport.direction.name)")
                                    .font(.caption2)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        
                        HStack(spacing: 2) {
                            ForEach(departures.indices, id: \.self) { index in
                                let departure = departures[index]
                                Text(departure.scheduledDepartureTime ?? "Unknown")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.leading)
                                if departure.hasLowFloor == true {
                                    Image("Low Floor Tram")
                                        .resizable()
                                        .frame(width: 12.0, height: 12.0)
                                        .padding(.trailing, 2)
                                }
                                if index < 2 {
                                    Text("⎥")
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                    }
                    Spacer()
                    
                    // Time until first departure
                    if !departures.isEmpty, let firstDeparture = departures.first, let timeDifference = TimeUtils.timeDifference(from: firstDeparture.scheduledDepartureTime!) {
                        
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
