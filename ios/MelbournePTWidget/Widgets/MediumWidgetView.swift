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
        
        VStack(alignment: .leading) {
            if showFirstFourEntries {
                HStack {
                    Image(systemName: "pin.fill")
                        .resizable()
                        .frame(width: 9.0, height: 13.0)
                        .padding(.trailing, -4)
                    Text("Your saved routes:")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Divider()
            }
            
            ForEach(Array(transportsToShow.enumerated()), id: \.element.uniqueID) { index, transport in
                VStack(alignment: .leading, spacing: 3) {
                    
                    let departures = transport.departures.prefix(3) // First 3 departures
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            // Location of stop
                            WidgetUtils.stopLocationWidget(from: transport.stop.name)
                            
                            // Route number and direction
                            HStack(spacing: 6) {
                                WidgetUtils.transportTypeImage(transportType: transport.routeType.name, imageSize: 27, small: false)
                                WidgetUtils.transportNameWidget(transport: transport, small: false)
                                WidgetUtils.directionWidget(transportType: transport.routeType.name, direction: transport.direction.name, font: .caption, small: false)
                            }
                            
                            HStack(spacing: 2) {
                                ForEach(departures.indices, id: \.self) { index in
                                    
                                    let departure = departures[index]
                                    let departureTime = departure.estimatedDepartureTime ?? departure.scheduledDepartureTime ?? ""
                                    let trimmedTime = TimeUtils.trimTime(from: departureTime)
                                    
                                    Text(trimmedTime.timeElement)
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.leading)
                                    Text(trimmedTime.timeOfDay!)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.leading)
                                    
                                    WidgetUtils.lowFloorIcon(hasLowFloor: departure.hasLowFloor, small: false, iconSize: 12)
                                    
                                    if index < 2 {
                                        Text("•")
                                            .font(.footnote)
                                            .fontWeight(.medium)
                                            .multilineTextAlignment(.leading)
                                            .padding(.trailing, 2)
                                    }
                                }
                            }
                        }
                        Spacer()
                        
                        // Time until first departure
                        if !departures.isEmpty, let firstDeparture = departures.first, let timeDifference = TimeUtils.timeDifference(estimatedTime: firstDeparture.scheduledDepartureTime!, scheduledTime: nil) {
                            
                            WidgetUtils.timeUntilDepartureWidget(from: timeDifference)
                            
//                            VStack {
//                                Image(systemName: "wifi")
//                                    .resizable()
//                                    .frame(width: 9.0, height: 6.0)
////                                    .padding(.trailing, -4)
////                                    .frame(maxWidth: .infinity, alignment: .trailing)
////                                Text("On time")
//                                WidgetUtils.timeUntilDepartureWidget(from: timeDifference)
//                            }
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
}
