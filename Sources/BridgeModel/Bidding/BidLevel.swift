import Foundation

public enum BidLevel: Int, Equatable, Comparable, CaseIterable, Codable, Sendable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7

    public static func < (lhs: BidLevel, rhs: BidLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var displayableName: String {
        "\(rawValue)"
    }
}
