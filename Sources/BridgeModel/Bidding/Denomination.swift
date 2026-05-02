import Foundation

public enum Denomination: Int, Equatable, Comparable, CaseIterable, Codable, Sendable {
    case clubs = 0
    case diamonds = 1
    case hearts = 2
    case spades = 3
    case noTrump = 4

    public static func < (lhs: Denomination, rhs: Denomination) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var suit: Suit? {
        switch self {
        case .clubs: .clubs
        case .diamonds: .diamonds
        case .hearts: .hearts
        case .spades: .spades
        case .noTrump: nil
        }
    }

    public var isMajor: Bool {
        self == .hearts || self == .spades
    }

    public var isMinor: Bool {
        self == .clubs || self == .diamonds
    }

    public var trickValue: Int {
        switch self {
        case .clubs, .diamonds: 20
        case .hearts, .spades: 30
        case .noTrump: 30
        }
    }

    public var firstTrickBonus: Int {
        self == .noTrump ? 10 : 0
    }

    public var displayableName: String {
        switch self {
        case .clubs: "Clubs"
        case .diamonds: "Diamonds"
        case .hearts: "Hearts"
        case .spades: "Spades"
        case .noTrump: "No Trump"
        }
    }

    public var symbol: String {
        switch self {
        case .clubs: "♣"
        case .diamonds: "♦"
        case .hearts: "♥"
        case .spades: "♠"
        case .noTrump: "NT"
        }
    }
}
