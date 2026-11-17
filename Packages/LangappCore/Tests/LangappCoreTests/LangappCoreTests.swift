import XCTest
@testable import LangappCore

final class PhoneNumberClassifierTests: XCTestCase {
    private func region(_ n: String, _ r: String? = "FR") -> PhoneRegion {
        PhoneNumberClassifier.region(of: n, defaultRegion: r)
    }

    func testInternationalFormats() {
        XCTAssertEqual(region("+44 7700 900123"), .unitedKingdom)
        XCTAssertEqual(region("0044 20 7946 0958"), .unitedKingdom)
        XCTAssertEqual(region("(+44) 20 7946 0958"), .unitedKingdom)
        XCTAssertEqual(region("+1 (415) 555-0132"), .unitedStates)
        XCTAssertEqual(region("+33 6 12 34 56 78"), .france)
        XCTAssertEqual(region("0033612345678"), .france)
        XCTAssertEqual(region("+49 30 123456"), .other)
        XCTAssertEqual(region("+353 1 234 5678"), .other)
    }

    func testNationalFormatsUseDeviceRegion() {
        XCTAssertEqual(region("06 12 34 56 78", "FR"), .france)
        XCTAssertEqual(region("07700 900123", "FR"), .other) // UK-looking number on a French phone
        XCTAssertEqual(region("07700 900123", "GB"), .unitedKingdom)
        XCTAssertEqual(region("(415) 555-0132", "US"), .unitedStates)
        XCTAssertEqual(region("011 44 20 7946 0958", "US"), .unitedKingdom)
        XCTAssertEqual(region("06 12 34 56 78", nil), .other)
    }

    func testJunk() {
        XCTAssertEqual(region(""), .other)
        XCTAssertEqual(region("n/a"), .other)
    }
}

final class KeyboardLanguagePolicyTests: XCTestCase {
    func testUKAndUSGetEnglish() {
        let policy = KeyboardLanguagePolicy(store: InMemoryLanguagePreferenceStore(), defaultRegion: "FR")
        XCTAssertEqual(policy.decide(contactID: "a", phoneNumbers: ["+44 7700 900123"]), .useLanguage("en-GB"))
        XCTAssertEqual(policy.decide(contactID: "b", phoneNumbers: ["+1 415 555 0132"]), .useLanguage("en-US"))
    }

    func testFrenchAsksThenRemembers() {
        let store = InMemoryLanguagePreferenceStore()
        let policy = KeyboardLanguagePolicy(store: store, defaultRegion: "FR")
        XCTAssertEqual(policy.decide(contactID: "c", phoneNumbers: ["06 12 34 56 78"]), .askUser)
        store.setLanguage("en-GB", forContact: "c")
        XCTAssertEqual(policy.decide(contactID: "c", phoneNumbers: ["06 12 34 56 78"]), .useLanguage("en-GB"))
        // The choice is per contact.
        XCTAssertEqual(policy.decide(contactID: "d", phoneNumbers: ["06 12 34 56 78"]), .askUser)
    }

    func testOtherNumbersLeaveKeyboardAlone() {
        let policy = KeyboardLanguagePolicy(store: InMemoryLanguagePreferenceStore(), defaultRegion: "FR")
        XCTAssertEqual(policy.decide(contactID: "e", phoneNumbers: ["+49 30 123456"]), .leaveUnchanged)
        XCTAssertEqual(policy.decide(contactID: "f", phoneNumbers: []), .leaveUnchanged)
    }

    func testFirstRecognisedNumberWins() {
        let policy = KeyboardLanguagePolicy(store: InMemoryLanguagePreferenceStore(), defaultRegion: "FR")
        XCTAssertEqual(policy.decide(contactID: "g", phoneNumbers: ["+49 30 123456", "+44 7700 900123", "06 12 34 56 78"]),
                       .useLanguage("en-GB"))
        XCTAssertEqual(policy.decide(contactID: "h", phoneNumbers: ["06 12 34 56 78", "+44 7700 900123"]), .askUser)
    }

    func testUserDefaultsStorePersists() {
        let defaults = UserDefaults(suiteName: "LangappCoreTests")!
        defaults.removePersistentDomain(forName: "LangappCoreTests")
        UserDefaultsLanguagePreferenceStore(defaults: defaults).setLanguage("fr-FR", forContact: "x")
        XCTAssertEqual(UserDefaultsLanguagePreferenceStore(defaults: defaults).language(forContact: "x"), "fr-FR")
    }
}

final class KeyboardLanguageMatcherTests: XCTestCase {
    func testBestMatch() {
        let enabled = ["fr-FR", "en-US", "emoji"]
        XCTAssertEqual(KeyboardLanguageMatcher.bestMatch(for: "en-US", among: enabled), "en-US")
        XCTAssertEqual(KeyboardLanguageMatcher.bestMatch(for: "en-GB", among: enabled), "en-US")
        XCTAssertEqual(KeyboardLanguageMatcher.bestMatch(for: "fr_FR", among: enabled), "fr-FR")
        XCTAssertNil(KeyboardLanguageMatcher.bestMatch(for: "de-DE", among: enabled))
    }

    func testLanguageOptions() {
        XCTAssertEqual(KeyboardLanguageMatcher.languageOptions(from: ["en-GB", "emoji", "dictation", "fr-FR", "en-GB"]),
                       ["en-GB", "fr-FR"])
        XCTAssertEqual(KeyboardLanguageMatcher.languageOptions(from: ["en-US", "es-ES"]),
                       ["en-US", "es-ES", "fr-FR"])
    }
}
