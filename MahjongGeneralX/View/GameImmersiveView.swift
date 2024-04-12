//
//  GameImmersiveView.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/11/24.
//

import Foundation
import SwiftUI
import RealityKit
import MahjongCore

struct GameImmersiveView: View {
    @Environment(AppState.self) private var appState
    @State var placementManager: PlacementManager
    @State var gameManager: GameManager
    var body: some View {
        let localPlayer = gameManager.localPlayer
        RealityView { content, _ in
            content.add(placementManager.rootEntity)
            placementManager.appState = appState
            Task {
                await placementManager.runARKitSession()
            }
        } update: { _, attachments in
            
            if gameManager.gameState == .round {
                let menu = attachments.entity(for: AttachmentIDs.gameMenu)
                menu?.position = PlacementState.attachmentPosition
            } else {
                attachments.entity(for: AttachmentIDs.gameMenu)?.removeFromParent()
            }
            
            if (localPlayer?.playerState == .decideDiscardSuit) ?? false {
                let menu = attachments.entity(for: AttachmentIDs.discardTypeMenu)
                menu?.position = PlacementState.attachmentPosition
            } else {
                attachments.entity(for: AttachmentIDs.discardTypeMenu)?.removeFromParent()
            }
            
            if localPlayer?.decisionNeeded ?? false {
                let menu = attachments.entity(for: AttachmentIDs.decisionMenu)
                menu?.position = PlacementState.attachmentPosition
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
            Attachment(id: AttachmentIDs.gameMenu) {
                UserGameMenu()
                    .environment(gameManager)
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
