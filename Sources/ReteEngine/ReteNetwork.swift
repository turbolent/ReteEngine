
/// A dataflow network to represent the conditions of productions.
///
/// ## CMU-CS-95-113:  2.1 Overview
///
/// > Rete uses a dataflow network to represent the conditions of the productions.
/// > The network has two parts. The alpha part performs the constant tests on
/// > working memory elements (tests for constant symbols such as red and left-of).
/// > Its output is stored in alpha memories (AM), each of which holds the current set
/// > of working memory elements passing all the constant tests of an individual condition.
/// >
/// > [...] The beta part of the network primarily contains join nodes and beta memories.
/// > Join nodes perform the tests for consistency of variable bindings between conditions.
/// > Beta memories store partial instantiations of productions (i.e., combinations of WMEs
/// > which match some but not all of the conditions of a production). These partial
/// > instantiations are called tokens.
/// >
/// > [...] the alpha network performs not only constant tests but also intra-condition
/// > variable binding consistency tests, where one variable occurs more than once in
/// > a single condition; [...]
/// >
/// > [...] the basic idea is that the alpha network performs all the tests which involve
/// > a single WME, while the beta network performs tests involving two or more WMEs.
///
public final class ReteNetwork<WorkingMemory>
    where WorkingMemory: ReteEngine.WorkingMemory
{
    public typealias WME = WorkingMemory.WME
    public typealias Constant = WME.Constant
    public typealias AlphaMemory = ReteEngine.AlphaMemory<WME>
    public typealias ReteNode = ReteEngine.ReteNode<WME>
    public typealias Token = ReteEngine.Token<WME>
    public typealias TestAtJoinNode = ReteEngine.TestAtJoinNode<WME>
    public typealias BetaMemory = ReteEngine.BetaMemory<WME>
    public typealias JoinNode = ReteEngine.JoinNode<WME>
    public typealias Condition = ReteEngine.Condition<WME>
    public typealias PNode = ReteEngine.PNode<WME>
    public typealias AlphaMemoryIndex = ReteEngine.AlphaMemoryIndex<Constant>
    public typealias DummyTopNode = ReteEngine.DummyTopNode<WME>

    /// The indexed alpha memories.
    public private(set) var alphaMemories: [AlphaMemoryIndex: AlphaMemory] = [:]

    /// The top most Rete node of the beta part.
    public let betaRoot = DummyTopNode()

    public private(set) var workingMemory: WorkingMemory

    /// Creates a new empty network.
    ///
    public init(workingMemory: WorkingMemory) {
        self.workingMemory = workingMemory
    }
}

/// ## CMU-CS-95-113:  2.2 Alpha Net Implementation
///
/// > When a WME is added to working memory, the alpha network performs the necessary
/// > constant (or intra-condition) tests on it and deposits it into (zero or more)
/// > appropriate alpha memories.
///
/// ## CMU-CS-95-113:  2.2.3 Exhaustive Hash Table Lookup
///
/// > For any given WME, there are at most eight alpha memories that WME can go into.
/// > This is because every alpha memory has the form `(test-1 ^test-2 test-3)`,
/// > where each of the three tests is either a test for equality with a specific
/// > constant symbol, or a "don't care," which we will denote by "*".
///
/// > If a WME `w = (v1 ^v2 v3)` goes into an alpha memory `a`, then `a` must have
/// > one of the following eight forms:
///
/// > - `(*  ^*   *  )`
/// > - `(*  ^*   v3 )`
/// > - `(*  ^v2  *  )`
/// > - `(*  ^v2  v3 )`
/// > - `(v1 ^*   *  )`
/// > - `(v1 ^*   v3 )`
/// > - `(v1 ^v2  *  )`
/// > - `(v1 ^v2  v3 )`
///
/// > These are the only eight ways to write a condition which `(v1 ^v2 v3)` will match.
/// > Thus, given a WME `w`, to determine which alpha memories `w` should be added to,
/// > we need only check whether any of these eight possibilities is actually present
/// > in the system. (Some might not be present, since there might not be any alpha memory
/// > corresponding to that particular combination of tests and *'s.
///
/// > We store pointers to all the system's alpha memories in a hash table, indexed
/// > according to the particular values being tested.
///
/// See `AlphaMemoryIndex` and `alphaMemories`
///
extension ReteNetwork {

