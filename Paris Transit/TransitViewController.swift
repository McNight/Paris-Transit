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
import MapKit
import DZNEmptyDataSet

class TransitViewController: UIViewController, UITableViewDelegate, MKMapViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, PTLocationManagerDelegate {
    var nearestStopPlace: PTStopPlace!
    var nearbyStopPlaces: [PTStopPlace]! {
        didSet {
            nearestStopPlace = self.nearbyStopPlaces.first!
        }
    }
    
    lazy private var distanceFormatter = MKDistanceFormatter()
    
    lazy private var linesDataSource = LinesDataSource()
    lazy private var timetableDataSource = TimetableDataSource()
    
    lazy private var allowedLineTypes = [1,2]
    
    private var refreshTimer: NSTimer!
    private var lastTimetableRequest: PTTimetableRequest! {
        didSet {
            if oldValue == nil {
                self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refreshCurrentTimetableFromTimer", userInfo: nil, repeats: true)
            }
        }
    }
    
    private var selectedLineIndex = 0
    private var selectedStopPlace: PTStopPlace?
    
    private var failureReason: String?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var linesTableView: UITableView!
    @IBOutlet weak var timetablesTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareLocationStuff()
        self.prepareUserInterface()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - User Interface
    
    func prepareUserInterface() {
        // Empty Data Sets
        self.linesTableView.emptyDataSetSource = self
        self.linesTableView.emptyDataSetDelegate = self
        self.linesTableView.delegate = self
        self.timetablesTableView.emptyDataSetSource = self
        self.timetablesTableView.emptyDataSetDelegate = self
        
        // Hide Rows
        self.linesTableView.tableFooterView = UIView()
        self.timetablesTableView.tableFooterView = UIView()
        
        // Scroll Views Content Insets
        let tabbarInset = UIEdgeInsets(top: 0, left: 0, bottom: CGRectGetHeight(self.tabBarController!.tabBar.frame), right: 0)
        self.timetablesTableView.contentInset = tabbarInset
        self.timetablesTableView.scrollIndicatorInsets = tabbarInset
        
        let navbarInset = UIEdgeInsets(top: 0, left: 0, bottom: -CGRectGetHeight(self.navigationController!.navigationBar.frame), right: 0)
        self.linesTableView.contentInset = navbarInset
        self.linesTableView.scrollIndicatorInsets = navbarInset
        
        // Refresh Control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshTimetable:", forControlEvents: .ValueChanged)
        self.timetablesTableView.addSubview(refreshControl)
    }
    
    private func displayStopPins() {
        var stopPlacesAnnotations = [MKPointAnnotation]()
        
        for stopPlace in self.nearbyStopPlaces
        {
            let stopPlaceAnnotation = MKPointAnnotation() // On peut éventuellement la subclasse et stocker la stopPlace avec !
            stopPlaceAnnotation.coordinate = stopPlace.location.coordinate
            stopPlaceAnnotation.title = stopPlace.name
            
            let numberOfSupportedLines = self.linesDataSource.numberOfSupportedLines(stopPlace, lineTypes: self.allowedLineTypes)
            
            var subtitle = "\(self.distanceFormatter.stringFromDistance(stopPlace.distance)) - \(numberOfSupportedLines) ligne"
            if numberOfSupportedLines > 1 {
                subtitle += "s"
            }

            stopPlaceAnnotation.subtitle = subtitle
            stopPlacesAnnotations.append(stopPlaceAnnotation)
        }
        
        self.mapView.showAnnotations(stopPlacesAnnotations, animated: true)
    }
    
    private func stopPlacePinSelectedFromMapView(stopPlace: PTStopPlace) {
        self.selectedStopPlace = stopPlace
        self.populateLinesTableView(stopPlace)
        self.timetableRequestWithStopPlace(stopPlace, lineIndex: self.selectedLineIndex)
    }

    // MARK: - Data
    
