import Fluent
import SQL

extension DatabaseSchema {
    /// Converts a database schema to sql schema query
    public func makeSchemaQuery() -> SchemaQuery {
        let schemaStatement: SchemaStatement

        switch action {
        case .create:
            schemaStatement = .create(
                columns: addFields.map { $0.makeSchemaColumn() },
                foreignKeys: []
            )
        case .update:
            schemaStatement = .alter(
                columns: addFields.map {
                    $0.makeSchemaColumn()
                },
                deleteColumns: removeFields,
                deleteForeignKeys: []
            )
        case .delete:
            schemaStatement = .drop
        }

        return SchemaQuery(statement: schemaStatement, table: entity)
    }
}
