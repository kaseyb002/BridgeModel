import Foundation

extension Round {
    public var activePosition: Position? {
        switch state {
        case .bidding(let turn): turn
        case .playing(let turn): turn
        case .passedOut, .complete: nil
        }
    }

    public var controllingPlayerHand: PlayerHand? {
        switch state {
        case .bidding(let turn):
            return playerHand(at: turn)

        case .playing(let turn):
            if let contract, turn == contract.dummy {
                return playerHand(at: contract.declarer)
            }
            return playerHand(at: turn)

        case .passedOut, .complete:
            return nil
        }
    }

    public func playerHand(at position: Position) -> PlayerHand? {
        playerHands.first { $0.position == position }
    }

    public func playerHandIndex(for position: Position) -> Int? {
        playerHands.firstIndex { $0.position == position }
    }

    public var isDummyRevealed: Bool {
        guard contract != nil else { return false }
        if let currentTrick {
            return !currentTrick.plays.isEmpty || !tricks.isEmpty
        }
        return !tricks.isEmpty
    }

    public var declarerTricksWon: Int {
        guard let contract else { return 0 }
        let declarerPartnership: Partnership = contract.declarerPartnership
        return tricks.filter { $0.winner?.partnership == declarerPartnership }.count
    }

    public var defenderTricksWon: Int {
        guard let contract else { return 0 }
        let defenderPartnership: Partnership = contract.declarerPartnership.opponent
        return tricks.filter { $0.winner?.partnership == defenderPartnership }.count
    }

    public func legalCards(for position: Position) -> [Card] {
        guard case .playing(let turn) = state, turn == position else {
            return []
        }
        guard let handIndex: Int = playerHandIndex(for: position) else {
            return []
        }

        let hand: PlayerHand = playerHands[handIndex]

        guard let trick: Trick = currentTrick,
              let firstPlay: Trick.Play = trick.plays.first,
              let ledCard: Card = cardsMap[firstPlay.cardID]
        else {
            return hand.cards.compactMap { cardsMap[$0] }
        }

        let ledSuit: Suit = ledCard.suit
        let suitCards: [Card] = hand.cards.compactMap { id in
            guard let card: Card = cardsMap[id], card.suit == ledSuit else { return nil }
            return card
        }

        if suitCards.isEmpty {
            return hand.cards.compactMap { cardsMap[$0] }
        }
        return suitCards
    }

    public var logValue: String {
        let contractDescription: String = contract?.displayableName ?? "No contract"
        let tricksSummary: String = contract != nil
            ? "Declarer: \(declarerTricksWon), Defenders: \(defenderTricksWon)"
            : "N/A"

        return """
        State: \(state.logValue)
        Dealer: \(dealer.displayableName)
        Contract: \(contractDescription)
        Tricks: \(tricksSummary)
        Completed tricks: \(tricks.count)

        \(playerHandsLogValue)
        """
    }

    private var playerHandsLogValue: String {
        playerHands.map { hand in
            let cards: String = hand.cards
                .compactMap { cardsMap[$0]?.logValue }
                .joined(separator: ", ")
            return "\(hand.position.displayableName) (\(hand.player.name), \(hand.cards.count) cards): [\(cards)]"
        }.joined(separator: "\n")
    }
}
