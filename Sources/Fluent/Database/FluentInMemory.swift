
class FluentInMemory: Driver {
    public var idKey: String = "id"
    
    internal var memory: Memory = Memory()
    
    @discardableResult
    func query<T: Entity>(_ query: Query<T>) throws -> Node {
        switch query.action {
        case .create:
            if let data = query.data {
                try self.memory.set(query.entity, data: data)
            } else {
                try self.memory.make(query.entity)
            }
            
            return .null
        case .delete:
            if let data = query.data {
                if let nodeObject = data.nodeObject,
                    let id = nodeObject[idKey]?.int {
                    try self.memory.remove(query.entity, at: id)
                    return .null
                }
            } else if let filter = query.filters.first {
                try self.memory.remove(query.entity, filter: filter)
                return .null    
            }
        
            try self.memory.remove(query.entity)
            return .null
            
        case .fetch:
            return try self.memory.get(query.entity, filters: query.filters)
        case .modify:
            if let data = query.data {
                if let filter = query.filters.first {
                    try self.memory.update(query.entity, data: data, filter: filter)
                    return .null
                } else {
                    if let nodeObject = data.nodeObject,
                       let idString = nodeObject[idKey] {
                        let filter = Filter.init(T.self, .compare(idKey, .equals, idString))
                        try self.memory.update(query.entity, data: data, filter: filter)
                        return .null
                    }
                }
            }
            throw FluentInMemoryError.cannotUpdate(query.entity)
        }
    }
    
    func schema(_ schema: Schema) throws {
        throw FluentInMemoryError.notSupported
    }
    
    @discardableResult
    func raw(_ raw: String, _ values: [Node]) throws -> Node {
        throw FluentInMemoryError.notSupported
    }
}

enum FluentInMemoryError: Error {
    case notSupported
    case cannotUpdate(String)
}
