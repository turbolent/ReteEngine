import Foundation

/// Parses rules of the format:
///
/// `[ ($a ^b $c) ^ (a ^$b c) => ($a ^$b $c), (a b c) ]`
///
public final class RuleParser<WME>
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

    private var input: AnyIterator<Unicode.Scalar>
    private let makeConstant: (String) -> WME.Constant
    private var character: Unicode.Scalar?
    public private(set) var position = 0

    public init<Iterator>(
        input: Iterator,
        makeConstant: @escaping (String) -> WME.Constant
    ) throws
        where Iterator: IteratorProtocol,
            Iterator.Element == Unicode.Scalar
    {
        self.input = AnyIterator(input)
        self.makeConstant = makeConstant
        readCharacter()
    }

    private func readCharacter() {
        character = input.next()
        position += 1
    }

    public func parse() throws -> Rule<WME>? {
        try skipWhitespaceAndNewlines()
        if character == nil {
            return nil
        }
        guard character == "[" else {
            throw Error(
                description: "expected rule start, but got \"\(character!)\"",
                position: position
            )
        }
        readCharacter()

        var conditions: [Condition<WME>] = []
        conditions.append(try readCondition())

        repeat {
            try skipWhitespaceAndNewlines(
                to: ["=", "^"],
                description: "next condition or rule separator"
            )

            let previousCharacter = character
            readCharacter()
            if previousCharacter == "=" {
                guard character == ">" else {
                    throw Error(
                        description: "expected rule separator",
                        position: position
                    )
                }
                readCharacter()
                break
            }

            conditions.append(try readCondition())
        } while true

        var actions: [RuleAction<WME>] = []
        actions.append(try readAction())

        repeat {
            try skipWhitespaceAndNewlines(
                to: ["]", ","],
                description: "next action or rule end"
            )

            let previousCharacter = character
            readCharacter()
            if previousCharacter == "]" {
                break
            }

            actions.append(try readAction())
        } while true

        return Rule(
            conditions: conditions,
            actions: actions
        )
    }

    private func readFields(kind: String) throws -> (
        identifier: Field<WME.Constant>,
        attribute: Field<WME.Constant>,
        value: Field<WME.Constant>
    ) {
        try skipWhitespaceAndNewlines(
            to: ["("],
            description: "\(kind) start"
        )
        readCharacter()

        let identifier = try readField()

        try skipWhitespaceAndNewlines(
            to: ["^"],
            description: "attribute start"
        )
        readCharacter()
        let attribute = try readField()

        let value = try readField()

        try skipWhitespaceAndNewlines(
            to: [")"],
            description: "\(kind) end"
        )
        readCharacter()

        return (identifier, attribute, value)
    }

    private func readCondition() throws -> Condition<WME> {
        let (identifier, attribute, value) = try readFields(kind: "condition")
        return Condition(identifier, attribute, value)
    }

    private func readAction() throws -> RuleAction<WME> {
        try skipWhitespaceAndNewlines()
        let action = try readOneOrMore(
            CharacterSet.lowercaseLetters,
            description: "action"
        )
        guard action == "add" else {
            throw Error(
                description: "expected action 'add', but got \"\(action)\"",
                position: position
            )
        }
        return .add(try readActionPattern())
    }

    private func readActionPattern() throws -> ActionPattern<WME> {
        let (identifier, attribute, value) = try readFields(kind: "action pattern")
        return ActionPattern(identifier, attribute, value)
    }

    private func readField() throws -> Field<WME.Constant> {
        try skipWhitespaceAndNewlines()

        guard let character = character else {
            throw Error(
                description: "expected field (variable or constant), but EOF",
                position: position
            )
        }

        if character == "$" {
            readCharacter()
            let variableName = try readOneOrMore(.alphanumerics, description: "variable name")
            return .variable(name: variableName)
        } else if CharacterSet.alphanumerics.contains(character) {
            let constantString = try readOneOrMore(.alphanumerics, description: "constant")
            let constant = makeConstant(constantString)
            return .constant(constant)
        } else {
            throw Error(
                description: "expected field (variable or constant), but got: \"\(character)\"",
                position: position
            )
        }
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
