
/// A part of a right-hand side of a production.
///
/// An action pattern is used in production actions. Each pattern field
/// can can either be a constant test, or a variable.
///
public struct ActionPattern<WME>: Hashable
    where WME: ReteEngine.WME
{
    public typealias Constant = WME.Constant
    public typealias Field = ReteEngine.Field<Constant>

    public let identifier: Field
    public let attribute: Field
    public let value: Field

    /// Creates an action pattern for the given identifier, attribute, and value fields.
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

    /// Creates an action pattern for the given identifier, attribute, and value fields.
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

    /// Returns a working memory entry by substituting all variable fields with
    /// the constants in the given variable bindings.
    ///
    /// - Parameter bindings: The variable bindings to use.
    ///
    /// - Returns: A working memory entry, if all variables can be subsituted.
    ///
    public func substitute(bindings: [String: Constant]) -> WME? {
        guard
            let identifierConstant = identifier.substitute(bindings: bindings),
            let attributeConstant = attribute.substitute(bindings: bindings),
            let valueConstant = value.substitute(bindings: bindings)
        else {
            return nil
        }

        return WME(
            identifier: identifierConstant,
            attribute: attributeConstant,
            value: valueConstant
        )
    }

    /// Returns a working memory entry by substituting all variable fields with
    /// the constants by using a lookup function.
    ///
    /// - Parameter getBinding: The function to get a binding for a variable.
    ///
    /// - Returns: A working memory entry, if all variables can be subsituted.
    ///
    public func substitute(getBinding: (String) -> Constant?) -> WME? {
        guard
            let identifierConstant = identifier.substitute(getBinding: getBinding),
            let attributeConstant = attribute.substitute(getBinding: getBinding),
            let valueConstant = value.substitute(getBinding: getBinding)
        else {
                return nil
        }

        return WME(
            identifier: identifierConstant,
            attribute: attributeConstant,
            value: valueConstant
        )
    }
}

extension ActionPattern: CustomStringConvertible {
    public var description: String {
        return "(\(identifier) ^\(attribute) \(value))"
    }
}
