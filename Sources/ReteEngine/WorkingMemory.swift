
public protocol WorkingMemory: Sequence
    where Element == WME<Constant>
{
    associatedtype Constant: Hashable

    mutating func insert(wme: WME<Constant>) -> Bool

    var count: Int { get }
}
