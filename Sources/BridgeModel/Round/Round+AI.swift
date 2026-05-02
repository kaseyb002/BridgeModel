import Foundation

extension Round {
    public enum AIDifficulty: String, Equatable, Codable, Sendable {
        case easy
        case medium
        case hard
    }

    public mutating func makeAIMove(difficulty: AIDifficulty) {
        switch state {
        case .bidding(let turn):
            makeAIBiddingMove(position: turn, difficulty: difficulty)

        case .playing(let turn):
            makeAIPlayMove(position: turn, difficulty: difficulty)

        case .passedOut, .complete:
            break
        }
    }

    // MARK: - Bidding AI

    private mutating func makeAIBiddingMove(position: Position, difficulty: AIDifficulty) {
        let call: Call = chooseBiddingCall(position: position, difficulty: difficulty)
        try? makeCall(call)
    }

    private func chooseBiddingCall(position: Position, difficulty: AIDifficulty) -> Call {
        guard let hand: PlayerHand = playerHand(at: position) else { return .pass }

        switch difficulty {
        case .easy:
            return .pass

        case .medium:
            return chooseMediumBid(hand: hand, position: position)

        case .hard:
            return chooseHardBid(hand: hand, position: position)
        }
    }

    private func chooseMediumBid(hand: PlayerHand, position: Position) -> Call {
        let hcp: Int = handHighCardPoints(hand)
        let longestSuit: Denomination = longestSuitDenomination(hand)

        if lastBid == nil && partnerHasBid(position: position) == false {
            if hcp >= 15 && isBalanced(hand) {
                return makeBidIfLegal(.init(level: .one, denomination: .noTrump))
            }
            if hcp >= 12 {
                return makeBidIfLegal(.init(level: .one, denomination: longestSuit))
            }
            return .pass
        }

        if let partnerBid: Bid = partnerLastBid(position: position) {
            if hcp >= 6 {
                if suitLength(hand, denomination: partnerBid.denomination) >= 3 {
                    let raiseLevel: BidLevel = nextLevel(above: partnerBid)
                    return makeBidIfLegal(.init(level: raiseLevel, denomination: partnerBid.denomination))
                }
                if let currentBid: Bid = lastBid, currentBid < Bid(level: .one, denomination: .noTrump) {
                    return makeBidIfLegal(.init(level: .one, denomination: .noTrump))
                }
            }
            return .pass
        }

        if let opponentBid: Bid = lastBid, opponentBid.level == .one {
            if hcp >= 12 {
                return makeBidIfLegal(.init(
                    level: longestSuit > opponentBid.denomination ? .one : .two,
                    denomination: longestSuit
                ))
            }
        }

        return .pass
    }

    private func chooseHardBid(hand: PlayerHand, position: Position) -> Call {
        let hcp: Int = handHighCardPoints(hand)
        let distribPoints: Int = distributionPoints(hand)
        let totalPoints: Int = hcp + distribPoints
        let longestSuit: Denomination = longestSuitDenomination(hand)

        if lastBid == nil && partnerHasBid(position: position) == false {
            if hcp >= 15 && hcp <= 17 && isBalanced(hand) {
                return makeBidIfLegal(.init(level: .one, denomination: .noTrump))
            }
            if totalPoints >= 12 {
                let openSuit: Denomination = bestOpeningSuit(hand)
                return makeBidIfLegal(.init(level: .one, denomination: openSuit))
            }
            return .pass
        }

        if let partnerBid: Bid = partnerLastBid(position: position) {
            if totalPoints >= 13 && suitLength(hand, denomination: partnerBid.denomination) >= 4 {
                let targetLevel: BidLevel = totalPoints >= 16 ? .four : .three
                let raiseDenom: Denomination = partnerBid.denomination
                if raiseDenom.isMajor {
                    return makeBidIfLegal(.init(level: targetLevel, denomination: raiseDenom))
                }
            }
            if totalPoints >= 10 {
                if suitLength(hand, denomination: partnerBid.denomination) >= 3 {
                    let raiseLevel: BidLevel = nextLevel(above: partnerBid)
                    return makeBidIfLegal(.init(level: raiseLevel, denomination: partnerBid.denomination))
                }
                if hcp >= 10 && isBalanced(hand) {
                    return makeBidIfLegal(.init(
                        level: nextLevel(above: partnerBid),
                        denomination: .noTrump
                    ))
                }
                return makeBidIfLegal(.init(
                    level: longestSuit > partnerBid.denomination
                        ? partnerBid.level : nextLevel(above: partnerBid),
                    denomination: longestSuit
                ))
            }
            if hcp >= 6 {
                if suitLength(hand, denomination: partnerBid.denomination) >= 3 {
                    return makeBidIfLegal(.init(
                        level: nextLevel(above: partnerBid),
                        denomination: partnerBid.denomination
                    ))
                }
                return .pass
            }
            return .pass
        }

        if hcp >= 12 {
            let overcallSuit: Denomination = longestSuit
            if let currentBid: Bid = lastBid {
                let level: BidLevel = overcallSuit > currentBid.denomination
                    ? currentBid.level : nextLevel(above: currentBid)
                return makeBidIfLegal(.init(level: level, denomination: overcallSuit))
            }
        }

        if canDouble(position: position) && hcp >= 13 {
            return .double
        }

        return .pass
    }

