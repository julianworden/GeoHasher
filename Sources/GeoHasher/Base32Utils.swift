//
//  GFGeoHashBase32Utils.swift
//  Veliola
//
//  Created by Tadreik Campbell on 10/11/21.
//  Copyright © 2021 Tadreik Campbell. All rights reserved.
//

import Foundation

struct Base32Utils {
    
    static let base32Chars = "0123456789bcdefghjkmnpqrstuvwxyz".cString(using: .utf8)!
    
    static func base32Characters() -> String {
        return String(bytes: base32Chars.map {UInt8($0)}, encoding: .utf8)!
    }
    
    static func valueToBase32Character(value: Int) -> Int8 {
        if value > 31 {
            NSException(name: .invalidArgumentException, reason: "Not a valid base32 value: \(value)").raise()
        }
        return base32Chars[value]
    }
    
    static func base32CharacterToValue(character: Int8) -> Int8 {
        for i in 0..<32 {
            if base32Chars[i] == character {
                return Int8(i)
            }
        }
        NSException(name: .invalidArgumentException, reason: "Not a valid base32 character: \(character)").raise()
        return 0
    }
    
}
