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
}

struct Direction: Codable {
    let direction: String
}

struct Departure: Codable {
    let estimatedDeparture: String?
    let scheduledDeparture: String?
}

struct Transport: Codable {
    let routeType: RouteType
    let stop: Stop
    let route: Route
    let direction: Direction
    let departure: [Departure]
}
