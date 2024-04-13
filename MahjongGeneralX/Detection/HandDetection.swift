//
//  HandDetection.swift
//  PlacingOnTable
//
//  Created by Katherine Xiong on 3/11/24.
//

import Foundation
import ARKit
import RealityKit
import simd

final class HandDetection {
    public var rootEntity: Entity
    public var handLocation: Entity

    init(rootEntity: Entity) {
        self.rootEntity = rootEntity
        self.handLocation = Entity()
        self.rootEntity.addChild(handLocation)
    }

    @MainActor
    func processHandUpdates(_ anchorUpdate: AnchorUpdate<HandAnchor>) {
        let handAnchor = anchorUpdate.anchor

        guard handAnchor.chirality == .right else { return }

        guard
            let indexTip = handAnchor.handSkeleton?.joint(.indexFingerTip),
            let midTip = handAnchor.handSkeleton?.joint(.middleFingerTip),
            let indexKnuckle = handAnchor.handSkeleton?.joint(.indexFingerKnuckle),
            let midKnuckle = handAnchor.handSkeleton?.joint(.middleFingerKnuckle)
        else { return }

        let originFromIndexTipTransform = matrix_multiply(
            handAnchor.originFromAnchorTransform, indexTip.anchorFromJointTransform
        ).columns.3.xyz
        let originFromMidTipTransform = matrix_multiply(
            handAnchor.originFromAnchorTransform, midTip.anchorFromJointTransform
        ).columns.3.xyz
        let originFromIndexKnuckleTransform = matrix_multiply(
            handAnchor.originFromAnchorTransform, indexKnuckle.anchorFromJointTransform
        ).columns.3.xyz
        let originFromMidKnuckleTransform = matrix_multiply(
            handAnchor.originFromAnchorTransform, midKnuckle.anchorFromJointTransform
        ).columns.3.xyz

        let indexHalfway = (originFromIndexTipTransform + originFromMidTipTransform) / 2
        let midHalfway = (originFromIndexKnuckleTransform + originFromMidKnuckleTransform) / 2
        let mahjongPlace = originFromIndexTipTransform - (originFromIndexTipTransform - originFromMidTipTransform) / 2

        let xAxis = normalize(indexHalfway - midHalfway)
        let yAxis = normalize(originFromIndexKnuckleTransform - originFromMidKnuckleTransform)
        let zAxis = normalize(cross(xAxis, yAxis))

        let handLocation = simd_matrix(
            SIMD4(xAxis.x, xAxis.y, xAxis.z, 0),
            SIMD4(yAxis.x, yAxis.y, yAxis.z, 0),
            SIMD4(zAxis.x, zAxis.y, zAxis.z, 0),
            SIMD4(mahjongPlace.x, mahjongPlace.y, mahjongPlace.z, 1)
        )

        self.handLocation.setTransformMatrix(handLocation, relativeTo: nil)
    }

}
