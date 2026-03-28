//
//  SettingsView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme = 0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @Environment(\.openURL) private var openURL

    // MARK: - Propriedades Dinâmicas (Lê do Xcode automaticamente)
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER FIXO (ESTILO SITE) ---
            ZStack(alignment: .bottom) {
                TBTheme.highlightGradient
                
                HStack {
                    Spacer()
                    Image("tb-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 28)
                    Spacer()
                }
                .padding(.bottom, 12)
            }
            .frame(height: 100)

            // --- LISTA DE AJUSTES ---
            List {
                // Secção Sobre
                Section {
                    HStack(spacing: 16) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tecnoblog").font(.headline)
                            Text("Tecnologia, inovação e cultura digital")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Secção Aparência
                Section("Aparência") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tema do Aplicativo", systemImage: appTheme == 1 ? "sun.max.fill" : (appTheme == 2 ? "moon.fill" : "iphone"))
                            .font(.subheadline)
                        
                        Picker("Tema", selection: $appTheme) {
                            Text("Sistema").tag(0)
                            Text("Claro").tag(1)
                            Text("Escuro").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                }

                // Secção Notificações
                Section("Notificações") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Receber notificações", systemImage: "bell.badge")
                    }
                    .tint(TBTheme.accent)
                }

                // Secção Links
                Section("Links") {
                    LinkRow(title: "Site do Tecnoblog", icon: "globe", color: TBTheme.accent) {
                        openURL(URL(string: "https://tecnoblog.net")!)
                    }
                    
                    LinkRow(title: "Canal no YouTube", icon: "play.rectangle.fill", color: .red) {
                        openURL(URL(string: "https://youtube.com/tecnoblog")!)
                    }
                }
                
                // Info do App (Lê do projeto Xcode)
                Section {
                    HStack {
                        Text("Versão")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(buildNumber).foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Este aplicativo não é oficial do Tecnoblog.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
    }
}

// MARK: - Componente LinkRow (Certifica-te que isto está no fim do ficheiro)

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
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
