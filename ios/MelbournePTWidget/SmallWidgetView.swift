//
//  SmallWidgetView.swift
//  Runner
//
//  Created by Nicole Penrose on 17/3/2025.
//

import SwiftUI

struct SystemSmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if entry.transports.isEmpty {
            Text("No transport routes to show.")
                .fontWeight(.semibold)
                .font(.title3)
                .multilineTextAlignment(.center)
        }
        
        if let firstTransport = entry.transports.first {
            // Design for systemSmall
            VStack(alignment: .leading, spacing: 3) {
                
                // Location of stop
                HStack {
                    Image(systemName: "location")
                        .resizable()
                        .frame(width: 9.0, height: 9.0)
                        .padding(.trailing, -4)
                    Text("\(firstTransport.stop.name)")
                        .font(.caption2)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                
                // Route number
                HStack {
                    let imageString = TransportTypeUtils.transportType(from: firstTransport.routeType.name)
                    let (routeColour, routeTextColour) = TransportTypeUtils.routeColour(routeColour: firstTransport.route.colour, textColour: firstTransport.route.textColour)
                    
                    // Train and V Line design
                    if firstTransport.routeType.name == "Train" || firstTransport.routeType.name == "VLine" {
                        Image("\(imageString)")
                            .resizable()
                            .frame(width: 25.0, height: 25.0)
                        Text("\(firstTransport.direction.name)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(routeTextColour)
                            .padding(.horizontal, 7.0)
                            .background(RoundedRectangle(cornerRadius: 3).fill(routeColour))
                            .lineLimit(1)
                    }
                    
                    // Tram and bus designs
                    else {
                        Image("\(imageString)")
                            .resizable()
                            .frame(width: 38.0, height: 38.0)
                        Text("\(firstTransport.route.number)")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(routeTextColour)
                            .padding(.horizontal, 7.0)
                            .background(RoundedRectangle(cornerRadius: 3).fill(routeColour))
                            .lineLimit(1)
                    }
                }
                
                // Route direction for tram, bus, and skybus
                if firstTransport.routeType.name != "Train" && firstTransport.routeType.name != "VLine"{
                    Text("To \(firstTransport.direction.name)")
                        .font(.caption2)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    Divider()
                }
                else {
                    Spacer().frame(height: 3)
                    Divider()
                    Spacer().frame(height: 2)
                }
                

//                firstTransport.departures.first.hasLowFloor
                let departures = firstTransport.departures.prefix(3) // First 3 departures
                
                // Information about first 3 departures
                ForEach(departures.indices, id: \.self) { index in
                    let departure = departures[index]
                    
                    HStack(spacing: 0) {
                        
                        // Time of departure
                        Text(departure.scheduledDepartureTime ?? "Unknown")
                            .font(.callout)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                            .padding(.trailing, 1)
                        
                        // Low Floor Tram icon (if applicable)
                        if departure.hasLowFloor == true {
                            Image("Low Floor Tram")
                                .resizable()
                                .frame(width: 12.0, height: 12.0)
                                
                        }
                        
                        Spacer()
                        
                        // Minutes until departure

                        if let departureTime = departure.scheduledDepartureTime, let timeDifference = TimeUtils.timeDifference(from: departureTime) {
                            if timeDifference.minutes > 0 && timeDifference.minutes < 60 {
                                Text("\(timeDifference.minutes) min")
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.trailing)
                                    .padding(.horizontal, 4.0)
                                    .padding(.vertical, 1.0)
                                    .background(RoundedRectangle(cornerRadius: 9).fill(Color(hue: 0.314, saturation: 0.216, brightness: 0.903)))
                            }
                            else if timeDifference.minutes == 0 {
                                Text("Now")
                                    .font(.caption)
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
            }
        }
    }
}
