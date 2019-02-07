
public protocol ProductionTarget: AnyObject, Equatable {
    associatedtype WME: ReteEngine.WME

    func productionNodeDidActivate(pNode: PNode<Self>)
}
