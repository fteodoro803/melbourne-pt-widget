import Foundation

// ~note make sure there is null checking

struct RouteType: Codable {
    let name: String
}

struct Stop: Codable {
    let name: String
}

struct Route: Codable {
    let number: String
    let colour: String
    let textColour: String
}

struct Direction: Codable {
    let name: String
}

struct Departure: Codable {
    let estimatedDepartureTime: String?
    let scheduledDepartureTime: String?
    let hasLowFloor: Bool?
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
            Route Type: \(routeType.name)
            Stop: \(stop.name)
            Route Number: \(route.number)
            Direction: \(direction.name)
            Departures:
            \(departures.map { departure in
                "Scheduled: \(departure.scheduledDepartureTime ?? "N/A"), Estimated: \(departure.estimatedDepartureTime ?? "N/A")"
            }.joined(separator: "\n"))
            """
        }
}
