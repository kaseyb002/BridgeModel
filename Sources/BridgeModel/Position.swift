import Foundation

public enum Position: String, Equatable, CaseIterable, Codable, Sendable {
    case north
    case east
    case south
    case west

    public var partner: Position {
        switch self {
        case .north: .south
        case .south: .north
        case .east: .west
        case .west: .east
        }
    }

    public var next: Position {
        switch self {
        case .north: .east
        case .east: .south
        case .south: .west
        case .west: .north
        }
    }

    public var partnership: Partnership {
        switch self {
        case .north, .south: .northSouth
        case .east, .west: .eastWest
        }
    }

    public var displayableName: String {
        switch self {
        case .north: "North"
        case .east: "East"
        case .south: "South"
        case .west: "West"
        }
    }
}
