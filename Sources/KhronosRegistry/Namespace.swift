import OrderedCollections
import Strings

public class Namespace {
    /// Namespace prefix found in function, type and constants names.\
    /// Lowercase single word string.
    /// 
    /// E.g. cl, gl, egl, vk.
    public let prefix: String

    /// Namespace name. Bindings can use it or
    /// uppercased Prefix for namespace indentificator.
    /// 
    /// E.g. OpenCL, OpenGL, EGL, Vulkan.
    public let name: String

    public var types: OrderedDictionary<String, Type> = [:]
    // TODO: enums are types too, so they should probably
    // be stored in types dictionary
    // Enum.name : Enum
    public private(set) var enums: [String : Enum] = [:]

    public var commands: [String : Command] = [:]

    public init (prefix: String, name: String)
    {
        self.prefix = prefix;
        self.name = name;
    }

    public func findType (cname: String) -> (any Type)? {
        if TypeCollection.basicTypes.contains(cname) {
            return BasicType(name: cname)
        }
        let name = removeNsPrefix(cname, prefix, strict: false)
        if let t = types[name] {
            return t
        }
        if let t = enums[name] {
            return t
        }

        return nil
    }

    public func addEnum (_ en: Enum)
    {
        var verified = types.first {$0.key == en.name} != nil

        if (!verified)
        {
            verified = TypeCollection.basicTypes.contains(en.cName);
        }

        if (!verified)
        {
            fatalError("Couldn't find type such type: \(en.name)");
        }
        enums[en.name] = en;
    }
}
