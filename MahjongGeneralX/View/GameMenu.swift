//
//  GameMenu.swift
//  MahjongGeneralX
//
//  Created by Katherine Xiong on 4/12/24.
//

import SwiftUI

struct GameMenu: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var paused = true
    var body: some View {
        HStack {
            Button {
                shouldCancelGame = true
                Task {
                    await dismissImmersiveSpace()
                    appState.appPhase = .mainMenu
                }
            } label: {
                Label("Leave", systemImage: "xmark.circle")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            
            Toggle(isOn: $paused) {
                Label(shouldPauseGame ? "Play" : "Pause", systemImage: shouldPauseGame ? "play.fill" : "pause.fill")
                    .labelStyle(.iconOnly)
            }
            .toggleStyle(.button)
            .padding(.leading, 17)
            .accessibilityElement()
            .accessibilityLabel(shouldPauseGame ? Text("Play Ride") : Text("Pause Ride"))
            
            Button {
                shouldCancelGame = true
                Task {
//                    appState.gameManager?.gameState = .gameResetToStart
                }
            } label: {
                Label("Restart Game", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
            }
            .padding(.trailing, 9)
            .accessibilityElement()
            .accessibilityValue(Text("Restart the game."))

            Button("Undo") {
                
            }
        }
        .onChange(of: paused) {
            shouldPauseGame.toggle()
            
            if !shouldPauseGame {
                // TODO: resume music and anime ?
            } else {
                // TODO: resume music and anime ?
            }
            
//            appState.music = shouldPauseGame ? .silent : .ride
        }
    }
}

#Preview {
    GameMenu()
        .environment(AppState())
}
