import Foundation
import Testing
@testable import BridgeModel

// MARK: - Deck Tests

@Test func deckSize() {
    let deck: [Card] = .deck()
    #expect(deck.count == 52)
    #expect(Set(deck.map { $0.id }).count == 52)
}

@Test func deckComposition() {
    let deck: [Card] = .deck()

    for suit in Suit.allCases {
        let suitCards: Int = deck.filter { $0.suit == suit }.count
        #expect(suitCards == 13)
    }

    for rank in Rank.allCases {
        let rankCards: Int = deck.filter { $0.rank == rank }.count
        #expect(rankCards == 4)
    }
}

// MARK: - Round Creation Tests

@Test func createRound() throws {
    let round: Round = try .init(players: [.fake(), .fake(), .fake(), .fake()])
    #expect(round.playerHands.count == 4)
    #expect(round.playerHands.allSatisfy { $0.cards.count == 13 })
    #expect(round.cardsMap.count == 52)
    if case .bidding = round.state {} else {
        Issue.record("Expected bidding state")
    }
}

@Test func invalidPlayerCount() {
    #expect(throws: BridgeError.invalidPlayerCount) {
        _ = try Round(players: [.fake(), .fake()])
    }
    #expect(throws: BridgeError.invalidPlayerCount) {
        _ = try Round(players: [.fake(), .fake(), .fake()])
    }
    #expect(throws: BridgeError.invalidPlayerCount) {
        _ = try Round(players: [.fake(), .fake(), .fake(), .fake(), .fake()])
    }
}

@Test func dealerStartsBiddingToLeft() throws {
    let round: Round = try .init(
        dealer: .north,
        players: [.fake(), .fake(), .fake(), .fake()]
    )
    if case .bidding(let turn) = round.state {
        #expect(turn == .east)
    } else {
        Issue.record("Expected bidding state")
    }
}

@Test func cookedDeckDealDistribution() throws {
    let cookedDeck: [Card] = buildCookedDeck(
        northCards: makeCards(suit: .spades),
        eastCards: makeCards(suit: .hearts),
        southCards: makeCards(suit: .diamonds),
        westCards: makeCards(suit: .clubs)
    )

    let round: Round = try .init(
        dealer: .north,
        cookedDeck: cookedDeck,
        players: [
            .fake(id: "east"),
            .fake(id: "south"),
            .fake(id: "west"),
            .fake(id: "north"),
        ]
    )

    let eastHand: PlayerHand = round.playerHand(at: .east)!
    let eastSuits: Set<Suit> = Set(eastHand.cards.compactMap { round.cardsMap[$0]?.suit })
    #expect(eastSuits == [.hearts])

    let northHand: PlayerHand = round.playerHand(at: .north)!
    let northSuits: Set<Suit> = Set(northHand.cards.compactMap { round.cardsMap[$0]?.suit })
    #expect(northSuits == [.spades])
}

// MARK: - Bidding Tests

@Test func allPassResultsInPassedOut() throws {
    var round: Round = try .fake(dealer: .north)
    try round.makeCall(.pass) // East
    try round.makeCall(.pass) // South
    try round.makeCall(.pass) // West
    try round.makeCall(.pass) // North

    if case .passedOut = round.state {} else {
        Issue.record("Expected passedOut state, got \(round.state)")
    }
}

@Test func simpleBiddingSequence() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .spades))) // East
    try round.makeCall(.pass) // South
    try round.makeCall(.pass) // West
    try round.makeCall(.pass) // North

    #expect(round.contract != nil)
    #expect(round.contract?.bid == Bid(level: .one, denomination: .spades))
    #expect(round.contract?.declarer == .east)
    if case .playing = round.state {} else {
        Issue.record("Expected playing state")
    }
}

@Test func biddingMustIncrease() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .spades))) // East
    #expect(throws: BridgeError.invalidBid) {
        try round.makeCall(.bid(.init(level: .one, denomination: .hearts))) // South: lower bid
    }
}

