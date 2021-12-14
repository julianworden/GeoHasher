//
//  GFGeoHashBase32Utils.swift
//  Veliola
//
//  Created by Tadreik Campbell on 10/11/21.
//  Copyright © 2021 Tadreik Campbell. All rights reserved.
//

import Foundation

struct Base32Utils {
    
    static var base32Chars: [Character] = {
        var chars: [Character] = []
        "0123456789bcdefghjkmnpqrstuvwxyz".forEach { char in
            chars.append(char)
        }
        return chars
    }()
    
    static func valueToBase32Character(value: Int) -> Character {
        if value > 31 {
            NSException(name: .invalidArgumentException, reason: "Not a valid base32 value: \(value)").raise()
        }
        return base32Chars[value]
    }
    
    static func base32CharacterToValue(character: Character) -> Int {
        for i in 0..<32 where base32Chars[i] == character {
            return i
        }
        NSException(name: .invalidArgumentException, reason: "Not a valid base32 character: \(character)").raise()
        return 0
    }
    
}
