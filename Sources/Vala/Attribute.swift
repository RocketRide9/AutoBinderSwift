public protocol Attribute {
    func toSource() -> String
}

extension Attribute {
    fileprivate static func write(_ attr: Attribute) -> String {
        let mirror = Mirror(reflecting: attr)
        var parts = [String]()
        
        for child in mirror.children {
            if let value = child.value as? CustomStringConvertible, 
               !String(describing: value).isEmpty
            {
                parts.append("\(child.label!) = \"\(value)\"")
            }
        }
        
        let typeName = mirror.subjectType
        
        if parts.isEmpty {
            return "[\(typeName)]"
        } else {
            let initializer = "(\(parts.joined(separator: ", ")))"
            return "[\(typeName) \(initializer)]"
        }
    }
    
    public func toSource() -> String {
        return Self.write(self)
    }
}

public struct Flags : Attribute {
    public init() {}
}

public struct CCode : Attribute
{
    public let cname: String?
    public let cprefix: String?
    public let has_type_id: Bool?

    public init(cname: String? = nil, cprefix: String? = nil, has_type_id: Bool? = nil) {
        self.cname = cname
        self.cprefix = cprefix
        self.has_type_id = has_type_id
    }
}

public struct Version : Attribute
{
    public let since: String?
    public let deprecated_since: String?
    public let deprecated: Bool?

    public init(since: String? = nil, deprecated_since: String? = nil, deprecated: Bool? = nil) {
        self.since = since
        self.deprecated_since = deprecated_since
        self.deprecated = deprecated
    }
}
