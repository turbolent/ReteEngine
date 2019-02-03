
/// A partial instantiation of a production. A sequence of working memory entries
/// satisfying a prefix of conditions of a production.
///
/// ## CMU-CS-95-113:  2.3 Memory Node Implementation
///
/// > [...] each token [represents] a sequence of WMEs specifically, a sequence of k WMEs
/// > (for some k) satisfying the first k conditions (with consistent variable bindings)
/// > of some production.
///
/// ## CMU-CS-95-113:  2.3.2 Beta Memory Implementation
///
/// > Turning now to the second question, "How is a token (sequence of WMEs) represented?",
/// > there are two main possibilities. A sequence can be represented either by an array
/// > (yielding array-form tokens) or by a list (yielding list-form tokens).
/// >
/// > Using an array would seem the obvious choice, since it offers the advantage of direct access
/// > to all the elements in the sequence – given `i`, we can find the `i`-th element in
/// > constant time – whereas a list requires a loop over the first `i-1` elements to get
/// > to the `i`-th one.
/// >
/// > However, array-form tokens can result in a lot of redundant information storage and hence
/// > much more space usage. [...]
/// >
/// > If we use this technique [list-form tokens] at all beta memory nodes, then each token
/// > effectively becomes a linked list, connected by parent pointers, representing a sequence
/// > of WMEs in reverse order, with `w_i` at the head of the list and `w_1` at the tail.
/// > For uniformity, we make tokens in the uppermost beta memories (which represent sequences
/// > of just one WME) have their parent point to a dummy top token, which represents the null
/// > sequence `h_i`. Note that the set of all tokens now forms a tree, with links pointing from
/// > children to their parents, and with the dummy top token at the root.
/// > [...]
/// >
/// > [...] using array-form tokens requires more space than using list-form tokens, and requires
/// > more time to create each token on each beta memory node activation. However, it affords
/// > faster access to a given element of the sequence than using list-form tokens does.
/// > Access to arbitrary elements is often required during join node activations, in order to
/// > perform variable binding consistency checks. So we have a tradeoff. Neither representation
/// > is clearly better for all systems.
/// > [...]
/// >
/// > To keep things as simple as possible, we use list-form tokens and unindexed memory nodes.
/// > [...]
/// >
/// > With list-form tokens [...] a token is just a pair:
///
/// ```
/// structure token:
///     parent: token  { points to the higher token, for items 1...i-1 }
///     wme: WME  { gives item i }
/// end
/// ```
///
public final class Token<Constant>: Equatable where Constant: Hashable {

    public typealias Token = ReteEngine.Token<Constant>
    public typealias WME = ReteEngine.WME<Constant>

    /// Points to the higher token, for items 1...i-1.
    public let parent: Token?

    /// Gives item i.
    public let wme: WME?

    /// Creates a token for the given parent (pointer to the higher token,
    /// for items 1...i-1) and working memory entry (item i)
    ///
    /// - Parameters:
    ///   - parent: The pointer to the higher token, for items 1...i-1.
    ///   - wme: The working memory entry (item i).
    ///
    public init(parent: Token?, wme: WME?) {
        self.parent = parent
        self.wme = wme
    }

    /// Returns all working memory entries of this token.
    ///
    /// The working memory entry of this token (item i) will be the last entry
    /// of the resulting array, preceeded by the items 1...i-1.
    ///
    public var workingMemoryEntries: [WME] {
        var entries: [WME] = []
        var current: Token? = self
        while let token = current,
            let wme = token.wme,
            token.parent != nil
        {
            entries.append(wme)
            current = token.parent
        }
        return entries.reversed()
    }

    public static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.parent == rhs.parent
            && lhs.wme == rhs.wme
    }
}
