import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = Lorem.fullName,
        imageURL: URL? = .randomImageURL,
        points: Int = 0
    ) -> Player {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            points: points
        )
    }
}
