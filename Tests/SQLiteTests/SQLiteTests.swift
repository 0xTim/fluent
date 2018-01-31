import CodableKit
import Async
import Dispatch
import Foundation
@testable import SQLite
import FluentSQLite
import XCTest

class SQLiteTests: XCTestCase {
    var database: SQLiteConnection!
    var queue: DefaultEventLoop!

    override func setUp() {
        self.queue = try! DefaultEventLoop(label: "sqlite.tests.queue")
        Thread.async { self.queue.runLoop() }
        self.database = SQLiteConnection.makeTestConnection(queue: queue)
    }

    func testTables() throws {
        _ = try database.query("DROP TABLE IF EXISTS foo").execute().blockingAwait()
        _ = try database.query("CREATE TABLE foo (bar INT(4), baz VARCHAR(16), biz FLOAT)").execute().blockingAwait()
        _ = try database.query("INSERT INTO foo VALUES (42, 'Life', 0.44)").execute().blockingAwait()
        _ = try database.query("INSERT INTO foo VALUES (1337, 'Elite', 209.234)").execute().blockingAwait()
        _ = try database.query("INSERT INTO foo VALUES (9, NULL, 34.567)").execute().blockingAwait()

        if let resultBar = try database.query("SELECT * FROM foo WHERE bar = 42").execute().blockingAwait()!.fetchRow().blockingAwait() {
            XCTAssertEqual(resultBar["bar"]?.integer, 42)
            XCTAssertEqual(resultBar["baz"]?.text, "Life")
            XCTAssertEqual(resultBar["biz"]?.float, 0.44)
        } else {
            XCTFail("Could not get bar result")
        }


        if let resultBaz = try database.query("SELECT * FROM foo where baz = 'Elite'").execute().blockingAwait()!.fetchRow().blockingAwait() {
            XCTAssertEqual(resultBaz["bar"]?.integer, 1337)
            XCTAssertEqual(resultBaz["baz"]?.text, "Elite")
        } else {
            XCTFail("Could not get baz result")
        }

        if let resultBaz = try database.query("SELECT * FROM foo where bar = 9").execute().blockingAwait()!.fetchRow().blockingAwait() {
            XCTAssertEqual(resultBaz["bar"]?.integer, 9)
            XCTAssertEqual(resultBaz["baz"]?.isNull, true)
        } else {
            XCTFail("Could not get null result")
        }
    }

    func testUnicode() throws {
        /// This string includes characters from most Unicode categories
        /// such as Latin, Latin-Extended-A/B, Cyrrilic, Greek etc.
        let unicode = "®¿ÐØ×ĞƋƢǂǊǕǮȐȘȢȱȵẀˍΔῴЖ♆"
        _ = try database.query("DROP TABLE IF EXISTS `foo`").execute().blockingAwait()
        _ = try database.query("CREATE TABLE `foo` (bar TEXT)").execute().blockingAwait()

        _ = try database.query("INSERT INTO `foo` VALUES(?)")
            .bind(unicode)
            .execute()
            .blockingAwait()


        let selectAllResults = try database.query("SELECT * FROM `foo`").execute().blockingAwait()!.fetchRow().blockingAwait()
        XCTAssertNotNil(selectAllResults)
        XCTAssertEqual(selectAllResults!["bar"]?.text, unicode)

        let selectWhereResults = try database.query("SELECT * FROM `foo` WHERE bar = '\(unicode)'").execute().blockingAwait()!.fetchRow().blockingAwait()
        XCTAssertNotNil(selectWhereResults)
        XCTAssertEqual(selectWhereResults!["bar"]?.text, unicode)
    }

    func testBigInts() throws {
        let max = Int.max

        _ = try database.query("DROP TABLE IF EXISTS foo").execute().blockingAwait()
        _ = try database.query("CREATE TABLE foo (max INT)").execute().blockingAwait()
        _ = try database.query("INSERT INTO foo VALUES (?)")
            .bind(max)
            .execute()
            .blockingAwait()

        if let result = try! database.query("SELECT * FROM foo").execute().blockingAwait()!.fetchRow().blockingAwait() {
            XCTAssertEqual(result["max"]?.integer, max)
        }
    }

    func testBlob() throws {
        let data = Data(bytes: [0, 1, 2])

        _ = try database.query("DROP TABLE IF EXISTS `foo`").execute().blockingAwait()
        _ = try database.query("CREATE TABLE foo (bar BLOB(4))").execute().blockingAwait()
        _ = try database.query("INSERT INTO foo VALUES (?)")
            .bind(data)
            .execute()
            .blockingAwait()

        if let result = try database.query("SELECT * FROM foo").execute().blockingAwait()!.fetchRow().blockingAwait() {
            XCTAssertEqual(result["bar"]!.blob, data)
        } else {
            XCTFail()
        }
    }

    func testError() {
        do {
            _ = try database.query("asdf").execute().blockingAwait()
            XCTFail("Should have errored")
        } catch let error as SQLiteError {
            print(error)
            XCTAssert(error.reason.contains("syntax error"))
        } catch {
            XCTFail("wrong error")
        }
    }

    static let allTests = [
        ("testTables", testTables),
        ("testUnicode", testUnicode),
        ("testBigInts", testBigInts),
        ("testBlob", testBlob),
        ("testError", testError)
    ]
}

extension SQLiteConnection {
    func query(_ string: String) throws -> SQLiteQuery {
        return SQLiteQuery(string: string, connection: self)
    }
}


final class Forum: Model, Migration {
    static var idKey: ReferenceWritableKeyPath<Forum, UUID?> = \Forum.id
    
    typealias Database = SQLiteDatabase
    
    typealias ID = UUID
    
    var id: UUID?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
