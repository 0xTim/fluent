import Fluent
import Foundation

final class Planet: Model {
    var storage: Storage
    
    var properties: [Property] {
        return [id, name, galaxy]
    }
    
    var entity: String {
        return "planets"
    }
    
    var id: Field<Int> {
        return self.field("id", isIdentifier: true)
    }
    
    var name: Field<String> {
        return self.field("name")
    }
    
    var galaxy: Parent<Galaxy> {
        return self.parent("galaxyID")
    }
    
    init(storage: Storage) {
        self.storage = storage
    }
}
