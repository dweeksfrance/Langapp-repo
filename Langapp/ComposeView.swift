import MessageUI
import SwiftUI

struct ComposeView: View {
    let contact: Contact
    @StateObject private var controller: ComposeController
    @State private var text = ""
    @State private var isShowingMessageComposer = false

    init(contact: Contact) {
        self.contact = contact
        _controller = StateObject(wrappedValue: ComposeController(contact: contact))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let note = controller.statusNote {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            LanguageTextView(
                text: $text,
                language: controller.keyboardLanguage,
                isFocused: controller.shouldFocus
            )
        }
        .padding()
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if controller.isFrenchContact {
                    Button {
                        controller.askAgain()
                    } label: {
                        Label("Keyboard language", systemImage: "globe")
                    }
                }
                Button("Send") { isShowingMessageComposer = true }
                    .disabled(text.isEmpty || !MFMessageComposeViewController.canSendText())
            }
        }
        .confirmationDialog(
            "Keyboard language for \(contact.name)",
            isPresented: $controller.isAskingForLanguage,
            titleVisibility: .visible
        ) {
            ForEach(controller.languageOptions, id: \.self) { language in
                Button(displayName(for: language)) { controller.choose(language) }
            }
        } message: {
            Text("\(contact.name) has a French number. Langapp will remember your choice for next time.")
        }
        .sheet(isPresented: $isShowingMessageComposer) {
            MessageComposer(recipient: contact.phoneNumbers.first ?? "", body: text) { sent in
                isShowingMessageComposer = false
                if sent { text = "" }
            }
            .ignoresSafeArea()
        }
        .onAppear { controller.start() }
    }
}

/// Hands the finished text to Messages for sending.
struct MessageComposer: UIViewControllerRepresentable {
    let recipient: String
    let body: String
    let onFinish: (_ sent: Bool) -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.recipients = [recipient]
        composer.body = body
        composer.messageComposeDelegate = context.coordinator
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: (Bool) -> Void
        init(onFinish: @escaping (Bool) -> Void) { self.onFinish = onFinish }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            onFinish(result == .sent)
        }
    }
}
