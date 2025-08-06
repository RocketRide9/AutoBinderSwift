import FoundationXML

public extension XMLElement {
    func element(_ name: String) -> XMLElement?
    {
        self.elements(forName: name).first
    }

    var elements: [XMLElement]
    {
        let res = self.children?.filter { $0 is XMLElement }
        return res?.map { $0 as! XMLElement } ?? []
    }
}

public extension XMLNode {
    var value: String {
        self.stringValue!
    }
}
