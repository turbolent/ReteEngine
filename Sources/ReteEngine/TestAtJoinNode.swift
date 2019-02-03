
/// A test to be performed at a join node.
///
/// The test consists of the field of the first working memory entry to be tested,
/// the field of a second working memory entry, and the offset of the second working
/// memory entry in the token to be tested.
///
/// ## CMU-CS-95-113:  2.4 Join Node Implementation
///
/// > The test-at-join-node structure specifies the locations of the two fields whose values
/// > must be equal in order for some variable to be bound consistently:
///
/// ```
/// structure test-at-join-node:
///     field-of-arg1: "identifier", "attribute", or "value"
///     condition-number-of-arg2: integer
///     field-of-arg2: "identifier", "attribute", or "value"
/// end
/// ```
///
/// > `Arg1` is one of the three fields in the WME (in the alpha memory), while `arg2`
/// > is a field from a WME that matched some earlier condition in the production
/// > (i.e., part of the token in the beta memory).
///
public struct TestAtJoinNode<Constant>: Equatable where Constant: Hashable {

    public typealias WME = ReteEngine.WME<Constant>

    /// The field of the first working memory entry to be tested.
    /// It is one of the three fields of a working memory entry.
    public let fieldOfArg1: KeyPath<WME, Constant>

    /// The offset of the second working memory entry in the token to be tested.
    public let conditionNumberOfArg2: Int

    /// The field of a second working memory entry to be tested.
    /// It is one of the three fields of a working memory entry.
    public let fieldOfArg2: KeyPath<WME, Constant>

    /// Creates a new test to be performed at a join node.
    ///
    /// - Parameters:
    ///   - fieldOfArg1: The field of the first working memory entry to be tested.
    ///   - conditionNumberOfArg2:
    ///       The offset of the second working memory entry in the token to be tested.
    ///   - fieldOfArg2: The field of a second working memory entry to be tested.
    ///
    public init(
        fieldOfArg1: KeyPath<WME, Constant>,
        conditionNumberOfArg2: Int,
        fieldOfArg2: KeyPath<WME, Constant>
    ) {
        self.fieldOfArg1 = fieldOfArg1
        self.conditionNumberOfArg2 = conditionNumberOfArg2
        self.fieldOfArg2 = fieldOfArg2
    }
}
