import OrderedCollections

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

    public private(set) var enums: [Enum] = []

    public init (prefix: String, name: String)
    {
        self.prefix = prefix;
        self.name = name;
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
        enums.append(en);
    }
}
