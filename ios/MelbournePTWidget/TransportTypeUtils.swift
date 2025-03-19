//
//  TransportTypeUtils.swift
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
    
    private static let validTransportTypes = ["Tram", "Bus", "Train", "VLine", "Night Bus"]
    
    // Returns image name for icon of given transport type
    static func transportType(from inputType: String) -> String {
        let type = validTransportTypes.contains(inputType) ? inputType : "Bus"
        return "PTV \(type)"
    }
    
    // Returns image name for icon of a given transport type (small, no colour)
    static func transportTypeSmall(from inputType: String) -> String {
        let type = validTransportTypes.contains(inputType) ? inputType : "Bus"
        return "PTV \(type) Small"
    }
    
    // Returns color code of given route type and/or route number, as well as text color
    static func routeColour(routeColour: String, textColour: String) -> (Color, Color?) {
        return (Color(hex: routeColour), Color(hex: textColour))
    }
}
