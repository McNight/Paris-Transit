//
//  PTTimetable.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation

struct PTTimetableRequest {
    let stopPlace: PTStopPlace
    let lineIndex: Int
}

struct PTTimetableResult {
    let destination: String
    let patternIdentifier: String
    let stopInStation: Bool
    let waitingTime: Int
    let passingHour: String
    
    func description() -> String {
        return "(\(self.patternIdentifier)) \(self.destination) at \(self.passingHour) (Stop : \(self.stopInStation))"
    }
}

struct PTTimetable {
    let request: PTTimetableRequest
    let result: PTTimetableResult
}