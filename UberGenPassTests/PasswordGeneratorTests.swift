@testable import UberGenPass
import XCTest

class PasswordGeneratorTests: XCTestCase {
  var generator = PasswordGenerator.sharedGenerator
  
  override func setUp() {
    super.setUp()
    self.generator.updateMasterPassword(masterPassword: "abra", secretPassword:"cadabra")
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testURLs() {
    let urls = [
      "http://example.com",
      "http://example.com/foo",
      "http://example.com?foo",
      
      "http://www.example.com",
      "http://www.example.com/foo",
      "http://www.example.com?foo"
    ]
    
    // MD5
    
    for url in urls {
      XCTAssertEqual(self.generator.passwordForSite(url, length:10, type:.MD5), "vECk329fUo")
    }
    
    // SHA

    for url in urls {
      XCTAssertEqual(self.generator.passwordForSite(url, length:10, type:.SHA512), "qUk8Mt3Kdg")
    }
  }

  func testDomains() {
    // MD5
    
    XCTAssertEqual(self.generator.passwordForSite("example.com", length:10, type:.MD5), "vECk329fUo")
    XCTAssertEqual(self.generator.passwordForSite("example.com/foo", length:10, type:.MD5), "vECk329fUo")
    
    XCTAssertEqual(self.generator.passwordForSite("www.example.com", length:10, type:.MD5), "bqH11xlQ4h")
    XCTAssertEqual(self.generator.passwordForSite("www.example.com/foo", length:10, type:.MD5), "bqH11xlQ4h")
    
    // SHA
    
    XCTAssertEqual(self.generator.passwordForSite("example.com", length:10, type:.SHA512), "qUk8Mt3Kdg")
    XCTAssertEqual(self.generator.passwordForSite("example.com/foo", length:10, type:.SHA512), "qUk8Mt3Kdg")
    
    XCTAssertEqual(self.generator.passwordForSite("www.example.com", length:10, type:.SHA512), "cl4IEJYsVB")
    XCTAssertEqual(self.generator.passwordForSite("www.example.com/foo", length:10, type:.SHA512), "cl4IEJYsVB")
  }

  func testTLDs() {
    // MD5
  
    XCTAssertEqual(self.generator.passwordForSite("example.co.uk", length:10, type:.MD5), "lqmq7iHtdE")
    XCTAssertEqual(self.generator.passwordForSite("example.com.au", length:10, type:.MD5), "wC3efbHg4M")
  
    // SHA
  
    XCTAssertEqual(self.generator.passwordForSite("example.co.uk", length:10, type:.SHA512), "nCY8DK8zuz")
    XCTAssertEqual(self.generator.passwordForSite("example.com.au", length:10, type:.SHA512), "zwwpWW95d9")
  }

  func testLengths() {
    // MD5
  
    XCTAssertEqual(self.generator.passwordForSite("http://example.com", length:4, type:.MD5), "sG0h")
    for i in 5..<24 {
      XCTAssertEqual(self.generator.passwordForSite("http://example.com", length:i, type:.MD5),
                     ("vECk329fUoS5hG82rn89MAAA" as NSString).substring(to: i))
    }

    // SHA
  
    for i in 4..<24 {
      XCTAssertEqual(self.generator.passwordForSite("http://example.com", length:i, type:.SHA512),
                     ("qUk8Mt3KdgS09faw1mdrOqRb" as NSString).substring(to: i))
    }
  }

  func testGarbage() {
    let urls = [
      "",
      "...",
      "http:",
      "x",
    ]

    // MD5

    for url in urls {
      XCTAssertNil(self.generator.passwordForSite(url, length:10 ,type:.MD5))
    }

    // SHA

    for url in urls {
      XCTAssertNil(self.generator.passwordForSite(url, length:10, type:.SHA512))
    }
  }
}
