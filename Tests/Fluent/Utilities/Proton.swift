import Fluent

final class Proton: Entity {
    var id: Node?
    init(with node: Node, in context: Context) throws {}

    func makeNode() -> Node { return .null }
    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}
}
