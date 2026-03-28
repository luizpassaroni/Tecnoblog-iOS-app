//
//  TecnoblogApp.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct TecnoblogApp: App {
    @State private var viewModel = MainViewModel()
    
    // 1. Escuta a mesma chave de AppStorage que definimos na SettingsView
    // 0 = Sistema, 1 = Claro, 2 = Escuro
    @AppStorage("appTheme") private var appTheme = 0

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(viewModel)
                .modelContainer(viewModel.modelContainer)
                // 2. Aplica o tema dinamicamente em todo o app
                .preferredColorScheme(selectedColorScheme)
        }
    }
    
    // 3. Helper para converter o número salvo no tipo que o SwiftUI entende
    private var selectedColorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil // 'nil' faz o app seguir o modo do sistema (Automático)
        }
    }
}
