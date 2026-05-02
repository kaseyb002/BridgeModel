import Foundation

extension Card {
    public var logValue: String {
        "\(rank.shortName)\(suit.symbol)"
    }
}

// MARK: - Deck Generation

extension [Card] {
    public static func deck() -> [Card] {
        var cards: [Card] = []
        var nextID: CardID = 0
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(id: nextID, suit: suit, rank: rank))
                nextID += 1
            }
        }
        return cards
    }

    public var logValue: String {
        map { $0.logValue }.joined(separator: ", ")
    }
}

extension [CardID] {
    public func sortedByRank(cardsMap: [CardID: Card]) -> [CardID] {
        sorted { a, b in
            guard let cardA: Card = cardsMap[a], let cardB: Card = cardsMap[b] else {
                return false
            }
            if cardA.suit != cardB.suit {
                return cardA.suit < cardB.suit
            }
            return cardA.rank < cardB.rank
        }
    }
}

extension [CardID: Card] {
    public func findCards(byIDs cardIDs: [CardID]) -> [Card] {
        cardIDs.compactMap { self[$0] }
    }
}
