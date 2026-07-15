import XCTest
@testable import Aria___Music_Browser

@MainActor
final class BackendConfigTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: BackendConfig.urlOverrideKey)
        UserDefaults.standard.removeObject(forKey: BackendConfig.apiKeyOverrideKey)
    }

    override func tearDown() {
        // Never leak an override into the shared simulator defaults — it would
        // silently redirect every later test that reads PlayerManager.backendURL.
        UserDefaults.standard.removeObject(forKey: BackendConfig.urlOverrideKey)
        UserDefaults.standard.removeObject(forKey: BackendConfig.apiKeyOverrideKey)
        super.tearDown()
    }

    // MARK: - resolve() precedence

    func test_resolve_overrideWins() {
        let url = BackendConfig.resolve(
            override: "https://music.example.com",
            plistURL: "https://plist.example.com",
            homelabHost: "10.0.0.1"
        )
        XCTAssertEqual(url, "https://music.example.com")
    }

    func test_resolve_fallsBackToPlistURL() {
        let url = BackendConfig.resolve(
            override: nil,
            plistURL: "https://plist.example.com",
            homelabHost: "10.0.0.1"
        )
        XCTAssertEqual(url, "https://plist.example.com")
    }

    func test_resolve_blankOverrideIsIgnored() {
        let url = BackendConfig.resolve(
            override: "   ",
            plistURL: "https://plist.example.com",
            homelabHost: nil
        )
        XCTAssertEqual(url, "https://plist.example.com")
    }

    func test_resolve_homelabFallback() {
        let url = BackendConfig.resolve(override: nil, plistURL: "", homelabHost: "100.64.0.7")
        XCTAssertEqual(url, "http://100.64.0.7:8000")
    }

    func test_resolve_placeholderWhenNothingConfigured() {
        let url = BackendConfig.resolve(override: nil, plistURL: nil, homelabHost: nil)
        XCTAssertEqual(url, "http://192.0.2.1:8000")
        XCTAssertTrue(url.contains(BackendConfig.placeholderHost))
    }

    // MARK: - normalize()

    func test_normalize_stripsTrailingSlashesAndWhitespace() {
        XCTAssertEqual(BackendConfig.normalize("  https://x.example//  "), "https://x.example")
        XCTAssertEqual(BackendConfig.normalize("https://x.example/"), "https://x.example")
    }

    func test_normalize_collapsesEmptyToNil() {
        XCTAssertNil(BackendConfig.normalize(nil))
        XCTAssertNil(BackendConfig.normalize(""))
        XCTAssertNil(BackendConfig.normalize("   "))
        XCTAssertNil(BackendConfig.normalize("///"))
    }

    // MARK: - API key precedence

    func test_resolveAPIKey_overrideWinsAndTrims() {
        XCTAssertEqual(BackendConfig.resolveAPIKey(override: " sekrit ", plistKey: "plist-key"), "sekrit")
    }

    func test_resolveAPIKey_fallsBackToPlistThenNil() {
        XCTAssertEqual(BackendConfig.resolveAPIKey(override: "", plistKey: "plist-key"), "plist-key")
        XCTAssertNil(BackendConfig.resolveAPIKey(override: nil, plistKey: ""))
        XCTAssertNil(BackendConfig.resolveAPIKey(override: nil, plistKey: nil))
    }

    // MARK: - Runtime wiring

    /// The UserDefaults override must flow through `baseURL` (and therefore
    /// `PlayerManager.backendURL`) without an app restart.
    func test_baseURL_readsUserDefaultsOverride() {
        UserDefaults.standard.set("https://override.example", forKey: BackendConfig.urlOverrideKey)
        XCTAssertEqual(BackendConfig.baseURL, "https://override.example")
        XCTAssertEqual(PlayerManager.backendURL, "https://override.example")
        XCTAssertTrue(BackendConfig.isConfigured)
    }

    /// With no override and the checked-in placeholder host, the app reports
    /// "not configured" and runs local-only.
    func test_isConfigured_falseOnPlaceholder() throws {
        // The test bundle's Info.plist carries the 192.0.2.1 placeholder (or
        // no keys at all) unless a developer pointed it at a real homelab —
        // skip in that case rather than fail on their machine.
        let plistURL = Bundle.main.object(forInfoDictionaryKey: "ARIA_BACKEND_URL") as? String
        let host = Bundle.main.object(forInfoDictionaryKey: "ARIA_HOMELAB_HOST") as? String
        let resolved = BackendConfig.resolve(override: nil, plistURL: plistURL, homelabHost: host)
        try XCTSkipIf(!resolved.contains(BackendConfig.placeholderHost),
                      "real backend configured in this environment")
        XCTAssertFalse(BackendConfig.isConfigured)
    }
}
