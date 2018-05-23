/// Capable of executing a database queries as defined by `Query`.
public protocol QuerySupporting: Database {
    /// Associated `Query` type. Instances of this type will be supplied to `queryExecute(...)`.
    associatedtype Query: Fluent.Query

    /// Query output type. Can be decoded using `queryDecode(...)`.
    associatedtype Output
    
    /// Executes the supplied query on the database connection. Results should be streamed into the handler.
    /// When the query is finished, the returned future should be completed.
    ///
    /// - parameters:
    ///     - query: Query to execute.
    ///     - handler: Handles query output.
    ///     - conn: Database connection to use.
    /// - returns: A future that will complete when the query has finished.
    static func queryExecute(_ query: Query, on conn: Connection, into handler: @escaping (Output, Connection) throws -> ()) -> Future<Void>

    /// Decodes a decodable type `D` from this database's output.
    ///
    /// - parameters:
    ///     - output: Query output to decode.
    ///     - entity: Entity to decode from (table or collection name).
    ///     - decodable: Decodable type to create.
    /// - returns: Decoded type.
    static func queryDecode<D>(_ output: Output, entity: String, as decodable: D.Type) throws -> D
        where D: Decodable

    /// This method will be called by Fluent during `Model` lifecycle events.
    /// This gives the database a chance to interact with the model before Fluent encodes it.
    static func modelEvent<M>(event: ModelEvent, model: M, on conn: Connection) -> Future<M>
        where M: Model, M.Database == Self
}
