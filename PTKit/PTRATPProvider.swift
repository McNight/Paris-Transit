//
//  PTRATPProvider.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation
import CoreLocation

class PTRATPProvider: PTProvider {
    static let sharedProvider: PTProvider = PTRATPProvider()
    
    var stopPlaces = [Int : PTStopPlace]()
    var finishedLoading = false
    
    func loadStopPlaces(completionHandler: (Bool) -> ()) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            guard let jsonPath = NSBundle(forClass: self.dynamicType).pathForResource("RPStopPlaces", ofType: "json") else {
                completionHandler(false)
                return
            }
            
            let data = NSData(contentsOfFile: jsonPath)!
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
                
                let parseStopPlaceBlock = { (stopPlaceDictionary: [String : AnyObject]) -> (PTStopPlace) in
                    let identifier = stopPlaceDictionary["id"] as! Int
                    let name = stopPlaceDictionary["name"] as! String
                    let latitude = stopPlaceDictionary["latitude"] as! Float
                    let longitude = stopPlaceDictionary["longitude"] as! Float
                    let lines = self.parseLines(stopPlaceDictionary["lines"] as! [[String : AnyObject]])
                    let points = stopPlaceDictionary["stopPoints"] as! [AnyObject]
                    
                    let location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
                    let parsedStopPlace = PTStopPlace(identifier: identifier, name: name, location: location, lines: lines, stopPoints: points, distance: 0)
                    
                    return parsedStopPlace
                }
                
                for stopPlace in json.objectForKey("stopPlaces") as! [[String : AnyObject]] {
                    let parsedStopPlace = parseStopPlaceBlock(stopPlace)
                    self.stopPlaces[parsedStopPlace.identifier] = parsedStopPlace
                }
                
                self.finishedLoading = true
                
                completionHandler(true)
            } catch let error as NSError {
                print("Error parsing JSON : \(error.localizedDescription)")
                completionHandler(false)
                return
            }
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
