//
//  UserDecisionInterface.swift
//  PlacingOnTable
//
//  Created by Katherine Xiong on 3/28/24.
//

import SwiftUI
import MahjongCore

 struct UserDecisionView: View {
    @Environment(GameManager.self) private var gameManager
    
    var body: some View {
        HStack {
            if let playerState = gameManager.localPlayer?.playerState {
                if playerState == .roundDraw {
                    DrawDecisionView()
                        .environment(gameManager)
                } else if playerState == .roundDecision {
                    DiscardDecisionView()
                        .environment(gameManager)
                }
            }
        }
    }
 }
