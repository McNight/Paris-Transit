//
//  PTProvider.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation

protocol PTProvider {
    static var sharedProvider: PTProvider { get }
    
    func loadStopPlaces(completionHandler: (Bool) -> ())
}