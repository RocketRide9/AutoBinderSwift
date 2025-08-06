struct Function
{
    static func parseArgument(_ arg: String) -> (type: String, stars: UInt, name: String)?
    {
        let reg = /^\s*(?:const )?\s*([ \w]+?)\s*([\* ]+?)\s*(\w+)\s*(\[\])?$/

        let match = try! reg.firstMatch(in: arg)
        guard let match = match else { return nil }
        let type = match.1
        let stars = UInt(match.2.count { $0=="*" })
        let name = match.3

        // TODO: use this variable
        // let isArray = match.4 != nil

        return (String(type), stars, String(name))
    }
}
