struct Enum: Symbol {
    public private(set) var members: [EnumMember] = []
    public var identifier: String
    public var attributes: [Attribute] = []
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    public mutating func add(_ newMembers: [EnumMember]) {
        members.append(contentsOf: newMembers)
    }
    
    public func asSource() -> String {
        var res = ""
        
        for a in attributes {
            res += a.toSource() + "\n"
        }
        
        res += "public enum \(identifier) {\n"
        
        for member in members {
            for attribute in member.attributes {
                res += "    " + attribute.toSource() + "\n"
            }
            res += "    \(member.name) = \(member.value),\n"
        }
        
        res += "}\n"
        
        return res
    }
}

public struct EnumMember {
    public let name: String
    public let value: String
    public var attributes: [Attribute] = []
}