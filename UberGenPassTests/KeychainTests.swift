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
    XCTAssertNil(Keychain.stringForKey("foo"))
    
    Keychain.setString("bar", forKey: "foo")
    XCTAssertEqual(Keychain.stringForKey("foo"), "bar")
    
    Keychain.setString("baz", forKey: "foo")
    XCTAssertEqual(Keychain.stringForKey("foo"), "baz")
    
    Keychain.removeStringForKey("foo")
    XCTAssertNil(Keychain.stringForKey("foo"))
  }
}
