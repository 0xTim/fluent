import Async
import Foundation

/// A Fluent database query builder.
public final class QueryBuilder<Model> where Model: Fluent.Model, Model.Database: QuerySupporting {
    /// The query we are building
    public var query: DatabaseQuery<Model.Database>

    /// The connection this query will be excuted on.
    /// note: don't call execute manually or fluent's
    /// hooks will not run properly.
    internal let connection: Future<Model.Database.Connection>

    /// Create a new query.
    public init(
        _ model: Model.Type = Model.self,
        on connection: Future<Model.Database.Connection>
    ) {
        query = DatabaseQuery(entity: Model.entity)
        self.connection = connection
    }

    /// Creates a result stream.
    public func run<D>(decoding type: D.Type) -> QueryResultStream<D, Model.Database> where D: Decodable {
        /// if the model is soft deletable, and soft deleted
        /// models were not requested, then exclude them
        if
            let type = Model.self as? AnySoftDeletable.Type,
            !self.query.withSoftDeleted
        {
            let deletedAtKey = D.unsafeCodingPath(forKey: type.anyDeletedAtKey)
            let deletedAtField = QueryField(entity: type.entity, name: deletedAtKey[0].stringValue)

            try! self.group(.or) { or in
                let notDeleted = QueryFilter<Model.Database>(
                    entity: type.entity,
                    method: .compare(deletedAtField, .equality(.equals), .value(Date.null))
                )
                or.addFilter(notDeleted)

                let notYetDeleted = QueryFilter<Model.Database>(
                    entity: type.entity,
                    method: .compare(deletedAtField, .order(.greaterThan), .value(Date()))
                )
                or.addFilter(notYetDeleted)
            }
        }

        return QueryResultStream(query: query, on: connection)
    }

    /// Convenience run that defaults to outputting a
    /// stream of the QueryBuilder's model type.
    /// Note: this also sets the model's ID if the ID
    /// type is autoincrement.
    public func run() -> QueryResultStream<Model, Model.Database> {
        let stream = self.run(decoding: Model.self)

        stream.outputMap = { output, conn in
            return Model.Database.modelEvent(
                event: .didRead, model: output, on: conn
            ).flatMap(to: Void.self) {
                return try output.didRead(on: conn)
            }.map(to: Model.self) {
                return output
            }

        }

        return stream
    }

    // Create a new query build with the same connection.
    internal func copy() -> QueryBuilder<Model> {
        return QueryBuilder(on: connection)
    }
}
