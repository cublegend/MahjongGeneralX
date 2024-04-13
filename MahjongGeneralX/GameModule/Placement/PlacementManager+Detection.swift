//
//  PlacementManager+Detection.swift
//  MahjongDemo2
//
//  Created by Katherine Xiong on 4/8/24.
//

import Foundation
import ARKit
import RealityKit
import QuartzCore
import SwiftUI

extension PlacementManager {
    @MainActor
    func processPlaneUpdates() async {
        for await update in planeTracking.anchorUpdates {
            await planeDetection.processPlaneUpdates(update)
        }
    }

    @MainActor
    func processWorldAnchorUpdates() async {
        for await anchorUpdate in worldTracking.anchorUpdates {
            worldDetection.process(anchorUpdate)
        }
    }

    @MainActor
    func processHandAnchorUpdates() async {
        for await anchorUpdate in handTracking.anchorUpdates {
            handDetection.processHandUpdates(anchorUpdate)
        }
    }

    func saveWorldAnchorsObjectsMapToDisk() {
        worldDetection.saveWorldAnchorsObjectsMapToDisk()
    }

    @MainActor
    func processDeviceAnchorUpdates() async {
        await run(function: self.queryAndProcessLatestDeviceAnchor, withFrequency: 90)
    }

    @MainActor
    private func queryAndProcessLatestDeviceAnchor() async {
        // Device anchors are only available when the provider is running.
        guard worldTracking.state == .running else { return }

        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())

        placementState.deviceAnchorPresent = deviceAnchor != nil
        placementState.planeAnchorsPresent = !planeDetection.planeAnchors.isEmpty
        placementState.selectedObject.isEnabled = placementState.shouldShowPreview

        guard let deviceAnchor, deviceAnchor.isTracked else { return }

        await updatePlacementLocation(deviceAnchor)
    }

    @MainActor
    private func updatePlacementLocation(_ deviceAnchor: DeviceAnchor) async {
        deviceLocation.transform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
        let originFromUprightDeviceAnchorTransform = deviceAnchor.originFromAnchorTransform.gravityAligned

        // Determine a placement location on planes in front of the device by casting a ray.

        // Cast the ray from the device origin.
        let origin: SIMD3<Float> = raycastOrigin.transformMatrix(relativeTo: nil).translation

        // Cast the ray along the negative z-axis of the device anchor, but with a slight downward angle.
        // (The downward angle is configurable using the `raycastOrigin` orientation.)
        let direction: SIMD3<Float> = -raycastOrigin.transformMatrix(relativeTo: nil).zAxis

        // Only consider raycast results that are within 0.2 to 3 meters from the device.
        let minDistance: Float = 0.2
        let maxDistance: Float = 3

        // Only raycast against horizontal planes.
        let collisionMask = PlaneAnchor.allPlanesCollisionGroup

        var originFromPointOnPlaneTransform: float4x4?
        if let result = rootEntity.scene?.raycast(origin: origin, direction: direction, length: maxDistance, query: .nearest, mask: collisionMask)
                                                  .first, result.distance > minDistance {
            if result.entity.components[CollisionComponent.self]?.filter.group != PlaneAnchor.verticalCollisionGroup {
                // If the raycast hit a horizontal plane, use that result with a small, fixed offset.
                originFromPointOnPlaneTransform = originFromUprightDeviceAnchorTransform
                originFromPointOnPlaneTransform?.translation = result.position + [0.0, PlacementState.placedObjectsOffsetOnPlanes, 0.0]
            }
        }

        if let originFromPointOnPlaneTransform {
            placementLocation.transform = Transform(matrix: originFromPointOnPlaneTransform)
            placementState.planeToProjectOnFound = true
        } else {
            // If no placement location can be determined, position the preview 50 centimeters in front of the device.
            let distanceFromDeviceAnchor: Float = 0.5
            let downwardsOffset: Float = 0.3
            var uprightDeviceAnchorFromOffsetTransform = matrix_identity_float4x4
            uprightDeviceAnchorFromOffsetTransform.translation = [0, -downwardsOffset, -distanceFromDeviceAnchor]
            let originFromOffsetTransform = originFromUprightDeviceAnchorTransform * uprightDeviceAnchorFromOffsetTransform

            placementLocation.transform = Transform(matrix: originFromOffsetTransform)
            placementState.planeToProjectOnFound = false
        }
    }

    @MainActor
    func run(function: () async -> Void, withFrequency hertz: UInt64) async {
        while true {
            if Task.isCancelled {
                return
            }

            // Sleep for 1 s / hz before calling the function.
            let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / hertz
            do {
                try await Task.sleep(nanoseconds: nanoSecondsToSleep)
            } catch {
                // Sleep fails when the Task is cancelled. Exit the loop.
                return
            }

            await function()
        }
    }
}
