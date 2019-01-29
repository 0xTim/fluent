import NIO

extension FluentDatabase {
    public func query<Model>(_ model: Model.Type) -> FluentQueryBuilder<Model>
        where Model: FluentKit.FluentModel
    {
        return .init(database: self)
    }
}

public final class FluentQueryBuilder<Model>
    where Model: FluentKit.FluentModel
{
    let database: FluentDatabase
    public var query: FluentQuery
    var eagerLoads: [String: EagerLoad]
    
    public init(database: FluentDatabase) {
        self.database = database
        self.query = .init(entity: Model.new().entity)
        self.eagerLoads = [:]
        self.query.fields = Model.new().fields.map { .field(
            name: $0.name,
            entity: $0.entity,
            alias: nil
        ) }
    }
    
    public enum EagerLoadMethod {
        case subquery
        case join
    }
    
    public func with<Child>(
        _ key: KeyPath<Model, FluentChildren<Model, Child>>,
        method: EagerLoadMethod = .subquery
    ) -> Self
        where Child: FluentKit.FluentModel
    {
        switch method {
        case .subquery:
            let id = Model.new()[keyPath: key].relation.appending(path: \.id)
            self.eagerLoads[Child.new().entity] = SubqueryChildEagerLoad<Model, Child>(id)
        case .join:
            fatalError()
        }
        return self
    }

    public func with<Parent>(
        _ key: KeyPath<Model, FluentParent<Model, Parent>>,
        method: EagerLoadMethod = .subquery
    ) -> Self
        where Parent: FluentKit.FluentModel
    {
        switch method {
        case .subquery:
            self.eagerLoads[Parent.new().entity] = SubqueryParentEagerLoad<Model, Parent>(key)
            return self
        case .join:
            self.eagerLoads[Parent.new().entity] = JoinParentEagerLoad<Model, Parent>()
            return self.join(key)
        }
    }
    
    public func join<Parent>(_ key: KeyPath<Model, FluentParent<Model, Parent>>) -> Self {
        let l = Model.new()[keyPath: key].id
        let f = Parent.new().id
        self.query.fields += Parent.new().fields.map { .field(name: $0.name, entity: $0.entity, alias: $0.entity! + "_" + $0.name) }
        self.query.joins.append(.model(
            foreign: .field(name: f.name, entity: f.entity, alias: nil),
            local: .field(name: l.name, entity: l.entity, alias: nil)
        ))
        return self
    }
    
    public func join<Foreign, T>(
        _ local: KeyPath<Model, FluentField<Model, T>>,
        _ foreign: KeyPath<Foreign, FluentField<Foreign, T>>
    ) -> Self
        where Foreign: FluentModel
    {
        let f = Foreign.new()[keyPath: foreign]
        let l = Model.new()[keyPath: local]
        self.query.fields += Foreign.new().fields.map { .field(name: $0.name, entity: $0.entity, alias: $0.entity! + "_" + $0.name) }
        print(self.query.fields)
        self.query.joins.append(.model(
            foreign: .field(name: f.name, entity: f.entity, alias: nil),
            local: .field(name: l.name, entity: l.entity, alias: nil)
        ))
        return self
    }
    
    
    public func filter(_ filter: ModelFilter<Model>) -> Self {
        return self.filter(filter.filter)
    }
    
    public func filter<T>(
        _ key: KeyPath<Model, FluentField<Model, T>>,
        in value: [T]
    ) -> Self
        where T: Encodable
    {
        return self.filter(
            .field(name: Model.new()[keyPath: key].name, entity: Model.new().entity, alias: nil),
            .subset(inverse: false),
            .group(value.map { .bind($0) })
        )
    }
    
    public func filter<T>(_ key: KeyPath<Model, FluentField<Model, T>>, _ method: FluentQuery.Filter.Method, _ value: T) -> Self
        where T: Encodable
    {
        let property = Model.new()[keyPath: key]
        return self.filter(.field(name: property.name, entity: property.entity, alias: nil), method, .bind(value))
    }
    
    public func filter(_ field: FluentQuery.Field, _ method: FluentQuery.Filter.Method, _ value: FluentQuery.Value) -> Self {
        return self.filter(.basic(field, method, value))
    }
    
    public func filter(_ filter: FluentQuery.Filter) -> Self {
        self.query.filters.append(filter)
        return self
    }
    
    public func set(_ data: [String: FluentQuery.Value]) -> Self {
        query.fields = data.keys.map { .field(name: $0, entity: nil, alias: nil) }
        query.input.append(.init(data.values))
        return self
    }
    
    public func set<Value>(_ field: KeyPath<Model, FluentField<Model, Value>>, to value: Value) -> Self {
        let ref = Model.new()
        query.fields.append(.field(name: ref[keyPath: field].name, entity: ref.entity, alias: nil))
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
            let model = Model.init(storage: .init(
                output: output,
                eagerLoads: self.eagerLoads,
                exists: true
            ))
            all.append(model)
            try onOutput(model)
        }.flatMap {
            return .andAll(self.eagerLoads.values.map { eagerLoad in
                return eagerLoad.run(all, on: self.database)
            }, eventLoop: self.database.eventLoop)
        }
    }
}

public struct ModelFilter<Model> where Model: FluentKit.FluentModel {
    static func make<Value>(
        _ lhs: KeyPath<Model, FluentField<Model, Value>>,
        _ method: FluentQuery.Filter.Method,
        _ rhs: Value
    ) -> ModelFilter {
        let property = Model.new()[keyPath: lhs]
        return .init(filter: .basic(
            .field(name: property.name, entity: property.entity, alias: nil),
            method,
            .bind(rhs)
        ))
    }
    
    let filter: FluentQuery.Filter
    init(filter: FluentQuery.Filter) {
        self.filter = filter
    }
}

public func ==<Model, Value>(lhs: KeyPath<Model, FluentField<Model, Value>>, rhs: Value) -> ModelFilter<Model> {
    return .make(lhs, .equality(inverse: false), rhs)
}
