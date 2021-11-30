//
//  GFGeoQueryBounds.swift
//  Veliola
//
//  Created by Tadreik Campbell on 10/11/21.
//  Copyright © 2021 Tadreik Campbell. All rights reserved.
//

import Foundation

public struct GeoQueryBounds: Equatable, CustomStringConvertible {
    
    public var startValue: String
    public var endValue: String
    
    public var description: String {
        return "GeoQueryBounds: \(startValue)-\(endValue)"
    }
    
    init(startValue: String, endValue: String) {
        self.startValue = startValue
        self.endValue = endValue
    }
    
    public static func ==(lhs: GeoQueryBounds, rhs: GeoQueryBounds) -> Bool {
        lhs.startValue == rhs.startValue && lhs.endValue == rhs.endValue
    }
    
    func hash() -> Int {
        return (startValue.hash) * 31 + (endValue.hash)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
