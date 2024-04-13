//
//  PlacementManager+Interaction.swift
//  MahjongGeneralX
//
//  Created by Katherine Xiong on 4/12/24.
//

import SwiftUI
import RealityKit
import MahjongCore
import UIKit

struct DragState {
    var draggedObject: MahjongEntity
    var initialPositionNewParent: SIMD3<Float>
    var initialPositionOldParent: SIMD3<Float>
    var parentEntity: Entity
    
    @MainActor
    init(objectToDrag: MahjongEntity, newPos: SIMD3<Float>) {
        draggedObject = objectToDrag
        initialPositionOldParent = objectToDrag.position
        initialPositionNewParent = newPos
        parentEntity = objectToDrag.parent!
        print("parent 1: \(parentEntity.name)")
    }
}

extension PlacementManager {
    @MainActor
    func updataDragDiscard(mahjong: MahjongEntity, value: EntityTargetValue<DragGesture.Value>, localPlayer: LocalPlayerController) {
        if let currentDrag, currentDrag.draggedObject !== mahjong {
            // Make sure any previous drag ends before starting a new one.
            print("A new drag started but the previous one never ended - ending that one now.")
            cannotDrag()
        }
        
        guard let table = self.table else { return }

        if currentDrag == nil {
            let tempPosition = table.convert(position: mahjong.position, from: mahjong)
            currentDrag = DragState(objectToDrag: mahjong, newPos: tempPosition)
            mahjong.removeFromParent()
            table.addChild(mahjong)
        }
        
        if let currentDrag {
            currentDrag.draggedObject.position = currentDrag.initialPositionNewParent + value.convert(value.translation3D, from: .local, to: table)
            if localPlayer.playerState == .roundDiscard {
                if inDiscardPileArea(handPos: currentDrag.draggedObject.position) {
                    highlightEntity.components.set(OpacityComponent(opacity: 1))
                } else {
                    highlightEntity.components.set(OpacityComponent(opacity: 0.3))
                }
            }
        }
    }
    
    @MainActor
    func endDrag(mahjong: MahjongEntity, localPlayer: LocalPlayerController) {
        guard let currentDrag else { return }
        highlightEntity.components.set(OpacityComponent(opacity: 0))

        if localPlayer.playerState == .roundDiscard && inDiscardPileArea(handPos: currentDrag.draggedObject.position) && localPlayer.tryProcessDiscardTile(mahjong) {
            self.currentDrag = nil
        } else {
            currentDrag.parentEntity.addChild(currentDrag.draggedObject)
            currentDrag.draggedObject.position = currentDrag.initialPositionOldParent
            self.currentDrag = nil
        }
    }
    
    @MainActor
    func cannotDrag() {
        guard let currentDrag else { return }
        currentDrag.draggedObject.isBeingDragged = false
        self.currentDrag = nil
    }
    
    func inDiscardPileArea(handPos: SIMD3<Float>) -> Bool {
        if handPos.x > +TableEntity.TABLE_WIDTH/3 {
            return false
        }
        if handPos.x < -TableEntity.TABLE_WIDTH/3 {
            return false
        }
        if handPos.z > +TableEntity.TABLE_LENGTH/3 {
            return false
        }
        if handPos.z <  -TableEntity.TABLE_LENGTH/3 {
            return false
        }
        if handPos.y >  +TableEntity.TABLE_LENGTH/2 {
            return false
        }
        if handPos.y < +TableEntity.TABLE_HEIGHT {
            return false
        }
        return true
    }
    
}
