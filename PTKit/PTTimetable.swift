//
//  PTTimetable.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation

public struct PTTimetableRequest {
    public let stopPlace: PTStopPlace
    public let lineIndex: Int
    
    public init(stopPlace: PTStopPlace, lineIndex: Int) {
        self.stopPlace = stopPlace
        self.lineIndex = lineIndex
    }
}

public struct PTTimetableResult {
    public let destination: String
    public let patternIdentifier: String?
    public let stopInStation: Bool
    public let waitingTime: Int
    public let passingHour: String
    
    public func description() -> String {
        return "(\(self.patternIdentifier)) \(self.destination) at \(self.passingHour) (Stop : \(self.stopInStation))"
    }
}

public struct PTTimetable {
    public let request: PTTimetableRequest
    public let firstDirectionResults: [PTTimetableResult]!
    public let secondDirectionResults: [PTTimetableResult]!
}