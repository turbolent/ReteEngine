
public enum RuleAction<WME>: Hashable
    where WME: ReteEngine.WME
{
    case add(ActionPattern<WME>)
}

extension RuleAction: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .add(pattern):
            return "add\(String(describing: pattern))"
        }
    }
}
