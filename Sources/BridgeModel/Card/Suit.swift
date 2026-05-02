import Foundation

public enum Suit: String, Equatable, Comparable, CaseIterable, Codable, Sendable {
    case clubs
    case diamonds
    case hearts
    case spades

    private var sortOrder: Int {
        switch self {
        case .clubs: 0
        case .diamonds: 1
        case .hearts: 2
        case .spades: 3
        }
    }

    public static func < (lhs: Suit, rhs: Suit) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    public var isMajor: Bool {
        self == .hearts || self == .spades
    }

    public var isMinor: Bool {
        self == .clubs || self == .diamonds
    }

    public var displayableName: String {
        switch self {
        case .clubs: "Clubs"
        case .diamonds: "Diamonds"
        case .hearts: "Hearts"
        case .spades: "Spades"
        }
    }

    public var symbol: String {
        switch self {
        case .clubs: "♣"
        case .diamonds: "♦"
        case .hearts: "♥"
        case .spades: "♠"
        }
    }
}
