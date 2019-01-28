import FluentKit
import Foundation
import XCTest

public final class FluentBenchmarker {
    public let database: FluentDatabase
    
    public init(database: FluentDatabase) {
        self.database = database
    }
    
    public func testAll() throws {
        try self.testCreate()
        try self.testRead()
        try self.testUpdate()
        try self.testDelete()
        try self.testEagerLoadChildren()
        try self.testEagerLoadParent()
    }
    
    public func testCreate() throws {
        try self.runTest(#function, [
            Galaxy.migration(on: self.database)
        ]) {
            let galaxy = Galaxy.new()
            galaxy.name.set(to: "Messier 82")
            try galaxy.save(on: self.database).wait()
            guard try galaxy.id.get() == 1 else {
                throw Failure("unexpected galaxy id: \(galaxy)")
            }
            
            guard let fetched = try self.database.query(Galaxy.self).filter(\.name == "Messier 82").first().wait() else {
                throw Failure("unexpected empty result set")
            }
            
            if try fetched.name.get() != galaxy.name.get() {
                throw Failure("unexpected name: \(galaxy) \(fetched)")
            }
            if try fetched.id.get() != galaxy.id.get() {
                throw Failure("unexpected id: \(galaxy) \(fetched)")
            }
        }
    }
    
    public func testRead() throws {
        try runTest(#function, [
            Galaxy.migration(on: self.database),
            GalaxySeed(on: self.database)
        ]) {
            guard let milkyWay = try self.database.query(Galaxy.self)
                .filter(\.name == "Milky Way")
                .first().wait()
                else {
                    throw Failure("unpexected missing galaxy")
            }
            guard try milkyWay.name.get() == "Milky Way" else {
                throw Failure("unexpected name")
            }
        }
    }
    
    public func testUpdate() throws {
        try runTest(#function, [
            Galaxy.migration(on: self.database)
        ]) {
            let galaxy = Galaxy.new()
            galaxy.name.set(to: "Milkey Way")
            try galaxy.save(on: self.database).wait()
            galaxy.name.set(to: "Milky Way")
            try galaxy.save(on: self.database).wait()
            
            // verify
            let galaxies = try self.database.query(Galaxy.self).filter(\.name == "Milky Way").all().wait()
            guard galaxies.count == 1 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
            guard try galaxies[0].name.get() == "Milky Way" else {
                throw Failure("unexpected galaxy name")
            }
        }
    }
    
    public func testDelete() throws {
        try runTest(#function, [
            Galaxy.migration(on: self.database)
        ]) {
            let galaxy = Galaxy.new()
            galaxy.name.set(to: "Milky Way")
            try galaxy.save(on: self.database).wait()
            try galaxy.delete(on: self.database).wait()
            
            // verify
            let galaxies = try self.database.query(Galaxy.self).all().wait()
            guard galaxies.count == 0 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
        }
    }
    
    public func testEagerLoadChildren() throws {
        try runTest(#function, [
            Galaxy.migration(on: self.database),
            Planet.migration(on: self.database),
            GalaxySeed(on: self.database),
            PlanetSeed(on: self.database)
        ]) {
            let galaxies = try self.database.query(Galaxy.self)
                .with(\.planets)
                .all().wait()

            for galaxy in galaxies {
                let planets = try galaxy.planets.get()
                switch try galaxy.name.get() {
                case "Milky Way":
                    guard try planets.contains(where: { try $0.name.get() == "Earth" }) else {
                        throw Failure("unexpected missing planet")
                    }
                    guard try !planets.contains(where: { try $0.name.get() == "PA-99-N2"}) else {
                        throw Failure("unexpected planet")
                    }
                default: break
                }
            }
        }
    }
    
    public func testEagerLoadParent() throws {
        try runTest(#function, [
            Galaxy.migration(on: self.database),
            Planet.migration(on: self.database),
            GalaxySeed(on: self.database),
            PlanetSeed(on: self.database)
        ]) {
            let planets = try self.database.query(Planet.self)
                .with(\.galaxy)
                .all().wait()
            
            for planet in planets {
                let galaxy = try planet.galaxy.get()
                switch try planet.name.get() {
                case "Earth":
                    guard try galaxy.name.get() == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(galaxy)")
                    }
                case "PA-99-N2":
                    guard try galaxy.name.get() == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(galaxy)")
                    }
                default: break
                }
            }
        }
    }
    
    struct Failure: Error {
        let reason: String
        let line: UInt
        let file: StaticString
        
        init(_ reason: String, line: UInt = #line, file: StaticString = #file) {
            self.reason = reason
            self.line = line
            self.file = file
        }
    }
    
    private func runTest(_ name: String, _ migrations: [Migration], _ test: () throws -> ()) throws {
        print("[FluentBenchmark] Running \(name)...")
        for migration in migrations {
            do {
                try migration.prepare().wait()
            } catch {
                print("[FluentBenchmark] Migration failed, attempting to revert existing...")
                try migration.revert().wait()
                try migration.prepare().wait()
            }
        }
        var e: Error?
        do {
            try test()
        } catch let failure as Failure {
            XCTFail(failure.reason, file: failure.file, line: failure.line)
        } catch {
            e = error
        }
        for migration in migrations {
            try migration.revert().wait()
        }
        if let error = e {
            throw error
        }
    }
}
