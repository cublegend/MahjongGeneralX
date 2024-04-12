//
//  DrawDecisionView.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/11/24.
//

import SwiftUI
import MahjongCore

 struct DrawDecisionView: View {
    @Environment(GameManager.self) private var gameManager
    
    var body: some View {
        HStack {
            if let localPlayer = gameManager.localPlayer {
                let mahjongSet = localPlayer.mahjongSet
                ForEach(localPlayer.possibleKangTiles, content: { tile in
                    Button("Kang \(tile.name)") {
                        localPlayer.processDrawDecision(ofType: .selfKang, tile: tile)
                    }
                })
                Button("Hu") {
                    localPlayer.processDrawDecision(ofType: .zimo, tile: nil)
                }.disabled(!localPlayer.canHu)
                Button("Pass") {
                    localPlayer.processDrawDecision(ofType: .pass, tile: nil)
                }.disabled(!localPlayer.decisionNeeded)
            }
        }
    }
 }
