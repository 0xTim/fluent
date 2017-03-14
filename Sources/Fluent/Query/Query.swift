/// Represents an abstract database query.
public final class Query<T: Entity> {
    /// The type of action to perform
    /// on the data. Defaults to `.fetch`
    public var action: Action

    /// An array of filters to apply
    ///during the query's action.
    public var filters: [Filter]

    /// Optional data to be used during
    ///`.create` or `.updated` actions.
    public var data: Node?

    /// Optionally limit the amount of
    /// entities affected by the action.
    public var limit: Limit?

    /// An array of sorts that will
    /// be applied to the results.
    public var sorts: [Sort]

    /// An array of joins: other entities
    /// that will be queried during this query's
    /// execution.
    public var joins: [Join]

    private(set) lazy var context: RowContext = {
        let context = RowContext()
        context.database = self.database
        return context
    }()

    /// Creates a new `Query` with the
    /// `Model`'s database.
    public init(_ database: Database) {
        filters = []
        action = .fetch
        self.database = database
        joins = []
        sorts = []
    }

    /// Performs the Query returning the raw
    /// Node data from the driver.
    @discardableResult
    public func raw() throws -> Node {
        return try database.query(self)
    }

    //MARK: Internal

    /// The database to which the query
    /// should be sent.
    internal let database: Database
}

extension Query: QueryRepresentable {
    /// Conformance to `QueryRepresentable`
    public func makeQuery() -> Query<T> {
        return self
    }
}
