import Async
import Dispatch
import Fluent
import Foundation

extension Benchmarker where Database: QuerySupporting & TransactionSupporting {
    /// The actual benchmark.
    fileprivate func _benchmark(on conn: Database.Connection) throws {
        // create
        let tanner = User<Database>(name: "Tanner", age: 23)
        _ = try test(tanner.save(on: conn))

        do {
            _ = try Database.transaction(on: conn) { conn in
                /// create 100 users
                var saves: [Future<User<Database>>] = []
                for i in 1...100 {
                    let user = User<Database>(name: "User \(i)", age: i)
                    saves.append(user.save(on: conn))
                }

                return saves.flatMap(to: Void.self) { _ in
                    return conn.query(User<Database>.self).count().map(to: Void.self) { count in
                        if count != 101 {
                            self.fail("count should be 101")
                        }

                        throw FluentBenchmarkError(identifier: "test", reason: "rollback")
                    }
                }

            }.await(on: eventLoop)
        } catch is FluentBenchmarkError {
            // expected
        }

        let count = try test(conn.query(User<Database>.self).count())
        if count != 1 {
            self.fail("count must have been restored to one")
            return
        }
    }

    /// Benchmark fluent transactions.
    public func benchmarkTransactions() throws {
        let conn = try test(pool.requestConnection())
        try self._benchmark(on: conn)
        pool.releaseConnection(conn)
    }
}

extension Benchmarker where Database: QuerySupporting & TransactionSupporting & SchemaSupporting {
    /// Benchmark fluent transactions.
    /// The schema will be prepared first.
    public func benchmarkTransactions_withSchema() throws {
        let conn = try test(pool.requestConnection())
        try test(UserMigration<Database>.prepare(on: conn))
        defer {
            try? test(UserMigration<Database>.revert(on: conn))
        }
        try self._benchmark(on: conn)
        pool.releaseConnection(conn)
    }
}


