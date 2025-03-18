//
//  TimeUtils.swift
//  Runner
//
//  Created by Nicole Penrose on 17/3/2025.
//

import Foundation

struct TimeUtils {
    
    // Finds time difference in days and minutes between system time and given departure time
    static func timeDifference(from inputTime: String) -> (days: Int, minutes: Int)? {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        
        guard let inputDate = formatter.date(from: inputTime) else {
            return nil
        }
        
        let currentDate = Date()
        
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
        var inputComponents = calendar.dateComponents([.hour, .minute], from: inputDate)
        
        inputComponents.year = currentComponents.year
        inputComponents.month = currentComponents.month
        inputComponents.day = currentComponents.day
        
        guard let fullInputDate = calendar.date(from: inputComponents) else {
            return nil
        }
        
        let difference = calendar.dateComponents([.day, .minute], from: currentDate, to: fullInputDate)
        return (difference.day ?? 0, difference.minute ?? 0)
    }
}
