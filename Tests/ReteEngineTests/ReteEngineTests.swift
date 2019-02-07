import XCTest
@testable import ReteEngine

final class ReteEngineTests: XCTestCase {

    func testProductionItems() {
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory>(workingMemory: workingMemory)
        let pNode1 = network.addProduction(conditions: [
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
        ])
        XCTAssertEqual(pNode1.items.count, 0)

        network.add(wme: Triple("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 0)

        network.add(wme: Triple("B", "hasBrother", "C"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(
            Set(pNode1.items.map { $0.allBindings }),
            Set([
                ["son": "A",
                 "father": "B",
                 "fathersBrother": "C"]
            ])
        )

        let pNode2 = network.addProduction(conditions: [
            Condition(
                .variable(name: "x"),
                .variable(name: "y"),
                .variable(name: "z")
            )
        ])
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

        network.add(wme: Triple("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemory.count)

        network.add(wme: Triple("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemory.count)

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

        network.add(wme: Triple("D", "hasSister", "F"))
        let pNode3 = network.addProduction(conditions: [
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
        ])
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
    }

    func testNetwork() {
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory>(workingMemory: workingMemory)
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
        network.addProduction(conditions: [c0, c1, c2])

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
        XCTAssertEqual((matchC0c1c2 as? PNode)?.items.count, 1)

        let t0 = Token(parent: Token(), wme: wmes[0])
        let t1 = Token(parent: t0, wme: wmes[4])
        let t2 = Token(parent: t1, wme: wmes[8])
        XCTAssertEqual((matchC0c1c2 as? PNode)?.items[0], t2)
    }

    func testDuplicate() {
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory>(workingMemory: workingMemory)
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
        network.addProduction(conditions: [c0, c1, c2])

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

        XCTAssertEqual((matchForAll as? PNode)?.items.count, 1)
    }

    func testMultiProductions() {
        let workingMemory = SetWorkingMemory<Triple<String>>()
        let network = ReteNetwork<SetWorkingMemory>(workingMemory: workingMemory)
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

        let p0 = network.addProduction(conditions: [c0, c1, c2])
        let p1 = network.addProduction(conditions: [c0, c1, c3, c4])

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

        let p2 = network.addProduction(conditions: [c0, c1, c3, c2])

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
}