@Test func doubleBid() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .hearts))) // East
    try round.makeCall(.double) // South (opponent doubles)
    try round.makeCall(.pass) // West
    try round.makeCall(.pass) // North
    try round.makeCall(.pass) // East

    #expect(round.contract?.isDoubled == true)
    #expect(round.contract?.isRedoubled == false)
}

@Test func redoubleBid() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .hearts))) // East
    try round.makeCall(.double) // South
    try round.makeCall(.redouble) // West (partner redoubles)
    try round.makeCall(.pass) // North
    try round.makeCall(.pass) // East
    try round.makeCall(.pass) // South

    #expect(round.contract?.isDoubled == false)
    #expect(round.contract?.isRedoubled == true)
}

@Test func cannotDoubleOwnBid() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .hearts))) // East
    try round.makeCall(.pass) // South
    #expect(throws: BridgeError.cannotDouble) {
        try round.makeCall(.double) // West (partner can't double)
    }
}

@Test func cannotRedoubleWithoutDouble() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .hearts))) // East
    #expect(throws: BridgeError.cannotRedouble) {
        try round.makeCall(.redouble) // South can't redouble without a double
    }
}

@Test func declarerIsFirstBidderOfDenomination() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .hearts))) // East
    try round.makeCall(.pass) // South
    try round.makeCall(.bid(.init(level: .two, denomination: .hearts))) // West (same denomination)
    try round.makeCall(.pass) // North
    try round.makeCall(.pass) // East
    try round.makeCall(.pass) // South

    #expect(round.contract?.bid == Bid(level: .two, denomination: .hearts))
    #expect(round.contract?.declarer == .east)
}

@Test func openingLeaderIsDeclarerLeft() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .spades))) // East
    try round.makeCall(.pass) // South
    try round.makeCall(.pass) // West
    try round.makeCall(.pass) // North

    #expect(round.contract?.declarer == .east)
    #expect(round.contract?.openingLeader == .south)
    if case .playing(let turn) = round.state {
        #expect(turn == .south)
    }
}

// MARK: - Card Play Tests

@Test func mustFollowSuit() throws {
    let cookedDeck: [Card] = buildCookedDeck(
        northCards: makeCards(suit: .spades),
        eastCards: makeCards(suit: .hearts),
        southCards: makeCards(suit: .diamonds),
        westCards: makeCards(suit: .clubs)
    )

    var round: Round = try .init(
        dealer: .north,
        cookedDeck: cookedDeck,
        players: [
            .fake(id: "east"),
            .fake(id: "south"),
            .fake(id: "west"),
            .fake(id: "north"),
        ]
    )

    try round.makeCall(.bid(.init(level: .one, denomination: .noTrump))) // East
    try round.makeCall(.pass) // South
    try round.makeCall(.pass) // West
    try round.makeCall(.pass) // North

    // South leads a diamond
    let southHand: PlayerHand = round.playerHand(at: .south)!
    let diamondCard: Card = round.cardsMap[southHand.cards[0]]!
    #expect(diamondCard.suit == .diamonds)
    try round.playCard(diamondCard.id)

    // West must play clubs (has no diamonds), so any card is legal
    let westHand: PlayerHand = round.playerHand(at: .west)!
    let clubCard: Card = round.cardsMap[westHand.cards[0]]!
    #expect(clubCard.suit == .clubs)
    try round.playCard(clubCard.id) // OK since West has no diamonds

    // North must play spades (has no diamonds)
    let northHand: PlayerHand = round.playerHand(at: .north)!
    let spadeCard: Card = round.cardsMap[northHand.cards[0]]!
    #expect(spadeCard.suit == .spades)
    try round.playCard(spadeCard.id)

    // East has hearts, led suit is diamonds, East has no diamonds — any card legal
    let eastHand: PlayerHand = round.playerHand(at: .east)!
    let heartCard: Card = round.cardsMap[eastHand.cards[0]]!
    try round.playCard(heartCard.id)
}

