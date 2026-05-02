import Foundation

// MARK: - Bidding Actions

extension Round {
    public mutating func makeCall(_ call: Call) throws {
        guard case .bidding(let turn) = state else {
            throw BridgeError.biddingNotInProgress
        }
        guard let playerHand: PlayerHand = playerHand(at: turn) else {
            throw BridgeError.playerNotFound
        }

        switch call {
        case .pass:
            break

        case .bid(let bid):
            if let lastBid: Bid = lastBid {
                guard bid > lastBid else {
                    throw BridgeError.invalidBid
                }
            }

        case .double:
            guard let lastBidEntry: AuctionEntry = lastBidEntry,
                  lastBidEntry.position.partnership != turn.partnership,
                  lastNonPassCall?.isDouble != true,
                  lastNonPassCall?.isRedouble != true
            else {
                throw BridgeError.cannotDouble
            }

        case .redouble:
            guard let lastBidEntry: AuctionEntry = lastBidEntry,
                  lastBidEntry.position.partnership == turn.partnership,
                  lastNonPassCall?.isDouble == true
            else {
                throw BridgeError.cannotRedouble
            }
        }

        auction.append(.init(position: turn, call: call))

        log.addAction(.init(
            playerID: playerHand.player.id,
            decision: .makeCall(call)
        ))

        if shouldEndAuction {
            if let contract: Contract = resolveContract() {
                self.contract = contract
                let openingLeader: Position = contract.openingLeader
                currentTrick = .init(leader: openingLeader)
                state = .playing(turn: openingLeader)
            } else {
                state = .passedOut
                ended = .init()
            }
        } else {
            state = .bidding(turn: turn.next)
        }
    }

    private var shouldEndAuction: Bool {
        guard auction.count >= 4 else { return false }
        let lastThree: ArraySlice<AuctionEntry> = auction.suffix(3)
        return lastThree.allSatisfy { $0.call == .pass }
    }

    var lastBid: Bid? {
        for entry in auction.reversed() {
            if case .bid(let bid) = entry.call {
                return bid
            }
        }
        return nil
    }

    var lastBidEntry: AuctionEntry? {
        for entry in auction.reversed() {
            if case .bid = entry.call {
                return entry
            }
        }
        return nil
    }

    var lastNonPassCall: Call? {
        for entry in auction.reversed() {
            if entry.call != .pass {
                return entry.call
            }
        }
        return nil
    }

    private func resolveContract() -> Contract? {
        guard let lastBidEntry: AuctionEntry = lastBidEntry else {
            return nil
        }
        guard case .bid(let winningBid) = lastBidEntry.call else {
            return nil
        }

        let declarerPartnership: Partnership = lastBidEntry.position.partnership
        var declarer: Position = lastBidEntry.position

        for entry in auction {
            if entry.position.partnership == declarerPartnership,
               case .bid(let bid) = entry.call,
               bid.denomination == winningBid.denomination {
                declarer = entry.position
                break
            }
        }

        var isDoubled: Bool = false
        var isRedoubled: Bool = false
        for entry in auction.reversed() {
            switch entry.call {
            case .pass:
                continue
            case .bid:
                break
            case .double:
                isDoubled = true
            case .redouble:
                isRedoubled = true
                isDoubled = false
            }
            if case .bid = entry.call { break }
            if entry.call == .double || entry.call == .redouble { break }
        }

        if isRedoubled { isDoubled = false }

        return .init(
            bid: winningBid,
            declarer: declarer,
            isDoubled: isDoubled,
            isRedoubled: isRedoubled
        )
    }
}

// MARK: - Play Actions

extension Round {
    public mutating func playCard(_ cardID: CardID) throws {
        guard case .playing(let turn) = state else {
            throw BridgeError.playingNotInProgress
        }
        guard var trick: Trick = currentTrick else {
            throw BridgeError.playingNotInProgress
        }
        guard let handIndex: Int = playerHandIndex(for: turn) else {
            throw BridgeError.playerNotFound
        }
        guard playerHands[handIndex].cards.contains(cardID) else {
            throw BridgeError.cardNotInHand
        }
        guard let card: Card = cardsMap[cardID] else {
            throw BridgeError.cardNotInHand
        }

        if let firstPlay: Trick.Play = trick.plays.first,
           let ledCard: Card = cardsMap[firstPlay.cardID] {
            let ledSuit: Suit = ledCard.suit
            let hasSuit: Bool = playerHands[handIndex].cards.contains { id in
                cardsMap[id]?.suit == ledSuit
            }
            if hasSuit && card.suit != ledSuit {
                throw BridgeError.mustFollowSuit
            }
        }

        playerHands[handIndex].cards.removeAll { $0 == cardID }
        trick.plays.append(.init(position: turn, cardID: cardID))

        let controllingPlayerID: PlayerID = self.controllingPlayerID(for: turn)

        log.addAction(.init(
            playerID: controllingPlayerID,
            decision: .playCard(cardId: cardID)
        ))

        if trick.isComplete {
            let winner: Position = determineTrickWinner(trick)
            trick.winner = winner
            tricks.append(trick)
            currentTrick = nil

            if tricks.count == Self.cardsPerPlayer {
                calculateScore()
                state = .complete
                ended = .init()
            } else {
                currentTrick = .init(leader: winner)
                state = .playing(turn: winner)
            }
        } else {
            currentTrick = trick
            state = .playing(turn: turn.next)
        }
    }

    func determineTrickWinner(_ trick: Trick) -> Position {
        let trumpSuit: Suit? = contract?.bid.denomination.suit
        guard let firstPlay: Trick.Play = trick.plays.first,
              let ledCard: Card = cardsMap[firstPlay.cardID]
        else {
            return trick.leader
        }
        let ledSuit: Suit = ledCard.suit

        var winningPlay: Trick.Play = firstPlay
        var winningPriority: Int = cardPriority(ledCard, trumpSuit: trumpSuit, ledSuit: ledSuit)

        for play in trick.plays.dropFirst() {
            guard let card: Card = cardsMap[play.cardID] else { continue }
            let priority: Int = cardPriority(card, trumpSuit: trumpSuit, ledSuit: ledSuit)
            if priority > winningPriority {
                winningPlay = play
                winningPriority = priority
            }
        }

        return winningPlay.position
    }

    func cardPriority(_ card: Card, trumpSuit: Suit?, ledSuit: Suit) -> Int {
        if let trump: Suit = trumpSuit, card.suit == trump {
            return 1000 + card.rank.rawValue
        }
        if card.suit == ledSuit {
            return 500 + card.rank.rawValue
        }
        return card.rank.rawValue
    }

    private func controllingPlayerID(for position: Position) -> PlayerID {
        if let contract, position == contract.dummy {
            return playerHand(at: contract.declarer)?.player.id ?? ""
        }
        return playerHand(at: position)?.player.id ?? ""
    }
}

// MARK: - Call Helpers

extension Call {
    var isDouble: Bool {
        if case .double = self { return true }
        return false
    }

    var isRedouble: Bool {
        if case .redouble = self { return true }
        return false
    }
}
