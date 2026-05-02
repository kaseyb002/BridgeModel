import Foundation

extension URL {
    public static var randomImageURL: URL {
        URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/512/512")!
    }

    public static var fakeImageURL: URL {
        URL(string: "https://picsum.photos/id/237/512/512")!
    }
}
