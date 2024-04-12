//
//  ContentView.swift
//  MahjongDemo2
//
//  Created by Katherine Xiong on 4/6/24.
// r

import SwiftUI
import RealityKit
import RealityKitContent

struct Welcome: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        @Bindable var appState = appState
        ZStack {
            HStack {
                Spacer()
                VStack {
                    Spacer(minLength: 250)
                    VStack {
                        Text("Welcome")
                            .monospaced()
                            .font(.system(size: 50, weight: .bold))
                        Text("Discover a new way of playing Mahjong.")
                            .font(.title)
                            .padding(.vertical, 6)
                    }
                    Spacer()
                    Group {
                        VStack {
                            InfoLabel(appState: appState)
                                .padding(.horizontal, 30)
                                .frame(width: 400)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("Enter") {
                                appState.appPhase = .mainMenu
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    Spacer(minLength: 170)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    Welcome()
        .environment(AppState())
}
