//
//  PTPreferencesManager.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation

public class PTPreferencesManager {
    public static let sharedManager = PTPreferencesManager()
    
    private let usersDefaults = NSUserDefaults.standardUserDefaults()
    
    private let PTAlreadyLaunchedPreferencesKey = "PTAlreadyLaunchedPreferencesKey"
    private let PTDisplayNonStoppingTrainsPreferencesKey = "PTDisplayNonStoppingTrainsPreferencesKey"
    private let PTRadiusStopPlacesPreferencesKey = "PTRadiusStopPlacesPreferencesKey"
    private let PTTwitterAccessAskedPreferencesKey = "PTTwitterAccessAskedPreferencesKey"
    private let PTTwitterUsersFollowUsPreferencesKey = "PTTwitterUsersFollowUsPreferencesKey"
    
    public func alreadyLaunchedVerification() -> Bool {
        let alreadyLaunched = self.usersDefaults.boolForKey(PTAlreadyLaunchedPreferencesKey)
        
        if alreadyLaunched == false
        {
            print("Premier lancement détecté !")
            self.usersDefaults.setBool(true, forKey: PTAlreadyLaunchedPreferencesKey)
            self.defaultSettingsRegistration()
            self.usersDefaults.synchronize()
        }
        
        return alreadyLaunched
    }
    
    private func defaultSettingsRegistration() {
        self.usersDefaults.setBool(false, forKey: PTDisplayNonStoppingTrainsPreferencesKey)
        self.usersDefaults.setDouble(500, forKey: PTRadiusStopPlacesPreferencesKey)
        self.usersDefaults.setBool(false, forKey: PTTwitterAccessAskedPreferencesKey)
        self.usersDefaults.setBool(false, forKey: PTTwitterUsersFollowUsPreferencesKey)
    }
    
    public func displayNonStoppingTrains() -> Bool {
        return self.usersDefaults.boolForKey(PTDisplayNonStoppingTrainsPreferencesKey)
    }
    
    public func setDisplayNonStoppingTrains(newValue: Bool) {
        self.usersDefaults.setBool(newValue, forKey: PTDisplayNonStoppingTrainsPreferencesKey)
        self.usersDefaults.synchronize()
    }
    
    public func radiusStopPlaces() -> Double {
        return self.usersDefaults.doubleForKey(PTRadiusStopPlacesPreferencesKey)
    }

    public func setRadiusStopPlaces(newValue: Double) {
        self.usersDefaults.setDouble(newValue, forKey: PTRadiusStopPlacesPreferencesKey)
        self.usersDefaults.synchronize()
    }
    
    public func twitterAccessAsked() -> Bool {
        return self.usersDefaults.boolForKey(PTTwitterAccessAskedPreferencesKey)
    }
    
    public func setTwitterAccessAsked(newValue: Bool) {
        self.usersDefaults.setBool(newValue, forKey: PTTwitterAccessAskedPreferencesKey)
        self.usersDefaults.synchronize()
    }
    
    public func doesUserFollowUs() -> Bool {
        return self.usersDefaults.boolForKey(PTTwitterUsersFollowUsPreferencesKey)
    }
    
    public func setUserFollowUs(newValue: Bool) {
        self.usersDefaults.setBool(newValue, forKey: PTTwitterUsersFollowUsPreferencesKey)
        self.usersDefaults.synchronize()
    }
}