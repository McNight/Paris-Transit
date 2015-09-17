//
//  PTStopPlace.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation
import CoreLocation

public struct PTStopPlace {
    let identifier: Int
    let name: String
    let location: CLLocation
    let lines: [PTLine]
    var distance: CLLocationDistance
    
    mutating public func updateDistanceFromLocation(usersLocation: CLLocation) -> CLLocationDistance {
        self.distance = self.location.distanceFromLocation(usersLocation)
        return self.distance
    }
        
    public func description() -> String {
        return "\(self.name) (\(self.identifier)) - \(self.lines.count) line(s) - \(self.distance) meters from user"
    }
}

func == (lhs: PTStopPlace, rhs: PTStopPlace) -> Bool {
    return ((lhs.identifier == rhs.identifier) && (lhs.name == rhs.name))
}

func != (lhs: PTStopPlace, rhs: PTStopPlace) -> Bool {
    return !(lhs == rhs)
}