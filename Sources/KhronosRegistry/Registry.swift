import FoundationXML
import OrderedCollections
import Strings

class EnumDraft {
    let cName: String
    let name: String
    let isBitmask: Bool
    var members: [EnumMemberDraft] = []

    init(
        cname: String,
        name: String,
        isBitmask: Bool,
    ) {
        self.cName = cname
        self.name = name
        self.isBitmask = isBitmask
    }
}

class EnumMemberDraft {
    /// Full name according to spec
    let cName: String
    var overrideName: String?
    let value: String

    init(cname: String, value: String) {
        self.cName = cname
        self.value = value
    }

    init(other: EnumMemberDraft) {
        self.cName = other.cName
        self.value = other.value
        self.overrideName = other.overrideName
    }
}


public class Registry {
    public private(set) var namespace: Namespace
    let _lastFeature = "CL_VERSION_3_0"

    @MainActor
    public init(_ root: XMLElement) {
        namespace = .init(prefix: "cl", name: "OpenCL")
        guard root.name == "registry" else {
            fatalError("Expected `registry`, got \(root.name!)")
        }

        parseTypes(root: root)
        parseEnums(root: root)
        parseCommands(root: root)
    }

    @MainActor
    func parseCommands(root: XMLElement) {
        let cmdParser = CommandParser(namespacePrefix: namespace.prefix)
        let fpTypes = cmdParser.parse(root: root, namespace: namespace)
        var commands: [String : Command] = [:]

        for f in root.elements(forName: "feature") {
            let stop = f.attribute(forName: "name")!.value == _lastFeature

            cmdParser.pickFromFeature(
                firstCmds: fpTypes,
                feat: f,
                resCmds: &commands
            )

            if stop {
                break
            }
        }

        namespace.commands = commands
    }

    @MainActor
    func parseTypes(root: XMLElement) {
        let tParser = TypeParser(namespacePrefix: namespace.prefix)
        let fpTypes = tParser.parse(root: root)
        var types: OrderedDictionary<String, Type> = [:]

        for f in root.elements(forName: "feature") {
            let stop = f.attribute(forName: "name")!.value == _lastFeature

            tParser.pickFromFeature(
                firstTypes: fpTypes,
                feat: f,
                resTypes: &types
            )

            if stop {
                break
            }
        }

        namespace.types = types
    }
    
    @MainActor
    func parseEnums(root: XMLElement) {
        // First pass
        let enParser = EnumParser(namespacePrefix: namespace.prefix)

        // Second pass
        var enumsDrafted = EnumCollection()
        let enumsFirstPass = enParser.parse(root: root)
        let features = root.elements(forName: "feature")
        // BUG: fundamental problem is that amount of parsed features
        // and hence amout of parsed enum members might depends on
        // member prefix detection
        // lets say:
        // feature 1.0: FW_PROPERTY_COLOR_RED
        //              FW_PROPERTY_COLOR_BLUE
        // feature 1.1: FW_PROPERTY_OPAQUE
        // prefix is going to be FW_PROPERTY_COLOR_ or FW_PROPERTY_
        // depending on the last feature
        for f in features {
            let stop = f.attribute(forName: "name")!.value == _lastFeature

            enParser.pickFromFeature(
                firstEnums: enumsFirstPass,
                feat: f,
                resEnums: &enumsDrafted
            )

            if stop {
                break
            }
        }

        // all enums are drafted
        // assigned their namespace prefix and 
        // find mutual prefix for it's members
        for (_, en) in enumsDrafted.enums {
            // Find common prefix of members
            let cnames = en.members
                .filter { $0.overrideName == nil }
                .map { $0.cName }

            let enumPrefix = if cnames.count > 1 {
                commonPrefix(values: cnames, divider: "_")
            } else {
                // Members already have names
                namespace.prefix + "_"
            }

            var newMembers: [EnumMember] = []
            for m in en.members {
                let name = m.overrideName ?? String(m.cName.dropFirst(enumPrefix.count))
                let newMem = EnumMember(cName: m.cName, name: name, value: m.value)
                newMembers.append(newMem)
            }
            let newEn = Enum (
                cname: en.cName,
                name: en.name,
                nsPrefix: namespace.prefix,
                enumPrefix: enumPrefix,
                isBitmask: en.isBitmask,
                members: consume newMembers
            )

            namespace.addEnum(newEn)
        }
    }
}
