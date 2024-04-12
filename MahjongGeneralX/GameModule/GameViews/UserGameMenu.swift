//
//  GameMenu.swift
//  PlacingOnTable
//
//  Created by Katherine Xiong on 3/25/24.
//

 import SwiftUI
 import RealityKit

 struct UserGameMenu: View {
    @Environment(GameManager.self) var gameManager
    @State private var paused = true
    
    var body: some View {
        HStack {
            Button {
                shouldCancelGame = true
            } label: {
                Label("Leave", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
            }
            
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
                    // Pause a moment to let the previous ride cancel.
                    try await Task.sleep(for: .seconds(0.1))
//                    appState.initializeAllMahjong()
//                    appState.gameState = .gameResetToStart
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
            if gameManager.gameState == .gameWaitToStart {
                Button("Start") {
                    gameManager.startGame()
                }
            } else if gameManager.gameState == .gameEnd {
                ForEach(gameManager.winnerIDs, id: \.self) { id in
                    Text(id)
                }
                Button("Restart") {
                    gameManager.enterWaitToStartState()
                }
            }
        }
        .onChange(of: paused) {
            shouldPauseGame.toggle()
            
            if !shouldPauseGame {
                // TODO: resume music and anime ?
            } else {
                // TODO: resume music and anime ?
            }
        }
    }
 }
