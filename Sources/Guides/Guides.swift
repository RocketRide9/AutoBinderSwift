import Foundation

public struct Guides : Decodable
{
    public let EnumCommentGuides: [String : EnumCommentGuides]
    public let Overrides: Overrides

    public let TypeGuides: [TypeGuide]
    public let StructGuides: [StructGuide]

    @MainActor
    public static let guides: Guides = {
        let url = URL(fileURLWithPath: "./guides.json")
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Guides.self, from: jsonData)
        } catch {
            fatalError("Failed to load or parse Guides.json: \(error)")
        }
    }()

    public func findStructGuide (_ cname: String) -> StructGuide? {
        StructGuides.first { cname.contains($0.MatchRegex) }
    }

    public func findTypeGuide (_ cname: String) -> TypeGuide? {
        TypeGuides.first { cname.contains($0.MatchRegex) }
    }

    public func findEnums (_ memberName: String) -> [Enum] {
        return Overrides
            .Enums
            .filter { $0.Members.contains (memberName) }
    }
}

public enum ActionType {
    case Parse
    case Skip
}

extension String {
    fileprivate func intoAction() -> ActionType {
        return switch self {
            case "Parse": .Parse
            case "Skip": .Skip
            default: fatalError("Unexpected Action value: \(self)")
        }
    }
}

public struct EnumCommentGuides : Decodable {
    public let Action: ActionType 
    public let Name: String?
    public let CName: String?
    public let ParentType: String?
    public let Attributes: [AttributeDescription]?

    private enum CodingKeys: CodingKey {
      case Action
      case Name
      case CName
      case ParentType
      case Attributes
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: EnumCommentGuides.CodingKeys.self)

      self.Action = try container.decodeIfPresent(String.self, forKey: .Action)?.intoAction() ?? .Parse
      self.Name = try container.decodeIfPresent(String.self, forKey: .Name)
      self.CName = try container.decodeIfPresent(String.self, forKey: .CName)
      self.ParentType = try container.decodeIfPresent(String.self, forKey: .ParentType)
      self.Attributes = try container.decodeIfPresent([AttributeDescription].self, forKey: .Attributes)
    } 
}

public struct AttributeDescription : Decodable
{
    public let Name: String
    public let Properties: Dictionary<String, String>? 
}

public struct Overrides : Decodable
{
    public let Enums: [Enum] 
    public let EnumMembers: [EnumMember] 
}

public struct EnumMember : Decodable
{
    public let CName: String 
    public let Name: String 
}

public struct Enum : Decodable
{
    public let Name: String 
    public let CName: String 
    public let Members: [String] 
}

public struct TypeGuide : Decodable
{
    public let MatchRegex: Regex<Substring>
    // Possible values: Parse, Skip
    public let Action: ActionType
    public let Transparent: Bool

    private enum CodingKeys: CodingKey {
      case MatchPattern
      case Action
      case Transparent
    }

    public init(from decoder: any Decoder) throws {
        let values  = try decoder.container(keyedBy: CodingKeys.self)
        Action      = try values.decodeIfPresent(String.self, forKey: .Action)?.intoAction() ?? .Parse
        Transparent = try values.decodeIfPresent(String.self, forKey: .Transparent) == "true";

        let matchPattern    = try values.decode(String.self, forKey: .MatchPattern)
        MatchRegex          = try Regex.init(matchPattern)
    }
}

public struct StructGuide : Decodable
{
    public let MatchRegex: Regex<Substring>
    // Possible values: Parse, Skip
    public let Action: ActionType

    private enum CodingKeys: CodingKey {
      case MatchPattern
      case Action
    }

    public init(from decoder: any Decoder) throws {
        let values  = try decoder.container(keyedBy: CodingKeys.self)
        Action      = try values.decodeIfPresent(String.self, forKey: .Action)?.intoAction() ?? .Parse

        let matchPattern    = try values.decode(String.self, forKey: .MatchPattern)
        MatchRegex          = try Regex.init(matchPattern)
    }
}