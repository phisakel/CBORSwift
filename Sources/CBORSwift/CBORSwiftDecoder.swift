import Foundation

public protocol CBORDecodable {
    var decode: CBOREncodable? { get }
}

struct CBORDecoder {
    static func extractHeaderBody(header: UInt8, body: [UInt8], baseTag: Int) -> (Int, [UInt8]) {
        switch Int(header) % baseTag {
        case 24:
            return (Data([UInt8](body[0...0])).hex.hex_decimal, [UInt8](body[1..<body.count]))
        case 25:
            return (Data([UInt8](body[0...1])).hex.hex_decimal, [UInt8](body[2..<body.count]))
        case 26:
            return (Data([UInt8](body[0...3])).hex.hex_decimal, [UInt8](body[4..<body.count]))
        default:
            return (Data([header % UInt8(baseTag)]).hex.hex_decimal, [])
        }
    }

    static func extractHeaderBody(header: Int, body: [UInt8]) -> (Int, [UInt8]) {
        switch header {
        case 0..<24:
            return (header, [UInt8](body[0..<body.count]))
        case 24:
            return (Int(body[0]), [UInt8](body[1..<body.count]))
        case 25:
            return ([0, 1].reduce(into: "") { (result: inout String, index: Int) in
                        result += Int(body[index]).hex
                    }.hex_decimal, [UInt8](body[2..<body.count]))
        case 26:
            return ([0, 1, 2, 3].reduce(into: "") { (result: inout String, index: Int) in
                        result += Int(body[index]).hex
                    }.hex_decimal, [UInt8](body[3..<body.count]))
        case 27:
            return ([0, 1, 2, 3, 4].reduce(into: "") { (result: inout String, index: Int) in
                        result += Int(body[index]).hex
                    }.hex_decimal, [UInt8](body[4..<body.count]))
        default:
            fatalError("Unacceptable header value")
        }
    }
}