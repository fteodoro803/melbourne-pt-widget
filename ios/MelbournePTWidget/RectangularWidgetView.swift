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
            // DESIGN for accessoryRectangular
            VStack(alignment: .leading, spacing: 3) {
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
                HStack {
                    Image(systemName: "tram.fill")
                        .resizable()
                        .frame(width: 9.0, height: 12.0)
                        .padding(.trailing, -3)
                    Text("\(firstTransport.route.number)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.trailing, -5)
                    Text("to \(firstTransport.direction.name)")
                        .font(.caption2)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                let departures = firstTransport.departures.prefix(2) // First 2 departures
                let departureText = departures.map { $0.scheduledDepartureTime ?? "Null" }
                
                // Now and in 15 min
                // In 15 min and 20 min
                HStack {
                    if let timeDifference = TimeUtils.timeDifference(from: departureText[0]) {
                        if timeDifference.minutes > 0 && timeDifference.minutes < 60 {
                            Text("In ")
                                .font(.caption2)
                                .fontWeight(.regular)
                                .padding(.trailing, -9)
                            Text("\(timeDifference.minutes) min")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.trailing, -6)
                            Text("and ") // Only if there is an instance
                                .font(.caption2)
                                .fontWeight(.regular)
                                .padding(.trailing, -9)
                        }
                        else if timeDifference.minutes == 0 {
                            Text("Now")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.trailing, -6)
                            Text("and in ") // Only if there is an instance
                                .font(.caption2)
                                .fontWeight(.regular)
                                .padding(.trailing, -9)
                        }
                    }
                    if let timeDifference = TimeUtils.timeDifference(from: departureText[1]) {
                        if timeDifference.minutes > 0 && timeDifference.minutes < 60 {
                            Text("\(timeDifference.minutes) min")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }
}
