import XCTest
@testable import Fluent

class RelationTests: XCTestCase {
    static let allTests = [
        ("testHasMany", testHasMany),
        ("testBelongsToMany", testBelongsToMany),
        ("testCustomForeignKey", testCustomForeignKey),
        ("testPivotDatabase", testPivotDatabase),
    ]

    var memory: MemoryDriver!
    var database: Database!
    let ents = [Atom.self, Proton.self, Nucleus.self, Group.self] as [Entity.Type]

    override func setUp() {
        memory = try! MemoryDriver()
        database = Database(memory)

        try! ents.forEach { ent in
            ent.database = database
            try ent.prepare(database)
        }
    }

    override func tearDown() {
        try! ents.forEach { ent in try ent.revert(database) }
    }

    func testHasMany() throws {

        let hydrogen = try Atom(node: [
            Atom.idKey: 42,
            "name": "Hydrogen",
            "group_id": 1337
        ])

        let protons = try hydrogen.protons()
        _ = try protons.all()
        _ = try hydrogen.nucleus()
        _ = try hydrogen.group()
    }

    func testBelongsToMany() throws {
        let hydrogen = try Atom(node: [
            "name": "Hydrogen",
            "group_id": 1337
        ])
        try hydrogen.save()
        hydrogen.id = 42
        try hydrogen.save()

        let water = try Compound(node: [
            "name": "Water"
        ])
        try water.save()
        water.id = 1337
        try water.save()

        let pivot = try Pivot<Atom, Compound>(hydrogen, water)
        try pivot.save()

        _ = try hydrogen.compounds.all()
    }

    func testCustomForeignKey() throws {
        let hydrogen = try Atom(node: [
            Atom.idKey: 42,
            "name": "Hydrogen",
            "group_id": 1337
        ])
        Atom.database = database
        Nucleus.database = database

        do {
            let query = try hydrogen.children(type: Nucleus.self).makeQuery()
            let (sql, _) = GeneralSQLSerializer(sql: query.sql).serialize()
            print(sql)
        } catch {
            print(error)
        }
    }
    
    func testPivotDatabase() throws {
        Pivot<Atom, Nucleus>.database = database
        XCTAssertTrue(Pivot<Atom, Nucleus>.database === database)
        XCTAssertTrue(Pivot<Nucleus, Atom>.database === database)
    }
}
