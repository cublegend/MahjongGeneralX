////
////  GameMenu.swift
////  PlacingOnTable
////
////  Created by Katherine Xiong on 3/25/24.
////
//
// import SwiftUI
// import RealityKit
//
// struct UserGameMenu: View {
//    @Environment(AppState.self) var appState
//    @State private var paused = true
//    
//    var body: some View {
//        HStack {
//            Button {
//                shouldCancelGame = true
//            } label: {
//                Label("Leave", systemImage: "arrow.counterclockwise")
//                    .labelStyle(.iconOnly)
//            }
//            
//            Toggle(isOn: $paused) {
//                Label(shouldPauseGame ? "Play" : "Pause", systemImage: shouldPauseGame ? "play.fill" : "pause.fill")
//                    .labelStyle(.iconOnly)
//            }
//            .toggleStyle(.button)
//            .padding(.leading, 17)
//            .accessibilityElement()
//            .accessibilityLabel(shouldPauseGame ? Text("Play Ride") : Text("Pause Ride"))
//            
//            Button {
//                shouldCancelGame = true
//                Task {
//                    // Pause a moment to let the previous ride cancel.
//                    try await Task.sleep(for: .seconds(0.1))
////                    appState.initializeAllMahjong()
////                    appState.gameState = .gameResetToStart
//                }
//            } label: {
//                Label("Restart Game", systemImage: "arrow.counterclockwise")
//                    .labelStyle(.iconOnly)
//            }
//            .padding(.trailing, 9)
//            .accessibilityElement()
//            .accessibilityValue(Text("Restart the game."))
//
//            Button("Undo") {
//                
//            }
//            if appState.gameState == .gameResetToStart {
//                Button("Start") {
//                    appState.enterResetToStartState()
//                }
//            } else if appState.gameState == .gameEnd {
//                ForEach(GameInfo.winnersID, id: \.self) { id in
//                    Text(id)
//                }
//                Button("Restart") {
//                    appState.initializeAllMahjong()
//                    appState.gameState = .gameResetToStart
//                }
//            }
//        }
//        .onChange(of: paused) {
//            shouldPauseGame.toggle()
//            
//            if !shouldPauseGame {
//                // TODO: resume music and anime ?
//            } else {
//                // TODO: resume music and anime ?
//            }
//        }
//    }
// }
