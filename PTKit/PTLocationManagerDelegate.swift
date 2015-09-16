//
//  PTLocationManagerDelegate.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation
import CoreLocation

protocol PTLocationManagerDelegate {
    func locationManagerGotUsersLocation(locationManager: PTLocationManager, location: CLLocation)
}