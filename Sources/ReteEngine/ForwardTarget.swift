
public final class ForwardTarget<WorkingMemory>: ProductionTarget, Equatable
    where WorkingMemory: ReteEngine.WorkingMemory
{
    public typealias WME = WorkingMemory.WME
    public typealias ReteNetwork =
        ReteEngine.ReteNetwork<WorkingMemory, ForwardTarget<WorkingMemory>>

    public let network: ReteNetwork

    public init(network: ReteNetwork) {
        self.network = network
    }

    public func productionNodeDidActivate(pNode: PNode<ForwardTarget>) {
        pNode.actions.forEach { action in
            pNode.items.forEach { item in
                switch action {
                case let .add(pattern):
                    pattern.substitute(getBinding: item.getBinding)
                        .map(network.add)
                }
            }
        }
    }

    public static func == (lhs: ForwardTarget, rhs: ForwardTarget) -> Bool {
        return lhs === rhs
    }
}
