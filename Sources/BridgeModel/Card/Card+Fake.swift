import Foundation

extension Card {
    public static func fake(
        id: CardID = Int.random(in: 0...999),
        suit: Suit = .spades,
        rank: Rank = .ace
    ) -> Card {
        .init(id: id, suit: suit, rank: rank)
    }
}
