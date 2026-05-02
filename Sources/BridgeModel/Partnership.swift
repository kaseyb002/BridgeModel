import Foundation

public enum Partnership: String, Equatable, CaseIterable, Codable, Sendable {
    case northSouth
    case eastWest

    public var opponent: Partnership {
        switch self {
        case .northSouth: .eastWest
        case .eastWest: .northSouth
        }
    }

    public var positions: [Position] {
        switch self {
        case .northSouth: [.north, .south]
        case .eastWest: [.east, .west]
        }
    }

    public var displayableName: String {
        switch self {
        case .northSouth: "North-South"
        case .eastWest: "East-West"
        }
    }
}