    // MARK: - Bidding Helpers

    private func handHighCardPoints(_ hand: PlayerHand) -> Int {
        hand.cards.reduce(0) { total, cardID in
            total + (cardsMap[cardID]?.rank.highCardPoints ?? 0)
        }
    }

    private func distributionPoints(_ hand: PlayerHand) -> Int {
        var points: Int = 0
        for suit in Suit.allCases {
            let count: Int = hand.cards.filter { cardsMap[$0]?.suit == suit }.count
            switch count {
            case 0: points += 3
            case 1: points += 2
            case 2: points += 1
            default: break
            }
        }
        return points
    }

    private func isBalanced(_ hand: PlayerHand) -> Bool {
        for suit in Suit.allCases {
            let count: Int = hand.cards.filter { cardsMap[$0]?.suit == suit }.count
            if count < 2 || count > 5 { return false }
        }
        return true
    }

    private func longestSuitDenomination(_ hand: PlayerHand) -> Denomination {
        var bestDenom: Denomination = .clubs
        var bestCount: Int = 0
        for denom in Denomination.allCases where denom != .noTrump {
            let suit: Suit? = denom.suit
            let count: Int = hand.cards.filter { cardsMap[$0]?.suit == suit }.count
            if count > bestCount || (count == bestCount && denom > bestDenom) {
                bestCount = count
                bestDenom = denom
            }
        }
        return bestDenom
    }

    private func bestOpeningSuit(_ hand: PlayerHand) -> Denomination {
        var suits: [(Denomination, Int)] = []
        for denom in [Denomination.spades, .hearts, .diamonds, .clubs] {
            let count: Int = hand.cards.filter { cardsMap[$0]?.suit == denom.suit }.count
            suits.append((denom, count))
        }
        suits.sort { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            return a.0 > b.0
        }
        if let best: (Denomination, Int) = suits.first, best.1 >= 4 {
            return best.0
        }
        return suits.first?.0 ?? .clubs
    }

    private func suitLength(_ hand: PlayerHand, denomination: Denomination) -> Int {
        guard let suit: Suit = denomination.suit else { return 0 }
        return hand.cards.filter { cardsMap[$0]?.suit == suit }.count
    }

    private func partnerHasBid(position: Position) -> Bool {
        let partner: Position = position.partner
        return auction.contains { entry in
            entry.position == partner && {
                if case .bid = entry.call { return true }
                return false
            }()
        }
    }

    private func partnerLastBid(position: Position) -> Bid? {
        let partner: Position = position.partner
        for entry in auction.reversed() {
            if entry.position == partner, case .bid(let bid) = entry.call {
                return bid
            }
        }
        return nil
    }

    private func canDouble(position: Position) -> Bool {
        guard let last: AuctionEntry = lastBidEntry else { return false }
        return last.position.partnership != position.partnership
            && lastNonPassCall?.isDouble != true
            && lastNonPassCall?.isRedouble != true
    }

    private func nextLevel(above bid: Bid) -> BidLevel {
        BidLevel(rawValue: bid.level.rawValue + 1) ?? .seven
    }

    private func makeBidIfLegal(_ bid: Bid) -> Call {
        if let currentBid: Bid = lastBid, bid <= currentBid {
            return .pass
        }
        guard bid.level.rawValue >= 1 && bid.level.rawValue <= 7 else {
            return .pass
        }
        return .bid(bid)
    }

    // MARK: - Play AI

    private mutating func makeAIPlayMove(position: Position, difficulty: AIDifficulty) {
        let legal: [Card] = legalCards(for: position)
        guard let card: Card = choosePlayCard(
            from: legal,
            position: position,
            difficulty: difficulty
        ) else { return }

        try? playCard(card.id)
    }

    private func choosePlayCard(
        from cards: [Card],
        position: Position,
        difficulty: AIDifficulty
    ) -> Card? {
        guard cards.isEmpty == false else { return nil }

        switch difficulty {
        case .easy:
            return cards.randomElement()

        case .medium:
            return chooseMediumPlayCard(from: cards, position: position)

        case .hard:
            return chooseHardPlayCard(from: cards, position: position)
        }
    }

