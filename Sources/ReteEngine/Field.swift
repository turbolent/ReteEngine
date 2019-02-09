
/// A field, e.g. as part of a condition or an action pattern.
/// It can either be a constant test, or a variable.
///
public enum Field<Constant>: Hashable
    where Constant: Hashable
{
    case constant(Constant)
    case variable(name: String)

    /// Returns a constant if the field is constant, or if it is a variable and the bindings
    /// contain an appropriate binding for the variable field.
    ///
    /// - Parameter bindings: The variable bindings to use.
    ///
    /// - Returns:
    ///     A constant, if the field is constant,
    ///     or if it is a variable and it can be subsituted.
    ///
    public func substitute(bindings: [String: Constant]) -> Constant? {
        switch self {
        case let .variable(variableName):
            return bindings[variableName]
        case let .constant(constant):
            return constant
        }
    }

    /// Returns a constant if the field is constant, or if it is a variable and
    /// the binding lookup function returns an appropriate binding for the variable field.
    ///
    /// - Parameter bindings: The variable bindings to use.
    ///
    /// - Returns:
    ///     A constant, if the field is constant,
    ///     or if it is a variable and it can be subsituted.
    ///
    public func substitute(getBinding: (String) -> Constant?) -> Constant? {
        switch self {
        case let .variable(variableName):
            return getBinding(variableName)
        case let .constant(constant):
            return constant
        }
    }
}

extension Field: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .constant(constant):
            return String(describing: constant)
        case let .variable(variableName):
            return "$\(variableName)"
        }
    }
}
