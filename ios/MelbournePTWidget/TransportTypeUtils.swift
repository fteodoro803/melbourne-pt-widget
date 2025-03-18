//
//  TransportTypeUtils.swift
//  Runner
//
//  Created by Nicole Penrose on 18/3/2025.
//

import SwiftUI
import Foundation

struct TransportTypeUtils {
    
    // Returns image name for icon of given transport type
    static func transportType(from inputType: String) -> String {
        if inputType == "Tram" {
            return "PTV Tram"
        }
        else if inputType == "Bus" {
            return "PTV Bus"
        }
        else if inputType == "Train" {
            return "PTV Train"
        }
        else if inputType == "V Line" {
            return "PTV VLine"
        }
        else if inputType == "Sky Bus" {
            return "PTV Skybus"
        } else {
            return "PTV Tram"
        }
    }
    
    // Returns image name for icon of a given transport type (small, no colour)
    static func transportTypeSmall(from inputType: String) -> String {
        if inputType == "Tram" {
            return "PTV Tram Small"
        }
        else if inputType == "Bus" {
            return "PTV Bus Small"
        }
        else if inputType == "Train" {
            return "PTV Train Small"
        }
        else if inputType == "V Line" {
            return "PTV Train Small"
        }
        else if inputType == "Skybus" {
            return "PTV Bus Small"
        } else {
            return "PTV Tram Small"
        }
    }
    
    // Returns color code of given route type and/or route number, as well as text color
    static func routeColor(from inputType: String, routeNumber: String? = nil) -> (Color, Color?) {
        if inputType == "Bus" {
            return (Color.orange, Color.white)
        }
        else if inputType == "Train" {
            return (Color.yellow, Color.black)
        }
        else if inputType == "Tram" {
            return (Color.gray, Color.white)
        }
        else if inputType == "V Line" {
            return (Color.purple, Color.white)
        }
        else if inputType == "Skybus" {
            return (Color.red, Color.white)
        } else {
            return (Color.gray, Color.white)
        }
    }
}
