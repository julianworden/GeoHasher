//
//  GFUtils.swift
//  Veliola
//
//  Created by Tadreik Campbell on 10/11/21.
//  Copyright © 2021 Tadreik Campbell. All rights reserved.
//

import Foundation
import CoreLocation

public struct Utils {
    
    public static func geoHash(forLocation location: CLLocationCoordinate2D) -> String {
        let geoHash: GeoHash = GeoHash(withLocation: location)
        return geoHash.geoHashValue
    }
    
    public static func geoHash(forLocation location: CLLocationCoordinate2D, withPrecision precision: Int) -> String {
        let geoHash = GeoHash(withLocation: location, precision: precision)
        return geoHash.geoHashValue
    }
    
    public static func distance(fromLocation locationA: CLLocation, toLocation locationB: CLLocation) -> Double {
        return locationA.distance(from: locationB)
    }
    
    public static func queryBounds(forLocation location: CLLocationCoordinate2D, withRadius radius: Double) -> [GeoQueryBounds] {
        var result: [GeoQueryBounds] = []
        let queries: [GeoHashQuery] = Array(GeoHashQuery.queries(forLocation: location, radius: radius))
        for q in queries {
            let bounds = GeoQueryBounds(startValue: q.startValue, endValue: q.endValue)
            result.append(bounds)
        }
        return result
    }
}
