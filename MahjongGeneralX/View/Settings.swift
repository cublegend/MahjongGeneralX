//
//  Settings.swift
//  MahjongDemo2
//
//  Created by Katherine Xiong on 4/6/24.
//

import SwiftUI

struct Settings: View {

    @Environment(AppState.self) private var appState
    @State private var anchorTable = true

    @State private var music = 50.0

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)

            HStack {
                Toggle(isOn: $anchorTable) {
                    Text("Placing Mahjong Table on Horizontal Plane")
                }
                .padding()
            }

            HStack {
                Label("low", systemImage: "speaker.1")
                    .labelStyle(.iconOnly)
                Slider(value: $music)
                Label("high", systemImage: "speaker.3")
                    .labelStyle(.iconOnly)
            }
        }
        .onChange(of: anchorTable) {
            shouldAnchorTable.toggle()
        }
    }
}

#Preview(windowStyle: .plain) {
    Settings()
        .environment(AppState())
        .padding(20)
        .frame(width: 400)
        .glassBackgroundEffect()
}
