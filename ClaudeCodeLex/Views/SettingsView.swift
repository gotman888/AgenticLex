// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var termStore: TermStore
    @StateObject private var updater = TermUpdateService.shared
    @State private var showResetConfirm = false
    @State private var showTipJar = false
    @State private var showFeedbackMail = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("settings.section.learning")) {
                    Picker("settings.uiLanguage", selection: $settings.uiLanguage) {
                        ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                            Text(lang.label).tag(lang.code)
                        }
                    }
                    Picker("settings.nativeLanguage", selection: $settings.nativeLanguage) {
                        ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                            Text(lang.label).tag(lang.code)
                        }
                    }
                    Picker("settings.dailyGoal", selection: $settings.dailyGoal) {
                        ForEach([3, 5, 10, 20], id: \.self) { Text("\($0)").tag($0) }
                    }
                }

                Section(header: Text("settings.section.audio")) {
                    HStack {
                        Text("settings.speed")
                        Slider(value: $settings.audioRate, in: 0.3...0.6)
                    }
                    Toggle("settings.autoplay", isOn: $settings.autoPlayOnOpen)
                }

                Section(header: Text("settings.section.appearance")) {
                    Picker("settings.theme", selection: $settings.theme) {
                        Text("settings.theme.auto").tag("auto")
                        Text("settings.theme.light").tag("light")
                        Text("settings.theme.dark").tag("dark")
                    }
                }

                Section(header: Text("settings.section.notifications")) {
                    Toggle("settings.notify.daily", isOn: $settings.dailyReminderEnabled)
                        .onChange(of: settings.dailyReminderEnabled) { enabled in
                            handleReminderToggle(enabled)
                        }
                    if settings.dailyReminderEnabled {
                        DatePicker("settings.notify.time",
                                   selection: reminderTime,
                                   displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    NavigationLink {
                        AchievementsView()
                    } label: {
                        Label("achv.title", systemImage: "rosette")
                    }
                    NavigationLink {
                        ListenModeView()
                    } label: {
                        Label("listen.tab", systemImage: "headphones")
                    }
                    NavigationLink {
                        AIBoostView()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(AppColor.brandPrimary)
                            Text("aiboost.title")
                            Spacer()
                            if settings.voiceProvider != .native || settings.chatProvider != nil {
                                Text("aiboost.active")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section(header: Text("settings.section.support")) {
                    Button {
                        showTipJar = true
                    } label: {
                        Label("tipjar.title", systemImage: "heart.fill")
                            .foregroundStyle(AppColor.brandPrimary)
                    }
                }

                Section(header: Text("settings.section.data")) {
                    Toggle("settings.dict.autoUpdate", isOn: $settings.dictionaryAutoUpdate)
                        .onChange(of: settings.dictionaryAutoUpdate) { on in
                            guard on else { return }
                            Task {
                                await updater.check(
                                    currentVersion: termStore.main?.metadata.version ?? "0")
                            }
                        }
                    Text(dictStatusKey)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if updater.status == .updated {
                        Text("settings.dict.thanks")   // "we listened" loop-closer
                            .font(.caption)
                            .foregroundStyle(AppColor.brandPrimary)
                    }
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("settings.resetAll")
                    }
                }

                Section(header: Text("aidisclosure.settings.section")) {
                    PrivacySettingsRow()
                }

                Section(header: Text("settings.section.about")) {
                    HStack {
                        Text("settings.version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    Link("settings.github",
                         destination: URL(string: "https://github.com/gotman888/AgenticLex")!)
                    Link("settings.privacy",
                         destination: URL(string: "https://agenticlex.pages.dev")!)
                    Button {
                        if MailComposer.canSend {
                            showFeedbackMail = true
                        } else if let u = FeedbackMail.mailtoURL(
                            subject: NSLocalizedString("feedback.subject", comment: ""),
                            body: NSLocalizedString("report.intro", comment: "")
                                + FeedbackMail.context(settings: settings,
                                                       dictVersion: termStore.main?.metadata.version)) {
                            openURL(u)
                        }
                    } label: {
                        Text("settings.feedback")
                    }
                }

                // Disclaimer 已移至 OnboardingView (顯眼位置)。
                // Settings 底部僅留版本與聯絡。
            }
            .navigationTitle("settings.tab")
            .confirmationDialog("settings.resetConfirm",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("settings.resetAll", role: .destructive) {
                    progress.resetAll()
                }
                Button("common.cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showTipJar) {
                TipJarView()
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showFeedbackMail) {
                MailComposer(
                    subject: NSLocalizedString("feedback.subject", comment: ""),
                    body: "\n\n" + NSLocalizedString("report.intro", comment: "")
                        + FeedbackMail.context(settings: settings,
                                               dictVersion: termStore.main?.metadata.version))
            }
        }
    }

    // MARK: - Daily reminder

    /// DatePicker binding backed by the hour/minute ints in AppSettings.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    from: DateComponents(hour: settings.reminderHour,
                                         minute: settings.reminderMinute)
                ) ?? Date()
            },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                settings.reminderHour = comps.hour ?? 20
                settings.reminderMinute = comps.minute ?? 0
                rescheduleReminder()
            }
        )
    }

    private func handleReminderToggle(_ enabled: Bool) {
        guard enabled else {
            NotificationService.reschedule(enabled: false, hour: 0, minute: 0, streakDays: 0)
            return
        }
        Task { @MainActor in
            let granted = await NotificationService.requestAuthorization()
            if granted {
                rescheduleReminder()
            } else {
                // Permission denied — reflect reality by reverting the toggle.
                settings.dailyReminderEnabled = false
            }
        }
    }

    private func rescheduleReminder() {
        guard settings.dailyReminderEnabled else { return }
        NotificationService.reschedule(
            enabled: true,
            hour: settings.reminderHour,
            minute: settings.reminderMinute,
            streakDays: progress.streakDays
        )
    }

    // MARK: - Dictionary update status

    private var dictStatusKey: LocalizedStringKey {
        switch updater.status {
        case .checking: return "settings.dict.checking"
        case .upToDate: return "settings.dict.upToDate"
        case .updated:  return "settings.dict.updated"
        case .failed:   return "settings.dict.failed"
        case .idle:     return "settings.dict.note"
        }
    }
}
