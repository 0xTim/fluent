import Async
import Fluent
import FluentSQL
import Foundation
import SQLite
import SQL

extension SQLiteDatabase: QuerySupporting {
    /// See QuerySupporting.execute
    public static func execute<I, D>(
        query: DatabaseQuery<SQLiteDatabase>,
        into stream: I,
        on connection: SQLiteConnection
    ) where I: Async.InputStream, D: Decodable, D == I.Input {
        do {
            /// convert fluent query to sql query
            var (dataQuery, binds) = query.makeDataQuery()

            // create row encoder, will only
            // be used if a model is being binded
            let rowEncoder = SQLiteRowEncoder()

            // bind model columns to sql query
            if let model = query.data {
                try model.encode(to: rowEncoder)
                dataQuery.columns += rowEncoder.row.fields.keys.map {
                    DataColumn(table: query.entity, name: $0.name)
                }
            }

            /// create sqlite query from string
            let sqlString = SQLiteSQLSerializer().serialize(data: dataQuery)
            let sqliteQuery = connection.query(string: sqlString)

            /// bind model data to sqlite query
            if query.data != nil {
                for data in rowEncoder.row.fields.values.map({ $0.data }) {
                    sqliteQuery.bind(data)
                }
            }

            /// encode sql placeholder binds
            let DataEncoder = SQLiteDataEncoder()
            for bind in binds {
                try sqliteQuery.bind(DataEncoder.makeSQLiteData(bind))
            }

            /// setup drain
            /// BLOCKING
            sqliteQuery.execute().do { results in
                if let results = results {
                    /// there are results to be streamed
                    results.stream().map(to: D.self) { row in
                        let decoder = SQLiteRowDecoder(row: row)
                        let model = try D(from: decoder)
                        return model
                    }.output(to: stream)
                } else {
                    stream.close()
                }
            }.catch { error in
                stream.error(error)
                stream.close()
            }
        } catch {
            stream.error(error)
            stream.close()
        }
    }

    /// See QuerySupporting.modelEvent
    public static func modelEvent<M>(
        event: ModelEvent,
        model: M,
        on connection: SQLiteConnection
    ) -> Future<Void> where SQLiteDatabase == M.Database, M: Model {
        switch event {
        case .willCreate:
            switch id(M.ID.self) {
            case id(UUID.self): model.fluentID = UUID() as? M.ID
            default: break
            }
        case .didCreate:
            switch id(M.ID.self) {
            case id(Int.self): model.fluentID = connection.lastAutoincrementID as? M.ID
            default: break
            }
        default: break
        }

        return .done
    }
}


extension SQLiteDataEncoder {
    /// Converts a SQL bind value into SQLite data.
    /// This method applies wildcards if necessary.
    fileprivate func makeSQLiteData(_ bind: BindValue) throws -> SQLiteData {
        try bind.encodable.encode(to: self)
        switch bind.method {
        case .plain:
            return data
        case .wildcard(let wildcard):
            // FIXME: fuzzy string
            guard let string = data.text else {
                throw FluentSQLiteError(identifier: "incorrect-string", reason: "could not convert value with wildcards to string: \(data)")
            }

            switch wildcard {
            case .fullWildcard: return .text("%" + string + "%")
            case .leadingWildcard: return .text("%" + string)
            case .trailingWildcard: return .text(string + "%")
            }
        }
    }
}

