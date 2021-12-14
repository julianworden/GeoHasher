import XCTest
@testable import GeoHasher

final class Base32UtilsTests: XCTestCase {
    
    func testValueToBase32Character() throws {
        (0..<32).forEach { num in
            let result = Base32Utils.valueToBase32Character(value: num)
            let char = Base32Utils.base32Chars[num]
            XCTAssert(char == result)
        }
    }
    
    func testBase32CharacterToValue() throws {
        Base32Utils.base32Chars.forEach { char in
            let result = Base32Utils.base32CharacterToValue(character: char)
            XCTAssert(result >= 0 && result < 32)
        }
    }
}
