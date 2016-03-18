public class SQL<T: Model>: Helper<T> {
    public var values: [String]
    public var statement: String {
        var statement = [query.action.sql(query.fields)]
        statement.append(table)
        
        if let dataClause = self.dataClause {
            statement.append(dataClause)
        } else if let unionClause = self.unionClause {
            statement.append(unionClause)
        }
        
        if let whereClause = self.whereClause {
            statement.append("WHERE \(whereClause)")
        }
        
        if let limit = query.limit where limit.count > 0 {
            statement.append(limit.sql)
        }
        
        if let offset = query.offset where offset.count > 0 {
            statement.append(offset.sql)
        }
        
        return "\(statement.joinWithSeparator(" "));"
    }
    
    var table: String {
        return query.entity
    }
    
    var nextPlaceholder: String {
        return "?"
    }
    
    var dataClause: String? {
        guard let items = query.items else {
            return nil
        }
        
        if case .Insert = query.action {
            let fieldsString = items.keys.joinWithSeparator(", ")
            let valuesString = items.values.map {
                self.values.append($0.string)
                return self.nextPlaceholder
            }.joinWithSeparator(", ")
            return "(\(fieldsString)) VALUES (\(valuesString))"
        } else if case .Update = query.action {
            let updatesString = items.map {
                self.values.append($0.1.string)
                return "\($0.0) = \(self.nextPlaceholder)"
            }.joinWithSeparator(", ")
            return "SET \(updatesString)"
        }
        return nil
    }
    
    var unionClause: String? {
        return nil
    }
    
    var whereClause: String? {
        var clause: [String] = []
        for filter in query.filters {
            clause.append(filterOutput(filter))
        }
        
        if clause.count == 0 {
            return nil
        }
        
        return clause.joinWithSeparator(" ")
    }

    public override init(query: Query<T>) {
        values = []
        super.init(query: query)
    }
    
    func filterOutput(filter: Filter) -> String {
        switch filter {
        case .Compare(let field, let comparison, let value):
            self.values.append(value.string)
            return "\(field) \(comparison.sql) \(nextPlaceholder)"
        case .Subset(let field, let scope, let values):
            let valueStrings = values.map { value in
                self.values.append(value.string)
                return nextPlaceholder
                }.joinWithSeparator(", ")
            
            return "\(field) \(scope.sql) (\(valueStrings))"
        case .Group(let op, let filters):
            let f: [String] = filters.map {
                if case .Group = $0 {
                    return self.filterOutput($0)
                }
                return "\(op.sql) \(self.filterOutput($0))"
            }
            return f.joinWithSeparator(" ")
        }
    }
}

//:

extension Action {
    func sql(fields: [String]) -> String {
        switch self {
        case .Select(let distinct):
            var select = ["SELECT"]
            
            if distinct {
                select.append("DISTINCT")
            }
            
            if fields.count > 0 {
                select.append(fields.joinWithSeparator(", "))
            } else {
                select.append("*")
            }
            
            select.append("FROM")
            return select.joinWithSeparator(" ")
        case .Delete:
            return "DELETE FROM"
        case .Insert:
            return "INSERT INTO"
        case .Update:
            return "UPDATE"
        case .Count:
            return "SELECT count(\(fields.first ?? "*")) FROM"
        case .Maximum:
            return "SELECT max(\(fields.first ?? "*")) FROM"
        case .Minimum:
            return "SELECT min(\(fields.first ?? "*")) FROM"
        case .Average:
            return "SELECT avg(\(fields.first ?? "*")) FROM"
        case .Sum:
            return "SELECT sum(\(fields.first ?? "*")) FROM"
        }
    }
}

extension Limit {
    var sql: String {
        return "LIMIT \(count)"
    }
}

extension Offset {
    var sql: String {
        return "OFFSET \(count)"
    }
}


extension Filter.Scope {
    var sql: String {
        switch self {
        case .In:
            return "IN"
        case .NotIn:
            return "NOT IN"
        }
    }
}

extension Filter.Operation {
    var sql: String {
        switch self {
        case .And:
            return "AND"
        case .Or:
            return "OR"
        }
    }
}

extension Filter.Comparison {
    var sql: String {
        switch self {
        case .Equals:
            return "="
        case .NotEquals:
            return "!="
        case .GreaterThan:
            return ">"
        case .LessThan:
            return "<"
        }
    }
}

///public class SQL {
//    public var placeholderFormat: String = "?" // append %c for counting
//    func addPlaceholder() -> String {
//        var m = ""
//        if placeholderFormat.hasSuffix("%c") {
//            m = "$\(placeholderCount)"
//            placeholderCount += 1
//        } else {
//            m = placeholderFormat
//        }
//        return m
//    }
//
//    private func buildQuery() -> String {
//        var query: [String] = []
//        self.values = []
//        self.placeholderCount = 1
//        query.append(buildClauseComponent())
//        query.append("\(self.entity)")
//
//        if self.joins.count > 0 {
//            query.append(buildJoinsComponent(joins))
//        } else if !self.data.isEmpty {
//            query.append(buildDataComponent())
//        }
//
//        if self.operation.count > 0 {
//            query.append("WHERE")
//            query.append(buildOperationComponent(operation))
//        }
//
//        if self.orderBy.count > 0 {
//            query.append("ORDER BY")
//            query.append(buildOrderByComponent(orderBy))
//        }
//
//        if !self.groupBy.isEmpty {
//            query.append("GROUP BY")
//            query.append(groupBy)
//        }
//
//        if self.limit > 0 {
//            query.append("LIMIT \(limit)")
//        }
//
//        if self.offset > 0 {
//            query.append("OFFSET \(offset)")
//        }
//
//        let queryString = query.joinWithSeparator(" ")
//        return queryString + ";"
//    }
//
//    // MARK: - Builder Methods
//
//    private func buildJoinsComponent(joins: [(String, Join)]) -> String {
//        var component = [String]()
//        for (joinEntity, join) in joins {
//            var joinComponent = [String]()
//            switch join {
//            case .Inner:
//                joinComponent.append("INNER JOIN")
//            case .Left:
//                joinComponent.append("LEFT JOIN")
//            case .Right:
//                joinComponent.append("RIGHT JOIN")
//            }
//            joinComponent.append(joinEntity)
//            joinComponent.append("ON")
//            joinComponent.append("\(joinEntity).\(self.entity)_id=\(self.entity).id")
//
//            component.append(joinComponent.joinWithSeparator(" "))
//        }
//
//        return component.joinWithSeparator(", ")
//    }
//
//    private func buildOrderByComponent(orderBy: [(String, OrderBy)]) -> String {
//        var component = ""
//        for (key, oBy) in orderBy {
//            switch oBy {
//            case .Ascending:
//                component = "\(key) ASC"
//            case .Descending:
//                component = "\(key) DESC"
//            }
//        }
//        return component
//    }
//}