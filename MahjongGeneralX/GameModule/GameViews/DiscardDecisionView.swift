//
//  DiscardDecisionView.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/11/24.
//

import Foundation
import SwiftUI

struct DiscardDecisionView: View {
    @Environment(GameManager.self) private var gameManager
    var body: some View {
        HStack {
            if let localPlayer = gameManager.localPlayer {
                let lastTileDiscarded = localPlayer.mahjongSet.lastTileDiscarded
                Button("Kang") {
                    localPlayer.processDiscardDecision(ofType: .kang, discarded: lastTileDiscarded)
                }.disabled(!localPlayer.canKang)
                Button("Pong") {
                    localPlayer.processDiscardDecision(ofType: .pong, discarded: lastTileDiscarded)
                }.disabled(!localPlayer.canPong)
                Button("Hu") {
                    localPlayer.processDiscardDecision(ofType: .hu, discarded: lastTileDiscarded)
                }.disabled(!localPlayer.canHu)
                Button("Pass") {
                    localPlayer.processDiscardDecision(ofType: .pass, discarded: nil)
                }.disabled(!localPlayer.decisionNeeded)
            }
        }
    }
}
