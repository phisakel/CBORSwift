//
//  MyNSObject.swift
//  CBORSwift
//
//  Created by Hassan Shahbazi on 2018-05-15.
//  Copyright © 2018 Hassan Shahbazi. All rights reserved.
//

import Foundation

// philip additions

public protocol BinaryDataEncodable {
    func getBinaryData() -> Data
}

public class NSByteString: NSObject {
    private var value: String = ""
    private var bytes: [UInt8]!
    
    public init(_ value: String) {
        super.init()
        self.value = value
    }
    
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    public func stringValue() -> String {
        if let ba = bytes, ba.count>0, value.count == 0 {
            value = ba.data!.hex
        }
        return value
    }
  
  override public var description: String { "0x: \(stringValue())" }
    
    public var byteArray: [UInt8] {
        if let ba = bytes { return ba }
        var res = [UInt8]()
        for offset in stride(from: 0, to: self.value.count, by: 2) {
            let byte = value[offset..<offset+2].hex_decimal
            res.append(UInt8(byte))
        }
        return res
    }
    
    @objc internal override func encode() -> String {

        let encodedArray = Encoder.prepareByteArray(major: .major2, measure: byteArray.count)
        let headerData   = Data(encodedArray).binary_decimal.hex
        let byteData     = Data(byteArray).hex
        
        return headerData.appending(byteData)
    }
}

extension NSByteString: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeByteString(byteArray).data!
    }
}

extension Array {
      var data : Data?{
          return (self is Array<UInt8>) ? Data(self as! Array<UInt8>) : nil
      }
      var byteString: String? {
          return (self is Array<UInt8>) ? (self as! Array<UInt8>).map { String(format: "%02x", $0)}.joined() : nil
      }
  }

extension Int: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        if (self < 0) {
            return Encoder.encodeNegativeInt(Int64(self)).data!
        } else {
            return Encoder.encodeVarUInt(UInt64(self)).data!
        }
    }
}

extension UInt: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeVarUInt(UInt64(self)).data!
    }
}

extension UInt8: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeUInt8(self).data!
    }
}


extension UInt16: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeUInt16(self).data!
    }
}


extension UInt64: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeUInt64(self).data!
    }
}

extension UInt32: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeUInt32(self).data!
    }
}

extension String: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeString(self).data!
    }
}

extension Float: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeFloat(self).data!
    }
}

extension Double: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeDouble(self).data!
    }
}

extension Bool: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        return Encoder.encodeBool(self).data!
    }
}

public class NSSimpleValue: NSObject {
    private static let FALSECode: UInt8   = 0x14
    private static let TRUECode: UInt8    = 0x15
    private static let NILCode: UInt8     = 0x16
    private var value: Bool?
    
    public init(_ value: NSNumber?) {
        super.init()
        self.value = value?.boolValue
    }
    
    public func stringValue() -> Bool {
        return self.value!
    }
    
    @objc internal override func encode() -> String {
        var byte = NSSimpleValue.NILCode
        if value != nil {
            byte = (value!) ? NSSimpleValue.TRUECode : NSSimpleValue.FALSECode
        }
        var encodedArray = Encoder.prepareByteArray(major: .major7, measure: 0)
        encodedArray = [UInt8](encodedArray[0..<3])
        
        var byteArray = Data([byte]).hex.hex_binary
        byteArray = [UInt8](byteArray[3..<byteArray.count])
        
        encodedArray.append(contentsOf: byteArray)
        return Data(encodedArray).binary_decimal.hex
    }
    
    public class func decode(header: Int) -> NSNumber? {
        let header = header + Int(0x14)
        
        if header == FALSECode {
            return NSNumber(value: false)
        }
        if header == TRUECode {
            return NSNumber(value: true)
        }
        return nil
    }
  
  public override var description: String { "SimpleValue: " + (value == nil ? "nil" : String(value!)) }
  public override var debugDescription: String { "SimpleValue: " + (value == nil ? "nil" : String(value!)) }

}

public class NSTag: NSObject {
    private var tag: Int! = -1
    private var value: NSObject!
    
    public init(tag: Int, _ value: NSObject) {
        super.init()
        
        self.tag = tag
        self.value = value
    }
    
    @objc internal override func encode() -> String {
      //  if tag > 0 {
            let encodedArray = Encoder.prepareByteArray(major: .major6, measure: self.tag)
            let headerData   = Data(encodedArray).binary_decimal.hex
            let encodedValue = Data(self.value.encode()!).hex
            
            return headerData.appending(encodedValue)
       // }
       // return ""
    }
    
    public func tagValue() -> Int {
        return self.tag
    }
    
    public func objectValue() -> NSObject {
        return self.value
    }
  
  public override var description: String { "\(self.tag ?? -1): \(self.value ?? NSString())" }
  public override var debugDescription: String { "\(self.tag ?? -1): \(self.value ?? NSString())" }

}


extension NSTag: BinaryDataEncodable {
    public func getBinaryData() -> Data {
        var res = Encoder.encodeVarUInt(UInt64(tag!))
        res[0] = res[0] | 0b110_00000
        res.append(contentsOf: CBOR.encode(value)!)
        return res.data!
    }
}








