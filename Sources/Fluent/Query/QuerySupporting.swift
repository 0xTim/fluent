import Async

/// Capable of executing a database query.
public protocol QuerySupporting: Database {
    /// Executes the supplied query on the database connection.
    /// The returned future will be completed when the query is complete.
    /// Results will be outputed through the query's output stream.
    static func execute(
        query: DatabaseQuery<Self>,
        into handler: @escaping ([QueryField: QueryData], Connection) throws -> (),
        on connection: Connection
    ) -> Future<Void>

    /// Handle model events.
    static func modelEvent<M>(event: ModelEvent, model: M, on connection: Connection) -> Future<M>
        where M: Model, M.Database == Self

    // MARK: Codable

    static func queryEncode<E>(_ encodable: E, entity: String) throws -> [QueryField: QueryData]

    static func queryDecode<D>(_ data: [QueryField: QueryData], entity: String, as decodable: D.Type) throws -> D

    // MARK: Field

    /// This database's native data type.
    associatedtype QueryField: FluentField

    /// Creates a `QueryField` for the supplied `ReflectedProperty`.
    static func queryField(for reflectedProperty: ReflectedProperty) throws -> QueryField

    // MARK: Data

    /// This database's native data type.
    associatedtype QueryData: FluentData

    /// This database's convertible data type.
    /// This type is used in-place of the `QueryData` type wherever the user can input data.
    associatedtype QueryDataConvertible

    /// Serializes a native type to this db's `QueryDataConvertible`.
    static func queryDataSerialize<T>(data: T?) throws -> QueryData

    /// Parses this db's `QueryDataConvertible` into a native type.
    static func queryDataParse<T>(_ type: T.Type, from data: QueryData) throws -> T?

    /// This database's native filter types.
    associatedtype QueryFilter: Equatable
}

public protocol FluentField: Hashable { }

extension QuerySupporting {
    public static func queryField<M, T>(for keyPath: KeyPath<M, T>) throws -> QueryField where M: Model {
        guard let property = try M.reflectProperty(forKey: keyPath) else {
            throw FluentError(identifier: "reflectProperty", reason: "No property reflected for: \(keyPath)", source: .capture())
        }
        return try queryField(for: property)
    }
}

public protocol FluentData {
    var isNull: Bool { get }
}

/// Model events.
public enum ModelEvent {
    case willCreate
    case didCreate
    case willUpdate
    case didUpdate
    case willRead
    case willDelete
}
