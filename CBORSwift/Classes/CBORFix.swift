//
//  CBORFix.swift
//  Alamofire
//
//  Created by Filippos Sakellaropoulos on 22/4/20.
//

import Foundation
//import SwiftCBOR

// not used
extension Decoder {
  public func DecodeTaggedValueFixed() -> NSTag? {
    /*
    if let dec = try? SwiftCBOR.CBOR.decode(body) {
      if case let .tagged(t, l) = dec {
        if case let .byteString(barr) = l {
          return NSTag(tag: Int(t.rawValue), NSByteString(bytes: barr))
        }
      }
    }
 */
    return nil
  }
}
