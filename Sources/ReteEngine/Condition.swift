
/// A part of a left-hand side of a production.
///
/// A condition tests the fields of a working memory entry. Each condition field
/// can can either be a constant test, or a variable.
///
public struct Condition<WME>: Hashable
    where WME: ReteEngine.WME
{
    public typealias Constant = WME.Constant
    public typealias Field = ReteEngine.Field<Constant>

    public let identifier: Field
    public let attribute: Field
    public let value: Field

    /// Creates a condition for the given identifier, attribute, and value fields.
    ///
    public init(
        identifier: Field,
        attribute: Field,
        value: Field
    ) {
        self.identifier = identifier
        self.attribute = attribute
        self.value = value
    }

    /// Creates a condition for the given identifier, attribute, and value fields.
    ///
    public init(
        _ identifier: Field,
        _ attribute: Field,
        _ value: Field
    ) {
        self.init(
            identifier: identifier,
            attribute: attribute,
            value: value
        )
    }

    /// Returns an array of tuples of key path and variable name,
    /// one element for each variable field of the condition.
    ///
    public var variables: [(KeyPath<WME, Constant>, String)] {
        var variables: [(KeyPath<WME, Constant>, String)] = []

        if case let .variable(identifierVariable) = identifier {
            variables.append((\WME.identifier, identifierVariable))
        }

        if case let .variable(attributeVariable) = attribute {
            variables.append((\WME.attribute, attributeVariable))
        }

        if case let .variable(valueVariable) = value {
            variables.append((\WME.value, valueVariable))
        }

        return variables
    }

    /// Returns a key path for the variable field with the given variable name, if any.
    ///
    /// - Parameter variableName: The variable name that may occur in the condition.
    ///
    /// - Returns: a key path for the variable field with the given variable name, if any.
    ///
    public func keyPath(forVariable variableName: String) -> KeyPath<WME, Constant>? {
        if case let .variable(identifierVariable) = identifier,
            identifierVariable == variableName
        {
            return \WME.identifier
        }

        if case let .variable(attributeVariable) = attribute,
            attributeVariable == variableName
        {
            return \WME.attribute
        }

        if case let .variable(valueVariable) = value,
            valueVariable == variableName
        {
            return \WME.value
        }

        return nil
    }

    /// Returns true if the given working memory entry matches this condition.
    ///
    /// For the condition to match, each constant field of the condition must match
    /// the corresponding field of the working memory entry.
    ///
    /// - Parameter wme: The working memory entry to be tested against this condition.
    ///
    /// - Returns:
    ///     `true` if the given working memory entry matches this condition;
    ///     otherwise, `false`.
    ///
    public func test(wme: WME) -> Bool {
        if case let .constant(constant) = identifier,
            wme.identifier != constant
        {
            return false
        }

        if case let .constant(constant) = attribute,
            wme.attribute != constant
        {
            return false
        }

        if case let .constant(constant) = value,
            wme.value != constant
        {
            return false
        }

        return true
    }

    /// Returns the variable bindings for the given working memory entry.
    ///
    /// - Parameter wme: The working memory entry from which to extract the constants.
    ///
    public func bindings(forWME wme: WME) -> [String: Constant] {
        var bindings: [String: Constant] = [:]
        for (keyPath, variableName) in variables {
            bindings[variableName] = wme[keyPath: keyPath]
        }
        return bindings
    }
}

extension Condition: CustomStringConvertible {
    public var description: String {
        return "(\(identifier) ^\(attribute) \(value))"
    }
}
