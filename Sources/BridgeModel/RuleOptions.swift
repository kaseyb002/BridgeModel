import Foundation

public struct RuleOptions: Equatable, Codable, Sendable {
    public var honorsScoring: Bool

    public init(honorsScoring: Bool = true) {
        self.honorsScoring = honorsScoring
    }

    public static let standard: RuleOptions = .init()
}
