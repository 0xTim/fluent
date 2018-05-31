extension QueryBuilder {
    // MARK: CRUD

    /// Performs an `create` action on the database with the supplied data.
    ///
    ///     // creates a new User with custom data.
    ///     User.query(on: conn).create(data: ["name": "Vapor"])
    ///
    /// - warning: This method will not invoke model lifecycle hooks.
    ///
    /// - parameters:
    ///     - data: Encodable data to create.
    /// - returns: A `Future` that will be completed when the create is done.
    public func create<E>(data: E) -> Future<Void> where E: Encodable {
        return crud(Database.queryActionCreate, data)
    }

    /// Performs an `update` action on the database with the supplied data.
    ///
    ///     // set all users' names to "Vapor"
    ///     User.query(on: conn).update(data: ["name": "Vapor"])
    ///
    /// - warning: This method will not invoke model lifecycle hooks.
    ///
    /// - parameters:
    ///     - data: Encodable data to update.
    /// - returns: A `Future` that will be completed when the update is done.
    public func update<E>(data: E) -> Future<Void> where E: Encodable {
        return crud(Database.queryActionUpdate, data)
    }

    // MARK: Private

    /// Internal CRUD implementation.
    private func crud<E>(_ action: Database.QueryAction, _ data: E) -> Future<Void> where E: Encodable {
        return connection.flatMap { conn in
            try Database.queryDataApply(Database.queryEncode(data, entity: Database.queryEntity(for: self.query)), to: &self.query)
            return self.run(action)
        }
    }
}