    /// Inserts the given working memory entry into the network.
    ///
    /// - Parameter wme: A working memory entry to insert into the network.
    ///
    /// ## CMU-CS-95-113:  2.2.3 Exhaustive Hash Table Lookup
    ///
    /// ```
    /// procedure add-wme (w: WME) { exhaustive hash table version }
    ///     let v1, v2, and v3 be the symbols in the three fields of w
    ///
    ///     alpha-mem lookup-in-hash-table (v1,v2,v3)
    ///     if alpha-mem = "not-found" then
    ///         alpha-memory-activation (alpha-mem, w)
    ///
    ///     alpha-mem <- lookup-in-hash-table (v1,v2,*)
    ///     if alpha-mem = "not-found" then
    ///         alpha-memory-activation (alpha-mem, w)
    ///
    ///     alpha-mem <- lookup-in-hash-table (v1,*,v3)
    ///     if alpha-mem = "not-found" then
    ///         alpha-memory-activation (alpha-mem, w)
    ///     .
    ///     .
    ///     .
    ///     alpha-mem lookup-in-hash-table (*,*,*)
    ///     if alpha-mem = "not-found" then
    ///         alpha-memory-activation (alpha-mem, w)
    /// end
    /// ```
    ///
    public func add(wme: WME) {

        let inserted = workingMemory.insert(wme: wme)
        guard inserted else {
            return
        }

        typealias Index = AlphaMemoryIndex

        let indices = [
            // `(v1 ^v2 v3)`
            Index(wme.identifier, wme.attribute, wme.value),
            // `(v1 ^v2 *)`
            Index(wme.identifier, wme.attribute, nil),
            // `(v1 ^* v3)`
            Index(wme.identifier, nil, wme.value),
            // `(v1 ^* *)`
            Index(wme.identifier, nil, nil),
            // `(* ^v2 v3)`
            Index(nil, wme.attribute, wme.value),
            // `(* ^v2 *)`
            Index(nil, wme.attribute, nil),
            // `(* ^* v3)`
            Index(nil, nil, wme.value),
            // `(* ^* *)`
            Index(nil, nil, nil)
        ]

        for index in indices {
            alphaMemories[index]?
                .activate(wme: wme)
        }
    }
}

/// ## CMU-CS-95-113:  2.6 Adding and Removing Productions
///
/// > The basic method for adding a production with conditions `c_1; ... ; c_k`
/// > is to start at the top of the beta network and work our way down, building new memory
/// > and join nodes (or finding existing ones to share, if possible) for `c_1; ... ; c_k`,
/// > in that order. We assume that the ordering of the conditions is given to us in advance.
/// >
/// > At avery high level, the procedure looks like this:
///
/// ```
/// M_1 <- dummy-top-node
/// build/share J_1 (a child of M_1), the join node for c_1
/// for i = 2 to k do
///     build/share M_i (a child of J_i-1), a beta memory node
///     build/share J_i (a child of M_i), the join node for c_i
/// make P (a child of J_k ), the production node
/// ```
///
/// > This procedure handles only the beta part of the net; we will also need to build
/// > or share an alpha memory for each condition as we go along.
///
extension ReteNetwork {

