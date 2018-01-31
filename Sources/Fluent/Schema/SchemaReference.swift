import CodableKit
import Async

/// Defines database types that support references
public protocol ReferenceSupporting: SchemaSupporting {
    /// Enables references errors.
    static func enableReferences(on connection: Connection) -> Future<Void>

    /// Disables reference errors.
    static func disableReferences(on connection: Connection) -> Future<Void>
}

/// A reference / foreign key is a field (or collection of fields) in one table
/// that uniquely identifies a row of another table or the same table.
public struct SchemaReference<Database> where Database: ReferenceSupporting & SchemaSupporting {
    /// The base field.
    public let base: QueryField

    /// The field this base field references.
    /// Note: this is a `QueryField` because we have limited info.
    /// we assume it is the same type as the base field.
    public let referenced: QueryField

    /// Creates a new SchemaReference
    public init(
        base: QueryField,
        referenced: QueryField
    ) {
        self.base = base
        self.referenced = referenced
    }

    /// Convenience init w/ schema field
    public init(base: SchemaField<Database>, referenced: QueryField) {
        self.base = QueryField(entity: nil, name: base.name)
        self.referenced = referenced
    }
}

extension DatabaseSchema where Database: ReferenceSupporting {
    /// Field to field references for this database schema.
    public var addReferences: [SchemaReference<Database>] {
        get { return extend["add-references"] as? [SchemaReference<Database>] ?? [] }
        set { extend["add-references"] = newValue }
    }

    /// Field to field references for this database schema.
    public var removeReferences: [SchemaReference<Database>] {
        get { return extend["remove-references"] as? [SchemaReference<Database>] ?? [] }
        set { extend["remove-references"] = newValue }
    }
}

extension SchemaBuilder where Model.Database: ReferenceSupporting, Model.ID: KeyStringDecodable {
    /// Adds a field to the schema and creates a reference.
    /// T : T
    public func field<T, Other>(
        for key: KeyPath<Model, T>,
        referencing: KeyPath<Other, T>
    ) throws where Other: Fluent.Model, T: KeyStringDecodable {
        let base = try field(for: key)
        let reference = SchemaReference(base: base, referenced: referencing.makeQueryField())
        schema.addReferences.append(reference)
    }

    /// Adds a field to the schema and creates a reference.
    /// T : Optional<T>
    public func field<T, Other>(
        for key: KeyPath<Model, T>,
        referencing: KeyPath<Other, Optional<T>>
    ) throws where Other: Fluent.Model, T: KeyStringDecodable {
        let base = try field(for: key)
        let reference = SchemaReference(base: base, referenced: referencing.makeQueryField())
        schema.addReferences.append(reference)
    }

    /// Adds a field to the schema and creates a reference.
    /// Optional<T> : T
    public func field<T, Other>(
        for key: KeyPath<Model, Optional<T>>,
        referencing: KeyPath<Other, T>
    ) throws where Other: Fluent.Model, T: KeyStringDecodable {
        let base = try field(for: key)
        let reference = SchemaReference(base: base, referenced: referencing.makeQueryField())
        schema.addReferences.append(reference)
    }

    /// Adds a field to the schema and creates a reference.
    /// Optional<T> : Optional<T>
    public func field<T, Other>(
        for key: KeyPath<Model, Optional<T>>,
        referencing: KeyPath<Other, Optional<T>>
    ) throws where Other: Fluent.Model, T: KeyStringDecodable {
        let base = try field(for: key)
        let reference = SchemaReference<Model.Database>(base: base, referenced: referencing.makeQueryField())
        schema.addReferences.append(reference)
    }

    /// Adds a field to the schema and creates a reference.
    /// Optional<T> : Optional<T>
    public func remove<T, Other>(
        for key: KeyPath<Model, Optional<T>>,
        referencing: KeyPath<Other, Optional<T>>
    ) throws where Other: Fluent.Model, T: KeyStringDecodable {
        let base = try field(for: key)
        let reference = SchemaReference<Model.Database>(base: base, referenced: referencing.makeQueryField())
        schema.addReferences.append(reference)
    }

    /// Adds a field to the schema.
    public func removeField<T, Other>(for field: KeyPath<Model, T>, referencing: KeyPath<Other, Optional<T>>) throws
        where Other: Fluent.Model, T: KeyStringDecodable
    {
        removeField(for: field)
        try removeReference(from: field, to: referencing)
    }

    /// Adds a field to the schema.
    public func removeReference<T, Other>(from field: KeyPath<Model, T>, to referencing: KeyPath<Other, Optional<T>>) throws
        where Other: Fluent.Model, T: KeyStringDecodable
    {
        let reference = SchemaReference<Model.Database>(
            base: field.makeQueryField(),
            referenced: referencing.makeQueryField()
        )
        schema.removeReferences.append(reference)
    }
}
