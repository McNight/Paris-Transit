//
//  PTLocationManager.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation
import CoreLocation

public class PTLocationManager: NSObject, CLLocationManagerDelegate {
    public static let sharedManager = PTLocationManager()
    
    private let locationManager = CLLocationManager()
    private var lastUsersLocation: CLLocation!
    
    public var delegate: PTLocationManagerDelegate?
    
    public func prepareLocationStuff() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.requestAlwaysAuthorization()
    }
    
    public func requestUsersLocation() {
        self.locationManager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.lastUsersLocation = location
        }
        
        delegate?.locationManagerGotUsersLocation(self, location: self.lastUsersLocation)
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error updating location : \(error.localizedDescription)")
    }
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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