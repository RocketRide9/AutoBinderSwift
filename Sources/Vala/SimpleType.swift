public class SimpleType : Symbol {
    var identifier: String
    public var attributes: [Attribute] = []
    var parentType: String?

    public init (
        name: String,
        parentType: String? = nil,
        attributes: [Attribute] = []
    ) {
        self.identifier = name
        self.parentType = parentType
        self.attributes = attributes
    }

    public func asSource() -> String {
        var res = "";
        res += "[SimpleType]\n";
        for a in attributes
        {
            res += a.toSource() + "\n";
        }
        res += "public struct \(identifier)";

        if parentType != nil
        {
            res += " : \(parentType!)";
        }

        res += " {}\n";

        return res;
    }
}