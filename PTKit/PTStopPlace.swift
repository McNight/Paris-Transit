//
//  PTStopPlace.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation
import CoreLocation

struct PTStopPlace {
    let identifier: Int
    let name: String
    let location: CLLocation
    let lines: [PTLine]
    var distance: CLLocationDistance
    
    mutating func updateDistanceFromPosition(position: CLLocation) {
        self.distance = self.location.distanceFromLocation(position)
    }
    
    func description() -> String {
        return "\(self.name) (\(self.identifier)) - \(self.lines.count) line(s) - \(self.distance) meters from user"
    }
}