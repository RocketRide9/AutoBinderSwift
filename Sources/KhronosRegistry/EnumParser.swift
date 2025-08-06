import FoundationXML
import Guides
import Strings

class EnumParser {
    private let nsPrefix: String
    
    init(namespacePrefix: String) {
        self.nsPrefix = namespacePrefix
    }
    
    // 1. Parse enums as they are presented in <enums> elements
    func parse(root: XMLElement) -> EnumCollection {
        let enums = EnumCollection()
        
        // First pass
        for elemEn in root.elements(forName: "enums") {
            let cName = elemEn.attribute(forName: "name")!.value
            // HACK: Name doesn't matter in this case. Just anything
            let name = cName;
            let isBitmask = elemEn.attribute(forName: "type")?.value == "bitmask"

            let en = EnumDraft(cname: cName, name: name, isBitmask: isBitmask)
            
            for elemMember in elemEn.elements {
                switch elemMember.name {
                    case "enum":
                        let name = elemMember.attribute(forName: "name")!.value
                        let val = elemMember.attribute(forName: "value")?.value
                            ?? "1<<" + elemMember.attribute(forName: "bitpos")!.value
                        
                        en.members.append(.init(cname: name, value: val))
                    
                    case "unused", "comment":
                        // just skip it
                        continue

                    default:
                        fatalError("Unhandled enum element: \(elemMember.name!)")
                }
            }

            enums.addEnumIfNotExists(en)
        }
        
        if enums.enums.isEmpty {
            fatalError("Didn't find any <enums> elements")
        }
        
        return enums
    }
    
    // 2. Parse features to get more info how enums are structured
    // e.g. `CL_MEM_DEVICE_HANDLE_LIST_KHR = 0x2051` is located inside <enums name="enums.2000"...>
    // and by looking at feature we get a more helpful enum identifier hint - `cl_mem_properties` or `MemProperties`
    @MainActor
    func pickFromFeature(
        firstEnums: EnumCollection,
        feat: XMLElement,
        resEnums: inout EnumCollection
    ) {
        for req in feat.elements {

            guard let firstChild = req.elements.first else { continue }
            if firstChild.name != "enum" {
                // skip non enum <require>
                continue
            }
            
            var comment = req.attribute(forName: "comment")!.value
            let guides = Guides.guides
            
            let over = guides.EnumCommentGuides[comment]
            if over?.Action == .Skip {
                continue
            }
            let overrideEnName = over?.Name
            let overrideEnCName = over?.CName
            
            let bitmaskSuffix = " - bitfield"
            let isBitmask = comment.hasSuffix(bitmaskSuffix)
            if isBitmask {
                comment = String(comment.dropLast(bitmaskSuffix.count))
            }
            
            for el in req.elements {
                guard el.name == "enum" else {
                    // we assume that elements in <require> have the same type
                    fatalError("expected 'enum', got \(el.name!)")
                }
                
                let memberName = el.attribute(forName: "name")!.value
                let enMember = firstEnums.findMember(memberName)
                
                enMember.overrideName = guides
                    .Overrides
                    .EnumMembers
                    .first {$0.CName == memberName}?
                    .Name
                
                let overrideEnums = guides.findEnums(memberName)
                if !overrideEnums.isEmpty {
                    for en in overrideEnums {
                        let en2 = EnumDraft(
                            cname: en.CName,
                            name: en.Name,
                            isBitmask: isBitmask
                        )
                        resEnums.addEnumIfNotExists(en2)
                        resEnums.addMember(en2.name, .init(other: enMember))
                    }
                } else {
                    let cname = overrideEnCName ?? comment
                    let name = overrideEnName ?? removeNsPrefix(cname, nsPrefix)
                    let en2 = EnumDraft(
                        cname: cname,
                        name: name,
                        isBitmask: isBitmask
                    )
                    en2.isBitmask = isBitmask
                    resEnums.addEnumIfNotExists(en2)
                    resEnums.addMember(en2.name, enMember)
                }
            }
        }
    }
}
