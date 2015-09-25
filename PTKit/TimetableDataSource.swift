//
//  TimetableDataSource.swift
//  Paris Transit
//
//  Created by Adam McNight on 17/09/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import UIKit

public class TimetableDataSource: NSObject, UITableViewDataSource {
    public var timetable: PTTimetable!
    
    // MARK: - Table View Data Source
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return self.timetable.firstDirectionResults.count
        case 1:
            return self.timetable.secondDirectionResults.count
        default:
            return 0
        }
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let request = self.timetable.request
        let line = request.stopPlace.lines[request.lineIndex]
        
        switch (section) {
        case 0:
            return line.directions[0].name
        case 1:
            return line.directions[1].name
        default:
            return nil
        }
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if self.timetable.request.stopPlace.lines[self.timetable.request.lineIndex].type == 1 {
            cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell")!
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("TimetableCell") as! TimetableViewCell
        }
        
        var timetableResult: PTTimetableResult!
        var text: String
        var detailText: String
        var image: UIImage?
        
        switch (indexPath.section) {
        case 0:
            timetableResult = self.timetable.firstDirectionResults[indexPath.row]
            text = timetableResult.destination
            detailText = "\(timetableResult.waitingTime / 60) min"
            image = timetableResult.stopInStation ? UIImage(named: "pastilleVerte") : UIImage(named: "pastilleRouge")
        case 1:
            timetableResult = self.timetable.secondDirectionResults[indexPath.row]
            text = timetableResult.destination
            detailText = "\(timetableResult.waitingTime / 60) min"
            image = timetableResult.stopInStation ? UIImage(named: "pastilleVerte") : UIImage(named: "pastilleRouge")
        default:
            text = "Erreur"
            detailText = "?"
        }
        
        if let timetableResult = timetableResult {
            if let cell = cell as? TimetableViewCell {
                cell.mainLabel!.text = text
                cell.detailLabel!.text = timetableResult.patternIdentifier
                cell.accessoryLabel!.text = detailText
            } else {
                cell.textLabel!.text = text
                cell.detailTextLabel!.text = detailText
            }
            
            cell.imageView?.image = image
        }
        
        return cell
    }
}
