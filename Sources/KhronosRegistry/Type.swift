import OrderedCollections

public protocol Type {}

public struct OpaqueType: Type {
    public let cName: String
    public let name: String
}

public struct Typedef: Type {
    public let cName: String
    public let name: String
    public let baseType: Type
    public let transparent: Bool
}

public struct BasicType: Type {
    public let name: String
}

public struct TypeNamePair {
    public let type: Type
    public let cName: String
}

public struct Struct: Type {
    public let cName: String
    public var name: String
    public var members: OrderedDictionary<String, TypeNamePair> = [:]
}

public struct Ptr: Type {
    public enum PtrType {
        case out
        case `in`
        case unknown
    }
    
    public let target: Type
    public let type: PtrType = .unknown
}

public enum TypeCollection {
    // HACK: basic types can be retrieved from the XML
    // HACK: BasicTypes probably need their own namespace
    // TODO: Still not sure if void should be included
    public static let basicTypes: Set<String> = [
        "void",
        "char", // i8
        "int",  // i32
        "unsigned char", // u8
        "unsigned int",  // u32
        "intptr_t", // isize - ptr size
        "size_t",   // isize - index size
        "float",    // f32
        "double",   // f64

        "int8_t",   // i8
        "int16_t",  // i16
        "int32_t",  // i32
        "int64_t",  // i64
        "uint8_t",  // u8
        "uint16_t", // u16
        "uint32_t", // u32
        "uint64_t", // u64
    ]
}