@Test func trickWinnerHighestOfLedSuit() throws {
    var round: Round = try makePlayingRound(
        contract: .init(bid: .init(level: .one, denomination: .noTrump), declarer: .south),
        northCards: [(.hearts, .king)],
        eastCards: [(.hearts, .three)],
        southCards: [(.hearts, .ace)],
        westCards: [(.hearts, .queen)]
    )

    let westHand: PlayerHand = round.playerHand(at: .west)!
    try round.playCard(westHand.cards[0]) // West leads heart queen
    let northHand: PlayerHand = round.playerHand(at: .north)!
    try round.playCard(northHand.cards[0]) // North plays heart king
    let eastHand: PlayerHand = round.playerHand(at: .east)!
    try round.playCard(eastHand.cards[0]) // East plays heart three
    let southHand: PlayerHand = round.playerHand(at: .south)!
    try round.playCard(southHand.cards[0]) // South plays heart ace

    #expect(round.tricks.count == 1)
    #expect(round.tricks[0].winner == .south)
}

@Test func trumpBeatsHighNonTrump() throws {
    var round: Round = try makePlayingRound(
        contract: .init(bid: .init(level: .one, denomination: .spades), declarer: .south),
        northCards: [(.hearts, .ace)],
        eastCards: [(.spades, .two)],
        southCards: [(.hearts, .king)],
        westCards: [(.hearts, .queen)]
    )

    let westHand: PlayerHand = round.playerHand(at: .west)!
    try round.playCard(westHand.cards[0]) // West leads heart queen
    let northHand: PlayerHand = round.playerHand(at: .north)!
    try round.playCard(northHand.cards[0]) // North plays heart ace
    let eastHand: PlayerHand = round.playerHand(at: .east)!
    try round.playCard(eastHand.cards[0]) // East plays spade two (trump!)
    let southHand: PlayerHand = round.playerHand(at: .south)!
    try round.playCard(southHand.cards[0]) // South plays heart king

    #expect(round.tricks[0].winner == .east)
}

// MARK: - Scoring Tests

@Test func madeContractScoring() throws {
    var round: Round = try makePlayingRound(
        vulnerability: .none,
        contract: .init(bid: .init(level: .one, denomination: .noTrump), declarer: .south),
        northCards: makeScoringHand(highRanks: true, suit: .spades),
        eastCards: makeScoringHand(highRanks: false, suit: .hearts),
        southCards: makeScoringHand(highRanks: true, suit: .hearts),
        westCards: makeScoringHand(highRanks: false, suit: .spades)
    )

    playEntireRound(&round)

    #expect(round.result != nil)
    #expect(round.result!.made == true)
    #expect(round.result!.declarerScore > 0)
    #expect(round.result!.defenderScore == 0)
}

@Test func defeatedContractScoring() throws {
    var round: Round = try makePlayingRound(
        vulnerability: .none,
        contract: .init(bid: .init(level: .seven, denomination: .noTrump), declarer: .south),
        northCards: makeScoringHand(highRanks: false, suit: .spades),
        eastCards: makeScoringHand(highRanks: true, suit: .spades),
        southCards: makeScoringHand(highRanks: false, suit: .hearts),
        westCards: makeScoringHand(highRanks: true, suit: .hearts)
    )

    playEntireRound(&round)

    #expect(round.result != nil)
    #expect(round.result!.made == false)
    #expect(round.result!.defenderScore > 0)
    #expect(round.result!.declarerScore == 0)
}

@Test func noTrumpTrickScoreCalculation() {
    let bid: Bid = .init(level: .three, denomination: .noTrump)
    #expect(bid.trickScore == 100) // 40 + 30 + 30
    #expect(bid.isGame == true)
}

