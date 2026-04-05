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
    
    // ✅ Estado para controlar se o usuário "comprou" a versão sem anúncios
    @AppStorage("isAdFree") private var isAdFree = false
    
    @Environment(\.openURL) private var openURL

    // MARK: - Propriedades Dinâmicas
    
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
                // Seção Premium
                Section("Premium") {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isAdFree ? .green : TBTheme.accent)
                                .frame(width: 32, height: 32)
                            Image(systemName: isAdFree ? "checkmark.seal.fill" : "crown.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(isAdFree ? "Versão Pro Ativa" : "Remover Anúncios")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(isAdFree ? "Obrigado por apoiar!" : "Acesso total sem interrupções")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if !isAdFree {
                            Button("Comprar") {
                                withAnimation {
                                    isAdFree = true
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(TBTheme.accent)
                            .controlSize(.small)
                        } else {
                            Button("Restaurar") {
                                withAnimation {
                                    isAdFree = false
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Seção Aparência
                Section("Aparência") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tema do Aplicativo", systemImage: themeIcon)
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

                // Seção Notificações
                Section("Notificações") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Receber notificações", systemImage: "bell.badge")
                    }
                    .tint(TBTheme.accent)
                }

                // Seção Links
                Section("Links Rápidos") {
                    // ✅ O LinkRow agora será encontrado aqui
                    LinkRow(title: "Site do Tecnoblog", icon: "globe", color: TBTheme.accent) {
                        openURL(URL(string: "https://tecnoblog.net")!)
                    }
                    
                    LinkRow(title: "Canal no YouTube", icon: "play.rectangle.fill", color: .red) {
                        openURL(URL(string: "https://youtube.com/tecnoblog")!)
                    }
                }
                
                // Info do App e Créditos
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
                    VStack(alignment: .center, spacing: 8) {
                        Text("Tecnoblog: Tecnologia, inovação e cultura digital.")
                        Text("Este aplicativo não é oficial e não possui vínculo com a equipe do Tecnoblog.")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                }
            }
            .listStyle(.insetGrouped)
        }
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
    }
    
    private var themeIcon: String {
        switch appTheme {
        case 1: return "sun.max.fill"
        case 2: return "moon.fill"
        default: return "iphone"
        }
    }
}

// MARK: - ✅ Definição do LinkRow (Necessário para resolver o erro)

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
