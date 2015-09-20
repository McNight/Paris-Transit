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
    private let PTRATPTimetableURL: NSString = "http://apixha.ixxi.net/APIX?keyapp=mPnXzdqWEI0EFvmlgJv9&withDetails=true&stopArea=%d&cmd=getNextStopsRealtime&apixFormat=json&line=%d&withText=true&direction=%d"
    
    public var stopPlaces = [Int : PTStopPlace]()
    
    public func loadAndfilterStopPlaces(location: CLLocation, radius: CLLocationDistance, lineTypes: [Int], completionHandler: ([PTStopPlace]?) -> ()) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            guard let jsonPath = NSBundle(forClass: self.dynamicType).pathForResource(self.PTStopPlacesFileName, ofType: "json") else {
                completionHandler(nil)
                return
            }
            
            self.purgeStopPlaces()
            
            var data = NSData(contentsOfFile: jsonPath)
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
                
                data = nil
                
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
                        if lineTypes.contains(line.type) && filteredStopPlaces.contains(stopPlace) == false {
                            filteredStopPlaces.append(stopPlace)
                        }
                    }
                }
                
                // Bon, dans self.stopPlaces il reste des arrêts avec pas le bon lineType.
                
                filteredStopPlaces = filteredStopPlaces.sort({ $0.distance < $1.distance })
                
                completionHandler(filteredStopPlaces)
            } catch let error as NSError {
                print("Error parsing JSON : \(error.localizedDescription)")
                completionHandler(nil)
                return
            }
        }
    }
    
    private func purgeStopPlaces() {
        self.stopPlaces.removeAll()
    }
    
    public func getStopTimetableWithRequest(request: PTTimetableRequest, limit: Int, completionHandler: (PTTimetable?) -> Void) {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfiguration)
        
        let stopPlace = request.stopPlace
        let line = stopPlace.lines[request.lineIndex]
        
        let lineIdentifier = line.identifier
        
        let firstDirectionIdentifier = line.directions[0].identifier
        let secondDirectionIdentifier = line.directions[1].identifier
        
        let firstRATPTimetableURL = NSString(format: self.PTRATPTimetableURL, stopPlace.identifier, lineIdentifier, firstDirectionIdentifier)
        let secondRATPTimetableURL = NSString(format: self.PTRATPTimetableURL, stopPlace.identifier, lineIdentifier, secondDirectionIdentifier)
        
        // print("URL 1 : \(firstRATPTimetableURL)")
        // print("URL 2 : \(secondRATPTimetableURL)")
        
        let firstURL = NSURL(string: String(firstRATPTimetableURL))
        let secondURL = NSURL(string: String(secondRATPTimetableURL))
        
        let firstDataTask = session.dataTaskWithURL(firstURL!) { (data, response, error) -> Void in
            if let error = error
            {
                print("Response First Data Task : \(response?.description)")
                print("Error : \(error.localizedDescription)")
                
                completionHandler(nil)
            }
            else
            {
                self.parseTimetableData(data!, request: request, limit: limit, completionHandler: { (firstResults: [PTTimetableResult]?) -> Void in
                    let secondDataTask = session.dataTaskWithURL(secondURL!, completionHandler: { (data, response, error) -> Void in
                        if let error = error
                        {
                            print("Response Second Data Task: \(response?.description)")
                            print("Error : \(error.localizedDescription)")
                            
                            completionHandler(nil)
                        }
                        else
                        {
                            self.parseTimetableData(data!, request: request, limit: limit, completionHandler: { (secondResults) -> Void in
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    let timetable = PTTimetable(request: request, firstDirectionResults: firstResults, secondDirectionResults: secondResults)
                                    completionHandler(timetable)
                                })
                            })
                        }
                    })
                    
                    secondDataTask.resume()
                })
            }
        }
        
        firstDataTask.resume()
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
    
    private func parseTimetableData(data: NSData, request: PTTimetableRequest, limit: Int, completionHandler: ([PTTimetableResult]?) -> Void) {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            let nextStopsOnLine = json.objectForKey("nextStopsOnLines") as? NSArray
            let temp = nextStopsOnLine?.firstObject as? NSDictionary
            let nextStops = temp?.objectForKey("nextStops") as? NSArray
            
            guard nextStops?.count > 0 else {
                completionHandler(nil)
                return
            }
            
            var results = [PTTimetableResult]()
            let displayNonStoppingTrains = PTPreferencesManager.sharedManager.displayNonStoppingTrains()
            
            for nextStop in nextStops! as! [[String : AnyObject]] {
                if displayNonStoppingTrains || nextStop["bStopInStation"]!.boolValue! {
                    let destination = nextStop["destinationName"] as! String
                    let patternIdentifier = nextStop["servicePatternId"] as? String
                    let stopInStation = nextStop["bStopInStation"] as! Bool
                    let waitingTime = nextStop["waitingTime"] as! Int
                    let passingHour = nextStop["waitingTimeRaw"] as! String
                    
                    let result = PTTimetableResult(destination: destination, patternIdentifier: patternIdentifier, stopInStation: stopInStation, waitingTime: waitingTime, passingHour: passingHour)
                    results.append(result)
                    
                    if (results.count == limit) {
                        break;
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(results)
            })
        } catch let error as NSError {
            print("Error parsing Timetable JSON Object : \(error.localizedDescription)")
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
