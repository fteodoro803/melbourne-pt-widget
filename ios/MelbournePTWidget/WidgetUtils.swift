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

struct TimeUtils {
    
    static func trimTime(from inputTime: String) -> (timeElement: String, timeOfDay: String?) {
        guard inputTime.count > 5 else { return (inputTime, nil) }
        
        var timeElement: String
        let timeOfDay = String(inputTime.suffix(2))
        

        if inputTime.hasPrefix("0") {
            timeElement = String(inputTime[inputTime.index(inputTime.startIndex, offsetBy: 1)..<inputTime.index(inputTime.endIndex, offsetBy: -2)])
        } else {
            timeElement = String(inputTime[inputTime.index(inputTime.startIndex, offsetBy: 0)..<inputTime.index(inputTime.endIndex, offsetBy: -2)])
        }
        return (timeElement, timeOfDay)
        
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
        let isTrain = transport.route.label == ""
        let name = isTrain ? transport.direction.name : transport.route.label
        let (backgroundColour, textColour) = TransportTypeUtils.routeColour(routeColour: transport.route.colour, textColour: transport.route.textColour)
        return Text(name)
            .font(small ? (isTrain ? .system(size: 16) : .system(size: 19)) : (isTrain ? .system(size: 13) : . system(size: 16)))
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
                Image(systemName: "figure.roll.circle.fill")
                    .resizable()
                    .frame(width: 13.0, height: 13.0)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color(hue: 0.609, saturation: 0.886, brightness: 0.682))
                    .padding(.trailing, -4)
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
            if small {
                Spacer().frame(height: 0.5)
                Divider()
                
            }
            else {
                EmptyView()
            }
        }
    }
}

