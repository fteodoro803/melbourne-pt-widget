import Foundation

//struct RouteType: Codable {
//    let type: RouteTypeEnum
//    
//    // Accessor to retrieve the name of the routeType from the enum
//    var name: String {
//        return type.name
//    }
//}

// ~note make sure there is null checking

struct RouteType: Codable {
    let name: String
}

struct Stop: Codable {
    let name: String
}

struct Route: Codable {
    let label: String
    let colour: String
    let textColour: String
}

struct Direction: Codable {
    let name: String
}

struct Departure: Codable {
    let departureTime: String
    let hasLowFloor: Bool?
    let platformNumber: String?
    let statusColour: String
    let timeString: String?
}

struct Transport: Codable, CustomStringConvertible {
    let uniqueID: String
    let routeType: RouteType
    let stop: Stop
    let route: Route
    let direction: Direction
    let departures: [Departure]
            
    var description: String {
        return """
        Route Type: \(routeType.name) // Access name from RouteType
        Stop: \(stop.name)
        Route Number: \(route.label)
        Direction: \(direction.name)
        Departures:
        \(departures.map { departure in
            "Departure Time: \(departure.departureTime)"
        }.joined(separator: "\n"))
        """
    }
}
