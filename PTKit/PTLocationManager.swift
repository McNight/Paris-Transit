//
//  PTLocationManager.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation
import CoreLocation

class PTLocationManager: NSObject, CLLocationManagerDelegate {
    static let sharedManager = PTLocationManager()
    
    let locationManager = CLLocationManager()
    var lastUsersLocation: CLLocation!
    
    var delegate: PTLocationManagerDelegate?
    
    func prepareLocationStuff() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.requestAlwaysAuthorization()
    }
    
    func requestUsersLocation() {
        self.locationManager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.lastUsersLocation = location
        }
        
        delegate?.locationManagerGotUsersLocation(self, location: self.lastUsersLocation)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error updating location : \(error.localizedDescription)")
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch (status) {
        case .NotDetermined:
            print("Not determined")
        case .Restricted:
            print("Restricted")
        case .Denied:
            print("Denied")
        case .AuthorizedAlways:
            print("Authorized Always")
        case .AuthorizedWhenInUse:
            print("Authorized When In Use")
        }
    }
}