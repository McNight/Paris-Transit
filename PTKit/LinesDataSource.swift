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

    func imageNameForLineType(type: Int, code: String) -> String? {
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
    
    // MARK: - Table View Data Source
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stopPlace!.lines.count
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Arrêt : " + self.stopPlace!.name
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        
        let currentLine = self.stopPlace!.lines[indexPath.row]
        
        cell.textLabel?.text = "Ligne " + currentLine.code
        cell.imageView?.image = UIImage(named: self.imageNameForLineType(currentLine.type, code: currentLine.code)!)
        
        return cell
    }
}