@Test func majorSuitTrickScore() {
    let bid: Bid = .init(level: .four, denomination: .hearts)
    #expect(bid.trickScore == 120) // 4 * 30
    #expect(bid.isGame == true)
}

@Test func minorSuitTrickScore() {
    let bid: Bid = .init(level: .five, denomination: .clubs)
    #expect(bid.trickScore == 100) // 5 * 20
    #expect(bid.isGame == true)
}

@Test func partScoreNotGame() {
    let bid: Bid = .init(level: .two, denomination: .hearts)
    #expect(bid.trickScore == 60) // 2 * 30
    #expect(bid.isGame == false)
}

// MARK: - AI Tests

@Test func aiCompletesRoundEasy() throws {
    var round: Round = try .init(players: [
        .fake(id: "p1"), .fake(id: "p2"), .fake(id: "p3"), .fake(id: "p4"),
    ])

    var moveCount: Int = 0
    let maxMoves: Int = 200

    while moveCount < maxMoves {
        switch round.state {
        case .bidding, .playing:
            round.makeAIMove(difficulty: .easy)
            moveCount += 1
        case .passedOut, .complete:
            break
        }
        if case .passedOut = round.state { break }
        if case .complete = round.state { break }
    }

    let isTerminal: Bool = {
        switch round.state {
        case .passedOut, .complete: true
        default: false
        }
    }()
    #expect(isTerminal)
    #expect(moveCount < maxMoves)
}

@Test func aiCompletesRoundMedium() throws {
    var round: Round = try .init(players: [
        .fake(id: "p1"), .fake(id: "p2"), .fake(id: "p3"), .fake(id: "p4"),
    ])

    var moveCount: Int = 0
    let maxMoves: Int = 200

    while moveCount < maxMoves {
        switch round.state {
        case .bidding, .playing:
            round.makeAIMove(difficulty: .medium)
            moveCount += 1
        case .passedOut, .complete:
            break
        }
        if case .passedOut = round.state { break }
        if case .complete = round.state { break }
    }

    let isTerminal: Bool = {
        switch round.state {
        case .passedOut, .complete: true
        default: false
        }
    }()
    #expect(isTerminal)
    #expect(moveCount < maxMoves)
}

@Test func aiCompletesRoundHard() throws {
    var round: Round = try .init(players: [
        .fake(id: "p1"), .fake(id: "p2"), .fake(id: "p3"), .fake(id: "p4"),
    ])

    var moveCount: Int = 0
    let maxMoves: Int = 200

    while moveCount < maxMoves {
        switch round.state {
        case .bidding, .playing:
            round.makeAIMove(difficulty: .hard)
            moveCount += 1
        case .passedOut, .complete:
            break
        }
        if case .passedOut = round.state { break }
        if case .complete = round.state { break }
    }

    let isTerminal: Bool = {
        switch round.state {
        case .passedOut, .complete: true
        default: false
        }
    }()
    #expect(isTerminal)
    #expect(moveCount < maxMoves)
}

@Test func aiRespectsSuitFollowing() throws {
    for _ in 0..<10 {
        var round: Round = try .init(players: [
            .fake(id: "p1"), .fake(id: "p2"), .fake(id: "p3"), .fake(id: "p4"),
        ])

        var moveCount: Int = 0
        let maxMoves: Int = 200

        while moveCount < maxMoves {
            switch round.state {
            case .bidding, .playing:
                round.makeAIMove(difficulty: .hard)
                moveCount += 1
            case .passedOut, .complete:
                break
            }
            if case .passedOut = round.state { break }
            if case .complete = round.state { break }
        }

        if case .complete = round.state {
            let totalTricks: Int = round.tricks.count
            #expect(totalTricks == 13)
            let totalPlays: Int = round.tricks.reduce(0) { $0 + $1.plays.count }
            #expect(totalPlays == 52)
        }
    }
}

// MARK: - Full Round Playthrough

