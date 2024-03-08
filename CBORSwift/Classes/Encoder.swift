//
//  Encoder.swift
//  CBORSwift
//
//  Created by Hassan Shahbazi on 5/2/18.
//  Copyright © 2018 Hassan Shahbazi. All rights reserved.
//

import Foundation

let isBigEndian = Int(bigEndian: 42) == 42
/// Takes a value breaks it into bytes. assumes necessity to reverse for endianness if needed
/// This function has only been tested with UInt_s, Floats and Doubles
/// T must be a simple type. It cannot be a collection type.
func rawBytes<T>(of x: T) -> [UInt8] {
    var mutable = x // create mutable copy for `withUnsafeBytes`
    let bigEndianResult = withUnsafeBytes(of: &mutable) { Array($0) }
    return isBigEndian ? bigEndianResult : bigEndianResult.reversed()
}

class Encoder: NSObject {
    class func prepareByteArray(major: MajorType, measure: Int) -> [UInt8] {
        var encoded = MajorTypes(major).get().bytes
        
        var rawBytes = [UInt8]()
        prepareHeaderByteArray(bytes: &rawBytes, measure: measure)
        rawBytes.append(contentsOf: measure.decimal_binary)
        encoded.append(contentsOf: [UInt8](rawBytes[3..<rawBytes.count]))
        
        return encoded
    }
    
    private class func prepareHeaderByteArray(bytes: inout [UInt8], measure: Int) {
        let upperBound: UInt64 = 4294967295
        
        if measure >= 0 && measure <= 23 {}
        else if measure >= 24 && measure <= 255 { bytes = 24.decimal_binary }
        else if measure >= 256 && measure <= 65535 { bytes = 25.decimal_binary }
        else if measure >= 65536 && measure <= upperBound { bytes = 26.decimal_binary }
    }
    
    class func getIncludedEncodings(item: AnyObject) -> String {
        var data = ""
        data.append(item.encode())
        return data
    }
    
    // copied from swift-cbor
    // MARK: - major 0: unsigned integer

    public static func encodeUInt8(_ x: UInt8) -> [UInt8] {
        if (x < 24) { return [x] }
        else { return [0x18, x] }
    }

    public static func encodeUInt16(_ x: UInt16) -> [UInt8] {
        return [0x19] + rawBytes(of: x)
    }

    public static func encodeUInt32(_ x: UInt32) -> [UInt8] {
        return [0x1a] + rawBytes(of: x)
    }

    public static func encodeUInt64(_ x: UInt64) -> [UInt8] {
        return [0x1b] + rawBytes(of: x)
    }

    internal static func encodeVarUInt(_ x: UInt64) -> [UInt8] {
        switch x {
        case let x where x <= UInt8.max: return encodeUInt8(UInt8(x))
        case let x where x <= UInt16.max: return encodeUInt16(UInt16(x))
        case let x where x <= UInt32.max: return encodeUInt32(UInt32(x))
        default: return encodeUInt64(x)
        }
    }

    // MARK: - major 1: negative integer

    public static func encodeNegativeInt(_ x: Int64) -> [UInt8] {
        assert(x < 0)
        var res = encodeVarUInt(~UInt64(bitPattern: x))
        res[0] = res[0] | 0b001_00000
        return res
    }

    // MARK: - major 2: bytestring

    public static func encodeByteString(_ bs: [UInt8]) -> [UInt8] {
        var res = bs.count.getBinaryData().bytes // .encode()
        res[0] = res[0] | 0b010_00000
        res.append(contentsOf: bs)
        return res
    }
    
    #if canImport(Foundation)
    public static func encodeData(_ data: Data) -> [UInt8] {
        return encodeByteString([UInt8](data))
    }
    #endif

    // MARK: - major 3: UTF8 string

    public static func encodeString(_ str: String) -> [UInt8] {
        let utf8array = Array(str.utf8)
        var res = utf8array.count.getBinaryData().bytes //.encode()
        res[0] = res[0] | 0b011_00000
        res.append(contentsOf: utf8array)
        return res
    }
    // MARK: - major 7: floats, simple values, the 'break' stop code

     public static func encodeSimpleValue(_ x: UInt8) -> [UInt8] {
         if x < 24 {
             return [0b111_00000 | x]
         } else {
             return [0xf8, x]
         }
     }

     public static func encodeNull() -> [UInt8] {
         return [0xf6]
     }

     public static func encodeUndefined() -> [UInt8] {
         return [0xf7]
     }

     public static func encodeBreak() -> [UInt8] {
         return [0xff]
     }

     public static func encodeFloat(_ x: Float) -> [UInt8] {
         return [0xfa] + rawBytes(of: x)
     }

     public static func encodeDouble(_ x: Double) -> [UInt8] {
         return [0xfb] + rawBytes(of: x)
     }

     public static func encodeBool(_ x: Bool) -> [UInt8] {
         return x ? [0xf5] : [0xf4]
     }
}

extension NSObject: Any {
    @objc internal func encode() -> String {
        return self.encode()
    }
}

extension NSNumber {
    @objc override func encode() -> String {
        let major: MajorType = (self.intValue < 0) ? .major1 : .major0
        let measure = (self.intValue < 0) ? (self.intValue * -1) - 1 : self.intValue

        let encodedArray = Encoder.prepareByteArray(major: major, measure: measure)
        return Data(encodedArray).binary_decimal.hex
    }
}

extension NSNumber: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return self.intValue.getBinaryData()
    }
}

extension NSString {
    @objc override func encode() -> String {
        let strData = (self as String).data(using: .utf8)!.hex
        let encodedArray = Encoder.prepareByteArray(major: .major3, measure: self.length)
        let headerData  = Data(encodedArray).binary_decimal.hex
         
        return headerData.appending(strData)
    }
}

// philip fix for encoding strings
extension NSString: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return (self as String).getBinaryData()
    }
}

extension NSArray {
    @objc override func encode() -> String {
        let encodedArray = Encoder.prepareByteArray(major: .major4, measure: self.count)
        return (Data(encodedArray).binary_decimal.hex).appending(getItemsEncoding())
    }
    
    private func getItemsEncoding() -> String {
        var data = ""
        for item in self {
            data.append(Encoder.getIncludedEncodings(item: item as AnyObject))
        }
        return data
    }
}

extension NSDictionary {
    @objc override func encode() -> String {
        let encodedArray = Encoder.prepareByteArray(major: .major5, measure: self.allKeys.count)
        return (Data(encodedArray).binary_decimal.hex).appending(getItemsEncoding())
    }
    
    private func getItemsEncoding() -> String {
        var data = ""
        var key_value = [String:String]()
        for (key, value) in self {
            key_value[Encoder.getIncludedEncodings(item: key as AnyObject)] = Encoder.getIncludedEncodings(item: value as AnyObject)
        }
        
        let dic = key_value.valueKeySorted
        for item in dic {
            data.append(item.0)
            data.append(item.1)
        }
        return data
    }
}

extension NSData {
    @objc override func encode() -> String {
        let data = self as Data
        let encodedArray = Encoder.prepareByteArray(major: .major2, measure: data.count)
        return Data(encodedArray).binary_decimal.hex
    }
}
