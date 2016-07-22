import XCTest
@testable import Fluent

class RelationTests: XCTestCase {
    static let allTests = [
        ("testHasMany", testHasMany),
        ("testBelongsToMany", testBelongsToMany),
    ]

    final class Atom: Entity {
        var id: Node?
        var groupId: Node?

        init(with node: Node, in context: Context) throws {
            id = try node.extract("id")
            groupId = try node.extract("group_id")
        }

        func group() throws -> Group? {
            return try belongsTo(groupId)
        }

        func compounds() throws -> Query<Compound> {
            return try belongsToMany()
        }

        func protons() throws -> Query<Proton> {
            return try hasMany()
        }

        func nucleus() throws -> Nucleus? {
            return try hasOne()
        }

        func makeNode() -> Node { return .null }
        static func prepare(_ database: Database) throws {}
        static func revert(_ database: Database) throws {}
    }

    final class Group: Entity {
        var id: Node?
        init(with node: Node, in context: Context) throws { }

        func makeNode() -> Node { return .null }
        static func prepare(_ database: Database) throws {}
        static func revert(_ database: Database) throws {}
    }

    final class Compound: Entity {
        var id: Node?
        init(with node: Node, in context: Context) throws { }

        func makeNode() -> Node { return .null }
        static func prepare(_ database: Database) throws {}
        static func revert(_ database: Database) throws {}
    }

    final class Proton: Entity {
        var id: Node?
        init(with node: Node, in context: Context) throws { }

        func makeNode() -> Node { return .null }
        static func prepare(_ database: Database) throws {}
        static func revert(_ database: Database) throws {}
    }

    final class Nucleus: Entity {
        static var entity = "nuclei"
        var id: Node?
        init(with node: Node, in context: Context) throws { }

        func makeNode() -> Node { return .null }
        static func prepare(_ database: Database) throws {}
        static func revert(_ database: Database) throws {}
    }

    func testHasMany() throws {
        let hydrogen = try Atom(Node([
            "id": 42,
            "group_id": 1337
        ]))

        _ = try hydrogen.protons().all()
        _ = try hydrogen.nucleus()
        _ = try hydrogen.group()
    }

    func testBelongsToMany() throws {
        let hydrogen = try Atom(Node([
            "id": 42,
            "group_id": 1337
        ]))

        _ = try hydrogen.compounds().all()
    }
}
