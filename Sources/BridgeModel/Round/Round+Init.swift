import Foundation

extension Round {
    public static let cardsPerPlayer: Int = 13
    public static let totalCards: Int = 52

    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        ruleOptions: RuleOptions = .standard,
        dealer: Position = .north,
        vulnerability: Vulnerability = .none,
        cookedDeck: [Card]? = nil,
        players: [Player]
    ) throws {
        guard players.count == 4 else {
            throw BridgeError.invalidPlayerCount
        }

        self.id = id
        self.started = started
        self.ruleOptions = ruleOptions
        self.dealer = dealer
        self.vulnerability = vulnerability
        self.auction = []
        self.contract = nil
        self.tricks = []
        self.currentTrick = nil
        self.result = nil
        self.log = .init()
        self.ended = nil

        var allCards: [Card] = cookedDeck ?? [Card].deck().shuffled()
        self.cardsMap = Dictionary(uniqueKeysWithValues: allCards.map { ($0.id, $0) })

        let dealOrder: [Position] = Self.dealOrder(from: dealer)
        self.playerHands = Self.dealCards(
            to: players,
            positions: dealOrder,
            deck: &allCards
        )

        self.state = .bidding(turn: dealer.next)
    }

    static func dealOrder(from dealer: Position) -> [Position] {
        var order: [Position] = []
        var pos: Position = dealer.next
        for _ in 0..<4 {
            order.append(pos)
            pos = pos.next
        }
        return order
    }

    private static func dealCards(
        to players: [Player],
        positions: [Position],
        deck: inout [Card]
    ) -> [PlayerHand] {
        var hands: [PlayerHand] = []
        for (index, position) in positions.enumerated() {
            let playerCards: [Card] = Array(deck.suffix(cardsPerPlayer))
            deck.removeLast(cardsPerPlayer)
            let playerHand: PlayerHand = .init(
                player: players[index],
                position: position,
                cards: playerCards.map(\.id)
            )
            hands.append(playerHand)
        }
        return hands
    }
}
