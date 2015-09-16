//
//  TransitViewController.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import UIKit
import PTKit
import CoreLocation

class TransitViewController: UIViewController, PTLocationManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareLocationStuff()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Location
    
    func locationManagerGotUsersLocation(locationManager: PTLocationManager, location: CLLocation) {
        
    }
    
    func prepareLocationStuff() {
        PTLocationManager.sharedManager.delegate = self
        PTLocationManager.sharedManager.prepareLocationStuff()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