    private func chooseMediumPlayCard(from cards: [Card], position: Position) -> Card {
        guard let trick: Trick = currentTrick else {
            return leadCard(from: cards, position: position, smart: false)
        }

        if trick.plays.isEmpty {
            return leadCard(from: cards, position: position, smart: false)
        }

        return followCard(from: cards, trick: trick, position: position, smart: false)
    }

    private func chooseHardPlayCard(from cards: [Card], position: Position) -> Card {
        guard let trick: Trick = currentTrick else {
            return leadCard(from: cards, position: position, smart: true)
        }

        if trick.plays.isEmpty {
            return leadCard(from: cards, position: position, smart: true)
        }

        return followCard(from: cards, trick: trick, position: position, smart: true)
    }

    private func leadCard(from cards: [Card], position: Position, smart: Bool) -> Card {
        if smart, let trumpSuit: Suit = contract?.bid.denomination.suit {
            let trumpCards: [Card] = cards.filter { $0.suit == trumpSuit }
            if trumpCards.isEmpty == false {
                return trumpCards.sorted { $0.rank > $1.rank }.first!
            }
        }

        let sortedBySuit: [Suit: [Card]] = Dictionary(grouping: cards, by: \.suit)
        if let longestSuitCards: [Card] = sortedBySuit.values.max(by: { $0.count < $1.count }) {
            if smart {
                return longestSuitCards.sorted { $0.rank > $1.rank }.first!
            }
            return longestSuitCards.sorted { $0.rank < $1.rank }.first!
        }

        return cards.first!
    }

    private func followCard(
        from cards: [Card],
        trick: Trick,
        position: Position,
        smart: Bool
    ) -> Card {
        guard let firstPlay: Trick.Play = trick.plays.first,
              let ledCard: Card = cardsMap[firstPlay.cardID]
        else {
            return cards.first!
        }

        let ledSuit: Suit = ledCard.suit
        let suitCards: [Card] = cards.filter { $0.suit == ledSuit }
        let trumpSuit: Suit? = contract?.bid.denomination.suit

        let currentWinnerPriority: Int = trick.plays.map { play in
            guard let card: Card = cardsMap[play.cardID] else { return 0 }
            return cardPriority(card, trumpSuit: trumpSuit, ledSuit: ledSuit)
        }.max() ?? 0

        let partnerIsWinning: Bool = isPartnerWinning(trick: trick, position: position)

        if smart && partnerIsWinning && trick.plays.count == 3 {
            return cards.sorted { $0.rank < $1.rank }.first!
        }

        if suitCards.isEmpty == false {
            let winners: [Card] = suitCards.filter { card in
                cardPriority(card, trumpSuit: trumpSuit, ledSuit: ledSuit) > currentWinnerPriority
            }

            if winners.isEmpty == false {
                if smart {
                    return winners.sorted { $0.rank < $1.rank }.first!
                }
                return winners.sorted { $0.rank > $1.rank }.first!
            }

            return suitCards.sorted { $0.rank < $1.rank }.first!
        }

        if let trump: Suit = trumpSuit {
            let trumpCards: [Card] = cards.filter { $0.suit == trump }
            if trumpCards.isEmpty == false {
                if smart && partnerIsWinning {
                    return cards.filter { $0.suit != trump }
                        .sorted { $0.rank < $1.rank }
                        .first ?? trumpCards.sorted { $0.rank < $1.rank }.first!
                }
                return trumpCards.sorted { $0.rank < $1.rank }.first!
            }
        }

        return cards.sorted { $0.rank < $1.rank }.first!
    }

    private func isPartnerWinning(trick: Trick, position: Position) -> Bool {
        guard trick.plays.isEmpty == false else { return false }
        let trumpSuit: Suit? = contract?.bid.denomination.suit
        guard let firstPlay: Trick.Play = trick.plays.first,
              let ledCard: Card = cardsMap[firstPlay.cardID]
        else { return false }
        let ledSuit: Suit = ledCard.suit

        var winningPlay: Trick.Play = trick.plays[0]
        var winningPriority: Int = cardPriority(
            cardsMap[winningPlay.cardID]!, trumpSuit: trumpSuit, ledSuit: ledSuit
        )

        for play in trick.plays.dropFirst() {
            guard let card: Card = cardsMap[play.cardID] else { continue }
            let priority: Int = cardPriority(card, trumpSuit: trumpSuit, ledSuit: ledSuit)
            if priority > winningPriority {
                winningPlay = play
                winningPriority = priority
            }
        }

        return winningPlay.position.partnership == position.partnership
    }
}
