//
//  TimeUtils.swift
//  Runner
//
//  Created by Nicole Penrose on 17/3/2025.
//

import Foundation
import UIKit

struct TimeUtils {
    
    // Finds time difference in days and minutes between system time and given departure time
    static func timeDifference(estimatedTime: String, scheduledTime: String?) -> (days: Int, hours: Int, minutes: Int)? {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        
        guard let estimatedDate = formatter.date(from: estimatedTime) else {
            return nil
        }
        
        let scheduledDate = scheduledTime != nil ? formatter.date(from: scheduledTime!) : nil
        
        let currentDate = Date()
        
        let calendar = Calendar.current
        let currentTimeComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
        
        var scheduledTimeComponents = scheduledTime != nil ? calendar.dateComponents([.hour, .minute], from: scheduledDate!) : nil
        var estimatedTimeComponents = calendar.dateComponents([.hour, .minute], from: estimatedDate)
        
        estimatedTimeComponents.year = currentTimeComponents.year
        estimatedTimeComponents.month = currentTimeComponents.month
        estimatedTimeComponents.day = currentTimeComponents.day
        
        if scheduledTimeComponents != nil {
            scheduledTimeComponents!.year = currentTimeComponents.year
            scheduledTimeComponents!.month = currentTimeComponents.month
            scheduledTimeComponents!.day = currentTimeComponents.day
        }
        
        guard let fullEstimatedDate = calendar.date(from: estimatedTimeComponents) else {
            return nil
        }
        
        if scheduledTimeComponents != nil {
            guard let fullScheduledDate = calendar.date(from: scheduledTimeComponents!) else {
                return nil
            }
            let difference = calendar.dateComponents([.day, .hour, .minute], from: fullScheduledDate, to: fullEstimatedDate)
            return (difference.day ?? 0, difference.hour ?? 0, difference.minute ?? 0)
        }
        
        let difference = calendar.dateComponents([.day, .hour, .minute], from: currentDate, to: fullEstimatedDate)
        return (difference.day ?? 0, difference.hour ?? 0, difference.minute ?? 0)
    }
    
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
    
    static func getStatus(estimatedTime: String?, scheduledTime: String) -> (status: String, minutes: Int?, colour: UIColor, textColour: UIColor) {
        if estimatedTime == nil {
            return ("Scheduled", nil, .gray, .white)
        }
        else if estimatedTime == scheduledTime {
            return ("On time", nil, .green, .black)
        }
        else {
            let timeDifference = timeDifference(estimatedTime: estimatedTime!, scheduledTime: scheduledTime)
            if timeDifference!.minutes > 0 && timeDifference!.hours == 0 && timeDifference!.days == 0 {
                return ("Delayed", timeDifference!.minutes, .red, .black)
            }
            else if timeDifference!.minutes < 0 && timeDifference!.hours == 0 && timeDifference!.days == 0 {
                return ("Early", timeDifference!.minutes, .yellow, .black)
            }
            else {
                return ("Scheduled", nil, .gray, .white)
            }
        }
    }
}
