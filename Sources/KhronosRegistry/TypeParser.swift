import FoundationXML
import Guides
import Strings
import Extensions
import OrderedCollections

fileprivate struct TypeNamePairDraft {
    public let typeStr: String
    public let stars: UInt
    public let argName: String   
}

fileprivate struct StructDraft {
    public let cName: String
    public var name: String
    public var members: OrderedDictionary<String, TypeNamePairDraft> = [:]
}

class TypeParser {
    private var opaqueTypes: Set<String> = []
    private var typeDefs: OrderedDictionary<String, String> = [:]
    private var structs: OrderedDictionary<String, StructDraft> = [:]
    
    private let nsPrefix: String
    
    init(namespacePrefix: String) {
        self.nsPrefix = namespacePrefix
    }
    
    // Name -> Type
    @MainActor
    func parse(root: XMLElement) -> OrderedDictionary<String, Type> {
        for ts in root.elements(forName: "types") {
            for t in ts.elements(forName: "type") {
                let val = t.attribute(forName: "category")!.value
                
                switch val {
                    case "define":
                        registerDefine(typedef: t)
                    case "include":
                        // TODO: idk what to do with it
                        continue
                    case "struct":
                        registerStruct(structElement: t)
                    default:
                        print("Unhandled type category \(val)")
                }
            }
        }
        
        let guides = Guides.guides
        var res: OrderedDictionary<String, Type> = [:]
        
        // Process opaque types
        for opCName in opaqueTypes {
            let name = removeNsPrefix(opCName, nsPrefix)
            res[name] = OpaqueType(cName: opCName, name: name)
        }
        
        // Process typedefs
        for (tdCName, baseCName) in typeDefs {
            let tdname = removeNsPrefix(tdCName, nsPrefix)
            let baseName: String
            
            if TypeCollection.basicTypes.contains(baseCName) {
                baseName = baseCName
            } else {
                baseName = removeNsPrefix(baseCName, nsPrefix)
            }
            
            var transparent = false
            for item in guides.TypeGuides {
                transparent = transparent
                    || tdCName.contains(item.MatchRegex)
            }
            
            // HACK: How basic types are handled is a big smelly hack.
            // There are a lot of assumptions that symbol names won't collide
            // Future me: they shouldn't collide if they aren't stored in the same
            // dictionary
            if let val = res[baseName] {
                res[tdname] = Typedef(
                    cName: tdCName,
                    name: tdname,
                    baseType: val,
                    transparent: transparent
                )
            } else if TypeCollection.basicTypes.contains(baseName) {
                res[tdname] = Typedef(
                    cName: tdCName, 
                    name: tdname, 
                    baseType: BasicType(name: baseName),
                    transparent: transparent
                )
            }
        }
        
        // Process structs
        for (_, strTemplate) in structs {
            let guide = guides.findStructGuide(strTemplate.cName)
            if guide?.Action == .Skip {
                continue
            }
            
            let strtName = removeNsPrefix(strTemplate.cName, nsPrefix)
            
            var final = Struct(cName: strTemplate.cName, name: strtName)
            for (_, member0) in strTemplate.members {
                if member0.argName.isEmpty {
                    // TODO: fix parser to stop skipping
                    print("Skipped")
                    continue
                }
                
                let typeName = removeNsPrefix(member0.typeStr, nsPrefix, strict: false)
                
                var type: Type
                if let resType = res[typeName] {
                    type = resType
                } else if TypeCollection.basicTypes.contains(typeName) {
                    type = BasicType(name: typeName)
                } else {
                    fatalError("Type \(typeName) wasn't found")
                }
                
                for _ in 0..<member0.stars {
                    type = Ptr(target: type)
                }
                
                let member1 = TypeNamePair(type: type, cName: member0.argName)
                final.members[member1.cName] = member1
            }
            
            res[final.name] = final
        }
        
        return res
    }
    
    @MainActor func pickFromFeature(
        firstTypes: OrderedDictionary<String, Type>,
        feat: XMLElement,
        resTypes: inout OrderedDictionary<String, Type>
    ) {
        let guide = Guides.guides
        
        for req in feat.elements {
            guard req.elements.first!.name == "type" else {
                // skip non type <require>
                continue
            }
            
            for el in req.elements {
                guard el.name == "type" else {
                    fatalError("expected \"type\", got \"\(el.name!)\"")
                }
                
                let typeCName = el.attribute(forName: "name")!.value
                
                if guide.findStructGuide(typeCName)?.Action == .Skip {
                    continue
                }
                
                if guide.findTypeGuide(typeCName)?.Action == .Skip {
                    continue
                }
                
                let reg = /^\w+$/
                if !typeCName.contains(reg) {
                    // not a valid identifier
                    // probably header name
                    break
                }
                
                let typeName = removeNsPrefix(typeCName, nsPrefix)
                resTypes[typeName] = firstTypes[typeName]
            }
        }
    }
    
    @MainActor
    private func registerDefine(typedef: XMLElement) {
        let type = typedef.element("type")?.value
        var name = typedef.element("name")?.value
        
        let guides = Guides.guides
        
        guard name != nil else {
            // conditional constant definition
            // TODO: handle it
            name = typedef.attribute(forName: "name")!.value
            return
        }

        let guide = guides.findTypeGuide(name!)
        if (guide?.Action == .Skip)
        {
            return
        }
        
        if type == nil || type == "void" {
            opaqueTypes.insert(name!)
        } else {
            typeDefs[name!] = type
        }
    }
    
    private func registerStruct(structElement: XMLElement) {
        let cname = structElement.attribute(forName: "name")!.value
        let name = removeNsPrefix(cname, nsPrefix)
        var strt = StructDraft(cName: cname, name: name)
        
        for member in structElement.elements(forName: "member") {
            guard let (typeStr, stars, argName) = Function.parseArgument(member.value)
                else { continue; }
            let typeNamePair = TypeNamePairDraft(typeStr: typeStr, stars: stars, argName: argName)
            strt.members[argName] = typeNamePair
        }
        
        structs[cname] = strt
    }
}
