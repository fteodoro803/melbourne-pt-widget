//
//  WidgetUtils.swift
//  Runner
//
//  Created by Nicole Penrose on 18/3/2025.
//

import SwiftUI
import Foundation

extension Color {
    init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexSanitized)
        scanner.charactersToBeSkipped = CharacterSet.alphanumerics.inverted
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

struct TransportTypeUtils {
    
    private static let validTransportTypes = ["tram", "bus", "train", "vLine", "nightBus"]
    
    // Returns image name for icon of given transport type
    static func transportTypeImage(from inputType: String) -> String {
        let type = validTransportTypes.contains(inputType) ? inputType : "bus"
        return "PTV \(type)"
    }
    
    // Returns image name for icon of a given transport type (small, no colour)
    static func transportTypeSmallImage(from inputType: String) -> String {
        let type = validTransportTypes.contains(inputType) ? inputType : "bus"
        return "PTV \(type) Small"
    }
    
    // Returns color code of given route type and/or route number, as well as text color
    static func routeColour(routeColour: String, textColour: String) -> (Color, Color?) {
        return (Color(hex: routeColour), Color(hex: textColour))
    }
    
    static func getTransportName(direction: String, number: String) -> String {
        return number != "" ? number : direction
    }
}

struct WidgetUtils {
    static func transportTypeImage(transportType: String, imageSize: Double, small: Bool) -> some View {
        let imageString = small ? TransportTypeUtils.transportTypeSmallImage(from: transportType) : TransportTypeUtils.transportTypeImage(from: transportType)
        return Image("\(imageString)")
            .resizable()
            .frame(width: imageSize, height: imageSize)
    }
    
    static func transportNameWidget(transport: Transport, small: Bool) -> some View {
        let isTrain = transport.route.number == ""
        let name = isTrain ? transport.direction.name : transport.route.number
        let (backgroundColour, textColour) = TransportTypeUtils.routeColour(routeColour: transport.route.colour, textColour: transport.route.textColour)
        return Text(name)
            .font(small ? (isTrain ? .title3 : .title2) : (isTrain ? .headline : .title3))
            .fontWeight(.semibold)
            .foregroundColor(textColour)
            .padding(.vertical, small ? 3.0 : 2.0)
            .padding(.horizontal, small ? 9.0 : 7.0)
            .background(RoundedRectangle(cornerRadius: 8).fill(backgroundColour))
            .lineLimit(1)
    }
    
    static func stopLocationWidget(from stopName: String) -> some View {
        return HStack {
            Image(systemName: "location")
                .resizable()
                .frame(width: 9.0, height: 9.0)
                .padding(.trailing, -4)
            Text(stopName)
                .font(.caption2)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
        }
    }
    
    static func lowFloorIcon(hasLowFloor: Bool?, small: Bool, iconSize: Double) -> some View {
        Group {
            if hasLowFloor == true {
                Image("Low Floor Tram")
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .padding(.trailing, small ? 0 : 2)
            }
            else {
                EmptyView()
            }
        }
    }
    
    static func timeUntilDepartureWidgetWithStatus(estimatedTime: String?, scheduledTime: String) -> some View {
        
        Group {
            let estimatedTime = estimatedTime ?? scheduledTime
            let status = TimeUtils.getStatus(estimatedTime: estimatedTime, scheduledTime: scheduledTime)
            let timeDifference = TimeUtils.timeDifference(estimatedTime: estimatedTime, scheduledTime: nil)
            
            if timeDifference!.minutes >= 0 && timeDifference!.minutes < 60 && timeDifference!.days == 0 && timeDifference!.hours == 0 {
                
                let isNow = timeDifference!.minutes == 0
                let minutesString = isNow ? "Now" : "\(timeDifference!.minutes) min"
                
                Text(minutesString)
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(Color(status.textColour))
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 4.0)
                    .padding(.vertical, 1.0)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Color(status.colour)))
            }
            else {
                EmptyView()
            }
        }
    }
    
    static func timeUntilDepartureWidget(from timeDifference: (days: Int, hours: Int, minutes: Int)?) -> some View {
        Group {
            if timeDifference!.minutes >= 0 && timeDifference!.minutes < 60 && timeDifference!.days == 0 && timeDifference!.hours == 0 {
                
                let isNow = timeDifference!.minutes == 0
                let minutesString = isNow ? "Now" : "\(timeDifference!.minutes) min"
                
                Text(minutesString)
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(isNow ? Color(hue: 0.324, saturation: 0.671, brightness: 0.656) : .black)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 4.0)
                    .padding(.vertical, 1.0)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Color(hue: 0.314, saturation: 0.216, brightness: 0.903)))
            }
            else {
                EmptyView()
            }
        }
    }
    
    static func directionWidget(transportType: String, direction: String, font: Font, small: Bool) -> some View {
        Group {
            if transportType != "train" && transportType != "vLine" {
                Text("To \(direction)")
                    .font(font)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            else if small {
                Spacer().frame(height: 3)
                Divider()
                Spacer().frame(height: 2)
                
            }
            else {
                EmptyView()
            }
        }
    }
}

