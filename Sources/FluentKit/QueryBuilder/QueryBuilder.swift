import NIO

extension FluentDatabase {
    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
    }
}

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    let database: FluentDatabase
    public var query: DatabaseQuery
    var eagerLoad: EagerLoad
    
    public init(database: FluentDatabase) {
        self.database = database
        self.query = .init(entity: Model.new().entity)
        self.query.fields = Model.new().properties.map { .field(name: $0.name, entity: $0.entity) }
        self.eagerLoad = .init()
    }
    
    public func with<Child>(_ key: KeyPath<Model, ChildrenRelation<Model, Child>>) -> Self
        where Child: FluentKit.Model
    {
        let children = Model.new()[keyPath: key]
        let parent = Child.new()[keyPath: children.relation]

        self.eagerLoad.requests.append(.init { cache, database, models in
            let rawIDs: [Model.ID] = try (models as! [Model])
                .map { try $0.id.get() }
            let ids = Array(Set(rawIDs))
                .map { DatabaseQuery.Value.bind($0) }
            return database.query(Child.self)
                .filter(.field(name: parent.id.name, entity: Child.new().entity), .subset(inverse: false), .group(ids))
                .all()
                .map { EagerLoad.Result(Child.new().entity, $0) }
        })
        return self
    }
    
    public func with<Parent>(_ key: KeyPath<Model, ParentRelation<Model, Parent>>) -> Self
        where Parent: FluentKit.Model
    {
        let id = Parent.new().id
        self.eagerLoad.requests.append(.init { cache, database, models in
            let rawIDs = try (models as! [Model])
                .map { try $0[keyPath: key].id.get() }
            
            let ids = Array(Set(rawIDs))
                .map { DatabaseQuery.Value.bind($0) }
            return database.query(Parent.self)
                .filter(.field(name: id.name, entity: Parent.new().entity), .subset(inverse: false), .group(ids))
                .all()
                .map { EagerLoad.Result(Parent.new().entity, $0) }
            })
        return self
    }
    
    public func filter(_ filter: ModelFilter<Model>) -> Self {
        return self.filter(filter.filter)
    }
    
    public func filter<T>(_ key: KeyPath<Model, ModelField<Model, T>>, _ method: DatabaseQuery.Filter.Method, _ value: T) -> Self
        where T: Encodable
    {
        let property = Model.new()[keyPath: key]
        return self.filter(.field(name: property.name, entity: property.entity), method, .bind(value))
    }
    
    public func filter(_ field: DatabaseQuery.Field, _ method: DatabaseQuery.Filter.Method, _ value: DatabaseQuery.Value) -> Self {
        return self.filter(.basic(field, method, value))
    }
    
    public func filter(_ filter: DatabaseQuery.Filter) -> Self {
        self.query.filters.append(filter)
        return self
    }
    
    public func set(_ data: [String: DatabaseQuery.Value]) -> Self {
        query.fields = data.keys.map { .field(name: $0, entity: nil) }
        query.input.append(.init(data.values))
        return self
    }
    
    public func set<Value>(_ field: KeyPath<Model, ModelField<Model, Value>>, to value: Value) -> Self {
        let ref = Model.new()
        query.fields.append(.field(name: ref[keyPath: field].name, entity: ref.entity))
        switch query.input.count {
        case 0: query.input = [[.bind(value)]]
        default: query.input[0].append(.bind(value))
        }
        return self
    }
    
    public func create() -> EventLoopFuture<Void> {
        #warning("model id not set this way")
        self.query.action = .delete
        return self.run()
    }
    
    public func update() -> EventLoopFuture<Void> {
        self.query.action = .update
        return self.run()
    }
    
    public func delete() -> EventLoopFuture<Void> {
        self.query.action = .delete
        return self.run()
    }
    
    public func first() -> EventLoopFuture<Model?> {
        return all().map { $0.first }
    }
    
    public func all() -> EventLoopFuture<[Model]> {
        #warning("re-use array required by run for eager loading")
        var models: [Model] = []
        return self.run { model in
            models.append(model)
        }.map { models }
    }
    
    public func run() -> EventLoopFuture<Void> {
        return self.run { _ in }
    }
    
    public func run(_ onOutput: @escaping (Model) throws -> ()) -> EventLoopFuture<Void> {
        var all: [Model] = []
        return self.database.execute(self.query) { output in
            let model = Model.init(storage: .init(output: output, cache: self.eagerLoad.cache, exists: true))
            all.append(model)
            try onOutput(model)
        }.flatMap {
            return .andAll(self.eagerLoad.requests.map { request in
                #warning("fix force try")
                return try! request.run(self.eagerLoad.cache, self.database, all).map { result in
                    self.eagerLoad.cache.storage[result.entity] = result
                }
            }, eventLoop: self.database.eventLoop)
        }
    }
}

public struct ModelFilter<Model> where Model: FluentKit.Model {
    static func make<Value>(
        _ lhs: KeyPath<Model, ModelField<Model, Value>>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: Value
    ) -> ModelFilter {
        let property = Model.new()[keyPath: lhs]
        return .init(filter: .basic(
            .field(name: property.name, entity: property.entity),
            method,
            .bind(rhs)
        ))
    }
    
    let filter: DatabaseQuery.Filter
    init(filter: DatabaseQuery.Filter) {
        self.filter = filter
    }
}

public func ==<Model, Value>(lhs: KeyPath<Model, ModelField<Model, Value>>, rhs: Value) -> ModelFilter<Model> {
    return .make(lhs, .equality(inverse: false), rhs)
}
