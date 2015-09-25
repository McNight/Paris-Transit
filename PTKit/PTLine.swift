//
//  PTLine.swift
//  Paris Transit
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import Foundation

public struct PTLine {
    public let identifier: Int
    public let name: String
    public let code: String
    public let directions: [PTDirection]
    public let type: Int
}