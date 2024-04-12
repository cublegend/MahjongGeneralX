//
//  MahjongGeneralXApp.swift
//  MahjongGeneralX
//
//  Created by Katherine Xiong on 4/9/24.
//

import SwiftUI
import MahjongCore

enum UIIdentifier {
    static let entryPoint = "Entry point"
    static let gameModule = "Game Module"
}

@main
@MainActor
struct MahjongGeneralXApp: App {

    @State private var appState = AppState()

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup(id: UIIdentifier.entryPoint) {
            MahjongView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        ImmersiveSpace(id: UIIdentifier.gameModule) {
            if ModelLoader.didFinishLoading {
                ImmersiveView(placementManager: PlacementManager(), gameManager: GameManager(table: ModelLoader.getTable()))
                    .environment(appState)
            }
        }
        .onChange(of: scenePhase, initial: true) {
            if scenePhase != .active {
                // Leave the immersive space when the user dismisses the app.
                if appState.immersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.cleanUpAfterLeavingImmersiveSpace()
                    }
                }
            }
        }
    }
}
