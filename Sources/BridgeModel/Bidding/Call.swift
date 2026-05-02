import Foundation

public enum Call: Equatable, Codable, Sendable {
    case pass
    case bid(Bid)
    case double
    case redouble

    public var displayableName: String {
        switch self {
        case .pass: "Pass"
        case .bid(let bid): bid.displayableName
        case .double: "Double"
        case .redouble: "Redouble"
        }
    }
}
