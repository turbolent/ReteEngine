
/// The top-most Rete node.
///
/// The dummy top node is the entry point of the beta part of the Rete network.
///
/// ## CMU-CS-95-113:  2.1 Overview
///
/// > Some Rete implementations do not use a dummy top node and instead have
/// > the uppermost join nodes take inputs from two alpha memories. The use
/// > of a dummy top node, however, simplifies the description and can also
/// > simplify the implementation.
///
public final class DummyTopNode<Constant>: ReteNode<Constant> where Constant: Hashable {}
