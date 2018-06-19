struct Galaxy<Database>: Model where Database: QuerySupporting {
    typealias ID = UUID
    static var idKey: IDKey { return \.id }
    var id: UUID?
    var name: String
    init(id: UUID? = nil, name: String) {
        self.name = name
    }
}

extension Galaxy: AnyMigration, Migration where
    Database: SchemaSupporting & MigrationSupporting { }
