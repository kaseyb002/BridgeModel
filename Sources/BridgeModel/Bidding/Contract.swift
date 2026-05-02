import Foundation

public struct Contract: Equatable, Codable, Sendable {
    public let bid: Bid
    public let declarer: Position
    public let isDoubled: Bool
    public let isRedoubled: Bool

    public init(
        bid: Bid,
        declarer: Position,
        isDoubled: Bool = false,
        isRedoubled: Bool = false
    ) {
        self.bid = bid
        self.declarer = declarer
        self.isDoubled = isDoubled
        self.isRedoubled = isRedoubled
    }

    public var dummy: Position { declarer.partner }
    public var tricksNeeded: Int { bid.tricksNeeded }
    public var declarerPartnership: Partnership { declarer.partnership }
    public var openingLeader: Position { declarer.next }

    public var multiplier: Int {
        if isRedoubled { return 4 }
        if isDoubled { return 2 }
        return 1
    }

    public var displayableName: String {
        var name: String = bid.displayableName
        if isRedoubled {
            name += " Redoubled"
        } else if isDoubled {
            name += " Doubled"
        }
        return name
    }
}
