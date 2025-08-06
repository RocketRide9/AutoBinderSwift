import OrderedCollections

class EnumCollection
{
    // Name : Enum
    public private(set) var enums: OrderedDictionary<String, EnumDraft> = [:]

    func findMember (_ pairName: String) -> EnumMemberDraft
    {
        for (_, en) in enums {
            if let member = en.members.first(where: { $0.cName == pairName }) {
                return member
            }
        }

        fatalError("Couldn't find a member with name: \(pairName)")
    }

    func addEnumIfNotExists (_ en: EnumDraft)
    {
        if enums[en.name] == nil {
            enums[en.name] = en;
        }
    }

    func addMember (_ enumName: String, _ member: EnumMemberDraft)
    {
        guard let en = enums[enumName] else {
            fatalError("\(enumName) doesn't exist in this collection")
        } 

        en.members.append(member)
    }
}