
/// A Rete node which gets activated when a production's conditions are completely matched
/// and stored all matching tokens.
///
/// P-nodes are part of the beta part of the Rete network.
///
/// ## CMU-CS-95-113:  2.1 Overview
///
/// > Whenever the propagation reaches the bottom of the network, it indicates that
/// > a production's conditions are completely matched. This is commonly implemented
/// > by having a special node for each production (called its production node,
/// > or p-node for short) at the bottom of the network. [...]
/// >
/// > Whenever a p-node gets activated, it signals the newly found complete match.
///
/// ## CMU-CS-95-113:  2.3.3 P-Node Implementation
///
/// > A p-node may store tokens, just as beta memories do; these tokens represent complete
/// > matches for the production's conditions. (In traditional production systems, the set
/// > of all tokens at all p-nodes represents the conict set.) On a left activation, a p-node
/// > will build a new token, or some similar representation of the newly found complete match.
/// > It then signals the new match in some appropriate (system-dependent) way
///
/// > In general, a p-node also contains a specification of what production it corresponds to –
/// > the name of the production, its right-hand-side actions, etc. A p-node may also contain
/// > information about the names of the variables that occur in the production.
///
public final class PNode<Target>: ReteNode<Target.WME>, Equatable
    where Target: ProductionTarget
{
    public typealias WME = Target.WME

    /// The matching tokens.
    public private(set) var items: [Token] = []

    public weak var target: Target?

    public init(parent: ReteNode, target: Target? = nil) {
        self.target = target
        super.init(parent: parent)
    }

    /// Informs the node of a new match (a token and a working memory entry).
    ///
    /// - Parameters:
    ///   - token: The matching token (partial instantiation of a production).
    ///   - wme: The matching working memory entry.
    ///   - bindings: The variable bindings.
    ///
    /// ## CMU-CS-95-113:  2.1 Overview
    ///
    /// > Whenever a p-node gets activated, it signals the newly found complete match.
    ///
    public override func leftActivation(token: Token, wme: WME?, bindings: [String: Constant]) {
        let newToken = Token(parent: token, wme: wme, bindings: bindings)
        items.append(newToken)
        target?.productionNodeDidActivate(pNode: self)
    }

    public static func == (lhs: PNode<Target>, rhs: PNode<Target>) -> Bool {
        return lhs.items == rhs.items
            && lhs.parent === rhs.parent
            && zip(lhs.children, rhs.children)
                .allSatisfy { $0 === $1 }
    }
}
