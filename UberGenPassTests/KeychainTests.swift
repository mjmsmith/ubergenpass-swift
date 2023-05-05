//
//  KeychainTests.swift
//  UberGenPass
//
//  Created by Mark Smith on 8/5/15.
//  Copyright © 2015 Camazotz Limited. All rights reserved.
//

@testable import UberGenPass
import XCTest

class KeychainTests: XCTestCase {
    
  override func setUp() {
    super.setUp()
  }
    
  override func tearDown() {
    super.tearDown()
  }
  
  func testKeychain() {
    XCTAssertNil(DefaultKeychain["foo"])
    
    DefaultKeychain["foo"] = "bar"
    XCTAssertEqual(DefaultKeychain["foo"], "bar")
    
    DefaultKeychain["foo"] = "baz"
    XCTAssertEqual(DefaultKeychain["foo"], "baz")
    
    DefaultKeychain["foo"] = nil
    XCTAssertNil(DefaultKeychain["foo"])
  }
}
