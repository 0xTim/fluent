import Fluent

class LastQueryDriver: Driver {
    var keyNamingConvention: KeyNamingConvention = .snake_case
    var idType: IdentifierType = .int
    let idKey: String = "#id"
    var log: QueryLogCallback?

    var lastQuery: (String, [Node])?
    var lastRaw: (String, [Node])?
    
    public func makeConnection(_ type: ConnectionType) throws -> Connection {
        return LastQueryConnection(driver: self)
    }
}

class LastQueryConnection: Connection {
    public var isClosed: Bool = false
    
    var driver: LastQueryDriver
    var log: QueryLogCallback?
    
    init(driver: LastQueryDriver) {
        self.driver = driver
    }
    
    @discardableResult
    func query<E: Entity>(_ query: RawOr<Query<E>>) throws -> Node {
        switch query {
        case .raw(let raw, let values):
            driver.lastRaw = (raw, values)
            return .null
        case .some(let query):
            let serializer = GeneralSQLSerializer(query)
            driver.lastQuery = serializer.serialize()
            return try Node(node: [
                [
                    E.idKey: 5
                ]
            ], in: nil)
        }
    }
}
