import Foundation

public struct Bid: Equatable, Comparable, Codable, Sendable {
    public let level: BidLevel
    public let denomination: Denomination

    public init(level: BidLevel, denomination: Denomination) {
        self.level = level
        self.denomination = denomination
    }

    public static func < (lhs: Bid, rhs: Bid) -> Bool {
        if lhs.level != rhs.level {
            return lhs.level < rhs.level
        }
        return lhs.denomination < rhs.denomination
    }

    public var tricksNeeded: Int {
        level.rawValue + 6
    }

    public var trickScore: Int {
        denomination.firstTrickBonus + denomination.trickValue * level.rawValue
    }

    public var isGame: Bool {
        trickScore >= 100
    }

    public var isSmallSlam: Bool {
        level == .six
    }

    public var isGrandSlam: Bool {
        level == .seven
    }

    public var displayableName: String {
        "\(level.rawValue)\(denomination.symbol)"
    }
}
