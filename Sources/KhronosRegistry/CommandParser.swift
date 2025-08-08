import FoundationXML
import Strings
import Guides

class CommandParser {
    // Command.cname : Command
    private var cmds: [String : Command] = [:]

    private let nsPrefix: String

    init(namespacePrefix: String) {
        nsPrefix = namespacePrefix
    }

    @MainActor
    func parse(root: XMLElement, namespace: Namespace) -> [String : Command] {
        for cmds in root.elements(forName: "commands") {
            for cmd in cmds.elements(forName: "command") {
                registerCmd(cmdElem: cmd, namespace: namespace)
            }
        }

        return cmds
    }

    @MainActor
    func registerCmd(cmdElem: XMLElement, namespace: Namespace) {
        let proto = cmdElem.element("proto")!.value
        let (retTypeCName, retStars, cmdCName) = Function.parseArgument(proto)!
        guard var retType = namespace.findType(cname: retTypeCName) else {
            print("Couldn't find '\(retTypeCName)'")
            print("Skipping function \(cmdCName)")
            return
        }

        for _ in 0..<retStars {
            retType = Ptr(target: retType)
        }


        let guides = Guides.guides
        if guides.findCommandGuide(cmdCName)?.Action == .Skip {
            return
        }

        var typeNamePairs: [TypeNamePair] = []
        for argElem in cmdElem.elements(forName: "param") {
            guard let (typeCName, stars, argName) = Function.parseArgument(argElem.value) else {
                print("Couldn't parse '\(argElem.value)'")
                print("Skipping function \(cmdCName)")
                return
            }

            guard var type = namespace.findType(cname: typeCName) else {
                print("Couldn't find '\(typeCName)'")
                print("Skipping function \(cmdCName)")
                return
            }

            for _ in 0..<stars {
                type = Ptr(target: type)
            }

            typeNamePairs.append(.init(type: type, cName: argName))
        }

        let cmdName = removeNsPrefix(cmdCName, nsPrefix)
        cmds[cmdName] = .init(
            cname: cmdCName,
            name: cmdName,
            returnType: retType,
            parameters: typeNamePairs,
        )
    }

    @MainActor
    func pickFromFeature(
        firstCmds: [String : Command],
        feat: XMLElement,
        resCmds: inout [String : Command]
    ) {
        let guides = Guides.guides
        for req in feat.elements {
            guard req.elements.first!.name == "command" else {
                // skip non command <require>
                continue
            }
            
            for el in req.elements {
                guard el.name == "command" else {
                    fatalError("expected 'type', got '\(el.name!)'")
                }
                
                let cmdCName = el.attribute(forName: "name")!.value
                
                if guides.findCommandGuide(cmdCName)?.Action == .Skip {
                    continue
                }
                
                // let reg = /^\w+$/
                // if !cmdCName.contains(reg) {
                //     // not a valid identifier
                //     // probably header name
                //     break
                // }
                
                let cmdName = removeNsPrefix(cmdCName, nsPrefix)
                resCmds[cmdName] = firstCmds[cmdName]!
            }
        }
    }
}