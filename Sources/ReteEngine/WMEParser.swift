import Foundation

/// Parses working memory entries of the format:
///
/// ` a b c .`
///
public final class WMEParser<WME>
    where WME: ReteEngine.WME
{
    public struct Error: LocalizedError {
        let description: String
        let position: Int

        fileprivate init(description: String, position: Int) {
            self.description = description
            self.position = position
        }

        public var errorDescription: String? {
            return description
        }
    }

    public private(set) var input: AnyIterator<Unicode.Scalar>
    public let constantCharacterSet: CharacterSet
    public let makeConstant: (String) -> WME.Constant
    private var character: Unicode.Scalar?
    public private(set) var position = 0

    public init<Iterator>(
        input: Iterator,
        constantCharacterSet: CharacterSet = CharacterSet.whitespacesAndNewlines.inverted,
        makeConstant: @escaping (String) -> WME.Constant
    ) throws
        where Iterator: IteratorProtocol,
            Iterator.Element == Unicode.Scalar
    {
        self.input = AnyIterator(input)
        self.constantCharacterSet = constantCharacterSet
        self.makeConstant = makeConstant
        readCharacter()
    }

    private func readCharacter() {
        character = input.next()
        position += 1
    }

    public func parse() throws -> WME? {
        try skipWhitespaceAndNewlines()
        if character == nil {
            return nil
        }

        let identifier = try readConstant()
        try skipWhitespaceAndNewlines()

        let attribute = try readConstant()
        try skipWhitespaceAndNewlines()

        let value = try readConstant()
        try skipWhitespaceAndNewlines(
            to: ["."],
            description: "separator"
        )
        readCharacter()

        return WME(identifier: identifier, attribute: attribute, value: value)
    }

    private func readConstant() throws -> WME.Constant {
        try skipWhitespaceAndNewlines()
        let constantString = try readOneOrMore(constantCharacterSet, description: "constant")
        return makeConstant(constantString)
    }

    private func readZeroOrMore(_ characterSet: CharacterSet) -> String {
        var result = ""
        while let character = self.character {
            guard characterSet.contains(character) else {
                break
            }
            result.append(String(character))
            readCharacter()
        }
        return result
    }

    private func readOneOrMore(_ characterSet: CharacterSet, description: String) throws -> String {
        let string = readZeroOrMore(characterSet)
        guard !string.isEmpty else {
            throw Error(
                description: "expected \(description) (\(characterSet))",
                position: position
            )
        }
        return string
    }

    private func skipWhitespaceAndNewlines() throws {
        try skip(while: CharacterSet.whitespacesAndNewlines)
    }

    private func skipWhitespaceAndNewlines(
        to characterSet: CharacterSet,
        description: String
    ) throws {
        try skipWhitespaceAndNewlines()
        guard let character = character else {
            throw Error(
                description: "expected \(description) (\(characterSet)), but got EOF",
                position: position
            )
        }

        guard characterSet.contains(character) else {
            throw Error(
                description: "expected \(description) (\(characterSet)), but got \"\(character)\"",
                position: position
            )
        }
    }

    private func skip(while characterSet: CharacterSet) throws {
        while let character = character,
            characterSet.contains(character)
        {
            readCharacter()
        }
    }
}
