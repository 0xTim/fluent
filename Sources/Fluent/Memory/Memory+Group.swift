import Node

extension MemoryDriver {
    final class Group {
        var increment: Int
        var data: [Node]

        func create(_ node: Node, idKey: String) -> Int {
            increment += 1
            var node = node

            if var n = node.nodeObject {
                n[idKey] = Node.number(.int(increment))
                node = Node.object(n)
            }

            data.append(node)
            return increment
        }

        func delete(_ filters: [Filter]) {
            data = data.fails(filters)
        }

        func fetch(_ filters: [Filter]) -> [Node] {
            return data.passes(filters)
        }

        func modify(_ update: Node, filters: [Filter]) -> [Node] {
            var modified: [Node] = []

            for (key, node) in data.enumerated() {
                if node.passes(filters) {
                    data[key] = update
                    modified += update
                }
            }

            return modified
        }

        init() {
            increment = 0
            data = []
        }
    }
}
