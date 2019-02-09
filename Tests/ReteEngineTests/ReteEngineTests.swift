import XCTest
@testable import ReteEngine

private final class TestTarget<WME>: ProductionTarget, Equatable
    where WME: ReteEngine.WME
{
    var activations: [PNode<TestTarget>] = []

    static func == (lhs: TestTarget, rhs: TestTarget) -> Bool {
        return lhs === rhs
    }

    func productionNodeDidActivate(pNode: PNode<TestTarget>) {
        activations.append(pNode)
    }
}

final class ReteEngineTests: XCTestCase {

    func testProductionItems() {
        let testTarget = TestTarget<Triple<String>>()
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory, TestTarget>(workingMemory: workingMemory)
        let rule1: Rule<Triple> = Rule(
            conditions: [
                Condition(
                    .variable(name: "son"),
                    .constant("hasFather"),
                    .variable(name: "father")
                ),
                Condition(
                    .variable(name: "father"),
                    .constant("hasBrother"),
                    .variable(name: "fathersBrother")
                )
            ],
            actions: []
        )
        let pNode1 = network.addProduction(
            rule: rule1,
            target: testTarget
        )
        XCTAssertEqual(pNode1.items.count, 0)
        XCTAssertEqual(testTarget.activations, [])
        testTarget.activations.removeAll()

        network.add(wme: Triple("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 0)
        XCTAssertEqual(testTarget.activations, [])
        testTarget.activations.removeAll()

        network.add(wme: Triple("B", "hasBrother", "C"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(testTarget.activations, [pNode1])
        testTarget.activations.removeAll()
        XCTAssertEqual(
            Set(pNode1.items.map { $0.allBindings }),
            Set([
                ["son": "A",
                 "father": "B",
                 "fathersBrother": "C"]
            ])
        )

        let rule2 = Rule<Triple<String>>(
            conditions: [
                Condition<Triple<String>>(
                    .variable(name: "x"),
                    .variable(name: "y"),
                    .variable(name: "z")
                )
            ],
            actions: []
        )
        let pNode2 = network.addProduction(
            rule: rule2,
            target: testTarget
        )
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(
            pNode2.items.count,
            network.workingMemory.count
        )
        XCTAssertEqual(
            Set(pNode2.items.map { $0.allBindings }),
            Set([
                ["x": "A", "y": "hasFather", "z": "B"],
                ["x": "B", "y": "hasBrother", "z": "C"],
            ])
        )
        XCTAssertEqual(testTarget.activations, [pNode2, pNode2])
        testTarget.activations.removeAll()

        network.add(wme: Triple("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemory.count)
        XCTAssertEqual(testTarget.activations, [])

        network.add(wme: Triple("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemory.count)
        XCTAssertEqual(testTarget.activations, [])

        network.add(wme: Triple("A", "hasFather", "D"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemory.count)
        XCTAssertEqual(
            Set(pNode1.items.map { $0.allBindings }),
            Set([
                ["son": "A",
                 "father": "B",
                 "fathersBrother": "C"]
            ])
        )
        XCTAssertEqual(
            Set(pNode2.items.map { $0.allBindings }),
            Set([
                ["x": "A", "y": "hasFather", "z": "B"],
                ["x": "A", "y": "hasFather", "z": "D"],
                ["x": "B", "y": "hasBrother", "z": "C"],
            ])
        )
        XCTAssertEqual(testTarget.activations, [pNode2])
        testTarget.activations.removeAll()

        network.add(wme: Triple("D", "hasBrother", "E"))
        XCTAssertEqual(pNode1.items.count, 2)
        XCTAssertEqual(pNode2.items.count, network.workingMemory.count)
        XCTAssertEqual(
            Set(pNode1.items.map { $0.allBindings }),
            Set([
                ["son": "A",
                 "father": "B",
                 "fathersBrother": "C"],
                ["son": "A",
                 "father": "D",
                 "fathersBrother": "E"],
                ])
        )
        XCTAssertEqual(
            Set(pNode2.items.map { $0.allBindings }),
            Set([
                ["x": "A", "y": "hasFather", "z": "B"],
                ["x": "A", "y": "hasFather", "z": "D"],
                ["x": "B", "y": "hasBrother", "z": "C"],
                ["x": "D", "y": "hasBrother", "z": "E"],
            ])
        )
        XCTAssertEqual(testTarget.activations, [pNode1, pNode2])
        testTarget.activations.removeAll()

        network.add(wme: Triple("D", "hasSister", "F"))
        let rule3 = Rule<Triple>(
            conditions: [
                Condition(
                    .variable(name: "son"),
                    .constant("hasFather"),
                    .variable(name: "father")
                ),
                Condition(
                    .variable(name: "father"),
                    .constant("hasSister"),
                    .variable(name: "fathersSister")
                )
            ],
            actions: []
        )
        let pNode3 = network.addProduction(
            rule: rule3,
            target: testTarget
        )
        XCTAssertEqual(pNode1.items.count, 2)
        XCTAssertEqual(pNode2.items.count, network.workingMemory.count)
        XCTAssertEqual(pNode3.items.count, 1)
        XCTAssertEqual(
            Set(pNode1.items.map { $0.allBindings }),
            Set([
                ["son": "A",
                 "father": "B",
                 "fathersBrother": "C"],
                ["son": "A",
                 "father": "D",
                 "fathersBrother": "E"],
                ])
        )
        XCTAssertEqual(
            Set(pNode2.items.map { $0.allBindings }),
            Set([
                ["x": "A", "y": "hasFather", "z": "B"],
                ["x": "A", "y": "hasFather", "z": "D"],
                ["x": "B", "y": "hasBrother", "z": "C"],
                ["x": "D", "y": "hasBrother", "z": "E"],
                ["x": "D", "y": "hasSister", "z": "F"],
            ])
        )
        XCTAssertEqual(
            Set(pNode3.items.map { $0.allBindings }),
            Set([
                ["son": "A",
                 "father": "D",
                 "fathersSister": "F"],
            ])
        )
        XCTAssertEqual(testTarget.activations, [pNode2, pNode3])
        testTarget.activations.removeAll()
    }

    func testNetwork() {
        let testTarget = TestTarget<Triple<String>>()
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory, TestTarget>(workingMemory: workingMemory)
        let c0 = Condition<Triple>(
            .variable(name: "x"),
            .constant("on"),
            .variable(name: "y")
        )
        let c1 = Condition<Triple>(
            .variable(name: "y"),
            .constant("left-of"),
            .variable(name: "z")
        )
        let c2 = Condition<Triple>(
            .variable(name: "z"),
            .constant("color"),
            .constant("red")
        )
        let rule = Rule(
            conditions: [c0, c1, c2],
            actions: []
        )
        network.addProduction(
            rule: rule,
            target: testTarget
        )

        let am0 = network.buildOrShareAlphaMemory(condition: c0)
        let am1 = network.buildOrShareAlphaMemory(condition: c1)
        let am2 = network.buildOrShareAlphaMemory(condition: c2)
        let dummyJoin = am0.successors[0]
        let joinOnValueY = am1.successors[0]
        let joinOnValueZ = am2.successors[0]
        let matchC0 = dummyJoin.children[0]
        let matchC0c1 = joinOnValueY.children[0]
        let matchC0c1c2 = joinOnValueZ.children[0]

        let wmes = [
            Triple("B1", "on", "B2"),
            Triple("B1", "on", "B3"),
            Triple("B1", "color", "red"),
            Triple("B2", "on", "table"),
            Triple("B2", "left-of", "B3"),
            Triple("B2", "color", "blue"),
            Triple("B3", "left-of", "B4"),
            Triple("B3", "on", "table"),
            Triple("B3", "color", "red")
        ]
        for wme in wmes {
            network.add(wme: wme)
        }

        XCTAssertEqual(am0.items, [wmes[0], wmes[1], wmes[3], wmes[7]])
        XCTAssertEqual(am1.items, [wmes[4], wmes[6]])
        XCTAssertEqual(am2.items, [wmes[2], wmes[8]])
        XCTAssertEqual((matchC0 as? BetaMemory)?.items.count, 4)
        XCTAssertEqual((matchC0c1 as? BetaMemory)?.items.count, 2)
        XCTAssertEqual((matchC0c1c2 as? PNode<TestTarget>)?.items.count, 1)

        let t0 = Token(parent: Token(), wme: wmes[0])
        let t1 = Token(parent: t0, wme: wmes[4])
        let t2 = Token(parent: t1, wme: wmes[8])
        XCTAssertEqual((matchC0c1c2 as? PNode<TestTarget>)?.items[0], t2)
    }

    func testDuplicate() {
        let testTarget = TestTarget<Triple<String>>()
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory, TestTarget>(workingMemory: workingMemory)
        let c0 = Condition<Triple>(
            .variable(name: "x"),
            .constant("self"),
            .variable(name: "y")
        )
        let c1 = Condition<Triple>(
            .variable(name: "x"),
            .constant("color"),
            .constant("red")
        )
        let c2 = Condition<Triple>(
            .variable(name: "y"),
            .constant("color"),
            .constant("red")
        )
        let rule = Rule(
            conditions: [c0, c1, c2],
            actions: []
        )
        network.addProduction(
            rule: rule,
            target: testTarget
        )

        let wmes = [
            Triple("B1", "self", "B1"),
            Triple("B1", "color", "red"),
        ]
        for wme in wmes {
            network.add(wme: wme)
        }

        let am = network.buildOrShareAlphaMemory(condition: c2)
        let joinOnValueY = am.successors[1]
        let matchForAll = joinOnValueY.children[0]

        XCTAssertEqual((matchForAll as? PNode<TestTarget>)?.items.count, 1)
    }

    func testMultiProductions() {
        let testTarget = TestTarget<Triple<String>>()
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory, TestTarget>(workingMemory: workingMemory)
        let c0 = Condition<Triple>(
            .variable(name: "x"),
            .constant("on"),
            .variable(name: "y")
        )
        let c1 = Condition<Triple>(
            .variable(name: "y"),
            .constant("left-of"),
            .variable(name: "z")
        )
        let c2 = Condition<Triple>(
            .variable(name: "z"),
            .constant("color"),
            .constant("red")
        )
        let c3 = Condition<Triple>(
            .variable(name: "z"),
            .constant("on"),
            .constant("table")
        )
        let c4 = Condition<Triple>(
            .variable(name: "z"),
            .constant("left-of"),
            .constant("B4")
        )

        let rule0 = Rule(
            conditions: [c0, c1, c2],
            actions: []
        )
        let p0 = network.addProduction(
            rule: rule0,
            target: testTarget
        )
        let rule1 = Rule(
            conditions: [c0, c1, c3, c4],
            actions: []
        )
        let p1 = network.addProduction(
            rule: rule1,
            target: testTarget
        )

        let wmes = [
            Triple("B1", "on", "B2"),
            Triple("B1", "on", "B3"),
            Triple("B1", "color", "red"),
            Triple("B2", "on", "table"),
            Triple("B2", "left-of", "B3"),
            Triple("B2", "color", "blue"),
            Triple("B3", "left-of", "B4"),
            Triple("B3", "on", "table"),
            Triple("B3", "color", "red"),
            ]
        for wme in wmes {
            network.add(wme: wme)
        }

        let rule2 = Rule(
            conditions: [c0, c1, c3, c2],
            actions: []
        )
        let p2 = network.addProduction(
            rule: rule2,
            target: testTarget
        )

        XCTAssertEqual(p0.items.count, 1)
        XCTAssertEqual(p1.items.count, 1)
        XCTAssertEqual(p2.items.count, 1)
        XCTAssertEqual(p0.items[0].workingMemoryEntries, [wmes[0], wmes[4], wmes[8]])
        XCTAssertEqual(p1.items[0].workingMemoryEntries, [wmes[0], wmes[4], wmes[7], wmes[6]])
        XCTAssertEqual(p2.items[0].workingMemoryEntries, [wmes[0], wmes[4], wmes[7], wmes[8]])

    }

    func testTokenBinding() {
        let t1 = Token<Triple>(bindings: ["x": 1])
        let t2 = Token<Triple>(parent: t1, bindings: ["y": 2])
        let t3 = Token<Triple>(parent: t2, bindings: ["z": 3])

        XCTAssertEqual(t3.allBindings, ["x": 1, "y": 2, "z": 3])
        XCTAssertEqual(t3.getBinding(variableName: "x"), 1)
        XCTAssertEqual(t3.getBinding(variableName: "y"), 2)
        XCTAssertEqual(t3.getBinding(variableName: "z"), 3)
    }

    func testActionPatternSubstitution() {
        let p1 = ActionPattern<Triple<String>>(
            .variable(name: "x"),
            .variable(name: "y"),
            .variable(name: "z")
        )
        XCTAssertEqual(
            p1.substitute(bindings: ["x": "1", "y": "2", "z": "3"]),
            Triple("1", "2", "3")
        )
        XCTAssertEqual(
            p1.substitute(bindings: ["x": "1", "z": "3"]),
            nil
        )
    }

    func testRuleAction() {
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory, ForwardTarget<SetWorkingMemory>>(workingMemory: workingMemory)
        let forwardTarget = ForwardTarget(network: network)

        // RDF(S) Entailment Rule 6: (?a ?p ?b) ^ (?p subPropertyOf ?q) => add(?a ?q ?b)

        let rdfs6 = Rule<Triple>(
            conditions: [
                Condition(
                    .variable(name: "a"),
                    .variable(name: "p"),
                    .variable(name: "b")
                ),
                Condition(
                    .variable(name: "p"),
                    .constant("subPropertyOf"),
                    .variable(name: "q")
                ),
                ],
            actions: [
                .add(ActionPattern(
                    .variable(name: "a"),
                    .variable(name: "q"),
                    .variable(name: "b")
                ))
            ]
        )

        network.addProduction(rule: rdfs6, target: forwardTarget)

        network.add(wme: Triple("A", "hasChild", "B"))
        network.add(wme: Triple("hasChild", "subPropertyOf", "hasAncestor"))

        XCTAssertEqual(
            workingMemory.workingMemoryEntries,
            [
                Triple("A", "hasChild", "B"),
                Triple("hasChild", "subPropertyOf", "hasAncestor"),
                Triple("A", "hasAncestor", "B"),
            ]
        )

        network.add(wme: Triple("hasAncestor", "subPropertyOf", "isRelatedTo"))
        XCTAssertEqual(
            workingMemory.workingMemoryEntries,
            [
                Triple("A", "hasChild", "B"),
                Triple("hasChild", "subPropertyOf", "hasAncestor"),
                Triple("A", "hasAncestor", "B"),
                Triple("hasAncestor", "subPropertyOf", "isRelatedTo"),
                Triple("A", "isRelatedTo", "B")
            ]
        )
    }
}
