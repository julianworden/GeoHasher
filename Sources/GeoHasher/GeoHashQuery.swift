//
//  GFGeoHashQuery.swift
//  Veliola
//
//  Created by Tadreik Campbell on 10/11/21.
//  Copyright © 2021 Tadreik Campbell. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

// Length of a degree latitude at the equator
fileprivate let METERS_PER_DEGREE_LATITUDE: Double = 110_574
// The equatorial circumference of the earth in meters
fileprivate let EARTH_MERIDIONAL_CIRCUMFERENCE: Double = 40_007_860
// The equatorial radius of the earth in meters
fileprivate let EARTH_EQ_RADIUS: Double = 6378_137
// The following value assumes a polar radius of
// r_p = 6356752.3
// and an equatorial radius of
// r_e = 6378137
// The value is calculated as e2 == (r_e^2 - r_p^2)/(r_e^2)
// Use exact value to avoid rounding errors
fileprivate let E2: Double = 0.00669447819799
// Number of bits per character in a geohash
fileprivate let BITS_PER_GEOHASH_CHAR = 5
// The maximum number of bits in a geohash
fileprivate let MAXIMUM_BITS_PRECISION = 22 * BITS_PER_GEOHASH_CHAR
// Cutoff for floating point calculations
fileprivate let EPSILON: Double = 1e-12


public struct GeoHashQuery: Equatable, Hashable {
    
    var startValue: String
    var endValue: String
    lazy var description: String = String(format: "GFGeoHashQuery: %@-%@", startValue, endValue)
    
    init(startValue: String, endValue: String) {
        self.startValue = startValue
        self.endValue = endValue
    }
    
    static func bitsForLatitiude(withResolution resolution: Double) -> Double {
        return log2(EARTH_MERIDIONAL_CIRCUMFERENCE/2/resolution)
    }
    
    static func meters(distance: Double, toLongitudeDegreesAtLattitude latitude: Double) -> CLLocationDegrees {
        let radians = (latitude * .pi)/2
        let numerator = cos(radians)*EARTH_EQ_RADIUS*Double.pi/180
        let denominator = 1/sqrt(1-E2*sin(radians)*sin(radians))
        let deltaDegrees = numerator*denominator
        if deltaDegrees < EPSILON {
            return distance > 0 ? 360 : 0
        } else {
            return fmin(360, distance/deltaDegrees)
        }
    }
    
    static func bitsForLongitude(withResolution resolution: Double, atLatitude latitude: CLLocationDegrees) -> Double {
        let degrees = GeoHashQuery.meters(distance: resolution, toLongitudeDegreesAtLattitude: latitude)
        return (fabs(degrees) > 0) ? log2(360/degrees) : 1
    }
    
    static func wrapLongitude(longitude: CLLocationDegrees) -> CLLocationDegrees {
        if longitude >= -180 && longitude <= 180 {
            return longitude
        }
        let adjusted = longitude + 180
        if adjusted > 0 {
            return fmod(adjusted, 360) - 180
        } else {
            return 180 - fmod(-adjusted, 360)
        }
    }
    
    static func bitsForBoundingBox(atLocation location: CLLocationCoordinate2D, withSize size: Double) -> Int {
        let latitudeDegreesDelta = size/METERS_PER_DEGREE_LATITUDE
        let latitudeNorth = fmin(90, location.latitude + latitudeDegreesDelta)
        let latitudeSouth = fmax(-90, location.latitude - latitudeDegreesDelta)
        let bitsLatitude = max(0, Int(floor(bitsForLatitiude(withResolution: size))))
        let bitsNorth = bitsForLongitude(withResolution: size, atLatitude: latitudeNorth)
        let bitsSouth = bitsForLongitude(withResolution: size, atLatitude: latitudeSouth)
        let bitsLongitudeNorth = max(1, Int(floor(bitsNorth)))*2-1
        let bitsLongitudeSouth = max(1, Int(bitsSouth))*2-1
        return min(bitsLatitude, min(bitsLongitudeNorth, min(bitsLongitudeSouth,MAXIMUM_BITS_PRECISION)))
    }
    
    static func bits(for region: MKCoordinateRegion) -> Int {
        let bitsLatitude = max(0, Int(floor(log2(180/region.span.latitudeDelta / 2))))*2
        let bitsLongitude = max(1, Int(floor(log2(360/(region.span.longitudeDelta / 2)))))*2
        return min(bitsLatitude, min(bitsLongitude, MAXIMUM_BITS_PRECISION))
    }
    
    static func geoHashQuery(withGeoHash geoHash: GeoHash, bits: Int) -> GeoHashQuery {
        var hash = geoHash.geoHashValue
        let precision = ((bits - 1)/BITS_PER_GEOHASH_CHAR) + 1
        if hash.count < precision {
            return GeoHashQuery(startValue: hash, endValue: String(format: "%@~", hash))
        }
        hash = String(hash[...String.Index(utf16Offset: precision, in: hash)])
        let base = hash[...String.Index(utf16Offset: hash.count - 1, in: hash)]
        let char = CChar(String.Index(utf16Offset: hash.count-1, in: hash).distance(in: hash))
        let lastValue = Base32Utils.base32CharacterToValue(character: Base32Utils.base32Chars[Int(char)])
        let significantBits = bits - (base.count*5)
        let unusedbits = 5 - significantBits
        // delete unused bits
        let startValue = (lastValue >> unusedbits) << unusedbits
        let endValue = startValue + (1 << unusedbits)
        let startHash = String(format: "%@%c", String(base), Base32Utils.valueToBase32Character(value: Int(startValue)) as! CVarArg)
        var endHash: String
        if endValue > 31 {
            endHash = String(format: "%@~", String(base))
        } else {
            endHash = String(format: "%@%c", String(base), Base32Utils.valueToBase32Character(value: Int(endValue)) as! CVarArg)
        }
        return GeoHashQuery(startValue: startHash, endValue: endHash)
    }
    
