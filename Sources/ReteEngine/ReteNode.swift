
/// A node in the beta part of the Rete network.
///
/// A Rete node stores its children (other nodes in the beta part of the network)
/// and has a pointer to its parent node, if any.
///
/// ## CMU-CS-95-113:  2.3.2 Beta Memory Implementation
///
/// > [...] plus a list of its children (other nodes in the beta part of the network).
///
/// > Each node in the beta part of the net will be represented by a rete-node structure:
///
/// ```
/// structure rete-node:
///     type: "beta-memory", "join-node", or "p-node"
///     children: list of rete-node
///     parent: rete-node
///
/// end
/// ```
///
public class ReteNode<WME>
    where WME: ReteEngine.WME
{
    public typealias Constant = WME.Constant
    public typealias Token = ReteEngine.Token<WME>
    public typealias ReteNode = ReteEngine.ReteNode<WME>

    /// The node's children (other nodes in the beta part of the network).
    public private(set) var children: [ReteNode]

    /// The node's parent node.
    public weak var parent: ReteNode?

    /// Creates a new Rete node for the given children and parent node, if any.
    ///
    public init(children: [ReteNode] = [], parent: ReteNode? = nil) {
        self.children = children
        self.parent = parent
    }

    /// Inserts the given child to the stored children.
    ///
    /// - Parameter child: The new child node.
    ///
    internal func add(child: ReteNode) {
        children.append(child)
    }

    /// Performs the given function while temporarily setting this node's children
    /// to the given temporary children.
    ///
    /// While the function is running, this node's children are set to the temporary
    /// children. After the function returned, the node's children are set back to
    /// the original children.
    ///
    internal func with(temporaryChildren: [ReteNode], _ f: () -> Void) {
        let savedListOfChildren = children
        defer {
            children = savedListOfChildren
        }

        children = temporaryChildren

        f()
    }

    /// Informs the node of the insertion of a new working memory entry.
    ///
    /// - Parameter wme: The inserted working memory entry.
    ///
    func rightActivation(wme: WME) {}

    /// Informs the node of a new match (a token and a working memory entry).
    ///
    /// - Parameters:
    ///   - token: The matching token (partial instantiation of a production).
    ///   - wme: The matching working memory entry.
    ///   - bindings: The variable bindings.
    ///
    func leftActivation(
        token: Token,
        wme: WME? = nil,
        bindings: [String: Constant] = [:]
    ) {}
}
