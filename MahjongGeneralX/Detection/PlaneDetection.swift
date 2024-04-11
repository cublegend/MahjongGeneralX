//
//  PlaneDetection.swift
//  PlacingOnTable
//
//  Created by Katherine Xiong on 3/9/24.
//

import Foundation
import ARKit
import RealityKit

final class PlaneDetection {
    // A map of plane anchor UUIDs to their entities.
    private var planeEntities: [UUID: Entity] = [:]

    // A dictionary of all current plane anchors based on the anchor updates received from ARKit.
    private var planeAnchorsByID: [UUID: PlaneAnchor] = [:]

    public var rootEntity: Entity

    var planeAnchors: [PlaneAnchor] {
        Array(planeAnchorsByID.values)
    }

    init(rootEntity: Entity) {
        self.rootEntity = rootEntity
    }

    @MainActor
    func processPlaneUpdates(_ anchorUpdate: AnchorUpdate<PlaneAnchor>) async {
        let planeAnchor = anchorUpdate.anchor

        if anchorUpdate.event == .removed {
            planeAnchorsByID.removeValue(forKey: planeAnchor.id)
            if let entity = planeEntities.removeValue(forKey: planeAnchor.id) {
                entity.removeFromParent()
            }
            return
        }

        planeAnchorsByID[planeAnchor.id] = planeAnchor

        // Create Entity for detected planes
        let entity = Entity()
        entity.name = "Plane \(planeAnchor.id)"
        entity.setTransformMatrix(planeAnchor.originFromAnchorTransform, relativeTo: nil)

        // Generate a mesh for the plane (for occlusion).
        var meshResource: MeshResource?
        do {
            let contents = MeshResource.Contents(planeGeometry: planeAnchor.geometry)
            meshResource = try MeshResource.generate(from: contents)
        } catch {
            print("Failed to create a mesh resource for a plane anchor: \(error).")
            return
        }

        if let meshResource {
            // Make this plane occlude virtual objects behind it.
            entity.components.set(ModelComponent(mesh: meshResource, materials: [OcclusionMaterial()]))
        }

        // Generate a collision shape for the plane (for object placement and physics).
        var shape: ShapeResource?
        do {
            let vertices = planeAnchor.geometry.meshVertices.asSIMD3(ofType: Float.self)
            shape = try await ShapeResource.generateStaticMesh(positions: vertices,
                                                               faceIndices: planeAnchor.geometry.meshFaces.asUInt16Array())
        } catch {
            print("Failed to create a static mesh for a plane anchor: \(error).")
            return
        }

        if let shape {
            var collisionGroup = PlaneAnchor.verticalCollisionGroup
            if planeAnchor.alignment == .horizontal {
                collisionGroup = PlaneAnchor.horizontalCollisionGroup
            }

            entity.components.set(CollisionComponent(shapes: [shape], isStatic: true,
                                                     filter: CollisionFilter(group: collisionGroup, mask: .all)))
            // The plane needs to be a static physics body so that objects come to rest on the plane.
            let physicsMaterial = PhysicsMaterialResource.generate()
            let physics = PhysicsBodyComponent(shapes: [shape], mass: 0.0, material: physicsMaterial, mode: .static)
            entity.components.set(physics)
        }

        let existingEntity = planeEntities[planeAnchor.id]
        planeEntities[planeAnchor.id] = entity

        // Show planes being detected.
//        showPlane(planeAnchor: planeAnchor)

        rootEntity.addChild(entity)
        existingEntity?.removeFromParent()
    }

    func showPlane(planeAnchor: PlaneAnchor) {
        // A help function to show the detected planes.
        let modelEntity = ModelEntity(
            mesh: .generateSphere(radius: 0.005), // 5mm
            materials: [UnlitMaterial(color: .cyan)],
            collisionShape: .generateSphere(radius: 0.005),
            mass: 0.0
          )

        modelEntity.components.set(PhysicsBodyComponent(mode: .kinematic))
        modelEntity.components.set(OpacityComponent(opacity: 1))
        modelEntity.setTransformMatrix(planeAnchor.originFromAnchorTransform, relativeTo: nil)
        rootEntity.addChild(modelEntity)
    }
}

extension MeshResource.Contents {
    init(planeGeometry: PlaneAnchor.Geometry) {
        self.init()
        self.instances = [MeshResource.Instance(id: "main", model: "model")]
        var part = MeshResource.Part(id: "part", materialIndex: 0)
        part.positions = MeshBuffers.Positions(planeGeometry.meshVertices.asSIMD3(ofType: Float.self))
        part.triangleIndices = MeshBuffer(planeGeometry.meshFaces.asUInt32Array())
        self.models = [MeshResource.Model(id: "model", parts: [part])]
    }
}

extension GeometrySource {
    func asArray<T>(ofType: T.Type) -> [T] {
        assert(MemoryLayout<T>.stride == stride, "Invalid stride \(MemoryLayout<T>.stride); expected \(stride)")
        return (0..<count).map {
            buffer.contents().advanced(by: offset + stride * Int($0)).assumingMemoryBound(to: T.self).pointee
        }
    }

    func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
    }

    subscript(_ index: Int32) -> (Float, Float, Float) {
        precondition(format == .float3, "This subscript operator can only be used on GeometrySource instances with format .float3")
        return buffer.contents().advanced(by: offset + (stride * Int(index))).assumingMemoryBound(to: (Float, Float, Float).self).pointee
    }
}

extension GeometryElement {
    subscript(_ index: Int) -> [Int32] {
        precondition(bytesPerIndex == MemoryLayout<Int32>.size,
                     """
This subscript operator can only be used on GeometryElement instances with bytesPerIndex == \(MemoryLayout<Int32>.size).
This GeometryElement has bytesPerIndex == \(bytesPerIndex)
"""
        )
        var data = [Int32]()
        data.reserveCapacity(primitive.indexCount)
        for indexOffset in 0 ..< primitive.indexCount {
            data.append(buffer
                .contents()
                .advanced(by: (Int(index) * primitive.indexCount + indexOffset) * MemoryLayout<Int32>.size)
                .assumingMemoryBound(to: Int32.self).pointee)
        }
        return data
    }

    func asInt32Array() -> [Int32] {
        var data = [Int32]()
        let totalNumberOfInt32 = count * primitive.indexCount
        data.reserveCapacity(totalNumberOfInt32)
        for indexOffset in 0 ..< totalNumberOfInt32 {
            data.append(buffer.contents().advanced(by: indexOffset * MemoryLayout<Int32>.size).assumingMemoryBound(to: Int32.self).pointee)
        }
        return data
    }

    func asUInt16Array() -> [UInt16] {
        asInt32Array().map { UInt16($0) }
    }

    public func asUInt32Array() -> [UInt32] {
        asInt32Array().map { UInt32($0) }
    }
}

extension PlaneAnchor {
    static let horizontalCollisionGroup = CollisionGroup(rawValue: 1 << 31)
    static let verticalCollisionGroup = CollisionGroup(rawValue: 1 << 30)
    static let allPlanesCollisionGroup = CollisionGroup(rawValue: horizontalCollisionGroup.rawValue | verticalCollisionGroup.rawValue)
}
