extension QueryBuilder where Database: SQLSupporting {
    // MARK: Group By

    /// Adds a group by to the query builder.
    ///
    ///     query.groupBy(\.name)
    ///
    /// - parameters:
    ///     - field: Swift `KeyPath` to field on model to group by.
    /// - returns: Query builder for chaining.
    public func groupBy<T>(_ field: KeyPath<Result, T>) -> Self {
        return groupBy(.column(Database.queryField(.keyPath(field))))
    }

    /// Adds a manually created group by to the query builder.
    /// - parameters:
    ///     - groupBy: New `Query.GroupBy` to add.
    /// - returns: Query builder for chaining.
    public func groupBy(_ groupBy: SQLQuery.DML.GroupBy) -> Self {
        query.groupBys.append(groupBy)
        return self
    }
}
