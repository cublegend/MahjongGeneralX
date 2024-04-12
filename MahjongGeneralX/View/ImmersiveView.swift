//
//  ImmersiveView.swift
//  MahjongDemo2
//
//  Created by Katherine Xiong on 4/6/24.
//

import SwiftUI
import RealityKit

enum AttachmentIDs: Int {
    case decisionMenu = 100
    case discardTypeMenu = 101
    case gameMenu = 102
}

@MainActor
struct ImmersiveView: View {
    @Environment(AppState.self) private var appState
    // FIXME: game manager should be located in the game view (could be this one) but not the entire app's view, since it is only needed in a game of mahjong
    @State private var bootstrapper = GameBootstrapper()
    var body: some View {
        if bootstrapper.isReady {
            GameImmersiveView(placementManager: bootstrapper.placementManager, gameManager: bootstrapper.gameManager)
        } else {
            LoadingView()
                .task {
                    await bootstrapper.bootstrap()
                }
        }
        
    }
}

// #Preview(immersionStyle: .mixed) {
//    ImmersiveView()
// }
