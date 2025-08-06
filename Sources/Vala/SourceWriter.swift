import KhronosRegistry
import Foundation

public class SourceWriter {
    public init() {}

    public func write (
        writer: URL,
        registry: Registry
    ) {
        let namesp = Namespace(khrNamespace: registry.namespace)
        try! namesp.asSource().write(to: writer, atomically: false, encoding: String.Encoding.utf8)
    }
}