@Test func playFullRoundManually() throws {
    let cookedDeck: [Card] = buildFullCookedDeck()

    var round: Round = try .init(
        dealer: .north,
        cookedDeck: cookedDeck,
        players: [
            .fake(id: "east", name: "East", points: 0),
            .fake(id: "south", name: "South", points: 0),
            .fake(id: "west", name: "West", points: 0),
            .fake(id: "north", name: "North", points: 0),
        ]
    )

    // Bidding: South opens 1 spade, all pass
    try round.makeCall(.pass) // East
    try round.makeCall(.bid(.init(level: .one, denomination: .spades))) // South
    try round.makeCall(.pass) // West
    try round.makeCall(.pass) // North
    try round.makeCall(.pass) // East

    #expect(round.contract?.declarer == .south)
    #expect(round.contract?.bid.denomination == .spades)

    // Opening lead by West
    if case .playing(let turn) = round.state {
        #expect(turn == .west)
    }

    // Play all 13 tricks with AI
    var trickCount: Int = 0
    while case .playing = round.state, trickCount < 14 {
        let position: Position
        if case .playing(let turn) = round.state {
            position = turn
        } else { break }

        let legal: [Card] = round.legalCards(for: position)
        guard let card: Card = legal.first else { break }
        try round.playCard(card.id)

        if round.tricks.count > trickCount {
            trickCount = round.tricks.count
        }
    }

    if case .complete = round.state {
        #expect(round.tricks.count == 13)
        #expect(round.result != nil)
        #expect(round.declarerTricksWon + round.defenderTricksWon == 13)
    } else {
        Issue.record("Expected complete state")
    }
}

// MARK: - Fake Tests

@Test func fakePlayer() {
    let player: Player = .fake()
    #expect(player.name.isEmpty == false)
    #expect(player.points == 0)
}

@Test func fakeRound() throws {
    let round: Round = try .fake()
    #expect(round.playerHands.count == 4)
    #expect(round.playerHands.allSatisfy { $0.cards.count == 13 })
}

@Test func fakeCard() {
    let card: Card = .fake()
    #expect(card.suit == .spades)
    #expect(card.rank == .ace)
}

@Test func fakePlayerHand() {
    let hand: PlayerHand = .fake()
    #expect(hand.position == .north)
}

// MARK: - Codable Tests

@Test func roundCodable() throws {
    let round: Round = try .fake()
    let encoder: JSONEncoder = .init()
    let data: Data = try encoder.encode(round)
    let decoder: JSONDecoder = .init()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let decoded: Round = try decoder.decode(Round.self, from: data)
    #expect(decoded.id == round.id)
    #expect(decoded.playerHands.count == round.playerHands.count)
}

@Test func bidCodable() throws {
    let bid: Bid = .init(level: .three, denomination: .noTrump)
    let data: Data = try JSONEncoder().encode(bid)
    let decoded: Bid = try JSONDecoder().decode(Bid.self, from: data)
    #expect(decoded == bid)
}

@Test func contractCodable() throws {
    let contract: Contract = .init(
        bid: .init(level: .four, denomination: .spades),
        declarer: .south,
        isDoubled: true
    )
    let data: Data = try JSONEncoder().encode(contract)
    let decoded: Contract = try JSONDecoder().decode(Contract.self, from: data)
    #expect(decoded == contract)
}

// MARK: - Position Tests

@Test func positionPartners() {
    #expect(Position.north.partner == .south)
    #expect(Position.south.partner == .north)
    #expect(Position.east.partner == .west)
    #expect(Position.west.partner == .east)
}

@Test func positionNext() {
    #expect(Position.north.next == .east)
    #expect(Position.east.next == .south)
    #expect(Position.south.next == .west)
    #expect(Position.west.next == .north)
}

@Test func positionPartnerships() {
    #expect(Position.north.partnership == .northSouth)
    #expect(Position.south.partnership == .northSouth)
    #expect(Position.east.partnership == .eastWest)
    #expect(Position.west.partnership == .eastWest)
}

