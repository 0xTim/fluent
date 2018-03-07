import CodableKit
import Async

/// A siblings relation is a many-to-many relation between
/// two models.
///
/// Each model should have an opposite Siblings relation.
///
///     typealias PetToyPivot = BasicPivot<Pet, Toy> // or custom `Pivot`
///
///     class Pet: Model {
///         var toys: Siblings<Pet, Toy, PetToyPivot> {
///             return siblings()
///         }
///     }
///
///     class Toy: Model {
///         var pets: Siblings<Toy, Pet, PetToyPivot> {
///             return siblings()
///         }
///     }
///
/// The third generic parameter to this relation is a Pivot.
/// Althrough not enforced by compiler (due to the handedness), the Through pivot _must_
/// have Left & Right model types equal to the siblings From & To models.
/// (This cannot be enforced by the compiler due to the handedness)
///
/// In other words a pivot for Foo & Bar should not be used in a siblings
/// relation between Boo & Baz.
///
/// It is recommended that you use your own types conforming to `Pivot`
/// for Siblings pivots as you cannot add additional fields to a `BasicPivot`.
public struct Siblings<Base: Model, Related: Model, Through: Pivot>
    where
        Base.Database == Through.Database,
        Related.Database == Through.Database,
        Through.Database: JoinSupporting
{
    /// The base model which all fetched models
    /// should be related to.
    public let base: Base

    /// Base pivot field type.
    public typealias BasePivotField = WritableKeyPath<Through, Base.ID>

    /// The base model's foreign id field
    /// that appears on the pivot.
    /// ex: Through.baseID
    public let basePivotField: BasePivotField

    // Related pivot field type.
    public typealias RelatedPivotField = WritableKeyPath<Through, Related.ID>

    /// The related model's foreign id field
    /// that appears on the pivot.
    /// ex: Through.relatedID
    public let relatedPivotField: RelatedPivotField

    /// Create a new Siblings relation.
    public init(
        base: Base,
        related: Related.Type = Related.self,
        through: Through.Type = Through.self,
        basePivotField: BasePivotField,
        relatedPivotField: RelatedPivotField
    ) {
        self.base = base
        self.basePivotField = basePivotField
        self.relatedPivotField = relatedPivotField
    }
}

extension Siblings where Base.Database: QuerySupporting, Base.ID: KeyStringDecodable, Related.ID: KeyStringDecodable {
    /// Create a query for the parent.
    public func query(on conn: DatabaseConnectable) throws -> QueryBuilder<Related, Related> {
        let baseID = try Base.Database.queryDataSerialize(data: base.requireID())
        return Related.query(on: conn)
            .join(field: relatedPivotField)
            .filter(Through.self, basePivotField == baseID)
    }
}

// MARK: ModifiablePivot

extension Siblings where Base.Database: QuerySupporting, Base.ID: KeyStringDecodable {
    /// Returns true if the supplied model is attached
    /// to this relationship.
    public func isAttached(_ model: Related, on conn: DatabaseConnectable) -> Future<Bool> {
        return Future.flatMap(on: conn) {
            let baseID = try Base.Database.queryDataSerialize(data: self.base.requireID())
            let modelID = try Related.Database.queryDataSerialize(data: model.requireID())
            return Through.query(on: conn)
                .filter(self.basePivotField == baseID)
                .filter(self.relatedPivotField == modelID)
                .first()
                .map(to: Bool.self) { $0 != nil }
        }
    }

    /// Detaches the supplied model from this relationship
    /// if it was attached.
    public func detach(_ model: Related, on conn: DatabaseConnectable) -> Future<Void> {
        return Future.flatMap(on: conn) {
            let baseID = try Base.Database.queryDataSerialize(data: self.base.requireID())
            let modelID = try Related.Database.queryDataSerialize(data: model.requireID())
            return Through.query(on: conn)
                .filter(self.basePivotField == baseID)
                .filter(self.relatedPivotField == modelID)
                .delete()
        }
    }
}

/// Left-side
extension Siblings
    where Through: ModifiablePivot, Through.Left == Base, Through.Right == Related, Through.Database: QuerySupporting
{
    /// Attaches the model to this relationship.
    public func attach(_ model: Related, on conn: DatabaseConnectable) -> Future<Through> {
        return Future.flatMap(on: conn) {
            let pivot = try Through(self.base, model)
            return pivot.save(on: conn)
        }
    }
}

/// Right-side
extension Siblings
    where Through: ModifiablePivot, Through.Left == Related, Through.Right == Base, Through.Database: QuerySupporting
{
    /// Attaches the model to this relationship.
    public func attach(_ model: Related, on conn: DatabaseConnectable) -> Future<Through> {
        return Future.flatMap(on: conn) {
            let pivot = try Through(model, self.base)
            return pivot.save(on: conn)
        }
    }
}


// MARK: Model

extension Model {
    /// Create a siblings relation for this model.
    ///
    /// Unless you are doing custom keys, you should not need to
    /// pass any parameters to this function.
    ///
    ///     class Toy: Model {
    ///         var pets: Siblings<Toy, Pet, PetToyPivot> {
    ///             return siblings()
    ///         }
    ///     }
    ///
    /// See Siblings class documentation for more information
    /// about the many parameters. They can be confusing at first!
    ///
    /// Note: From is assumed to be the model you are calling this method on.
    public func siblings<Related, Through>(
        related: Related.Type = Related.self,
        through: Through.Type = Through.self,
        _ basePivotField: Siblings<Self, Related, Through>.BasePivotField,
        _ relatedPivotField: Siblings<Self, Related, Through>.RelatedPivotField
    ) -> Siblings<Self, Related, Through> {
        return Siblings(
            base: self,
            basePivotField: basePivotField,
            relatedPivotField: relatedPivotField
        )
    }

    /// Free implementation where pivot constraints are met.
    /// See Model.siblings(_:_:)
    public func siblings<Related, Through>(
        related: Related.Type = Related.self,
        through: Through.Type = Through.self
    ) -> Siblings<Self, Related, Through>
        where Through.Right == Self, Through.Left == Related
    {
        return siblings(Through.rightIDKey, Through.leftIDKey)
    }

    /// Free implementation where pivot constraints are met.
    /// See Model.siblings(_:_:)
    public func siblings<Related, Through>(
        related: Related.Type = Related.self,
        through: Through.Type = Through.self
    ) -> Siblings<Self, Related, Through>
        where Through.Left == Self, Through.Right == Related
    {
        return siblings(Through.leftIDKey, Through.rightIDKey)
    }
}
