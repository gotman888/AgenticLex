// MailComposer.swift
// In-app feedback capture. Wraps MFMailComposeViewController so a tap on
// "Send feedback" / "Report a problem" opens a prefilled mail draft the user
// reviews and sends from their own Mail account. Device-only: nothing leaves
// the device except the email the user chooses to send. No backend, no tracking.

import SwiftUI
import MessageUI

/// Shared helpers for building feedback mail (recipient, diagnostic footer,
/// and a mailto fallback when no Mail account is configured).
enum FeedbackMail {
    static let recipient = "gotman888@gmail.com"

    /// Diagnostic footer appended below the user's message so the owner can
    /// triage by build / device / locale. Shown to the user before they send.
    @MainActor
    static func context(settings: AppSettings, dictVersion: String?) -> String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "?"
        let b = info?["CFBundleVersion"] as? String ?? "?"
        #if canImport(UIKit)
        let device = UIDevice.current.model
        let os = UIDevice.current.systemVersion
        #else
        let device = "?"
        let os = "?"
        #endif
        return """


        —
        AgenticLex \(v) (\(b)) · iOS \(os) · \(device)
        UI: \(settings.uiLanguage) · Native: \(settings.nativeLanguage) · Dict: \(dictVersion ?? "bundled")
        """
    }

    /// Fallback for devices with no Mail account configured.
    static func mailtoURL(subject: String, body: String) -> URL? {
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = recipient
        c.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return c.url
    }
}

/// SwiftUI wrapper around the system mail composer.
struct MailComposer: UIViewControllerRepresentable {
    let subject: String
    let body: String

    /// True when the device can present the in-app composer (a Mail account exists).
    static var canSend: Bool { MFMailComposeViewController.canSendMail() }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([FeedbackMail.recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}
