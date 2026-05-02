import Foundation

public struct PlayerHand: Equatable, Codable, Sendable {
    public var player: Player
    public let position: Position
    public var cards: [CardID]

    public init(
        player: Player,
        position: Position,
        cards: [CardID]
    ) {
        self.player = player
        self.position = position
        self.cards = cards
    }
}
