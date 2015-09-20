//
//  PTKitTests.swift
//  PTKitTests
//
//  Created by Adam McNight on 16/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import XCTest
@testable import PTKit
import CoreLocation

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
        XCTAssertNotNil(PTRATPProvider.sharedProvider, "A provider cannot return a nil sharedProvider")
    }
    
    func testNonNilLocationManager() {
        XCTAssertNotNil(PTLocationManager.sharedManager, "A location manager cannot be nil")
    }
    
    func testNonNilPreferencesManager() {
        XCTAssertNotNil(PTPreferencesManager.sharedManager, "A preferences manager cannot be nil")
    }
    
    func testStopPlacesEquality() {
        let stopPlace1 = PTStopPlace(identifier: 1, name: "Super Stop Place", location: CLLocation(), lines: [], distance: 250)
        let stopPlace2 = PTStopPlace(identifier: 1, name: "Super Stop Place", location: CLLocation(), lines: [], distance: 250)
        
        XCTAssertEqual(stopPlace1, stopPlace2, "Stop Places with same identifier and same name should be considered equal")
    }
    
    func testStopPlacesNonEquality() {
        let stopPlace1 = PTStopPlace(identifier: 1, name: "Super Stop Place", location: CLLocation(), lines: [], distance: 250)
        let stopPlace2 = PTStopPlace(identifier: 2, name: "Super Stop Place", location: CLLocation(), lines: [], distance: 250)
        let stopPlace3 = PTStopPlace(identifier: 2, name: "Amazing Stop Place", location: CLLocation(), lines: [], distance: 250)
        
        XCTAssertNotEqual(stopPlace1, stopPlace2, "Stop Places with different identifiers or different names shouldn't be considered equal")
        XCTAssertNotEqual(stopPlace2, stopPlace3, "Stop Places with different identifiers or different names shouldn't be considered equal")
    }
}
