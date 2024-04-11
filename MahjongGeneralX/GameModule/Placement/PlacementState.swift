//
//  PlacementState.swift
//  PlacingOnTable
//
//  State for keeping track of whether object placement is possible.
//
//  Created by Katherine Xiong on 3/9/24.
//

import Foundation
import RealityKit
import MahjongCore

@Observable
class PlacementState {
    var selectedObject = Entity()

    var planeToProjectOnFound = false
    var deviceAnchorPresent = false
    var planeAnchorsPresent = false

    static var tableX: Float = 0.0
    static var tableY: Float = 0.0
    static var tableZ: Float = 0.0

    static var mahjongBoundMax = SIMD3<Float>(0.0, 0.0, 0.0)
    static var mahjongBoundMin = SIMD3<Float>(0.0, 0.0, 0.0)

    static let holdRotateAngleY: Float = 90.0 * .pi / 180
    static let holdRotateAngleZ: Float = 52.0 * .pi / 100

    static let closedHandRotateAngleX: Float = 90.0 * .pi / 180
    static let closedHandRotateAngleZ: Float = 180.0 * .pi / 180

    static let discardRotateAngleZ: Float = 180.0 * .pi / 180

    static let decisionAttachment: Float = 180.0 * .pi / 180
    static let attachmentPosition: SIMD3<Float> = SIMD3<Float>(0, 
                                                               TableEntity.TABLE_HEIGHT +
                                                               MahjongEntity.TILE_HEIGHT * 1.5,
                                                               0 - MahjongEntity.TILE_HEIGHT * 2)
    static let gameMenuPosition: SIMD3<Float> = SIMD3<Float>(0, 
                                                             TableEntity.TABLE_HEIGHT +
                                                             MahjongEntity.TILE_HEIGHT * 1.5,
                                                             0 - TableEntity.TABLE_WIDTH +
                                                             MahjongEntity.TILE_HEIGHT)

    static let placedObjectsOffsetOnPlanes: Float = 0.01
    static let closedHandOffsetOnPlanes: Float = 0.005

    // Mahjong Location + Orientation reset
    static func resetMahjongPositionOrientation(mahjong: MahjongEntity) {
        mahjong.position = SIMD3<Float>(0.0, 0.0, 0.0)
        mahjong.orientation = simd_quatf()
    }

    // Place objects on planes with a small gap.
    static let snapToPlaneDistanceForDraggedObjects: Float = 0.04

    var shouldShowPreview: Bool {
        return deviceAnchorPresent && planeAnchorsPresent
    }

    var isPlaceTablePossible: Bool {
        return deviceAnchorPresent && planeAnchorsPresent && planeToProjectOnFound
    }
}
