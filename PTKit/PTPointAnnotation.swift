//
//  PTPointAnnotation.swift
//  Paris Transit
//
//  Created by Adam McNight on 23/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

public class PTPointAnnotation: MKPointAnnotation {
    public var stopPlace: PTStopPlace {
        willSet {
            self.coordinate = newValue.location.coordinate
            self.title = newValue.name
        }
    }
    
    public init(stopPlace: PTStopPlace) {
        self.stopPlace = stopPlace
        super.init()
        self.coordinate = stopPlace.location.coordinate
        self.title = stopPlace.name
    }
    
    public func setSubtitleWithDistance(distance: String, numberOfSupportedLines: Int) {
        var subtitle = "\(distance) - \(numberOfSupportedLines) ligne"
        if numberOfSupportedLines > 1 {
            subtitle += "s"
        }
        self.subtitle = subtitle
    }
}
