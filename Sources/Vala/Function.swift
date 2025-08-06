import Foundation
import OrderedCollections

class Function : Symbol {
    let returnType: String
    var identifier: String {name}
    var cName: String {name}
    var name: String
    let parameters: [FuncParameter]

    public init(returnType: String, name: String, parameters: [FuncParameter]) {
        self.returnType = returnType
        self.name = name
        self.parameters = parameters
    }

    func asSource() -> String {
        String(
            format: "public %@ %@(\n%@\n);\n",
            returnType,
            name,
            parameters
                .map {"    " + $0.asSource()}
                .joined(separator: ", \n")
        )
    }
}

struct FuncParameter {
    let type: String
    let name: String
    let typeConversion: OrderedDictionary<String, String> = [:]

    func asSource() -> String {
        "\(type) \(name)"
    }
}