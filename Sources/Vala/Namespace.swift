import Foundation
import Strings
import KhronosRegistry
import OrderedCollections

class Namespace: Symbol {
    var simpleTypes: OrderedDictionary<String, SimpleType> = [:]
    var enums: OrderedDictionary<String, Enum> = [:]
    let identifier: String
    
    // Transparent typedef might point on another transparent
    // typedef and so on...
    // This function returns resulting typename
    private static func unTypedef(_ typed: Typedef) -> String {
        switch typed.baseType {
            case let basic as BasicType:
                basicTypesConversion[basic.name] ?? basic.name
            case let opaque as OpaqueType:
                snakeToPascal(opaque.name)
            case let typed2 as Typedef where typed2.transparent:
                unTypedef(typed2)
            case let typed2 as Typedef where !typed2.transparent:
                snakeToPascal(typed2.name)
            default:
                fatalError("Unexpected type")
        }
    }
    
    static let basicTypesConversion: OrderedDictionary<String, String> = [
        "char":             "char",
        "int":              "int",
        "unsigned char":    "uchar",
        "unsigned int":     "uint",
        "intptr_t":         "intptr",
        "size_t":           "size_t",
        "float":            "float",
        "double":           "float",
        
        "int8_t":           "int8",
        "int16_t":          "int16",
        "int32_t":          "int32",
        "int64_t":          "int64",
        "uint8_t":          "uint8",
        "uint16_t":         "uint16",
        "uint32_t":         "uint32",
        "uint64_t":         "uint64",
    ]
    
    // TODO: Vala namespace shouldn't know about Khronos stuff
    init(khrNamespace: KhronosRegistry.Namespace) {
        self.identifier = khrNamespace.name
        
        // Convert enums
        for en in khrNamespace.enums {
            var valaEn = Enum(identifier: snakeToPascal(en.name))
            
            let members = en.members.map { m in
                var attrs: [Attribute] = []
                if m.isCNameOverriden() {
                    attrs.append(CCode(cname: m.cName))
                }
                let res = EnumMember(
                    name: m.name,
                    value: m.value,
                    attributes: attrs
                )
                return res
            }
            
            valaEn.add(members)
            valaEn.attributes.append(
                CCode(
                    cname: en.cName,
                    cprefix: en.enumPrefix.uppercased(),
                )
            )
            enums[valaEn.identifier] = valaEn
        }
        
        // Convert types
        for (khrName, khrType) in khrNamespace.types {
            switch khrType {
            case let t as OpaqueType:
                let name = snakeToPascal(khrName)
                let simple = SimpleType(name: name)
                simple.attributes.append(CCode(cname: t.cName))
                simpleTypes[simple.identifier] = simple
                
            case let t as Typedef:
                guard !t.transparent else { continue }
                
                let name = snakeToPascal(khrName)
                let parentType = Namespace.unTypedef(t)
                let simple = SimpleType(name: name, parentType: parentType)
                simple.attributes.append(CCode(cname: t.cName))
                
                if enums[simple.identifier] == nil {
                    simpleTypes[simple.identifier] = simple
                }
                
            default:
                break
            }
        }
    }
    
    func asSource() -> String {
        var result = "namespace \(identifier) {\n\n"
        
        for (_, sim) in simpleTypes {
            result += "\(sim.asSource())\n"
        }
        
        for (_, en) in enums {
            result += "\(en.asSource())\n"
        }
        
        result += "}\n"
        
        return result
    }
}