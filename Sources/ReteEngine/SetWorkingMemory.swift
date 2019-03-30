
public final class SetWorkingMemory<WME>: WorkingMemory
    where WME: ReteEngine.WME
{
    /// The working memory entries
    public private(set) var workingMemoryEntries: Set<WME> = []

    public init() {}

    public func makeIterator() -> Set<WME>.Iterator {
        return workingMemoryEntries.makeIterator()
    }

    public func insert(wme: WME) -> Bool {
        let (inserted, _) = workingMemoryEntries.insert(wme)
        return inserted
    }

    public var count: Int {
        return workingMemoryEntries.count
    }
}
