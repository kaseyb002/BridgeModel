import Foundation

extension PlayerHand {
    public static func fake(
        player: Player = .fake(),
        position: Position = .north,
        cards: [CardID] = []
    ) -> PlayerHand {
        .init(
            player: player,
            position: position,
            cards: cards
        )
    }
}
