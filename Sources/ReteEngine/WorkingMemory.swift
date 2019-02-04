
public protocol WorkingMemory: Sequence
    where Element == WME
{
    associatedtype WME: ReteEngine.WME

    mutating func insert(wme: WME) -> Bool

    var count: Int { get }
}
