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
        let transportsToShow: Array<Transport> = Array(showFirstFourEntries ? entry.transports.prefix(4) : entry.transports.prefix(2))

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
                TransportRowView(transport: transport, index: index, isLast: index == transportsToShow.count - 1)
                
                // Conditionally add divider if current entry is not final entry
                if index < transportsToShow.count - 1 {
                    Divider()
                }
            }
        }
    }
}


struct TransportRowView: View {
    let transport: Transport
    let index: Int
    let isLast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            let departures = transport.departures
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    WidgetUtils.stopLocationWidget(from: transport.stop.name)
                    
                    HStack(spacing: 6) {
                        WidgetUtils.transportTypeImage(transportType: transport.routeType.name, imageSize: 24, small: false)
                        WidgetUtils.transportNameWidget(transport: transport, small: false)
                        WidgetUtils.directionWidget(transportType: transport.routeType.name, direction: transport.direction.name, font: .caption, small: false)
                    }
                    
                    HStack(spacing: 2) {
                        Image(systemName: "clock.fill")
                            .resizable()
                            .frame(width: 13.0, height: 13.0)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color(hue: 0.609, saturation: 0.886, brightness: 0.682))
                            .padding(.trailing, 2)
                        ForEach(departures.indices, id: \.self) { index in
                            let departure = departures[index]
                            let trimmedTime = TimeUtils.trimTime(from: departure.departureTime)
                            
                            Text(trimmedTime.timeElement)
                                .font(.footnote)
                            Text(trimmedTime.timeOfDay!)
                                .font(.caption)
                            WidgetUtils.lowFloorIcon(hasLowFloor: departure.hasLowFloor, small: false, iconSize: 12)
                                .padding(.trailing, 4)
                            
                            if index < 2 {
                                Text("•")
                                    .font(.footnote)
                            }
                        }
                    }
                }
                Spacer()
                if let firstDeparture = departures.first {
                    if (firstDeparture.timeString != nil) {
                        Text(firstDeparture.timeString!)
                            .font(.caption)
                            .padding(.horizontal, 4.0)
                            .padding(.vertical, 1.0)
                            .foregroundColor(.black)
                            .background(RoundedRectangle(cornerRadius: 9).fill(Color(hex: firstDeparture.statusColour)))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
