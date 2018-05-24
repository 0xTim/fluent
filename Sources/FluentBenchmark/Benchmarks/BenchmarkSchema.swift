import Async
import Dispatch
import Fluent
import FluentSQL
import Foundation

extension Benchmarker where Database: QuerySupporting & SQLDatabase {
    /// Benchmark the basic schema creations.
    public func benchmarkSchema() throws {
        let conn = try test(pool.requestConnection())
        try test(KitchenSinkSchema<Database>.prepare(on: conn))
        try test(KitchenSinkSchema<Database>.revert(on: conn))
        pool.releaseConnection(conn)
    }
}
