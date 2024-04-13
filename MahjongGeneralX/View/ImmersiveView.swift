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
    case utilsView = 102
}

@MainActor
struct ImmersiveView: View {
    @Environment(AppState.self) private var appState
    @State var placementManager: PlacementManager = PlacementManager()
    @State var gameManager: GameManager = GameManager()
    var body: some View {
        let localPlayer = gameManager.localPlayer
        RealityView { content, attachments in
            if let utilsView = attachments.entity(for: AttachmentIDs.utilsView) {
                placementManager.userUtilsView = utilsView
            }
            
            content.add(placementManager.rootEntity)
            let table = ModelLoader.getTable()
            placementManager.onModelLoaded(table: table)
            gameManager.onModelLoaded(table: table)
            placementManager.appState = appState
            
            Task {
                await placementManager.runARKitSession()
            }
        } update: { _, attachments in
            if gameManager.gameState == .decideDiscard {
                let menu = attachments.entity(for: AttachmentIDs.discardTypeMenu)
                menu?.position = PlacementState.attachmentPosition
                localPlayer?.basePlayer.rootEntity.addChild(menu!)
            } else {
                attachments.entity(for: AttachmentIDs.discardTypeMenu)?.removeFromParent()
            }
            
            if localPlayer?.decisionNeeded ?? false {
                let menu = attachments.entity(for: AttachmentIDs.decisionMenu)
                menu?.position = PlacementState.attachmentPosition
                localPlayer?.basePlayer.rootEntity.addChild(menu!)
            } else {
                attachments.entity(for: AttachmentIDs.decisionMenu)?.removeFromParent()
            }
        } attachments: {
            Attachment(id: AttachmentIDs.decisionMenu) {
                UserDecisionView()
                    .environment(gameManager)
            }
            Attachment(id: AttachmentIDs.discardTypeMenu) {
                UserDiscardTypeView()
                    .environment(gameManager)
            }
            Attachment(id: AttachmentIDs.utilsView) {
                if shouldAnchorTable {
                    UserUtilsView(text: "Find a plane to place table. Tab to confirm.")
                } else {
                    UserUtilsView(text: "Tab to place the table.")
                }
            }
        }
        .onChange(of: placementManager.tablePlaced) {
            if placementManager.tablePlaced {
                print("Starting game")
                gameManager.startGame()
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
                if let mahjong = event.entity as? MahjongEntity {
                    localPlayer?.onClickedMahjong(mahjong)
                }
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

// #Preview(immersionStyle: .mixed) {
//    ImmersiveView()
// }
