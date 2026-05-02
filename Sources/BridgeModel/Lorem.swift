import Foundation

public final class Lorem {

    public static var word: String {
        allWords.randomElement()!
    }

    public static func words(_ count: Int) -> String {
        _compose(word, count: count, joinBy: .space)
    }

    public static var sentence: String {
        let numberOfWords: Int = Int.random(in: 4...16)
        return _compose(
            word,
            count: numberOfWords,
            joinBy: .space,
            endWith: .dot,
            decorate: { $0.firstLetterCapitalized }
        )
    }

    public static var firstName: String {
        firstNames.randomElement()!
    }

    public static var lastName: String {
        lastNames.randomElement()!
    }

    public static var fullName: String {
        "\(firstName) \(lastName)"
    }

    // MARK: - Private

    fileprivate enum Separator: String {
        case none = ""
        case space = " "
        case dot = "."
        case newLine = "\n"
    }

    fileprivate static func _compose(
        _ provider: @autoclosure () -> String,
        count: Int,
        joinBy middleSeparator: Separator,
        endWith endSeparator: Separator = .none,
        decorate decorator: ((String) -> String)? = nil
    ) -> String {
        var string: String = ""
        for index in 0..<count {
            string += provider()
            if index < count - 1 {
                string += middleSeparator.rawValue
            } else {
                string += endSeparator.rawValue
            }
        }
        if let decorator {
            string = decorator(string)
        }
        return string
    }

    fileprivate static let allWords: [String] = [
        "alias", "consequatur", "aut", "perferendis", "sit", "voluptatem",
        "accusantium", "doloremque", "aperiam", "eaque", "ipsa", "quae",
        "ab", "illo", "inventore", "veritatis", "et", "quasi", "architecto",
        "beatae", "vitae", "dicta", "sunt", "explicabo", "aspernatur",
        "odit", "fugit", "sed", "quia", "consequuntur", "magni", "dolores",
        "eos", "qui", "ratione", "voluptatem", "sequi", "nesciunt",
    ]

    fileprivate static let firstNames: [String] = [
        "Judith", "Angelo", "Margarita", "Kerry", "Elaine", "Lorenzo",
        "Justice", "Doris", "Raul", "Liliana", "Elise", "Ciaran",
        "Johnny", "Moses", "Davion", "Penny", "Mohammed", "Harvey",
        "Sheryl", "Hudson", "Brendan", "Brooklynn", "Denis", "Sadie",
        "Trisha", "Jacquelyn", "Virgil", "Cindy", "Alexa", "Marianne",
        "Casey", "Angela", "Katherine", "Skyler", "Carly", "Abel",
    ]

    fileprivate static let lastNames: [String] = [
        "Chung", "Chen", "Melton", "Hill", "Puckett", "Song", "Hamilton",
        "Bender", "Wagner", "McLaughlin", "McNamara", "Raynor", "Moon",
        "Woodard", "Desai", "Wallace", "Lawrence", "Griffin", "Dougherty",
        "Powers", "May", "Steele", "Teague", "Vick", "Gallagher",
        "Solomon", "Walsh", "Monroe", "Connolly", "Hawkins", "Middleton",
        "Goldstein", "Watts", "Johnston", "Weeks", "Wilkerson", "Barton",
    ]
}

extension String {
    fileprivate var firstLetterCapitalized: String {
        guard isEmpty == false else { return self }
        return prefix(1).capitalized + dropFirst()
    }
}
