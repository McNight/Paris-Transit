//
//  PTStopPlace.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation
import CoreLocation

public struct PTStopPlace: Equatable {
    public let identifier: Int
    public let name: String
    public let location: CLLocation
    public let lines: [PTLine]
    public var distance: CLLocationDistance
    
    mutating public func updateDistanceFromLocation(usersLocation: CLLocation) -> CLLocationDistance {
        self.distance = self.location.distanceFromLocation(usersLocation)
        return self.distance
    }
        
    public func description() -> String {
        return "\(self.name) (\(self.identifier)) - \(self.lines.count) line(s) - \(self.distance) meters from user"
    }
}

public func == (lhs: PTStopPlace, rhs: PTStopPlace) -> Bool {
    return ((lhs.identifier == rhs.identifier) && (lhs.name == rhs.name))
}

public func != (lhs: PTStopPlace, rhs: PTStopPlace) -> Bool {
    return !(lhs == rhs)
}