//
//  PlacementManager+Interaction.swift
//  MahjongGeneralX
//
//  Created by Katherine Xiong on 4/12/24.
//

import SwiftUI
import RealityKit
import MahjongCore

struct DragState {
    var draggedObject: MahjongEntity
    var initialPosition: SIMD3<Float>
    
    @MainActor
    init(objectToDrag: MahjongEntity) {
        draggedObject = objectToDrag
        initialPosition = objectToDrag.position
    }
}

extension PlacementManager {
    @MainActor
    func updataDragDiscard(mahjong: MahjongEntity, value: EntityTargetValue<DragGesture.Value>) {
        if let currentDrag, currentDrag.draggedObject !== mahjong {
            // Make sure any previous drag ends before starting a new one.
            print("A new drag started but the previous one never ended - ending that one now.")
            endDrag()
        }

        if currentDrag == nil {
            mahjong.isBeingDragged = true
            currentDrag = DragState(objectToDrag: mahjong)
        }
        
        if let currentDrag {
            currentDrag.draggedObject.position = currentDrag.initialPosition + value.convert(value.translation3D, from: .local, to: table[0])
        }
        mahjong.position.y = TableEntity.TABLE_HEIGHT
        
    }
    
    @MainActor
    func endDrag() {
        guard let currentDrag else { return }
        currentDrag.draggedObject.isBeingDragged = false
        self.currentDrag = nil
    }
    
//    func inDiscardPileArea() -> Bool {
//        
//    }
}
