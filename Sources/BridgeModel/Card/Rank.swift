import Foundation

public enum Rank: Int, Equatable, Comparable, CaseIterable, Codable, Sendable {
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    case ace = 14

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var highCardPoints: Int {
        switch self {
        case .ace: 4
        case .king: 3
        case .queen: 2
        case .jack: 1
        default: 0
        }
    }

    public var isHonor: Bool {
        self >= .ten
    }

    public var displayableName: String {
        switch self {
        case .two: "2"
        case .three: "3"
        case .four: "4"
        case .five: "5"
        case .six: "6"
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .ten: "10"
        case .jack: "Jack"
        case .queen: "Queen"
        case .king: "King"
        case .ace: "Ace"
        }
    }

    public var shortName: String {
        switch self {
        case .two: "2"
        case .three: "3"
        case .four: "4"
        case .five: "5"
        case .six: "6"
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .ten: "T"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        case .ace: "A"
        }
    }
}
