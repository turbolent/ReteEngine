
/// A Rete node storing partial instantiations of productions (tokens).
///
/// Beta memory nodes are part of the beta part of the Rete network.
///
/// ## CMU-CS-95-113:  2.1 Overview
///
/// > Beta memories store partial instantiations of productions (i.e. combinations of WMEs
/// > which match some but not all of the conditions of a production). These partial
/// > instantiations are called tokens.
///
/// ## CMU-CS-95-113:  2.3.2 Beta Memory Implementation
///
/// > [...] the only extra data a beta memory node stores is a list of the tokens it contains:
///
/// ```
/// structure beta-memory:
///     items: list of token
/// end
/// ```
///
public final class BetaMemory<Constant>: ReteNode<Constant> where Constant: Hashable {

    /// The partial instantiations of productions (tokens).
    public private(set) var items: [Token] = []

    /// Creates a beta memory from the given pointer to the parent node
    /// and optional initial token.
    ///
    /// - Parameters:
    ///   - parent: The pointer to the parent Rete node.
    ///   - initialToken: The optional initial token (partial instantiation of a production).
    ///
    public init(parent: ReteNode, initialToken: Token? = nil) {
        if let token = initialToken {
            items.append(token)
        }
        super.init(parent: parent)
    }

    /// Informs the node of a new match (a token and a working memory entry).
    ///
    /// - Parameters:
    ///   - token: The matching token (partial instantiation of a production).
    ///   - wme: The matching working memory entry.
    ///   - bindings: The variable bindings.
    ///
    /// ## CMU-CS-95-113:  2.3.2 Beta Memory Implementation
    ///
    /// > Whenever a beta memory is informed of a new match (consisting of an existing token
    /// > and some WME), we build a token, add it to the list in the beta memory, and inform
    /// > each of the beta memory's children
    ///
    /// ```
    /// procedure beta-memory-left-activation (node: beta-memory, t: token, w: WME)
    ///     new-token <- allocate-memory()
    ///     new-token.parent <- t
    ///     new-token.wme <- w
    ///     insert new-token at the head of node.items
    ///     for each child in node.children do
    ///         left-activation (child, new-token)
    /// end
    /// ```
    ///
    public override func leftActivation(
        token: Token,
        wme: WME? = nil,
        bindings: [String: Constant]
    ) {
        let newToken = Token(parent: token, wme: wme, bindings: bindings)
        items.append(newToken)

        children.forEach {
            $0.leftActivation(token: newToken)
        }
    }
}