    func getStopPlacesNearUsersLocation(location: CLLocation) {
        PTRATPProvider.sharedProvider.loadAndfilterStopPlaces(location, radius: 1000, lineTypes: self.allowedLineTypes, completionHandler: { (filteredStopPlaces) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let filteredStopPlaces = filteredStopPlaces {
                    self.nearbyStopPlaces = filteredStopPlaces
                    self.selectedStopPlace = self.nearestStopPlace
                    self.populateLinesTableView(self.selectedStopPlace!)
                    self.timetablesTableView.reloadData()
                    self.timetableRequestWithStopPlace(self.selectedStopPlace!, lineIndex: self.selectedLineIndex)
                    self.displayStopPins()
                }
            })
        })
    }
    
    func populateLinesTableView(stopPlace: PTStopPlace) {
        let filteredStopPlace = self.linesDataSource.filteredStopPlace(stopPlace, lineTypes: self.allowedLineTypes)
        self.linesDataSource.stopPlace = filteredStopPlace
        self.linesTableView.dataSource = self.linesDataSource
        self.linesTableView.reloadData()
    }
    
    func timetableRequestWithStopPlace(stopPlace: PTStopPlace, lineIndex: Int) {
        if let timetableRequest = self.lastTimetableRequest {
            if stopPlace != timetableRequest.stopPlace || lineIndex != timetableRequest.lineIndex {
                self.lastTimetableRequest = PTTimetableRequest(stopPlace: stopPlace, lineIndex: lineIndex)
            }
        } else {
            self.lastTimetableRequest = PTTimetableRequest(stopPlace: stopPlace, lineIndex: lineIndex)
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        PTRATPProvider.sharedProvider.getStopTimetableWithRequest(self.lastTimetableRequest, limit: 2) { (timetable) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if let timetable = timetable {
                if timetable.firstDirectionResults == nil || timetable.secondDirectionResults == nil {
                    self.timetablesTableView.dataSource = nil
                    self.failureReason = "Horaires indisponible !"
                } else {
                    self.failureReason = nil
                    self.timetableDataSource.timetable = timetable
                    self.timetablesTableView.dataSource = self.timetableDataSource
                }
                self.timetablesTableView.reloadData()
            }
        }
    }
    
    func refreshCurrentTimetableFromTimer() {
        print("Refresh from Timer")
        self.timetableRequestWithStopPlace(self.lastTimetableRequest.stopPlace, lineIndex: self.lastTimetableRequest.lineIndex)
    }
    
    func refreshTimetable(refreshControl: UIRefreshControl) {
        print("Refresh from UIRefreshControl")
        self.timetableRequestWithStopPlace(self.lastTimetableRequest.stopPlace, lineIndex: self.lastTimetableRequest.lineIndex)
        self.refreshTimer.invalidate()
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refreshCurrentTimetableFromTimer", userInfo: nil, repeats: true)
        refreshControl.endRefreshing()
    }
    
    // MARK: - Location
    
    func locationManagerGotUsersLocation(locationManager: PTLocationManager, location: CLLocation) {
        self.getStopPlacesNearUsersLocation(location)
    }
    
    func prepareLocationStuff() {
        PTLocationManager.sharedManager.delegate = self
        PTLocationManager.sharedManager.prepareLocationStuff()
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let view = view as? MKPinAnnotationView {
            let annotationCoordinates = view.annotation?.coordinate
            
            for stopPlace in self.nearbyStopPlaces {
                let stopPlaceCoordinates = stopPlace.location.coordinate
                
                if self.areCoordinatesEqual(stopPlaceCoordinates, secondCoordinates: annotationCoordinates!) {
                    self.stopPlacePinSelectedFromMapView(stopPlace)
                    break;
                }
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Selected !")
        
        self.timetablesTableView.dataSource = nil
        self.timetablesTableView.reloadData()
        
        self.selectedLineIndex = indexPath.row
        self.timetableRequestWithStopPlace(self.selectedStopPlace!, lineIndex: self.selectedLineIndex)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - DZNEmptyDataSetSource
    
    func customViewForEmptyDataSet(scrollView: UIScrollView!) -> UIView! {
        if scrollView === self.linesTableView {
            let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            activityIndicatorView.startAnimating()
            return activityIndicatorView
        }
        return nil
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if scrollView === self.linesTableView {
            return nil
        } else {
            var text: String
            
            if failureReason != nil {
                text = failureReason!
            } else {
                if self.nearestStopPlace == nil {
                    text = "Récupération de la position GPS..."
                } else {
                    text = "Récupération des horaires..."
                }
            }
            
            let attribs = [
                NSFontAttributeName: UIFont.boldSystemFontOfSize(18),
                NSForegroundColorAttributeName: UIColor.darkGrayColor()
            ]
            
            return NSAttributedString(string: text, attributes: attribs)
        }
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if scrollView === self.linesTableView {
            return nil
        } else {
            var text: String
            
            if failureReason != nil {
                text = "Impossible de récupérer les horaires. Cela provient peut être d'une erreur de communication, d'absence de trains ou d'une ligne non gérée."
            } else {
                if self.nearestStopPlace == nil {
                    text = "Elle sert à repérer les arrêts et les lignes les plus proches de votre position."
                } else {
                    text = "Horaires pour l'arrêt \(self.selectedStopPlace!.name) en téléchargement..."
                }
            }
            
            let para = NSMutableParagraphStyle()
            para.lineBreakMode = NSLineBreakMode.ByWordWrapping
            para.alignment = NSTextAlignment.Center
            
            let attribs = [
                NSFontAttributeName: UIFont.systemFontOfSize(14),
                NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                NSParagraphStyleAttributeName: para
            ]
            
            return NSAttributedString(string: text, attributes: attribs)
        }
    }
    
    // MARK: - Helpers
    
    func areCoordinatesEqual(firstCoordinates: CLLocationCoordinate2D, secondCoordinates: CLLocationCoordinate2D) -> Bool {
        return ((firstCoordinates.latitude == secondCoordinates.latitude) && (firstCoordinates.longitude == secondCoordinates.longitude))
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
