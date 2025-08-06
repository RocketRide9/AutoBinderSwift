import Foundation

public func snakeToPascal(_ snake: String) -> String {
    snake
        .split(separator: "_")
        .map { $0.prefix(1).capitalized + $0.dropFirst() }
        .joined()
}

public func removeNsPrefix(
    _ name: String, 
    _ nsPrefix: String, 
    strict: Bool = true
) -> String {
    let lowerName = name.lowercased()
    let lowerPrefix = nsPrefix.lowercased()
    
    if lowerName.starts(with: lowerPrefix + "_") {
        let index = name.index(name.startIndex, offsetBy: nsPrefix.count + 1)
        return String(name[index...])
    } 
    else if lowerName.starts(with: lowerPrefix) {
        let index = name.index(name.startIndex, offsetBy: nsPrefix.count)
        return String(name[index...])
    }
    else if !strict {
        return name
    } 
    else {
        fatalError("name: \(name), prefix: \(nsPrefix)")
    }
}

/// 
/// - Parameters:
///   - values: 
///   - atom: Delimeter of parts that can not be devided while searching
/// for common prefix, usually '_'
/// - Returns: Common prefix
public func commonPrefix(values: [String], divider: Unicode.Scalar) -> String {
    let path = values.first!
    var common = ""
    prefixSearch: while true {
        guard let underscoreIndex = path.rangeOfCharacter(
            from: [divider],
            range: common.endIndex..<path.endIndex
        )?.lowerBound else {
            break
        }
        
        let proposedPrefix = String(path[...underscoreIndex])
        
        // Check members that doesn't already have a Name
        for val in values {
            if !val.lowercased().hasPrefix(proposedPrefix.lowercased()) {
                break prefixSearch
            }
        }
        
        common = proposedPrefix
    }

    return common
}