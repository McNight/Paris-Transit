//
//  PTKitTests.swift
//  PTKitTests
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import XCTest
@testable import PTKit

class PTKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNonNilRATPProvider() {
        XCTAssertNotNil(PTRATPProvider.sharedProvider, "A provider cannot return a nil value")
    }
}
