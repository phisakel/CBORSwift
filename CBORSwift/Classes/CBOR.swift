//
//  CBOR.swift
//  CBORSwift
//
//  Created by Hassaniiii on 5/2/18.
//  Copyright © 2018 Hassan Shahbazi. All rights reserved.
//

class CBOR: NSObject {
    //MARK:- Encoder
    
    // MARK:- Positive integers
    public class func encode(integer value: NSNumber) -> [UInt8]? {
        return self.encode(value: value, major: .major0)
    }
    //MAKR:- Negative integers
    public class func encode(negative value: NSNumber) -> [UInt8]? {
        let value = NSNumber(value: (value.intValue * -1) - 1)
        return self.encode(value: value, major: .major1)
    }
    //MARK:- Byte strings
    public class func encode(byteString value: String) {}
    //MARK:- Text strings
    public class func encode(textString value: String) -> [UInt8]? {
        return self.encode(value: value as NSString, major: .major3)
    }
    //MARK:- Arrays
    public class func encode(array value: NSArray) -> [UInt8]? {
        return self.encode(value: value, major: .major4)
    }
    //MARK:- Maps
    public class func encode(map value: NSDictionary) -> [UInt8]? {
        return self.encode(value: value, major: .major5)
    }


    //MAKR:- Decoder
    public class func decode(integer value: [UInt8]) -> NSObject? {
        return Decoder.decode(value: value)
    }
}

extension CBOR: CBOREncoder {
    static func encode(value: NSObject, major: MajorType) -> [UInt8]? {
        let type = MajorTypes()
        type.set(type: major)
        
        return value.encode(major: type.get()).data?.binary
    }
}
