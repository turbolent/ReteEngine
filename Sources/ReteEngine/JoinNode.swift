
/// A Rete node performing tests for consistency of variable bindings between conditions.
///
/// Join nodes are part of the beta part of the Rete network.
///
/// ## CMU-CS-95-113:  2.1 Overview
///
/// > [...] Join nodes perform the tests for consistency of variable bindings between conditions.
///
/// ## CMU-CS-95-113:  2.4 Join Node Implementation
///
/// > [...] a join node can incur a right activation when a WME is added to its alpha memory,
/// > or a left activation when a token is added to its beta memory. In either case, the node's
/// > other memory is searched for items having variable bindings consistent with the
/// > new item; if any are found, they are passed on to the join node's children.
///
/// > The data structure for a join node, therefore, must contain pointers to its two memory
/// > nodes (so they can be searched), a specification of any variable binding consistency tests
/// > to be performed, and a list of the node's children. From the data common to all nodes
/// > (the rete-node structure [...[), we already have the children; also, the parent field
/// > automatically gives us a pointer to the join node's beta memory (the beta memory is always
/// > its parent). We need two extra fields for a join node:
///
/// ```
/// structure join-node:
///     amem: alpha-memory  { points to the alpha memory this node is attached to }
///     tests: list of test-at-join-node
/// end
/// ```
///
public final class JoinNode<Constant>: ReteNode<Constant> where Constant: Hashable {

    public typealias AlphaMemory = ReteEngine.AlphaMemory<Constant>
    public typealias TestAtJoinNode = ReteEngine.TestAtJoinNode<Constant>
    public typealias BetaMemory = ReteEngine.BetaMemory<Constant>
    public typealias Condition = ReteEngine.Condition<Constant>

    public let betaMemory: BetaMemory
    public let alphaMemory: AlphaMemory
    public let tests: [TestAtJoinNode]
    public let condition: Condition

    public init(
        betaMemory: BetaMemory,
        alphaMemory: AlphaMemory,
        tests: [TestAtJoinNode],
        condition: Condition
    ) {
        self.betaMemory = betaMemory
        self.alphaMemory = alphaMemory
        self.tests = tests
        self.condition = condition
        super.init(parent: betaMemory)
    }

    // TODO:
    // ## CMU-CS-95-113:  2.4 Join Node Implementation
    //
    // > [...] this pseudocode [for the activations] assumes that the alpha and beta memories
    // > are not indexed in any way [...]. If indexed memories are used, then the activation
    // > procedures [...] would be modified to use the index rather than simply iterating over
    // > all tokens or WMEs in the memory node. For example, if memories are hashed,
    // > the procedures would iterate only over the tokens or WMEs in the appropriate
    // > hash bucket, not over all tokens or WMEs in the memory. This can significantly
    // > speed up the Rete algorithm.

    /// Informs the node of the insertion of a new working memory entry.
    ///
    /// - Parameter wme: The inserted working memory entry.
    ///
    /// ## CMU-CS-95-113:  2.4 Join Node Implementation
    ///
    /// > Upon a right activation (when a new WME `w` is added to the alpha memory),
    /// > we look through the beta memory and find any token(s) `t` for which all these
    /// > `t`-versus-`w` tests succeed. Any successful `t`-`w` combinations are passed on
    /// > to the join node's children.
    ///
    /// ```
    /// procedure join-node-right-activation (node: join-node, w: WME)
    ///     for each t in node.parent.items do  { "parent" is the beta memory node }
    ///         if perform-join-tests (node.tests, t, w) then
    ///             for each child in node.children do
    ///                 left-activation (child, t, w)
    /// end
    /// ```
    ///
    public override func rightActivation(wme: WME) {
        for token in betaMemory.items
            where performJoinTest(token: token, wme: wme)
        {
            children.forEach {
                $0.leftActivation(token: token, wme: wme)
            }
        }
    }

    /// Informs the node of a new match (a token and a working memory entry).
    ///
    /// - Parameters:
    ///   - token: The matching token (partial instantiation of a production).
    ///   - wme: The matching working memory entry.
    ///
    /// ## CMU-CS-95-113:  2.4 Join Node Implementation
    ///
    /// > [...] upon a left activation (when a new token `t` is added to the beta memory),
    /// > we look through the alpha memory and find any WME(s) `w` for which all these
    /// > `t`-versus-`w` tests succeed. Again, any successful `t`-`w` combinations are passed on
    /// > to the node's children:
    ///
    /// ```
    /// procedure join-node-left-activation (node: join-node, t: token)
    ///     for each w in node.amem.items do
    ///         if perform-join-tests (node.tests, t, w) then
    ///             for each child in node.children do
    ///                 left-activation (child, t, w)
    /// end
    /// ```
    ///
    public override func leftActivation(token: Token, wme _: WME? = nil) {
        for wme in alphaMemory.items
            where performJoinTest(token: token, wme: wme)
        {
            children.forEach {
                $0.leftActivation(token: token, wme: wme)
            }
        }
    }

    /// Performs all variable binding consistency tests for the given token and
    /// working memory entry.
    ///
    /// - Parameters:
    ///   - token: The token (partial instantiation of a production) to be tested.
    ///   - wme: The working memory entry to be tested.
    ///
    /// - Returns:
    ///     `true` if the given token and working memory entry pass all tests of this node;
    ///     otherwise, `false`.
    ///
    /// ## CMU-CS-95-113:  2.4 Join Node Implementation
    ///
    /// ```
    /// function perform-join-tests (tests: list of test-at-join-node, t: token, w: WME)
    /// returning boolean
    ///     for each this-test in tests do
    ///         arg1 <- w.[this-test.field-of-arg1]
    ///         { With list-form tokens, the following statement is really a loop }
    ///         wme2 <- the [this-test.condition-number-of-arg2]'th element in t
    ///         arg2 <- wme2.[this-test.field-of-arg2]
    ///         if arg1 != arg2 then
    ///             return false
    ///     return true
    /// end
    /// ```
    ///
    private func performJoinTest(token: Token, wme: WME) -> Bool {
        return tests.allSatisfy { test in
            let arg1 = wme[keyPath: test.fieldOfArg1]
            let wme2 = token.workingMemoryEntries[test.conditionNumberOfArg2]
            let arg2 = wme2[keyPath: test.fieldOfArg2]
            return arg1 == arg2
        }
    }
}
