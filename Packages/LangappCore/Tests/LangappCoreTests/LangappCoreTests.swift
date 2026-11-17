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

    func testFrenchOverseasCountAsFrench() {
        XCTAssertEqual(region("+262 692 12 34 56"), .france)   // Réunion
        XCTAssertEqual(region("+590 690 12 34 56"), .france)   // Guadeloupe
        XCTAssertEqual(region("+594 694 12 34 56"), .france)   // French Guiana
        XCTAssertEqual(region("+596 696 12 34 56"), .france)   // Martinique
        XCTAssertEqual(region("+508 55 12 34"), .france)       // Saint-Pierre-et-Miquelon
        XCTAssertEqual(region("00687 75 12 34"), .france)      // New Caledonia
        XCTAssertEqual(region("+689 87 12 34 56"), .france)    // French Polynesia
        XCTAssertEqual(region("+681 82 12 34"), .france)       // Wallis-et-Futuna
        XCTAssertEqual(region("0692 12 34 56", "FR"), .france) // Réunion, national format
        XCTAssertEqual(region("+591 2 123 4567"), .other)      // Bolivia, a neighbouring code
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

final class WhatsAppLinkTests: XCTestCase {
    private func intl(_ n: String, _ r: String? = "FR") -> String? {
        WhatsAppLink.internationalDigits(of: n, defaultRegion: r)
    }

    func testInternationalDigits() {
        XCTAssertEqual(intl("+44 7700 900123"), "447700900123")
        XCTAssertEqual(intl("0033 6 12 34 56 78"), "33612345678")
        XCTAssertEqual(intl("06 12 34 56 78"), "33612345678")
        XCTAssertEqual(intl("0692 12 34 56"), "262692123456")   // Réunion mobile
        XCTAssertEqual(intl("0696 12 34 56"), "596696123456")   // Martinique mobile
        XCTAssertEqual(intl("07700 900123", "GB"), "447700900123")
        XCTAssertEqual(intl("(415) 555-0132", "US"), "14155550132")
        XCTAssertNil(intl("07700 900123", "FR"))                // can't tell which country
        XCTAssertNil(intl("123", "FR"))
    }

    func testURLEncodesMessage() {
        let url = WhatsAppLink.url(internationalDigits: "33612345678", text: "Ça va? 1+1 & co")
        XCTAssertEqual(url?.absoluteString, "https://wa.me/33612345678?text=%C3%87a%20va%3F%201%2B1%20%26%20co")
    }

    func testPicksFirstUsableNumber() {
        let url = WhatsAppLink.url(phoneNumbers: ["n/a", "06 12 34 56 78"], text: "hi", defaultRegion: "FR")
        XCTAssertEqual(url?.absoluteString, "https://wa.me/33612345678?text=hi")
        XCTAssertNil(WhatsAppLink.url(phoneNumbers: ["n/a"], text: "hi", defaultRegion: "FR"))
    }
}
