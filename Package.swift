// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Fluent",
    products: [
        .library(name: "Fluent", targets: ["Fluent"]),
        .library(name: "FluentBenchmark", targets: ["FluentBenchmark"]),
        .library(name: "FluentSQL", targets: ["FluentSQL"]),
        .library(name: "FluentSQLite", targets: ["FluentSQLite"]),
        .library(name: "SQLite", targets: ["SQLite"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", "1.0.0-beta.1"..<"1.0.0-beta.2"),

        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", "3.0.0-beta.1"..<"3.0.0-beta.2"),

        // Swift wrapper for Console I/O
        .package(url: "https://github.com/vapor/console.git", "3.0.0-beta.1"..<"3.0.0-beta.2"),

        // Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", "1.0.0-beta.2"..<"1.0.0-beta.3"),

        // Service container and configuration system.
        .package(url: "https://github.com/vapor/service.git", "1.0.0-beta.1"..<"1.0.0-beta.2"),
    ],
    targets: [
        .target(name: "CSQLite"),
        .target(name: "Fluent", dependencies: ["Async", "CodableKit", "Console", "DatabaseKit", "Service"]),
        .testTarget(name: "FluentTests", dependencies: ["FluentBenchmark", "FluentSQLite", "SQLite"]),
        .target(name: "FluentBenchmark", dependencies: ["Fluent"]),
        .target(name: "FluentSQL", dependencies: ["Fluent", "SQL"]),
        .target(name: "FluentSQLite", dependencies: ["Fluent", "FluentSQL", "SQLite"]),
        .target(name: "SQLite", dependencies: ["Bits", "CodableKit", "CSQLite", "Debugging"]),
        .testTarget(name: "SQLiteTests", dependencies: ["SQLite"]),
    ]
)
