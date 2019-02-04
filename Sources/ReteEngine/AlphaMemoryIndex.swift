
/// An index for alpha memories in a Rete network.
///
/// Each field can either be a constant, or a wildcard (`nil`).
///
/// ## CMU-CS-95-113:  2.2 Alpha Net Implementation, 2.2.3 Exhaustive Hash Table Lookup
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
/// See `ReteNetwork.alphaMemories`.
///
public struct AlphaMemoryIndex<Constant>: Hashable
    where Constant: Hashable
{
    public let identifier: Constant?
    public let attribute: Constant?
    public let value: Constant?

    /// Creates an alpha memory index from the given fields.
    ///
    /// A `nil` value is treated as a wildcard.
    ///
    public init(_ identifier: Constant?, _ attribute: Constant?, _ value: Constant?) {
        self.identifier = identifier
        self.attribute = attribute
        self.value = value
    }
}

/// A condition gets converted to an index by passing the constant value for each constant field,
/// and `nil` for each variable field.
///
/// ## CMU-CS-95-113:  2.6. Adding and Removing Productions
///
/// > [...] a helper function for creating a new alpha memory for a given condition,
/// > or finding an existing one to share. The implementation of this function depends
/// > on what type of alpha net implementation is used. [...]
/// >
/// > For the exhaustivehash-table-lookup implementation [...], the procedure is
/// > much simpler, as there is no network and all we have to deal with is a hash table:
///
/// ```
/// id-test <- nil ; attr-test <- nil ; value-test <- nil
/// if a constant test t occurs in the "id" field of c then
///     id-test <- t
/// if a constant test t occurs in the "attribute" field of c then
///     attr-test <- t
/// if a constant test t occurs in the "value" field of c then
///     value-test <- t
/// ```
///
extension AlphaMemoryIndex {

    /// Creates an alpha memory index from the given condition.
    ///
    /// Constant tests of the condition are extracted, and variables of the condition
    /// are treated as wildcards.
    ///
    /// - Parameter condition: The condition to be used as a template for the new index.
    ///
    public init<WME>(condition: Condition<WME>)
        where WME.Constant == Constant
    {
        let identifierTest: Constant?
        if case let .constant(constant) = condition.identifier {
            identifierTest = constant
        } else {
            identifierTest = nil
        }

        let attributeTest: Constant?
        if case let .constant(constant) = condition.attribute {
            attributeTest = constant
        } else {
            attributeTest = nil
        }

        let valueTest: Constant?
        if case let .constant(constant) = condition.value {
            valueTest = constant
        } else {
            valueTest = nil
        }

        self.init(identifierTest, attributeTest, valueTest)
    }
}
