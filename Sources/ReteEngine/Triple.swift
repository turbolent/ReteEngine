
public struct Triple<Constant>: WME where Constant: Hashable {
    public let identifier: Constant
    public let attribute: Constant
    public let value: Constant

    public init(identifier: Constant, attribute: Constant, value: Constant) {
        self.identifier = identifier
        self.attribute = attribute
        self.value = value
    }

    public init(_ identifier: Constant, _ attribute: Constant, _ value: Constant) {
        self.init(
            identifier: identifier,
            attribute: attribute,
            value: value
        )
    }
}
