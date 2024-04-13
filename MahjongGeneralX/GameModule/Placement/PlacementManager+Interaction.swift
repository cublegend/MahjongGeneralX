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
    var initialPosition: SIMD3<Float>
    var parentEntity: Entity
    
    @MainActor
    init(objectToDrag: MahjongEntity) {
        draggedObject = objectToDrag
        initialPosition = objectToDrag.position
        parentEntity = objectToDrag.parent!
        print("parent 1: \(parentEntity.name)")
    }
}

extension PlacementManager {
    @MainActor
    func updataDragDiscard(mahjong: MahjongEntity, value: EntityTargetValue<DragGesture.Value>) {
        if let currentDrag, currentDrag.draggedObject !== mahjong {
            // Make sure any previous drag ends before starting a new one.
            print("A new drag started but the previous one never ended - ending that one now.")
            cannotDrag()
        }
        
        guard let table = self.table else { return }

        if currentDrag == nil {
            currentDrag = DragState(objectToDrag: mahjong)
            let tempPosition = table.convert(position: mahjong.position, from: mahjong)
            mahjong.removeFromParent()
            table.addChild(mahjong)
            mahjong.position = tempPosition
        }
        
        if let currentDrag {
            currentDrag.draggedObject.position = currentDrag.initialPosition + value.convert(value.translation3D, from: .local, to: table)
            if inDiscardPileArea(handPos: currentDrag.draggedObject.position) {
                highlightEntity.components.set(OpacityComponent(opacity: 1))
            } else {
                highlightEntity.components.set(OpacityComponent(opacity: 0))
            }
        }
    }
    
    @MainActor
    func endDrag(mahjong: MahjongEntity, localPlayer: LocalPlayerController) {
        guard let currentDrag else { return }
        highlightEntity.components.set(OpacityComponent(opacity: 0))
        if !inDiscardPileArea(handPos: currentDrag.draggedObject.position) {
            // 放回去
            currentDrag.parentEntity.addChild(currentDrag.draggedObject)
            currentDrag.draggedObject.position = currentDrag.initialPosition
            print("parent2 name: ", currentDrag.parentEntity.name)
//            currentDrag.parentEntity.addChild(currentDrag.draggedObject)
//            currentDrag.draggedObject.affectedByPhysics = false
        } else {
            localPlayer.processDiscardTile(mahjong)
//            currentDrag.draggedObject.affectedByPhysics = false
        }
//        currentDrag.draggedObject.isBeingDragged = false
        self.currentDrag = nil
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
