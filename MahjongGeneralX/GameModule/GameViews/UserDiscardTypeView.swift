//
//  UserDiscardTypeView.swift
//  PlacingOnTable
//
//  Created by Katherine Xiong on 4/2/24.
//

import SwiftUI
import MahjongCommons

 struct UserDiscardTypeView: View {
    @Environment(GameManager.self) private var gameManager
    
    var body: some View {
        HStack {
            if let localPlayer = gameManager.localPlayer {
                ForEach(MahjongType.allCases) {type in
                    Button(type.text) {
                        localPlayer.processDecideType(type)
                    }
                }
            }
        }
        .padding()
    }
 }
