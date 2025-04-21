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
                WidgetUtils.stopLocationWidget(from: firstTransport.stop.name)
                
                // Route number
                HStack(spacing: 6) {
                    WidgetUtils.transportTypeImage(transportType: firstTransport.routeType.name, imageSize: 28, small: false)
                    WidgetUtils.transportNameWidget(transport: firstTransport, small: true)
                }
                
                WidgetUtils.directionWidget(transportType: firstTransport.routeType.name, direction: firstTransport.direction.name, font: .caption2, small: true)
               
                let departures = firstTransport.departures.prefix(3) // First 3 departures
                
                // Information about first 3 departures
                ForEach(departures.indices, id: \.self) { index in
                    let departure = departures[index]
                    let trimmedDepartureTime = TimeUtils.trimTime(from: departure.departureTime)
                    
                    HStack(spacing: 0) {
                        Text(trimmedDepartureTime.timeElement)
                            .font(.callout)
                            .fontWeight(.regular)
                            .multilineTextAlignment(.leading)
                            .padding(.trailing, 1)
                        Text(trimmedDepartureTime.timeOfDay!)
                            .font(.caption2)
                            .fontWeight(.regular)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 3)
                            .padding(.trailing, 1)
                        Spacer().frame(width: 2)
                        
                        WidgetUtils.lowFloorIcon(hasLowFloor: departure.hasLowFloor, small: true, iconSize: 11)
                        if departure.timeString != nil {
                            Text(departure.timeString!)
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, 4.0)
                                .padding(.vertical, 1.0)
                                .background(RoundedRectangle(cornerRadius: 9).fill(Color(hex: departure.statusColour)))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}
