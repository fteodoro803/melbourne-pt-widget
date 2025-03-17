//
//  MediumWidgetView.swift
//  Runner
//
//  Created by Nicole Penrose on 17/3/2025.
//

import SwiftUI

struct SystemMediumWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ForEach(Array(entry.transports.enumerated()), id: \.element.uniqueID) { index, transport in
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
                }
                // Transport ID and direction
                HStack {
                    Image("Melbourne_tram_logo.svg")
                        .resizable()
                        .frame(width: 20.0, height: 20.0)
                    Text("\(transport.route.number)")
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.horizontal, 7.0)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Color.gray))
                    Text("To \(transport.direction.name)")
                        .font(.caption2)
                        .multilineTextAlignment(.leading)
                }
                
                let departures = transport.departures.prefix(3) // First 3 departures
                let departureList = departures.map { $0.scheduledDepartureTime ?? "Null" }
                let departureText = departureList.joined(separator: " | ")
                HStack {
                    Text(departureText)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    if !departureList.isEmpty, let firstDeparture = departureList.first, let timeDifference = TimeUtils.timeDifference(from: firstDeparture) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Conditionally add Divider
            if index < entry.transports.count - 1 {
                Divider()
            }
        }
    }
}
