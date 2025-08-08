public class Command {
    let cname: String
    let name: String
    let returnType: Type
    let parameters: [TypeNamePair]

    init(cname: String, name: String, returnType: any Type, parameters: [TypeNamePair]) {
        self.cname = cname
        self.name = name
        self.returnType = returnType
        self.parameters = parameters
    }
}