    /// Inserts the given production into the network.
    ///
    /// - Parameter production: A production to insert into the network.
    ///
    /// ## CMU-CS-95-113:  2.6 Adding and Removing Productions
    ///
    /// > [...] the add-production procedure, [...] takes a production (actually, just
    /// > the conditions of the production – the match algorithm doesn't care what the
    /// > actions are) and adds it to the network. It follows the basic procedure given
    /// > at the beginning of this section, and uses the helper functions we have just
    /// > defined.
    ///
    /// ```
    /// procedure add-production (lhs: list of conditions)  { revised [...] version }
    ///     current-node <- build-or-share-network-for-conditions (dummy-top-node, lhs, nil )
    ///     build a new production node, make it a child of current-node
    ///     update-new-node-with-matches-from-above (the new production node)
    /// end
    /// ```
    ///
    @discardableResult
    public func addProduction(conditions: [Condition]) -> PNode {
        let currentNode = buildOrShareNetworkForConditions(
            parent: betaRoot,
            conditions:
            conditions,
            earlierConditions: []
        )
        return buildOrSharePNode(parent: currentNode)
    }

    /// Builds or shares a p-node.
    ///
    /// - Parameter parent: The parent Rete node.
    ///
    /// - Returns: a new or existing p-node.
    ///
    private func buildOrSharePNode(parent: ReteNode) -> PNode {
        // look for an existing node to share
        if let existing = parent.children.first(where: { $0 is PNode }) as? PNode {
            return existing
        }

        // create new node
        let new = PNode(parent: parent)
        parent.add(child: new)
        updateNewNodeWithMatchesFromAbove(newNode: new)
        return new
    }

    /// Builds or shares a network structure for the given conditions underneath
    /// the given parent node, and returns the lowermost node in the new-or-shared network.
    ///
    /// - Parameters:
    ///   - parent: The parent Rete node.
    ///   - conditions:
    ///       The conditions of the network to be built or shared underneath the given parent node.
    ///   - earlierConditions:
    ///       The conditions which occured earlier.
    ///
    /// ## CMU-CS-95-113:  Appendix A. Final Pseudocode
    ///
    /// > The build-or-share-network-for-conditions helper function takes a list of conditions,
    /// > builds or shares a network structure for them underneath the given parent node,
    /// > and returns the lowermost node in the new-or-shared network.
    ///
    /// ```
    /// function build-or-share-network-for-conditions (parent: rete-node,
    ///                                                 conds: list of condition,
    ///                                                 earlier-conds: list of condition)
    /// returning rete-node
    ///     let the conds be denoted by c_1; ... ; c_k
    ///     current-node <- parent
    ///     conds-higher-up <- earlier-conds
    ///     for i = 1 to k do
    ///     { ... }
    ///     current-node <- build-or-share-beta-memory-node (current-node)
    ///     tests = get-join-tests-from-condition (c_i, conds-higher-up)
    ///     am <- build-or-share-alpha-memory (c_i)
    ///     current-node <- build-or-share-join-node (current-node, am, tests)
    ///     append c_i to conds-higher-up
    ///     return current-node
    /// end
    /// ```
    ///
    private func buildOrShareNetworkForConditions(
        parent: ReteNode,
        conditions: [Condition],
        earlierConditions: [Condition]
    ) -> ReteNode {
        var currentNode = parent
        var conditionsHigherUp = earlierConditions
        for condition in conditions {
            let betaMemory = buildOrShareBetaMemory(parent: currentNode)
            currentNode = betaMemory
            let tests = getJoinTestsFromCondition(
                condition: condition,
                earlierConditions: conditionsHigherUp
            )
            let alphaMemory = buildOrShareAlphaMemory(condition: condition)
            currentNode = buildOrShareJoinNode(
                parent: betaMemory,
                alphaMemory: alphaMemory,
                tests: tests,
                condition: condition
            )
            conditionsHigherUp.append(condition)
        }
        return currentNode
    }

