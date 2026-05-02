import Foundation

public struct Round: Equatable, Codable, Sendable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date
    public let ruleOptions: RuleOptions
    public let dealer: Position
    public internal(set) var vulnerability: Vulnerability

    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var cardsMap: [CardID: Card]
    public internal(set) var playerHands: [PlayerHand]
    public internal(set) var auction: [AuctionEntry]
    public internal(set) var contract: Contract?
    public internal(set) var tricks: [Trick]
    public internal(set) var currentTrick: Trick?

    // MARK: - Results
    public internal(set) var result: RoundResult?
    public internal(set) var log: Log = .init()
    public internal(set) var ended: Date?

    public struct AuctionEntry: Equatable, Codable, Sendable {
        public let position: Position
        public let call: Call

        public init(position: Position, call: Call) {
            self.position = position
            self.call = call
        }
    }

    public struct RoundResult: Equatable, Codable, Sendable {
        public let contract: Contract
        public let declarerTricksWon: Int
        public let defenderTricksWon: Int
        public let made: Bool
        public let declarerScore: Int
        public let defenderScore: Int

        public init(
            contract: Contract,
            declarerTricksWon: Int,
            defenderTricksWon: Int,
            made: Bool,
            declarerScore: Int,
            defenderScore: Int
        ) {
            self.contract = contract
            self.declarerTricksWon = declarerTricksWon
            self.defenderTricksWon = defenderTricksWon
            self.made = made
            self.declarerScore = declarerScore
            self.defenderScore = defenderScore
        }
    }

    public enum State: Equatable, Codable, Sendable {
        case bidding(turn: Position)
        case playing(turn: Position)
        case passedOut
        case complete

        public var logValue: String {
            switch self {
            case .bidding(let turn):
                "Bidding — \(turn.displayableName) to call"
            case .playing(let turn):
                "Playing — \(turn.displayableName) to play"
            case .passedOut:
                "Passed out"
            case .complete:
                "Complete"
            }
        }
    }
}
