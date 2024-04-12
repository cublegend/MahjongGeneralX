//
//  PlacementManager.swift
//  MahjongDemo2
//
//  Created by Katherine Xiong on 4/7/24.
//

import Foundation
import ARKit
import RealityKit
import QuartzCore
import SwiftUI
import simd
import MahjongCore

public final class PlacementManager {
    // MARK: - Placement
    public var rootEntity: Entity

    var appState: AppState?

    let worldTracking = WorldTrackingProvider()
    let planeTracking = PlaneDetectionProvider()
    let handTracking = HandTrackingProvider()

    var handDetection: HandDetection
    var worldDetection: WorldDetection
    var planeDetection: PlaneDetection

    var placementState = PlacementState()

    let placementLocation: Entity
    let deviceLocation: Entity
    let raycastOrigin: Entity

    var table = [TableEntity]()
    var mahjongPrototype = [MahjongEntity]()

    // User decision attachment
    var userDecisionAttachment: ViewAttachmentEntity?
    var userDiscardTypeAttachment: ViewAttachmentEntity?
    var userGameMenu: ViewAttachmentEntity?

    init() {
        let root = Entity()
        rootEntity = root
        placementLocation = Entity()

        deviceLocation = Entity()
        raycastOrigin = Entity()

        planeDetection = PlaneDetection(rootEntity: root)
        handDetection = HandDetection(rootEntity: root)
        worldDetection = WorldDetection(worldTracking: worldTracking, rootEntity: root)
        worldDetection.deletePersistentObjectsFile()
        worldDetection.loadPersistedObjects()

        rootEntity.addChild(placementLocation)
        deviceLocation.addChild(raycastOrigin)

        Task {
            await table.append(ModelLoader.getTable())
            await placementState.selectedObject = self.table[0].previewEntity
            await placementLocation.addChild(placementState.selectedObject)
        }
    }

    @MainActor
    func runARKitSession() async {
        do {
            // Run a new set of providers every time when entering the immersive space.
            try await appState!.arkitSession.run([worldTracking, planeTracking, handTracking])
        } catch {
            // No need to handle the error here; the app is already monitoring the
            // session for error.
            return
        }
    }

    /// Called when user tapped a place to add the table into the world.
    @MainActor func userPlaceTable() {
        // Tap to add table in the world

        let table = self.table[0]

        // If table successfully placed, store table dimension and location to GameInfo, and loading mahjongs to the table
        if self.performPlaceTable(table: table) {
            logger.info("User successfually placed mahjong")
        }
    }

    @MainActor func performPlaceTable(table: TableEntity) -> Bool {
        if shouldAnchorTable {
            if !placementState.isPlaceTablePossible {
                logger.info("Can't add table here")
                return false
            }

            table.position = placementLocation.position
            table.orientation = placementLocation.orientation

            logger.info("Add table at \(table.position).")

            Task {
                await worldDetection.attachObjectToWorldAnchor(table)
            }

            table.previewEntity.removeFromParent()

            return true
        } else if !shouldAnchorTable {
            table.position = placementLocation.position
            table.orientation = placementLocation.orientation

            logger.info("Add table at \(table.position).")

            Task {
                await worldDetection.attachObjectToWorldAnchor(table)
            }

            table.previewEntity.removeFromParent()

            return true
        }
        return false
    }
}
