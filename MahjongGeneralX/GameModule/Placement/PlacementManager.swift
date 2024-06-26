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

@Observable
public final class PlacementManager {
    // MARK: - Placement
    public var rootEntity: Entity
    let highlightEntity = ModelEntity(
        mesh: .generatePlane(width: TableEntity.TABLE_WIDTH * 2 / 3, depth: TableEntity.TABLE_WIDTH * 2 / 3),
        materials: [UnlitMaterial(color: .cyan)],
        collisionShape: .generateSphere(radius: 0.005),
        mass: 0.0
    )

    var appState: AppState?
    var currentDrag: DragState?

    let worldTracking = WorldTrackingProvider()
    let planeTracking = PlaneDetectionProvider()
    let handTracking = HandTrackingProvider()
    
    var tablePlaced = false
    var handDetection: HandDetection
    var worldDetection: WorldDetection
    var planeDetection: PlaneDetection

    var placementState = PlacementState()

    let placementLocation: Entity
    let deviceLocation: Entity
    let raycastOrigin: Entity

    var table: TableEntity?

    // User decision attachment
    var userUtilsView: ViewAttachmentEntity?

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
    }
    
    public func onModelLoaded(table: TableEntity) {
        highlightEntity.components.set(OpacityComponent(opacity: 0))
        self.table = table
        placementState.selectedObject = table.previewEntity
        placementLocation.addChild(placementState.selectedObject)
        
        guard let menu = userUtilsView else { return }
        menu.position = SIMD3<Float>(0, 2 * TableEntity.TABLE_HEIGHT, 0)
        placementLocation.addChild(menu)
    }
    
    public func cleanUpData() {
        tablePlaced = false
        
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
        guard let table = self.table else { return }
        // If table successfully placed, store table dimension and location to GameInfo, and loading mahjongs to the table
        if self.performPlaceTable(table: table) {
            logger.info("User successfually placed mahjong")
            tablePlaced = true
            
            highlightEntity.position = SIMD3<Float>(0, TableEntity.TABLE_HEIGHT/2 + TableEntity.TABLE_HEIGHT/10, 0)
            table.addChild(highlightEntity)
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
            
            guard let menu = userUtilsView else { fatalError("Utils not found") }
            menu.removeFromParent()

            return true
        } else if !shouldAnchorTable {
            table.position = placementLocation.position
            table.orientation = placementLocation.orientation

            logger.info("Add table at \(table.position).")

            Task {
                await worldDetection.attachObjectToWorldAnchor(table)
            }

            table.previewEntity.removeFromParent()

            guard let menu = userUtilsView else { fatalError("Utils not found") }
            menu.removeFromParent()
            return true
        }
        return false
    }
}
