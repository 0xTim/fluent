public protocol Builder: class {
    var fields: [Field] { get set }
}

extension Builder {
    public func id<E: Entity>(for entityType: E.Type) {
        let field = Field(
            name: E.idKey,
            type: .id(type: E.idType),
            primaryKey: true
        )
        fields.append(field)
    }

    public func foreignId<E: Entity>(for entityType: E.Type) {
        let field = Field(
            name: E.foreignIdKey,
            type: .id(type: E.idType)
        )
        fields.append(field)
    }

    public func int(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .int,
            optional: optional,
            unique: unique,
            default: `default`
        )
        fields.append(field)
    }

    public func string(
        _ name: String,
        length: Int? = nil,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .string(length: length),
            optional: optional,
            unique: unique,
            default: `default`
        )
        fields.append(field)
    }

    public func double(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .double,
            optional: optional,
            unique: unique,
            default: `default`
        )
        fields.append(field)
    }

    public func bool(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .bool,
            optional: optional,
            unique: unique,
            default: `default`
        )
        fields.append(field)
    }

    public func bytes(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .bytes,
            optional: optional,
            unique: unique,
            default: `default`
        )
        fields.append(field)
    }

    public func date(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .date,
            optional: optional,
            unique: unique,
            default: `default`
        )
        fields.append(field)
    }

    public func custom(
        _ name: String,
        type: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .custom(type: type),
            optional: optional,
            unique: unique,
            default: `default`
        )
        fields.append(field)
    }

    // MARK: Relations
    
    public func parent<E: Entity>(
        _ entity: E.Type = E.self,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        parent(
            idKey: E.idKey,
            idType: E.idType,
            optional: optional,
            unique: unique,
            default: `default`
        )
    }

    public func parent(
        idKey: String,
        idType: IdentifierType,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: idKey,
            type: .id(type: idType),
            optional: optional,
            unique: unique,
            default: `default`
        )
        fields.append(field)
    }
}