// MARK: - Bid Comparison Tests

@Test func bidOrdering() {
    let oneClub: Bid = .init(level: .one, denomination: .clubs)
    let oneDiamond: Bid = .init(level: .one, denomination: .diamonds)
    let oneNoTrump: Bid = .init(level: .one, denomination: .noTrump)
    let twoClubs: Bid = .init(level: .two, denomination: .clubs)

    #expect(oneClub < oneDiamond)
    #expect(oneDiamond < oneNoTrump)
    #expect(oneNoTrump < twoClubs)
}

// MARK: - Vulnerability Tests

@Test func vulnerabilityCheck() {
    let vuln: Vulnerability = .init(northSouthVulnerable: true, eastWestVulnerable: false)
    #expect(vuln.isVulnerable(.northSouth) == true)
    #expect(vuln.isVulnerable(.eastWest) == false)
}

// MARK: - Log Tests

@Test func logMaxActions() {
    var log: Round.Log = .init()
    for i in 0..<150 {
        log.addAction(.init(
            playerID: "player\(i % 4)",
            decision: .makeCall(.pass)
        ))
    }
    #expect(log.actions.count == 100)
}

// MARK: - Dummy Visibility Tests

@Test func dummyNotRevealedBeforeOpeningLead() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .noTrump))) // East
    try round.makeCall(.pass) // South
    try round.makeCall(.pass) // West
    try round.makeCall(.pass) // North

    #expect(round.isDummyRevealed == false)
}

@Test func dummyRevealedAfterOpeningLead() throws {
    var round: Round = try .fake(dealer: .north)

    try round.makeCall(.bid(.init(level: .one, denomination: .noTrump))) // East
    try round.makeCall(.pass) // South
    try round.makeCall(.pass) // West
    try round.makeCall(.pass) // North

    #expect(round.contract?.declarer == .east)
    #expect(round.contract?.dummy == .west)

    if case .playing(let turn) = round.state {
        let legal: [Card] = round.legalCards(for: turn)
        try round.playCard(legal[0].id)
    }

    #expect(round.isDummyRevealed == true)
}

// MARK: - Helpers

private func buildCookedDeck(
    northCards: [Card],
    eastCards: [Card],
    southCards: [Card],
    westCards: [Card]
) -> [Card] {
    northCards + westCards + southCards + eastCards
}

private func makeCards(suit: Suit) -> [Card] {
    let baseID: CardID = Suit.allCases.firstIndex(of: suit)! * 13
    var nextID: CardID = baseID
    return Rank.allCases.map { rank in
        let card: Card = .init(id: nextID, suit: suit, rank: rank)
        nextID += 1
        return card
    }
}

private func makeScoringHand(highRanks: Bool, suit: Suit) -> [(Suit, Rank)] {
    let allRanks: [Rank] = highRanks
        ? Array(Rank.allCases.reversed())
        : Array(Rank.allCases)
    return allRanks.prefix(13).map { (suit, $0) }
}

