//
//  GFGeoHash.swift
//  Veliola
//
//  Created by Tadreik Campbell on 10/11/21.
//  Copyright © 2021 Tadreik Campbell. All rights reserved.
//

import Foundation
import CoreLocation

fileprivate let DEFAULT_PRECISION = 10
fileprivate let MAX_PRECISION = 22

public struct GeoHash {
    
    var geoHashValue: String
    
    init(withLocation location: CLLocationCoordinate2D) {
        self.init(withLocation: location, precision: DEFAULT_PRECISION)
    }
    
    init(withLocation location: CLLocationCoordinate2D, precision: Int) {
        if precision < 1 {
            NSException(name: .invalidArgumentException, reason: "Precision must be larger than 0").raise()
        }
        if precision > MAX_PRECISION {
            NSException(name: .invalidArgumentException, reason: "Precision must be less than \(MAX_PRECISION + 1)").raise()
        }
        if (!CLLocationCoordinate2DIsValid(location)) {
            NSException(name: .invalidArgumentException, reason: "Not a valid geo location \(location.latitude),\(location.longitude)").raise()
        }
        let longitudeRange = [-180.0, 180.0]
        let latitudeRange = [-90.0, 90.0]
        
        var buffer = [CChar](repeating: CChar("0")!, count: Int(precision) + 1)
        buffer[Int(precision)] = CChar("0")!
        
        for i in 0..<precision {
            var hashVal = 0
            for j in 0..<5 {
                let even: Bool = ((Int(i) * 5) + j) % 2 == 0
                let val: Double = (even) ? location.longitude : location.latitude
                var range: [Double] = (even) ? longitudeRange : latitudeRange
                let mid: Double = (range[0] + range[1])/2
                if val > mid {
                    hashVal = (hashVal << 1) + 1
                    range[0] = mid
                } else {
                    hashVal = (hashVal << 1) + 0
                    range[1] = mid
                }
            }
            buffer[Int(i)] = Base32Utils.valueToBase32Character(value: Int(hashVal))
        }
        self.geoHashValue = NSString(bytes: buffer, length: buffer.count, encoding: String.Encoding.ascii.rawValue)! as String
    }
    
    func isValidGeoHash(_ hash: String) -> Bool {
        let base32Set: CharacterSet = CharacterSet(charactersIn: Base32Utils.base32Characters())
        if hash.count == 0 {
            return false
        }
        let hashCharSet = CharacterSet(charactersIn: hash)
        if !base32Set.isSuperset(of: hashCharSet) {
            return false
        }
        return true
    }
    
    func new(withLocation location: CLLocationCoordinate2D) -> GeoHash {
        return GeoHash(withLocation: location)
    }
    
    func new(withLocation location: CLLocationCoordinate2D, precision: Int) -> GeoHash {
        return GeoHash(withLocation: location, precision: precision)
    }
    
}
