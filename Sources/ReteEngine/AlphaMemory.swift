
/// A storage of working memory entries and pointers to successors (join nodes).
///
/// ## CMU-CS-95-113: 2.3.1 Alpha Memory Implementation
///
/// > An alpha memory stores a list of the WMEs it contains, plus a list of its
/// > successors (join nodes attached to it):
///
/// ```
/// structure alpha-memory:
///     items: list of WME
///     successors: list of rete-node
/// end
/// ```
///
public final class AlphaMemory<Constant>: Equatable where Constant: Hashable {

    public typealias WME = ReteEngine.WME<Constant>
    public typealias JoinNode = ReteEngine.JoinNode<Constant>
    public typealias AlphaMemory = ReteEngine.AlphaMemory<Constant>

    /// The matching working memory entries.
    public private(set) var items: [WME] = []

    /// The succeeding join nodes attached to this alpha memory.
    public private(set) var successors: [JoinNode] = []

    /// Creates a new alpha memory without any working memory entries
    /// and without any succeeding join nodes.
    ///
    public init() {}

    /// Inserts the given working memory entry and right activates all successors (join nodes).
    ///
    /// - Parameter wme: The working memory entry.
    ///
    /// > Whenever a new WME is filtered through the alpha network and reaches
    /// > an alpha memory, we simply add it to the list of other WMEs in that memory,
    /// > and inform each of the attached join nodes:
    ///
    /// ```
    /// procedure alpha-memory-activation (node: alpha-memory, w: WME)
    ///     insert w at the head of node.items
    ///     for each child in node.successors do
    ///         right-activation (child, w)
    /// end
    /// ```
    ///
    public func activate(wme: WME) {
        items.append(wme)

        // ## CMU-CS-95-113:  2.4.1 Avoiding Duplicate Tokens:
        //
        // > A better approach which avoids this slowdown is to right-activate the join nodes
        // > in a different order. In the above example, if we right-activate the lower join node
        // > first, no duplicate tokens are generated. [...] In general, the solution is
        // > to right-activate descendents before their ancestors; i.e., if we need to
        // > right-activate join nodes J_1 and J_2 from the same alpha memory, and J_1 is
        // > a descendent of J_2, then we right-activate J_1 before rightactivating J_2.
        //
        // > Right-activate the attached join nodes, descendents before ancestors.

        successors.reversed().forEach {
            $0.rightActivation(wme: wme)
        }
    }

    /// Inserts the given successor join node.
    ///
    /// - Parameter successor: The succeeding Rete node.
    ///
    internal func add(successor: JoinNode) {
        successors.append(successor)
    }

    public static func == (lhs: AlphaMemory, rhs: AlphaMemory) -> Bool {
        return lhs.items == rhs.items
            && zip(lhs.successors, rhs.successors)
                .allSatisfy { $0 === $1 }
    }
}
