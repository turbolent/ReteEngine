import XCTest
@testable import ReteEngine

final class ReteEngineTests: XCTestCase {

    func testProductionItems() {
        let network = ReteNetwork<String>()
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

        network.add(wme: WME("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 0)

        network.add(wme: WME("B", "hasBrother", "C"))
        XCTAssertEqual(pNode1.items.count, 1)

        let pNode2 = network.addProduction(conditions: [
            Condition(
                .variable(name: "x"),
                .variable(name: "y"),
                .variable(name: "z")
            )
        ])
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemoryEntries.count)

        network.add(wme: WME("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemoryEntries.count)
        network.add(wme: WME("A", "hasFather", "B"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemoryEntries.count)

        network.add(wme: WME("A", "hasFather", "D"))
        XCTAssertEqual(pNode1.items.count, 1)
        XCTAssertEqual(pNode2.items.count, network.workingMemoryEntries.count)

        network.add(wme: WME("D", "hasBrother", "E"))
        XCTAssertEqual(pNode1.items.count, 2)
        XCTAssertEqual(pNode2.items.count, network.workingMemoryEntries.count)

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
            ),
            ])
        XCTAssertEqual(pNode1.items.count, 2)
        XCTAssertEqual(pNode2.items.count, network.workingMemoryEntries.count)
        XCTAssertEqual(pNode3.items.count, 0)

        network.add(wme: WME("D", "hasSister", "F"))
        XCTAssertEqual(pNode1.items.count, 2)
        XCTAssertEqual(pNode2.items.count, network.workingMemoryEntries.count)
        XCTAssertEqual(pNode3.items.count, 1)
    }

    func testNetwork() {
        let network = ReteNetwork<String>()
        let c0 = Condition(
            .variable(name: "x"),
            .constant("on"),
            .variable(name: "y")
        )
        let c1 = Condition(
            .variable(name: "y"),
            .constant("left-of"),
            .variable(name: "z")
        )
        let c2 = Condition(
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
            WME("B1", "on", "B2"),
            WME("B1", "on", "B3"),
            WME("B1", "color", "red"),
            WME("B2", "on", "table"),
            WME("B2", "left-of", "B3"),
            WME("B2", "color", "blue"),
            WME("B3", "left-of", "B4"),
            WME("B3", "on", "table"),
            WME("B3", "color", "red")
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

        let t0 = Token(parent: Token(parent: nil, wme: nil), wme: wmes[0])
        let t1 = Token(parent: t0, wme: wmes[4])
        let t2 = Token(parent: t1, wme: wmes[8])
        XCTAssertEqual((matchC0c1c2 as? PNode)?.items[0], t2)
    }

    func testDuplicate() {
        let network = ReteNetwork<String>()
        let c0 = Condition(
            .variable(name: "x"),
            .constant("self"),
            .variable(name: "y")
        )
        let c1 = Condition(
            .variable(name: "x"),
            .constant("color"),
            .constant("red")
        )
        let c2 = Condition(
            .variable(name: "y"),
            .constant("color"),
            .constant("red")
        )
        network.addProduction(conditions: [c0, c1, c2])

        let wmes = [
            WME("B1", "self", "B1"),
            WME("B1", "color", "red"),
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
        let net = ReteNetwork<String>()
        let c0 = Condition(.variable(name: "x"), .constant("on"), .variable(name: "y"))
        let c1 = Condition(.variable(name: "y"), .constant("left-of"), .variable(name: "z"))
        let c2 = Condition(.variable(name: "z"), .constant("color"), .constant("red"))
        let c3 = Condition(.variable(name: "z"), .constant("on"), .constant("table"))
        let c4 = Condition(.variable(name: "z"), .constant("left-of"), .constant("B4"))

        let p0 = net.addProduction(conditions: [c0, c1, c2])
        let p1 = net.addProduction(conditions: [c0, c1, c3, c4])

        let wmes = [
            WME("B1", "on", "B2"),
            WME("B1", "on", "B3"),
            WME("B1", "color", "red"),
            WME("B2", "on", "table"),
            WME("B2", "left-of", "B3"),
            WME("B2", "color", "blue"),
            WME("B3", "left-of", "B4"),
            WME("B3", "on", "table"),
            WME("B3", "color", "red"),
            ]
        for wme in wmes {
            net.add(wme: wme)
        }

        let p2 = net.addProduction(conditions: [c0, c1, c3, c2])

        XCTAssertEqual(p0.items.count, 1)
        XCTAssertEqual(p1.items.count, 1)
        XCTAssertEqual(p2.items.count, 1)
        XCTAssertEqual(p0.items[0].workingMemoryEntries, [wmes[0], wmes[4], wmes[8]])
        XCTAssertEqual(p1.items[0].workingMemoryEntries, [wmes[0], wmes[4], wmes[7], wmes[6]])
        XCTAssertEqual(p2.items[0].workingMemoryEntries, [wmes[0], wmes[4], wmes[7], wmes[8]])

    }
}