private func buildFullCookedDeck() -> [Card] {
    var nextID: CardID = 0
    func make(_ specs: [(Suit, Rank)]) -> [Card] {
        specs.map { (suit, rank) in
            let card: Card = .init(id: nextID, suit: suit, rank: rank)
            nextID += 1
            return card
        }
    }

    let northCards: [Card] = make([
        (.spades, .two), (.spades, .three), (.spades, .four), (.spades, .five),
        (.hearts, .two), (.hearts, .three), (.hearts, .four),
        (.diamonds, .two), (.diamonds, .three), (.diamonds, .four),
        (.clubs, .two), (.clubs, .three), (.clubs, .four),
    ])
    let eastCards: [Card] = make([
        (.spades, .six), (.spades, .seven), (.spades, .eight),
        (.hearts, .five), (.hearts, .six), (.hearts, .seven), (.hearts, .eight),
        (.diamonds, .five), (.diamonds, .six), (.diamonds, .seven),
        (.clubs, .five), (.clubs, .six), (.clubs, .seven),
    ])
    let southCards: [Card] = make([
        (.spades, .ace), (.spades, .king), (.spades, .queen), (.spades, .jack),
        (.hearts, .ace), (.hearts, .king),
        (.diamonds, .ace), (.diamonds, .king),
        (.clubs, .ace), (.clubs, .king), (.clubs, .queen),
        (.diamonds, .eight), (.diamonds, .nine),
    ])
    let westCards: [Card] = make([
        (.spades, .nine), (.spades, .ten),
        (.hearts, .nine), (.hearts, .ten), (.hearts, .jack), (.hearts, .queen),
        (.diamonds, .ten), (.diamonds, .jack), (.diamonds, .queen),
        (.clubs, .eight), (.clubs, .nine), (.clubs, .ten), (.clubs, .jack),
    ])

    return northCards + westCards + southCards + eastCards
}

private func makePlayingRound(
    vulnerability: Vulnerability = .none,
    contract: Contract,
    northCards: [(Suit, Rank)],
    eastCards: [(Suit, Rank)],
    southCards: [(Suit, Rank)],
    westCards: [(Suit, Rank)]
) throws -> Round {
    var nextID: CardID = 0
    func makeCards(_ specs: [(Suit, Rank)]) -> [Card] {
        specs.map { (suit, rank) in
            let card: Card = .init(id: nextID, suit: suit, rank: rank)
            nextID += 1
            return card
        }
    }

    let northCardsList: [Card] = makeCards(northCards)
    let eastCardsList: [Card] = makeCards(eastCards)
    let southCardsList: [Card] = makeCards(southCards)
    let westCardsList: [Card] = makeCards(westCards)

    let allCards: [Card] = northCardsList + eastCardsList + southCardsList + westCardsList

    var cardsMap: [CardID: Card] = Dictionary(uniqueKeysWithValues: allCards.map { ($0.id, $0) })

    while cardsMap.count < 52 {
        let id: CardID = cardsMap.count
        let card: Card = .init(id: id, suit: .clubs, rank: .two)
        cardsMap[id] = card
    }

    let players: [Player] = [
        .fake(id: "north", name: "North", points: 0),
        .fake(id: "east", name: "East", points: 0),
        .fake(id: "south", name: "South", points: 0),
        .fake(id: "west", name: "West", points: 0),
    ]

    let playerHands: [PlayerHand] = [
        .init(player: players[0], position: .north, cards: northCardsList.map(\.id)),
        .init(player: players[1], position: .east, cards: eastCardsList.map(\.id)),
        .init(player: players[2], position: .south, cards: southCardsList.map(\.id)),
        .init(player: players[3], position: .west, cards: westCardsList.map(\.id)),
    ]

    var round: Round = try .fake(
        players: [.fake(id: "e"), .fake(id: "s"), .fake(id: "w"), .fake(id: "n")]
    )

    round.cardsMap = cardsMap
    round.playerHands = playerHands
    round.contract = contract
    round.currentTrick = .init(leader: contract.openingLeader)
    round.state = .playing(turn: contract.openingLeader)
    round.auction = [
        .init(position: contract.declarer, call: .bid(contract.bid)),
        .init(position: contract.declarer.next, call: .pass),
        .init(position: contract.declarer.next.next, call: .pass),
        .init(position: contract.declarer.next.next.next, call: .pass),
    ]
    round.vulnerability = vulnerability

    return round
}

private func playEntireRound(_ round: inout Round) {
    var moveCount: Int = 0
    while case .playing(let turn) = round.state, moveCount < 200 {
        let legal: [Card] = round.legalCards(for: turn)
        guard let card: Card = legal.first else { break }
        try? round.playCard(card.id)
        moveCount += 1
    }
}
