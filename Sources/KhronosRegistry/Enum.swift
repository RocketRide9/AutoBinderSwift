import Extensions
import Strings

// Name - pair name as present in .xml spec
// e.g. CL_PLATFORM_PROFILE from cl_platform_info
// tho PlatformInfo.Profile makes more sense for bindings
public class EnumMember {
    /// Full name according to spec
    public let cName: String
    public let value: String
    
    /// Short name, cName without prefix
    public let name: String
    public fileprivate(set) weak var parent: Enum?

    public func isCNameOverriden() -> Bool {
        return cName != parent!.enumPrefix + name
    }
    
    public init(cName: String, name: String, value: String) {
        self.cName = cName
        self.name = name
        self.value = value
    }
    
    public init(other: EnumMember) {
        self.cName = other.cName
        self.value = other.value
        self.name = other.name
    }
}

public class Enum : Type {
    public let cName: String
    public let name: String
    public var vendor: String?
    public var comment: String?
    public let isBitmask: Bool

    public let members: [EnumMember]
    
    /// Prefix that identifies this enumeration \
    /// Includes namespace prefix and trailing `_`
    public var enumPrefix: String
    public var namespacePrefix: String
    
    public init(
        cname: String,
        name: String,
        nsPrefix: String,
        enumPrefix: String,
        isBitmask: Bool,
        members: consuming [EnumMember],
    ) {
        self.cName = cname
        self.namespacePrefix = nsPrefix
        self.enumPrefix = enumPrefix
        self.name = name
        self.isBitmask = isBitmask
        self.members = members

        for m in self.members {
            m.parent = self
        }
    }
    
    // find a pair with given name
    // if found, return value
    // else return null
    public func find(pairName: String) -> EnumMember? {
        members.first { $0.cName == pairName }
    }
}