    /// Builds or shares a beta memory node.
    ///
    /// - Parameter parent: The parent Rete node.
    ///
    /// - Returns: a new or existing beta memory node.
    ///
    /// ## CMU-CS-95-113:  2.6 Adding and Removing Productions
    ///
    /// > [...] build-or-share-beta-memory-node, looks for an existing beta memory node
    /// > that is a child of the given parent node. If there is one, it returns it
    /// > so it can be shared by the new production; otherwise the function builds
    /// > a new one and returns it. This pseudocode assumes that beta memories are
    /// > not indexed; if indexing is used, the procedure would take an extra argument
    /// > specifying which field(s) the memory must be indexed on.
    ///
    /// ```
    /// function build-or-share-beta-memory-node (parent: rete-node)
    /// returning rete-node
    ///     for each child in parent.children do  { look for an existing node to share }
    ///         if child is a beta memory node then
    ///             return child
    ///     new <- allocate-memory()
    ///     new.type <- "beta-memory"
    ///     new.parent <- parent; insert new at the head of the list parent.children
    ///     new.children <- nil
    ///     new.items <- nil
    ///     update-new-node-with-matches-from-above (new)
    ///     return new
    /// end
    /// ```
    ///
    private func buildOrShareBetaMemory(parent: ReteNode) -> BetaMemory {
        // look for an existing node to share
        if let existing = findExistingBetaMemory(parent: parent) {
            return existing
        }

        // create new node
        let initialToken = parent === betaRoot
            ? Token()
            : nil
        let new = BetaMemory(
            parent: parent,
            initialToken: initialToken
        )
        parent.add(child: new)
        updateNewNodeWithMatchesFromAbove(newNode: new)
        return new
    }

    private func findExistingBetaMemory(parent: ReteNode) -> BetaMemory? {
        return parent.children.first(where: { $0 is BetaMemory }) as? BetaMemory
    }

    /// Builds or shares a join node.
    ///
    /// - Parameters:
    ///   - parent: The parent Rete node.
    ///   - alphaMemory: The alpha memory.
    ///   - tests: The tests to be performed at the join node.
    ///   - condition: The condition to be tested for at the join node.
    ///
    /// - Returns: a new or existing join node.
    ///
    /// ## CMU-CS-95-113:  2.6 Adding and Removing Productions
    ///
    /// > [...] handles join nodes rather than beta memory nodes. The two additional arguments
    /// > specify the alpha memory to which the join node must be attached and the variable
    /// > binding consistency checks it must perform. Note that there is no need to call
    /// > update-new-node-with-matches-from-above in this case, because a join node does not
    /// > store any tokens, and a newly created join node has no children onto which join results
    /// > should be passed.
    ///
    /// ```
    /// function build-or-share-join-node (parent: rete-node,
    ///                                    am: alpha-memory,
    ///                                    tests: list of test-at-join-node)
    /// returning rete-node
    ///     for each child in parent.children do  { look for an existing node to share }
    ///         if child is a join node and child.amem = am and child.tests = tests then
    ///             return child
    ///     new <- allocate-memory()
    ///     new.type <- "join"
    ///     new.parent <- parent; insert new at the head of the list parent.children
    ///     new.children <- nil
    ///     new.tests tests; new.amem am
    ///     insert new at the head of the list am.successors
    ///     return new
    /// end
    /// ```
    ///
    private func buildOrShareJoinNode(
        parent: BetaMemory,
        alphaMemory: AlphaMemory,
        tests: [TestAtJoinNode],
        condition: Condition
    ) -> JoinNode {

        // look for an existing node to share
        if let existing = findExistingJoinNode(
            parent: parent,
            alphaMemory: alphaMemory,
            tests: tests,
            condition: condition
        ) {
            return existing
        }

        // create new node
        let new = JoinNode(
            betaMemory: parent,
            alphaMemory: alphaMemory,
            tests: tests,
            condition: condition
        )
        parent.add(child: new)
        alphaMemory.add(successor: new)
        return new
    }

    private func findExistingJoinNode(
        parent: BetaMemory,
        alphaMemory: AlphaMemory,
        tests: [TestAtJoinNode],
        condition: Condition
    ) -> JoinNode? {
        func test(node: ReteNode) -> Bool {
            guard let joinNode = node as? JoinNode else {
                return false
            }
            return joinNode.alphaMemory == alphaMemory
                && joinNode.tests == tests
                && joinNode.condition == condition
        }
        return parent.children.first(where: test) as? JoinNode
    }

