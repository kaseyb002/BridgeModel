import Foundation

public typealias CardID = Int

public struct Card: Equatable, Codable, Sendable, Identifiable {
    public let id: CardID
    public let suit: Suit
    public let rank: Rank

    public init(id: CardID, suit: Suit, rank: Rank) {
        self.id = id
        self.suit = suit
        self.rank = rank
    }
}
