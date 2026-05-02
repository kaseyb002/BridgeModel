import Foundation

public typealias PlayerID = String

public struct Player: Equatable, Codable, Sendable, Identifiable {
    public let id: PlayerID
    public var name: String
    public var imageURL: URL?
    public var points: Int

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case points
    }

    public init(
        id: PlayerID,
        name: String,
        imageURL: URL?,
        points: Int
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.points = points
    }
}