    /// Returns tests to be performed at a join node for the given condition
    /// and earlier conditions.
    ///
    /// - Parameters:
    ///   - condition: The condition to be tested at the join node.
    ///   - earlierConditions: The earlier conditions.
    ///
    /// - Returns: The tests to be performed at a join node.
    ///
    /// ## CMU-CS-95-113:  2.6 Adding and Removing Productions
    ///
    /// > get-join-tests-from-condition, takes a condition and builds a list of all
    /// > the variable binding consistency tests that need to be performed by its join node.
    /// > To do this, it needs to know what all the earlier conditions are, so it can determine
    /// > whether a given variable appeared in them – in which case its occurrence in the current
    /// > condition means a consistency test is needed – or whether it is simply a new
    /// > (not previously seen) variable – in which case no test is needed. If a variable `v`
    /// > has more than one previous occurrence, we still only need one consistency test
    /// > for it – join nodes for earlier conditions will ensure that all the previous
    /// > occurrences are equal, so the current join node just has to make sure the current
    /// > WME has the same value for it as any one of the previous occurrences. The pseudocode
    /// > below always chooses the nearest (i.e., most recent) occurrence for the test, because
    /// > with list-form tokens, the nearest occurrence is the cheapest to access.
    /// > With array-form tokens, this choice does not matter.
    ///
    /// ```
    /// function get-join-tests-from-condition (c: condition, earlier-conds: list of condition)
    /// returning list of test-at-join-node
    ///     result <- nil
    ///     for each occurrence of a variable v in a field f of c do
    ///         if v occurs anywhere in earlier-conds then
    ///             let i be the largest i such that the i-th condition in
    ///                 earlier-conds contains a field f2 in which v occurs
    ///
    ///             this-test <- allocate-memory()
    ///             this-test.field-of-arg1 <- f
    ///             this-test.condition-number-of-arg2 <- i
    ///             this-test.field-of-arg2 <- f2
    ///             append this-test to result
    ///     return result
    /// end
    /// ```
    ///
    private func getJoinTestsFromCondition(
        condition: Condition,
        earlierConditions: [Condition]
    ) -> [TestAtJoinNode] {

        var tests: [TestAtJoinNode] = []
        for (keyPath1, variable) in condition.variables {
            for (conditionIndex, earlierCondition) in earlierConditions.enumerated() {
                guard let keyPath2 = earlierCondition.keyPath(forVariable: variable) else {
                    continue
                }
                let test = TestAtJoinNode(
                    fieldOfArg1: keyPath1,
                    conditionNumberOfArg2: conditionIndex,
                    fieldOfArg2: keyPath2
                )
                tests.append(test)
            }
        }
        return tests
    }

    /// Builds or shares an alpha memory for the given condition.
    ///
    /// - Parameter condition: The condition.
    ///
    /// - Returns: a new or existing alpha memory.
    ///
    /// ## CMU-CS-95-113:  2.6 Adding and Removing Productions
    ///
    /// > [...] a helper function for creating a new alpha memory for a given condition,
    /// > or finding an existing one to share. The implementation of this function depends
    /// > on what type of alpha net implementation is used. [...]
    /// >
    /// > For the exhaustivehash-table-lookup implementation [...], the procedure is
    /// > much simpler, as there is no network and all we have to deal with is a hash table:
    ///
    /// ```
    /// function build-or-share-alpha-memory (c: condition)  { exhaustive table lookup version }
    /// returning alpha-memory
    ///     { figure out what the memory should look like }
    ///     id-test <- nil ; attr-test <- nil ; value-test <- nil
    ///     if a constant test t occurs in the "id" field of c then
    ///         id-test <- t
    ///     if a constant test t occurs in the "attribute" field of c then
    ///         attr-test <- t
    ///     if a constant test t occurs in the "value" field of c then
    ///         value-test <- t
    ///     { is there an existing memory like this? }
    ///     am <- lookup-in-hash-table (id-test, attr-test, value-test)
    ///     if am != nil then
    ///         return am
    ///     { no existing memory, so make a new one }
    ///     am <- allocate-memory()
    ///     add am to the hash table for alpha memories
    ///     am.successors <- nil ; am.items <- nil
    ///     { initialize am with any current WMEs }
    ///     for each WME w in working memory do
    ///         if w passes all the constant tests in c then
    ///             alpha-memory-activation (am ,w)
    ///     return am
    /// end
    /// ```
    ///
    internal func buildOrShareAlphaMemory(condition: Condition) -> AlphaMemory {
        // is there an existing memory like this?
        let alphaMemoryIndex = AlphaMemoryIndex(condition: condition)
        if let alphaMemory = alphaMemories[alphaMemoryIndex] {
            return alphaMemory
        }

        // no existing memory, so make a new one
        let alphaMemory = AlphaMemory()
        alphaMemories[alphaMemoryIndex] = alphaMemory

        // initialize alpha memory with any current WMEs
        for wme in workingMemory
            where condition.test(wme: wme)
        {
            alphaMemory.activate(wme: wme)
        }

        return alphaMemory
    }

