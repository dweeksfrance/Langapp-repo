import LangappCore
import SwiftUI
import UIKit

/// A text view that asks iOS for a keyboard in a given language.
///
/// iOS lets a text view request a keyboard by overriding `textInputMode`. The
/// request only works for keyboards the user has enabled in Settings, and iOS
/// reads it when the view becomes first responder.
final class KeyboardLanguageTextView: UITextView {
    var preferredLanguage: String? {
        didSet {
            guard preferredLanguage != oldValue, isFirstResponder else { return }
            // Re-focus so iOS reads textInputMode again and switches keyboards.
            resignFirstResponder()
            becomeFirstResponder()
        }
    }

    override var textInputMode: UITextInputMode? {
        if let language = preferredLanguage {
            let modes = UITextInputMode.activeInputModes
            if let match = KeyboardLanguageMatcher.bestMatch(for: language, among: modes.compactMap(\.primaryLanguage)),
               let mode = modes.first(where: { $0.primaryLanguage == match }) {
                return mode
            }
        }
        return super.textInputMode
    }
}

struct LanguageTextView: UIViewRepresentable {
    @Binding var text: String
    var language: String?
    var isFocused: Bool

    func makeUIView(context: Context) -> KeyboardLanguageTextView {
        let view = KeyboardLanguageTextView()
        view.font = .preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        view.textContainerInset = UIEdgeInsets(top: 10, left: 6, bottom: 10, right: 6)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: KeyboardLanguageTextView, context: Context) {
        context.coordinator.text = $text
        if view.text != text { view.text = text }
        view.preferredLanguage = language

        if isFocused, !view.isFirstResponder {
            DispatchQueue.main.async { view.becomeFirstResponder() }
        } else if !isFocused, view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}
