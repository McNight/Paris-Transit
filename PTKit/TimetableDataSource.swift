//
//  TimetableDataSource.swift
//  Paris Transit
//
//  Created by Adam McNight on 17/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import UIKit

class TimetableDataSource: NSObject, UITableViewDataSource {
    var timetable: PTTimetable!
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return self.timetable.firstDirectionResults.count
        case 1:
            return self.timetable.secondDirectionResults.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        
        var timetableResult: PTTimetableResult
        var text: String
        var detailText: String
        
        switch (indexPath.section) {
        case 0:
            timetableResult = self.timetable.firstDirectionResults[indexPath.row]
            text = timetableResult.stopInStation ? timetableResult.destination : "\(timetableResult.destination) (sans arrêt)"
            detailText = "\(timetableResult.waitingTime / 60) min"
        case 1:
            timetableResult = self.timetable.firstDirectionResults[indexPath.row]
            text = timetableResult.stopInStation ? timetableResult.destination : "\(timetableResult.destination) (sans arrêt)"
            detailText = "\(timetableResult.waitingTime / 60) min"
        default:
            text = "Erreur"
            detailText = "?"
        }
        
        cell.textLabel!.text = text
        cell.detailTextLabel!.text = detailText
        
        return cell
    }
}
