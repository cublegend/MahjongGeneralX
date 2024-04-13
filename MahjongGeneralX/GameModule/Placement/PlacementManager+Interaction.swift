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

        if currentDrag == nil {
            mahjong.isBeingDragged = true
            if mahjong.parent == table[0] {
                currentDrag = DragState(objectToDrag: mahjong)
            } else {
                // assume mahjong grandpa is table
                let tempPosition = table[0].convert(position: mahjong.position, from: mahjong)
                mahjong.removeFromParent()
                table[0].addChild(mahjong)
                mahjong.position = tempPosition
                currentDrag = DragState(objectToDrag: mahjong)
            }
        }
        
        if let currentDrag {
            currentDrag.draggedObject.position = currentDrag.initialPosition + value.convert(value.translation3D, from: .local, to: table[0])
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
            currentDrag.draggedObject.position = currentDrag.initialPosition
            currentDrag.parentEntity.addChild(currentDrag.draggedObject)
        } else {
            localPlayer.processDiscardTile(mahjong)
        }
        currentDrag.draggedObject.isBeingDragged = false
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
            print("false1")
            return false
        }
        if handPos.x < -TableEntity.TABLE_WIDTH/3 {
            print("false2")
            return false
        }
        if handPos.z > +TableEntity.TABLE_LENGTH/3 {
            print("false3")
            return false
        }
        if handPos.z <  -TableEntity.TABLE_LENGTH/3 {
            print("false4")
            return false
        }
        if handPos.y >  +TableEntity.TABLE_LENGTH/2 {
            print("false5")
            return false
        }
        if handPos.y < +TableEntity.TABLE_HEIGHT {
            print("false6")
            return false
        }
        return true
    }
    
}
