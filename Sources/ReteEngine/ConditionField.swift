
/// A field of a condition. It can either be a constant test, or a variable.
///
public enum ConditionField<Constant>: Hashable
    where Constant: Hashable
{
    case constant(Constant)
    case variable(name: String)
}

extension ConditionField: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .constant(constant):
            return String(describing: constant)
        case let .variable(variableName):
            return "$\(variableName)"
        }
    }
}
