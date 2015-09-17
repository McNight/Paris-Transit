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

class TransitViewController: UIViewController, MKMapViewDelegate, PTLocationManagerDelegate {
    var nearestStopPlace: PTStopPlace!
    var nearbyStopPlaces: [PTStopPlace]! {
        didSet (newValue) {
            nearestStopPlace = newValue.first
        }
    }
    
    lazy var distanceFormatter = MKDistanceFormatter()
    
    lazy var linesDataSource = LinesDataSource()
    
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
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
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
        
        // TIMETABLE REQUEST !
    }
    
    // MARK: - Data
    
    func getStopPlacesNearUsersLocation(location: CLLocation) {
        PTRATPProvider.sharedProvider.loadAndfilterStopPlaces(location, radius: 1000, lineType: 2, completionHandler: { (filteredStopPlaces) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let filteredStopPlaces = filteredStopPlaces {
                    self.nearbyStopPlaces = filteredStopPlaces
                    self.populateLinesTableView(self.nearestStopPlace)
                    self.displayStopPins()
                }
            })
        })
    }
    
    func populateLinesTableView(stopPlace: PTStopPlace) {
        self.linesDataSource.stopPlace = stopPlace
        self.linesTableView.dataSource = self.linesDataSource
        self.linesTableView.reloadData()
    }
    
    func timetableRequestWithStopPlace(stopPlace: PTStopPlace, lineIndex: Int) {
        let timetableRequest = PTTimetableRequest(stopPlace: stopPlace, lineIndex: lineIndex)
        
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
