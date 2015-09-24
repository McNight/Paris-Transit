//
//  TodayViewController.swift
//  Paris Transit Center
//
//  Created by Adam McNight on 24/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreLocation
import PTKit

class TodayViewController: UIViewController, NCWidgetProviding, PTLocationManagerDelegate {
    @IBOutlet weak var linesTableView: UITableView!
    @IBOutlet weak var timetableTableView: UITableView!
    
    private var linesDataSource: LinesDataSource {
        let linesDataSource = LinesDataSource()
        linesDataSource.isWidgetPresenting = true
        return linesDataSource
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    // MARK: - Location Stuff
    
    func prepareLocationStuff() {
        PTLocationManager.sharedManager.delegate = self
        PTLocationManager.sharedManager.prepareLocationStuff()
    }
    
    // MARK: - Data
    
    func getStopPlacesNearUsersLocation(location: CLLocation) {
        let radius = PTPreferencesManager.sharedManager.radiusStopPlaces()
        
        PTRATPProvider.sharedProvider.loadAndFilterStopPlacesFromWidget(location, radius: radius, linesTypes: [1,2]) { stopPlace -> () in
            if let stopPlace = stopPlace {
                print("StopPlace : \(stopPlace)")
            }
            else {
                
            }
        }
    }
    
    func populateLinesTableView(stopPlace: PTStopPlace) {
        self.linesDataSource.stopPlace = stopPlace
        self.linesTableView.dataSource = self.linesDataSource
        self.linesTableView.reloadData()
    }
    
    // MARK: - PTLocationManagerDelegate
    
    func locationManagerGotUsersLocation(locationManager: PTLocationManager, location: CLLocation) {
        print("Ready to load stop places...")
        // self.getStopPlacesNearUsersLocation(location)
    }
}
