
/// An implication between an antecedent (body) and consequent (head).
///
/// When the conditions specified in the antecedent hold,
/// then the actions specified in the consequent are performed.
///
public struct Rule<WME>: Hashable
    where WME: ReteEngine.WME
{
    /// The conditions of the antecedent. The body of the rule.
    public let conditions: [Condition<WME>]

    // The actions of the consequent. The head of the rule.
    public let actions: [RuleAction<WME>]

    public init(conditions: [Condition<WME>], actions: [RuleAction<WME>]) {
        self.conditions = conditions
        self.actions = actions
    }
}

extension Rule: CustomStringConvertible {

    public var description: String {
        let body = conditions.map(String.init).joined(separator: " ∧ ")
        let head = actions.map(String.init).joined(separator: ", ")
        return [body, head].joined(separator: " ⇒ ")
    }
}
