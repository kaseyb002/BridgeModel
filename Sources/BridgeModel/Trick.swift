import Foundation

public struct Trick: Equatable, Codable, Sendable {
    public let leader: Position
    public var plays: [Play]
    public var winner: Position?

    public struct Play: Equatable, Codable, Sendable {
        public let position: Position
        public let cardID: CardID

        public enum CodingKeys: String, CodingKey {
            case position
            case cardID = "cardId"
        }

        public init(position: Position, cardID: CardID) {
            self.position = position
            self.cardID = cardID
        }
    }

    public init(leader: Position, plays: [Play] = [], winner: Position? = nil) {
        self.leader = leader
        self.plays = plays
        self.winner = winner
    }

    public var isComplete: Bool { plays.count == 4 }
}