    /// Initializes the new Rete node to store tokens for any existing matches
    /// for the earlier conditions.
    ///
    /// This ensures newly added productions are immediately immediately matched against
    /// the current working memory.
    ///
    /// - Parameter newNode: The new Rete node that was added to the network.
    ///
    /// ## CMU-CS-95-113:  2.6 Adding and Removing Productions
    ///
    /// > The update-new-node-with-matches-from-above procedure initializes the memory node
    /// > to store tokens for any existing matches for the earlier conditions.
    ///
    /// > This is needed to ensure that newly added productions are immediately matched
    /// > against the current working memory. The procedure's job is to ensure that the given
    /// > new-node's left-activation procedure is called with all the existing matches for
    /// > the previous conditions, so that the new-node can take any appropriate actions
    /// > (e.g., a beta memory stores the matches as new tokens, and a p-node signals new
    /// > complete matches for the production). How update-new-node-with-matches-from-above
    /// > achieves this depends on what kind of node the new-node's parent is.
    /// >
    /// > If the parent is a beta memory [...], this is straightforward since the parent
    /// > has a list (items) of exactly the matches we want. But if the parent node is
    /// > a join node, we want to find the matches satisfying the join tests, and these may
    /// > not be recorded anywhere. To find these matches, we iterate over the WMEs and tokens
    /// > in the join node's alpha and beta memories and perform the join tests on each pair.
    /// >
    /// > The pseudocode below uses a trick to do this: while temporarily pretending the new-node
    /// > is the only child of the join node, it runs the join node's right-activation procedure
    /// > for all the WMEs in its alpha memory; any new matches will automatically be propagated
    /// > to the new-node.
    ///
    /// ```
    /// procedure update-new-node-with-matches-from-above (new-node: rete-node)
    ///     parent <- new-node.parent
    ///     case parent.type of
    ///         "beta-memory":
    ///             for each tok in parent.items do
    ///                 left-activation (new-node, tok)
    ///         "join":
    ///             saved-list-of-children <- parent.children
    ///             parent.children <- [new-node]  { list consisting of just new-node }
    ///             for each item in parent.amem.items do
    ///                 right-activation (parent, item.wme)
    ///             parent.children <- saved-list-of-children
    /// end
    /// ```
    ///
    private func updateNewNodeWithMatchesFromAbove(newNode: ReteNode) {
        guard let parent = newNode.parent else {
            return
        }

        switch parent {
        case let betaMemory as BetaMemory:
            betaMemory.items.forEach {
                newNode.leftActivation(token: $0)
            }

        case let joinNode as JoinNode:
            parent.with(temporaryChildren: [newNode]) {
                joinNode.alphaMemory.items.forEach {
                    joinNode.rightActivation(wme: $0)
                }
            }

        default:
            return
        }
    }
}
