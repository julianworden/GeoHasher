//
//  File.swift
//  
//
//  Created by Tadreik Campbell on 11/29/21.
//

import XCTest
import CoreLocation
@testable import GeoHasher

final class GeoHashTests: XCTestCase {
    
    let geohash = GeoHash(withLocation: CLLocationCoordinate2D.init(latitude: 10, longitude: 10))
    
    func testisValidGeoHash() throws {
        let perms = permute(items: Base32Utils.base32Chars)
        let permStrings = perms.map { String($0) }
        //let corruptedStrings = permStrings.map { "#\($0)"}
        for string in permStrings where string.count < 16 {
            let result = geohash.isValidGeoHash(string)
            XCTAssert(result == true)
        }
//        for string in corruptedStrings where string.count < 16 {
//            let result = geohash.isValidGeoHash(string)
//            XCTAssert(result == false)
//        }
    }
    
    // Takes any collection of T and returns an array of permutations
    func permute<C: Collection>(items: C) -> [[C.Iterator.Element]] {
        var scratch = Array(items) // This is a scratch space for Heap's algorithm
        var result: [[C.Iterator.Element]] = [] // This will accumulate our result

        // Heap's algorithm
        func heap(_ n: Int) {
            if n == 1 {
                result.append(scratch)
                return
            }

            for i in 0..<n-1 {
                heap(n-1)
                let j = (n%2 == 1) ? 0 : i
                scratch.swapAt(j, n-1)
            }
            heap(n-1)
        }

        // Let's get started
        heap(scratch.count)

        // And return the result we built up
        return result
    }
    
}
