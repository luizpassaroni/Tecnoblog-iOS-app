//
//  SettingsView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    // 0 = Sistema, 1 = Claro, 2 = Escuro
    @AppStorage("appTheme") private var appTheme = 0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                // Sobre o app
                aboutSection

                // Aparência (Tema)
                appearanceSection

                // Notificações
                notificationsSection

                // Links úteis
                linksSection

                // Info do app
                appInfoSection
            }
            .navigationTitle("Ajustes")
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Sections

    private var aboutSection: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(TBTheme.highlightGradient)
                        .frame(width: 64, height: 64)
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tecnoblog")
                        .font(.headline)
                    Text("Tecnologia, inovação e cultura digital")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var appearanceSection: some View {
        Section("Aparência") {
            VStack(alignment: .leading, spacing: 12) {
                Label("Tema do Aplicativo", systemImage: themeIcon)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Picker("Tema", selection: $appTheme) {
                    Text("Sistema").tag(0)
                    Text("Claro").tag(1)
                    Text("Escuro").tag(2)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)
        }
    }

    private var notificationsSection: some View {
        Section("Notificações") {
            Toggle(isOn: $notificationsEnabled) {
                Label("Receber notificações", systemImage: "bell.badge")
            }
            .tint(TBTheme.accent)
            .onChange(of: notificationsEnabled) { _, newValue in
                if newValue { requestNotificationPermission() }
            }

            if notificationsEnabled {
                Label("Você receberá alertas das principais notícias.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var linksSection: some View {
        Section("Links") {
            LinkRow(title: "Site do Tecnoblog", icon: "globe", color: TBTheme.accent) {
                openURL(TBConfig.App.siteURL)
            }

            LinkRow(title: "Canal no YouTube", icon: "play.rectangle.fill", color: .red) {
                openURL(TBConfig.App.youtube)
            }

            LinkRow(title: "Tecnocast no Spotify", icon: "music.note", color: .green) {
                openURL(URL(string: "spotify:show:2p0v6nU7868Yf0D394CpA3") ?? TBConfig.App.siteURL)
            }

            LinkRow(title: "Política de Privacidade", icon: "hand.raised.fill", color: .blue) {
                openURL(URL(string: "https://tecnoblog.net/privacidade")!)
            }
        }
    }

    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Versão")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Este aplicativo não é oficial do Tecnoblog. Desenvolvido de forma independente.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private var themeIcon: String {
        switch appTheme {
        case 1: return "sun.max.fill"
        case 2: return "moon.fill"
        default: return "iphone"
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationsEnabled = granted
            }
        }
    }
}

// MARK: - Link Row Component

struct LinkRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
