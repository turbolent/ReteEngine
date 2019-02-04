
public struct SetWorkingMemory<T>: WorkingMemory where T: Hashable {

    public typealias Constant = T

    public typealias WME = ReteEngine.WME<T>

    /// The working memory entries
    public private(set) var workingMemoryEntries: Set<WME> = []

    public func makeIterator() -> Set<WME>.Iterator {
        return workingMemoryEntries.makeIterator()
    }

    public mutating func insert(wme: WME) -> Bool {
        let (inserted, _) = workingMemoryEntries.insert(wme)
        return inserted
    }

    public var count: Int {
        return workingMemoryEntries.count
    }
}
