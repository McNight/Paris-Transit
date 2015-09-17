//
//  PTRATPProvider.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation
import CoreLocation

public class PTRATPProvider {
    public static let sharedProvider = PTRATPProvider()
    
    private let PTStopPlacesFileName = "RPStopPlaces"
    
    private var stopPlaces = [Int : PTStopPlace]()
    
    public func loadAndfilterStopPlaces(location: CLLocation, radius: CLLocationDistance, lineType: Int, completionHandler: ([PTStopPlace]) -> ()) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            guard let jsonPath = NSBundle(forClass: self.dynamicType).pathForResource(self.PTStopPlacesFileName, ofType: "json") else {
                completionHandler([])
                return
            }
            
            self.purgeStopPlaces()
            
            let data = NSData(contentsOfFile: jsonPath)!
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
                
                let parseStopPlaceBlock = { (stopPlaceDictionary: [String : AnyObject]) -> (PTStopPlace?) in
                    let latitude = stopPlaceDictionary["latitude"] as! Float
                    let longitude = stopPlaceDictionary["longitude"] as! Float
                    
                    let stopPlaceLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
                    let distance = location.distanceFromLocation(stopPlaceLocation)
                    
                    if distance > radius {
                        return nil
                    }
                    
                    let identifier = stopPlaceDictionary["id"] as! Int
                    let name = stopPlaceDictionary["name"] as! String
                    let lines = self.parseLines(stopPlaceDictionary["lines"] as! [[String : AnyObject]])
                    
                    let parsedStopPlace = PTStopPlace(identifier: identifier, name: name, location: stopPlaceLocation, lines: lines, distance: distance)
                    
                    return parsedStopPlace
                }
                
                for stopPlace in json.objectForKey("stopPlaces") as! [[String : AnyObject]] {
                    if let parsedStopPlace = parseStopPlaceBlock(stopPlace) {
                        self.stopPlaces[parsedStopPlace.identifier] = parsedStopPlace
                    }
                }
                
                var filteredStopPlaces = [PTStopPlace]()
                
                for (_, stopPlace) in self.stopPlaces {
                    for line in stopPlace.lines {
                        if line.type == lineType {
                            filteredStopPlaces.append(stopPlace)
                        }
                    }
                }
                
                completionHandler(filteredStopPlaces)
            } catch let error as NSError {
                print("Error parsing JSON : \(error.localizedDescription)")
                completionHandler([])
                return
            }
        }
    }
    
    private func purgeStopPlaces() {
        self.stopPlaces.removeAll()
    }
    
    public func getNearestStopPlaces(stopPlaces: [PTStopPlace], location: CLLocation, radius: CLLocationDistance, completionHandler: ([PTStopPlace]) -> ()) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            var nearestStopPlaces = [PTStopPlace]()
            
            for var stopPlace in stopPlaces {
                let distance = location.distanceFromLocation(stopPlace.location)
                stopPlace.distance = distance
                
                if distance < radius {
                    nearestStopPlaces.append(stopPlace)
                }
            }
            
            completionHandler(nearestStopPlaces)
        }
    }
    
    private func parseLines(lines: [[String : AnyObject]]) -> [PTLine] {
        var parsedLines = [PTLine]()
        
        for line in lines {
            let code = line["code"] as! String
            let id = line["id"] as! Int
            let name = line["name"] as! String
            let groupOfLines = line["groupOfLines"] as! [String : AnyObject]
            let type = groupOfLines["id"] as! Int
            let directions = self.parseDirections(line["directions"] as! [[String : AnyObject]])
            
            let parsedLine = PTLine(identifier: id, name: name, code: code, directions: directions, type: type)
            
            parsedLines.append(parsedLine)
        }
        
        return parsedLines
    }
    
    private func parseDirections(directions: [[String: AnyObject]]) -> [PTDirection] {
        var parsedDirections = [PTDirection]()
        
        for direction in directions {
            let id = direction["id"] as! Int
            let name = direction["name"] as! String
            
            let parsedDirection = PTDirection(identifier: id, name: name)
            parsedDirections.append(parsedDirection)
        }
        
        return parsedDirections
    }
}
