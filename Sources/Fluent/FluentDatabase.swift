import NIO

public protocol FluentDatabase {
    var eventLoop: EventLoop { get }
    func fluentQuery(_ query: FluentQuery, _ onOutput: @escaping (FluentOutput) throws -> ()) -> EventLoopFuture<Void>
}

extension FluentDatabase {
    public func query<M>(_ model: M.Type) -> FluentQueryBuilder<M>
        where M: FluentModel
    {
        return .init(database: self)
    }
}
