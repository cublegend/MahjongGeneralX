//
//  ImmersiveView.swift
//  MahjongDemo2
//
//  Created by Katherine Xiong on 4/6/24.
//

import SwiftUI
import RealityKit
import MahjongCore

enum AttachmentIDs: Int {
    case decisionMenu = 100
    case discardTypeMenu = 101
    case gameMenu = 102
}

@MainActor
struct ImmersiveView: View {
    @Environment(AppState.self) private var appState
    @State private var placementManager = PlacementManager()
    var body: some View {
        RealityView { content in
            content.add(placementManager.rootEntity)
            placementManager.appState = appState
            Task {
                await placementManager.runARKitSession()
            }

        }
        .task {
            await placementManager.processWorldAnchorUpdates()
        }
        .task {
            await placementManager.processDeviceAnchorUpdates()
        }
        .task {
            // Update plane anchors
            await placementManager.processPlaneUpdates()
        }
        .task {
            await placementManager.processHandAnchorUpdates()
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { event in
            // click on the cube to place it in the space
            print("Clicked on something")
            if event.entity.components[CollisionComponent.self]?.filter.group == TableEntity.previewCollisionGroup {
                logger.info("Placing table.")
                placementManager.userPlaceTable()
            } else if event.entity.components[CollisionComponent.self]?.filter.group == MahjongEntity.clickableCollisionGroup {
                print(event.entity.name)
//                print(appState.gameState)
//                print(appState.localPlayer!.playerState)
//                if appState.gameState == .switchTiles {
//                    appState.localPlayerChooseSwitchTiles(value: event.entity)
//                }
//                if appState.gameState == .round && appState.localPlayer!.playerState == .roundDiscard{
//                    appState.playerChooseDiscardTiles(value: event.entity)
//                }
            }
        }).onAppear {
            print("Entering immersive space.")
            appState.immersiveSpaceOpened(with: placementManager)
        }
        .onDisappear {
            print("Leaving immersive space.")
            appState.cleanUpAfterLeavingImmersiveSpace()
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
