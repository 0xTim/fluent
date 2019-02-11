import Fluent
import Foundation

final class Galaxy: FluentModel {
    var storage: Storage
    
    var properties: [Property] {
        return [id, name]
    }
    
    var entity: String {
        return "galaxies"
    }
    
    var id: Field<Int> {
        return self.field("id", .int, .identifier)
    }
    
    var name: Field<String> {
        return self.field("name")
    }
    
    var planets: Children<Planet> {
        return self.children(\.galaxy)
    }
    
    init(storage: Storage) {
        self.storage = storage
    }
}
