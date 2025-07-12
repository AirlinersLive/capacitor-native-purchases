import XCTest
@testable import Plugin

class NativePurchasesTests: XCTestCase {

    func testPluginVersion() {
        // Test that the plugin version can be retrieved
        let plugin = NativePurchasesPlugin()
        XCTAssertEqual(plugin.identifier, "NativePurchasesPlugin")
        XCTAssertEqual(plugin.jsName, "NativePurchases")
    }
}
