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

enum FailureReason {
    case NoFailure
    case NoStopPlacesFound
    case NoTimetable
}

class TransitViewController: UIViewController, UITableViewDelegate, MKMapViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, PTLocationManagerDelegate {
    var nearestStopPlace: PTStopPlace!
    var nearbyStopPlaces: [PTStopPlace]! {
        willSet {
            nearestStopPlace = newValue.count > 0 ? newValue.first! : nil
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
    
    private var failureReason: FailureReason = .NoFailure
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var linesTableView: UITableView!
    @IBOutlet weak var timetablesTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareUserInterface()
        self.prepareLocationStuff()
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
        
        // MapView
        self.mapView.setUserTrackingMode(.Follow, animated: true)
        
        // Refresh Control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshTimetable:", forControlEvents: .ValueChanged)
        self.timetablesTableView.addSubview(refreshControl)
    }
    
    private func displayStopPins() {
        var stopPlacesAnnotations = [PTPointAnnotation]()
        
        for stopPlace in self.nearbyStopPlaces
        {
            let stopPlaceAnnotation = PTPointAnnotation(stopPlace: stopPlace)
            let numberOfSupportedLines = self.linesDataSource.numberOfSupportedLines(stopPlace, lineTypes: self.allowedLineTypes)
            let distanceString = self.distanceFormatter.stringFromDistance(stopPlace.distance)
            stopPlaceAnnotation.setSubtitleWithDistance(distanceString, numberOfSupportedLines: numberOfSupportedLines)
            stopPlacesAnnotations.append(stopPlaceAnnotation)
        }
        
        self.mapView.showAnnotations(stopPlacesAnnotations, animated: true)
    }
    
    private func stopPlacePinSelectedFromMapView(stopPlace: PTStopPlace) {
        self.selectedStopPlace = stopPlace
        self.populateLinesTableView(stopPlace)
        self.timetableRequestWithStopPlace(stopPlace, lineIndex: self.selectedLineIndex, completionHandler: nil)
    }

    // MARK: - Data
    
    func getStopPlacesNearUsersLocation(location: CLLocation) {
        PTRATPProvider.sharedProvider.loadAndfilterStopPlaces(location, radius: 1000, lineTypes: self.allowedLineTypes, completionHandler: { (filteredStopPlaces) -> () in
            dispatch_async(dispatch_get_main_queue()) {
                if let filteredStopPlaces = filteredStopPlaces
                {
                    if filteredStopPlaces.count > 0
                    {
                        self.nearbyStopPlaces = filteredStopPlaces
                        self.selectedStopPlace = self.nearestStopPlace
                        self.populateLinesTableView(self.selectedStopPlace!)
                        self.timetablesTableView.reloadData()
                        self.timetableRequestWithStopPlace(self.selectedStopPlace!, lineIndex: self.selectedLineIndex, completionHandler: nil)
                        self.displayStopPins()
                    }
                    else
                    {
                        self.failureReason = .NoStopPlacesFound
                        self.linesTableView.reloadEmptyDataSet()
                        self.timetablesTableView.reloadEmptyDataSet()
                    }
                }
            }
        })
    }
    
    func populateLinesTableView(stopPlace: PTStopPlace) {
        let filteredStopPlace = self.linesDataSource.filteredStopPlace(stopPlace, lineTypes: self.allowedLineTypes)
        self.linesDataSource.stopPlace = filteredStopPlace
        self.linesTableView.dataSource = self.linesDataSource
        self.linesTableView.reloadData()
    }
    
    func timetableRequestWithStopPlace(stopPlace: PTStopPlace, lineIndex: Int, completionHandler: (Void -> Void)?) {
        if let timetableRequest = self.lastTimetableRequest {
            if stopPlace != timetableRequest.stopPlace || lineIndex != timetableRequest.lineIndex {
                self.lastTimetableRequest = PTTimetableRequest(stopPlace: stopPlace, lineIndex: lineIndex)
            }
        } else {
            self.lastTimetableRequest = PTTimetableRequest(stopPlace: stopPlace, lineIndex: lineIndex)
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        PTRATPProvider.sharedProvider.getStopTimetableWithRequest(&self.lastTimetableRequest!, limit: 2) { (timetable) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if let timetable = timetable {
                if timetable.firstDirectionResults == nil || timetable.secondDirectionResults == nil {
                    self.timetablesTableView.dataSource = nil
                    self.failureReason = .NoTimetable
                } else {
                    self.failureReason = .NoFailure
                    self.timetableDataSource.timetable = timetable
                    self.timetablesTableView.dataSource = self.timetableDataSource
                }
                
                self.timetablesTableView.reloadData()
            }
            
            completionHandler?()
        }
    }
    
    func refreshCurrentTimetableFromTimer() {
        print("Refresh from Timer")
        
        self.timetableRequestWithStopPlace(self.lastTimetableRequest.stopPlace, lineIndex: self.lastTimetableRequest.lineIndex, completionHandler: nil)
    }
    
    func refreshTimetable(refreshControl: UIRefreshControl) {
        print("Refresh from UIRefreshControl")
        
        self.timetableRequestWithStopPlace(self.lastTimetableRequest.stopPlace, lineIndex: self.lastTimetableRequest.lineIndex) {
            self.refreshTimer.invalidate()
            self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refreshCurrentTimetableFromTimer", userInfo: nil, repeats: true)
            
            refreshControl.endRefreshing()
        }
    }
    
    // MARK: - Location
    
    func locationManagerGotUsersLocation(locationManager: PTLocationManager, location: CLLocation) {
        print("Ready to load stop places...")
        self.getStopPlacesNearUsersLocation(location)
    }
    
    func prepareLocationStuff() {
        PTLocationManager.sharedManager.delegate = self
        PTLocationManager.sharedManager.prepareLocationStuff()
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let view = view as? MKPinAnnotationView {
            let annotation = view.annotation as! PTPointAnnotation
            self.stopPlacePinSelectedFromMapView(annotation.stopPlace)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? PTPointAnnotation {
            let stopPlace = annotation.stopPlace
            var annotationView: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier("StopPlacePin") as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                annotationView = dequeuedView
            }
            else {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "StopPlacePin")
                annotationView.canShowCallout = true
                
                if stopPlace == self.nearestStopPlace {
                    annotationView.pinTintColor = UIColor.greenColor()
                }
                
                if self.linesDataSource.numberOfSupportedLines(stopPlace, lineTypes: self.allowedLineTypes) == 1 {
                    let line = stopPlace.lines.first!
                    let imageName = self.linesDataSource.imageNameForLineType(line.type, code: line.code)
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30.0, height: 30.0))
                    imageView.contentMode = .ScaleAspectFill
                    imageView.image = UIImage(named: imageName!)
                    annotationView.leftCalloutAccessoryView = imageView
                }
            }
            
            return annotationView
        }
        return nil
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Selected !")
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard indexPath.row != self.selectedLineIndex else {
            return
        }
        
