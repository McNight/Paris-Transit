//
//  LinesDataSource.swift
//  Paris Transit
//
//  Created by Adam McNight on 17/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import UIKit

public class LinesDataSource: NSObject, UITableViewDataSource {
    public var stopPlace: PTStopPlace?
    public var isWidgetPresenting = false

    public func imageNameForLineType(type: Int, code: String) -> String? {
        switch type {
        case 1:
            return "M_" + code
        case 2:
            return "RER_" + code
        case 4:
            return code
        case 5:
            return code + "genRVB"
        default:
            return "L_M"
        }
    }
    
    public func filteredStopPlace(stopToFilter: PTStopPlace, lineTypes: [Int]) -> PTStopPlace {
        var lines = [PTLine]()
        
        for (_, line) in stopToFilter.lines.enumerate() {
            if lineTypes.contains(line.type) {
                lines.append(line)
            }
        }
        
        let filteredStopPlace = PTStopPlace(identifier: stopToFilter.identifier, name: stopToFilter.name, location: stopToFilter.location, lines: lines, distance: stopToFilter.distance)
        return filteredStopPlace
    }
    
    public func numberOfSupportedLines(stopToCount: PTStopPlace, lineTypes: [Int]) -> Int {
        var count = 0
        
        for (_, line) in stopToCount.lines.enumerate() {
            if lineTypes.contains(line.type) {
                count++
            }
        }
        
        return count
    }
    
    // MARK: - Table View Data Source
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stopPlace!.lines.count
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = self.isWidgetPresenting ? self.stopPlace!.name : "Arrêt : " + self.stopPlace!.name
        return title
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell")
        
        let currentLine = self.stopPlace!.lines[indexPath.row]
        
        cell?.textLabel?.text = "Ligne " + currentLine.code
        cell?.imageView?.image = UIImage(named: self.imageNameForLineType(currentLine.type, code: currentLine.code)!)
        
        return cell!
    }
}
