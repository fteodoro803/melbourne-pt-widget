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
        if let firstTransport = entry.transports.first {
            // DESIGN for systemSmall
            VStack(alignment: .leading, spacing: 3) {
                Spacer()
                HStack {
                    Image(systemName: "location")
                        .resizable()
                        .frame(width: 9.0, height: 9.0)
                        .padding(.trailing, -4)
                    
                    Text("\(firstTransport.stop.name)")
                        .font(.caption2)
                        .multilineTextAlignment(.leading)
                }
                HStack {
                    Image("Melbourne_tram_logo.svg")
                        .resizable()
                        .frame(width: 35.0, height: 35.0)
                    Text("\(firstTransport.route.number)")
                        .font(.title)
                        .fontWeight(.medium)
                        .padding(.horizontal, 7.0)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Color.gray))
                }
                
                Text("To \(firstTransport.direction.name)")
                    .font(.caption2)
                    .multilineTextAlignment(.leading)
                
                Divider()
                
                let departures = firstTransport.departures.prefix(3) // First 3 departures
                let departureText = departures.map { $0.scheduledDepartureTime ?? "Null" }
                
                ForEach(departureText, id: \.self) { departure in
                    HStack {
                        Text(departure)
                            .font(.callout)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if let timeDifference = TimeUtils.timeDifference(from: departure) {
                            if timeDifference.minutes > 0 && timeDifference.minutes < 60 {
                                Text("\(timeDifference.minutes) min")
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.trailing)
                                    .padding(.horizontal, 4.0)
                                    .padding(.vertical, 1.0)
                                    .background(RoundedRectangle(cornerRadius: 9).fill(Color(hue: 0.314, saturation: 0.216, brightness: 0.903)))
                            }
                            else if timeDifference.minutes == 0 {
                                Text("Now")
                                    .font(.footnote)
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
//            .padding(.trailing, 9)
//            .padding(.leading, 9)
//            .padding(.top, 9)
//            .padding(.bottom, 9)
            Spacer()
        }
    }
}
