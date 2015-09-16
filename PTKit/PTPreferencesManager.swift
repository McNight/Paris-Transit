//
//  PTPreferencesManager.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation

class PTPreferencesManager {
    static let sharedManager = PTPreferencesManager()
    
    private let usersDefaults = NSUserDefaults.standardUserDefaults()
    
    let PTAlreadyLaunchedPreferencesKey = "PTAlreadyLaunchedPreferencesKey"
    let PTDisplayNonStoppingTrainsPreferencesKey = "PTDisplayNonStoppingTrainsPreferencesKey"
    
    func alreadyLaunchedVerification() -> Bool {
        let alreadyLaunched = self.usersDefaults.boolForKey(PTAlreadyLaunchedPreferencesKey)
        
        if alreadyLaunched
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
    }
    
    func displayNonStoppingTrains() -> Bool {
        return self.usersDefaults.boolForKey(PTDisplayNonStoppingTrainsPreferencesKey)
    }
    
    func setDisplayNonStoppingTrains(newValue: Bool) {
        self.usersDefaults.setBool(newValue, forKey: PTDisplayNonStoppingTrainsPreferencesKey)
        self.usersDefaults.synchronize()
    }
}