    static func joinQueries(set: Set<GeoHashQuery>) -> Set<GeoHashQuery> {
        var queries = set
        var didJoin: Bool?
        repeat {
            var query1: GeoHashQuery?
            var query2: GeoHashQuery?
            for query in queries {
                for other in queries {
                    if query != other && query.canJoin(with: other) {
                        query1 = query
                        query2 = other
                    }
                }
            }
            if query1 != nil && query2 != nil {
                queries.remove(query1!)
                queries.remove(query2!)
                queries.insert(query1!.join(with: query2!)!)
                didJoin = true
            } else {
                didJoin = false
            }
        } while didJoin!
        return queries
    }
    
    static func queries(for region: MKCoordinateRegion) -> Set<GeoHashQuery> {
        let bits = GeoHashQuery.bits(for: region)
        let geoHashPrecision = ((bits - 1) / BITS_PER_GEOHASH_CHAR) + 1
        var queries: Set<GeoHashQuery> = []
        let addQuery: ((CLLocationDegrees, CLLocationDegrees) -> Void)? = { lat, lng in
            let geoHash = GeoHash(
                withLocation: CLLocationCoordinate2DMake(lat, lng),
                precision: geoHashPrecision)
            queries.insert(geoHashQuery(withGeoHash: geoHash, bits: bits))
        }
        let latitudeCenter = region.center.latitude
        let latitudeNorth = region.center.latitude + CLLocationDegrees(region.span.latitudeDelta / 2)
        let latitudeSouth = region.center.latitude - CLLocationDegrees(region.span.latitudeDelta / 2)
        let longitudeCenter = region.center.longitude
        let longitudeWest = GeoHashQuery.wrapLongitude(
            longitude: (region.center.longitude - CLLocationDegrees(region.span.longitudeDelta / 2)))
        let longitudeEast = GeoHashQuery.wrapLongitude(
            longitude: (region.center.longitude + CLLocationDegrees(region.span.longitudeDelta / 2)))
        
        addQuery?(latitudeCenter, longitudeCenter)
        addQuery?(latitudeCenter, longitudeEast)
        addQuery?(latitudeCenter, longitudeWest)
        
        addQuery?(latitudeNorth, longitudeCenter)
        addQuery?(latitudeNorth, longitudeEast)
        addQuery?(latitudeNorth, longitudeWest)
        
        addQuery?(latitudeSouth, longitudeCenter)
        addQuery?(latitudeSouth, longitudeEast)
        addQuery?(latitudeSouth, longitudeWest)
        
        return joinQueries(set: queries)
    }
    
    static func queries(forLocation center: CLLocationCoordinate2D, radius: Double) -> Set<GeoHashQuery> {
        let latitudeDelta = radius / METERS_PER_DEGREE_LATITUDE
        let latitudeNorth = fmin(90, center.latitude + latitudeDelta)
        let latitudeSouth = fmax(-90, center.latitude - latitudeDelta)
        let longitudeDeltaNorth = meters(distance: radius, toLongitudeDegreesAtLattitude: latitudeNorth)
        let longitudeDeltaSouth = meters(distance: radius, toLongitudeDegreesAtLattitude: latitudeSouth)
        let longitudeDelta = fmax(longitudeDeltaNorth, longitudeDeltaSouth)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: latitudeDelta*2, longitudinalMeters: longitudeDelta*2)
        return queries(for: region)
    }
    
    private func isPrefix(to other: GeoHashQuery) -> Bool {
        self.endValue.compare(other.startValue) != .orderedAscending &&
        self.startValue.compare(other.startValue) == .orderedAscending &&
        self.endValue.compare(other.endValue) == .orderedAscending
    }
    
    private func isSuperQuery(of other: GeoHashQuery) -> Bool {
        let start: ComparisonResult = self.startValue.compare(other.startValue)
        if start == .orderedSame || start == .orderedAscending {
            let end: ComparisonResult = self.endValue.compare(other.endValue)
            return end == .orderedSame || end == .orderedDescending
        } else {
            return false
        }
    }
    
    private func canJoin(with other: GeoHashQuery) -> Bool {
        self.isPrefix(to: other) ||
        other.isPrefix(to: self) ||
        self.isSuperQuery(of: other) ||
        other.isSuperQuery(of: self)
    }
    
    private func join(with other: GeoHashQuery) -> GeoHashQuery? {
        if self.isPrefix(to: other) {
            return GeoHashQuery(startValue: self.startValue, endValue: other.endValue)
        } else if other.isPrefix(to: self) {
            return GeoHashQuery(startValue: other.startValue, endValue: self.endValue)
        } else if self.isSuperQuery(of: other) {
            return self
        } else if other.isSuperQuery(of: self) {
            return other
        } else {
            return nil
        }
    }
    
    private func containsGeoHash(hash: GeoHash) -> Bool {
        self.startValue == hash.geoHashValue ||
        self.startValue.compare(hash.geoHashValue) == .orderedAscending &&
        self.endValue.compare(hash.geoHashValue) == .orderedDescending
    }
    
    private func hash() -> Int {
        return self.startValue.hash * 31 + self.endValue.hash
    }
    
    public static func ==(lhs: GeoHashQuery, rhs: GeoHashQuery) -> Bool {
        lhs.startValue == rhs.startValue && lhs.endValue == rhs.endValue
    }
    
}

extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int { string.distance(from: self, to: self) }
}
