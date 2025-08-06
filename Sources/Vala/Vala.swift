protocol Symbol
{
    var identifier: String { get }

    /// - Returns:
    /// Vala source of this object
    func asSource() -> String
}