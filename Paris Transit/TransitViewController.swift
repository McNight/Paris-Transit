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

class TransitViewController: UIViewController, MKMapViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, PTLocationManagerDelegate {
    var nearestStopPlace: PTStopPlace!
    var nearbyStopPlaces: [PTStopPlace]!
    
    lazy private var distanceFormatter = MKDistanceFormatter()
    
    lazy private var linesDataSource = LinesDataSource()
    lazy private var timetableDataSource = TimetableDataSource()
    
    lazy private var allowedLineTypes = [1,2]
    
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
        self.timetablesTableView.emptyDataSetSource = self
        self.timetablesTableView.emptyDataSetDelegate = self
        
        // Hide Rows
        self.linesTableView.tableFooterView = UIView()
        self.timetablesTableView.tableFooterView = UIView()
        
        // MapView
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        
        // Scroll Views Content Insets
        let tabbarInset = UIEdgeInsets(top: 0, left: 0, bottom: CGRectGetHeight(self.tabBarController!.tabBar.frame), right: 0)
        self.timetablesTableView.contentInset = tabbarInset
        self.timetablesTableView.scrollIndicatorInsets = tabbarInset
    }
    
    private func displayStopPins() {
        var stopPlacesAnnotations = [MKPointAnnotation]()
        
        for stopPlace in self.nearbyStopPlaces
        {
            let stopPlaceAnnotation = MKPointAnnotation()
            stopPlaceAnnotation.coordinate = stopPlace.location.coordinate
            stopPlaceAnnotation.title = stopPlace.name
            stopPlaceAnnotation.subtitle = "\(self.distanceFormatter.stringFromDistance(stopPlace.distance)) - \(stopPlace.lines.count) lignes"
            stopPlacesAnnotations.append(stopPlaceAnnotation)
        }
        
        self.mapView.showAnnotations(stopPlacesAnnotations, animated: true)
    }
    
    private func stopPlacePinSelectedFromMapView(stopPlace: PTStopPlace) {
        self.populateLinesTableView(stopPlace)
        self.timetableRequestWithStopPlace(stopPlace, lineIndex: 0) // À changer le lineIndex avec un index en property !
    }

    // MARK: - Data
    
    func getStopPlacesNearUsersLocation(location: CLLocation) {
        PTRATPProvider.sharedProvider.loadAndfilterStopPlaces(location, radius: 2000, lineTypes: self.allowedLineTypes, completionHandler: { (filteredStopPlaces) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let filteredStopPlaces = filteredStopPlaces {
                    self.nearbyStopPlaces = filteredStopPlaces
                    self.nearestStopPlace = self.nearbyStopPlaces.first!
                    self.populateLinesTableView(self.nearestStopPlace)
                    self.timetablesTableView.reloadData()
                    self.timetableRequestWithStopPlace(self.nearestStopPlace, lineIndex: 0)
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
        let timetableRequest = PTTimetableRequest(stopPlace: stopPlace, lineIndex: lineIndex)
        let ratpProvider = PTRATPProvider.sharedProvider
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        ratpProvider.getStopTimetableWithRequest(timetableRequest, limit: 3) { (timetable) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if let timetable = timetable {
                self.timetableDataSource.timetable = timetable
                self.timetablesTableView.dataSource = self.timetableDataSource
                self.timetablesTableView.reloadData()
            }
        }
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
            
            if self.nearestStopPlace == nil {
                text = "Récupération de la position GPS..."
            } else {
                text = "Récupération des horaires..."
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
            
            if self.nearestStopPlace == nil {
                text = "Elle sert à repérer les arrêts et les lignes les plus proches de votre position."
            } else {
                text = "Horaires pour l'arrêt \(self.nearestStopPlace.name) en téléchargement..."
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
