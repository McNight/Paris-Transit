//
//  PTLocationManager.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public class PTLocationManager: NSObject, CLLocationManagerDelegate {
    public static let sharedManager = PTLocationManager()
    
    private let locationManager = CLLocationManager()
    private var lastUsersLocation: CLLocation!
    
    lazy public var distanceFormatter = MKDistanceFormatter()
    
    public var delegate: PTLocationManagerDelegate?
    
    public func prepareLocationStuff() {
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = 20.0
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            self.locationManager.requestAlwaysAuthorization()
        }
        
        self.requestUsersLocation()
    }
    
    public func requestUsersLocation() {
        self.locationManager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Updating...")
        if let location = locations.first {
            if location !== self.lastUsersLocation {
                if self.lastUsersLocation != nil && self.lastUsersLocation.distanceFromLocation(location) == 0 {
                    return
                }
                
                self.lastUsersLocation = location
                delegate?.locationManagerGotUsersLocation(self, location: self.lastUsersLocation)
            }
        }
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error updating location : \(error.localizedDescription)")
    }
    
    public func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        print("Finished !")
    }
    
    public func locationManagerDidPauseLocationUpdates(manager: CLLocationManager) {
        print("Paused !")
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