        self.timetablesTableView.dataSource = nil
        self.timetablesTableView.reloadData()
        
        self.selectedLineIndex = indexPath.row
        self.timetableRequestWithStopPlace(self.selectedStopPlace!, lineIndex: self.selectedLineIndex, completionHandler: nil)
    }
    
    // MARK: - Basic Error Handling
    
    private func titleCurrentFailure() -> String {
        switch self.failureReason {
        case .NoFailure:
            return "Aucun soucis !"
        case .NoStopPlacesFound:
            return "Aucun arrêt dans les environs."
        case .NoTimetable:
            return "Horaires indisponibles !"
        }
    }
    
    private func descriptionCurrentFailure() -> String {
        switch self.failureReason {
        case .NoFailure:
            return "Aucun soucis !"
        case .NoStopPlacesFound:
            return "Êtes-vous sûr d'être en région parisienne ?"
        case .NoTimetable:
            return "Impossible de récupérer les horaires. Cela provient peut-être d'une erreur de communication, d'absence de trains ou d'une ligne non gérée."
        }
    }
    
    // MARK: - DZNEmptyDataSetSource
    
    func customViewForEmptyDataSet(scrollView: UIScrollView!) -> UIView! {
        if scrollView === self.linesTableView {
            if self.failureReason == .NoFailure {
                let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
                activityIndicatorView.startAnimating()
                return activityIndicatorView
            }
            else if self.failureReason == .NoStopPlacesFound {
                let warningImageView = UIImageView(image: UIImage(named: "warning"))
                warningImageView.contentMode = .ScaleAspectFit
                return warningImageView
            }
        }
        return nil
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if scrollView === self.linesTableView {
            return nil
        } else {
            var text: String
            
            if failureReason != .NoFailure
            {
                text = self.titleCurrentFailure()
            }
            else
            {
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
            
            if failureReason != .NoFailure
            {
                text = self.descriptionCurrentFailure()
            }
            else
            {
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

    // MARK: - Actions
    
    @IBAction func refreshEverythingAction(sender: UIBarButtonItem) {
        PTLocationManager.sharedManager.requestUsersLocation()
    }
}
