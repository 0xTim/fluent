extension SQLDatabase {
    /// See `MigrationSupporting`.
    public static func prepareMigrationMetadata(on conn: Connection) -> Future<Void> {
        return MigrationLog<Self>.prepareMetadata(on: conn)
    }
}

// MARK: Private

extension MigrationLog: Migration where Database: SQLDatabase { }

private extension MigrationLog where Database: SQLDatabase {
    /// Prepares the connection for storing migration logs.
    /// - note: this is unlike other migrations since we are checking
    ///         for an error instead of asking if the migration has already prepared.
    static func prepareMetadata(on conn: Database.Connection) -> Future<Void> {
        let promise = conn.eventLoop.newPromise(Void.self)

        conn.query(MigrationLog<Database>.self).count().do { count in
            promise.succeed()
        }.catch { err in
            // table needs to be created
            prepare(on: conn).cascade(promise: promise)
        }

        return promise.futureResult
    }

    /// For parity, reverts the migration metadata.
    /// This simply calls the migration revert function.
    static func revertMetadata(on connection: Database.Connection) -> Future<Void> {
        return revert(on: connection)
    }
}
