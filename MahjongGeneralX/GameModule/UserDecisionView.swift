//
//  UserDecisionInterface.swift
//  PlacingOnTable
//
//  Created by Katherine Xiong on 3/28/24.
//

import SwiftUI
import MahjongCore

// struct UserDecisionView: View {
//    @Environment(AppState.self) var appState
//    
//    var body: some View {
//        let localPlayer = appState.localPlayer!
//        HStack{
//            Button("Kang") {
//                if localPlayer.playerState == .roundDrawDecision {
//                    appState.localPlayerKang(mahjong: appState.possibleKangTiles[0])
//                } else {
//                    appState.localPlayerKang(mahjong: nil)
//                }
//            }.disabled(!appState.showKangButton)
//            Button("Pong") {
//                appState.localPlayerPong()
//            }.disabled(!appState.showPongButton)
//            Button("Hu") {
//                appState.localPlayerHu()
//            }.disabled(!appState.showHuButton)
//            Button("Pass") {
//                appState.localPlayerPass()
//            }.disabled(!appState.showPassButton)
//        }
//    }
// }
