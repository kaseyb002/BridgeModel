import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .init(),
        ruleOptions: RuleOptions = .standard,
        dealer: Position = .north,
        vulnerability: Vulnerability = .none,
        cookedDeck: [Card]? = nil,
        players: [Player] = [
            .fake(),
            .fake(),
            .fake(),
            .fake(),
        ]
    ) throws -> Round {
        try self.init(
            id: id,
            started: started,
            ruleOptions: ruleOptions,
            dealer: dealer,
            vulnerability: vulnerability,
            cookedDeck: cookedDeck,
            players: players
        )
    }
}
