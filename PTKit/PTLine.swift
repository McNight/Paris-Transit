//
//  PTLine.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import Foundation

public struct PTLine {
    let identifier: Int
    let name: String
    let code: String
    let directions: [PTDirection]
    let type: Int
}