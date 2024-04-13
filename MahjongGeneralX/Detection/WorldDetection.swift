//
//  WorldDetection.swift
//  PlacingOnTable
//
//  Created by Katherine Xiong on 3/9/24.
//

import Foundation
import ARKit
import RealityKit
import MahjongCore
import MahjongCommons

final class WorldDetection {
    private var worldTracking: WorldTrackingProvider

    private var rootEntity: Entity

    // Objects attached to the anchors.
    private var anchoredObjects: [UUID: PlacedObject] = [:]

    // A dictionary of world anchors.
    private var worldAnchors: [UUID: WorldAnchor] = [:]

    public var tableAnchor: [String: WorldAnchor] = [:]
    // Objects that are about to be anchored.
    public var objectsBeingAnchored: [UUID: PlacedObject] = [:]

    static let objectsDatabaseFileName = "persistentObjects.json"

    // A dictionary of 3D model files to be loaded for a given persistent world anchor.
    private var persistedObjectFileNamePerAnchor: [UUID: String] = [:]

    var placeableObjectsByFileName: [String: PlacedObject] = [:]

    init(worldTracking: WorldTrackingProvider, rootEntity: Entity) {
        self.worldTracking = worldTracking
        self.rootEntity = rootEntity
    }

    func deletePersistentObjectsFile() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let filePath = documentsDirectory?.appendingPathComponent(WorldDetection.objectsDatabaseFileName) else {
            print("Error forming path to the file.")
            return
        }

        if fileManager.fileExists(atPath: filePath.path) {
            do {
                try fileManager.removeItem(at: filePath)
                print("File successfully deleted.")
            } catch {
                print("Error deleting file: \(error.localizedDescription)")
            }
        } else {
            print("File does not exist.")
        }
    }

    /// Deserialize the JSON file that contains the mapping from world anchors to placed objects from the documents directory.
    func loadPersistedObjects() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = documentsDirectory.first?.appendingPathComponent(WorldDetection.objectsDatabaseFileName)

        guard let filePath, FileManager.default.fileExists(atPath: filePath.path(percentEncoded: true)) else {
            print("Couldn’t find file: '\(WorldDetection.objectsDatabaseFileName)' - skipping deserialization of persistent objects.")
            return
        }

        do {
            let data = try Data(contentsOf: filePath)
            persistedObjectFileNamePerAnchor = try JSONDecoder().decode([UUID: String].self, from: data)
        } catch {
            print("Failed to restore the mapping from world anchors to persisted objects.")
        }
    }
    
    @MainActor
    func placedObject(for entity: Entity) -> PlacedObject? {
        return anchoredObjects.first(where: { $0.value === entity })?.value
    }

    @MainActor
    func object(for entity: Entity) -> PlacedObject? {
        if let placedObject = placedObject(for: entity) {
            return placedObject
        }
        if let anchoringObject = objectsBeingAnchored.first(where: { $0.value === entity })?.value {
            return anchoringObject
        }
        return nil
    }
    
    /// Serialize the mapping from world anchors to placed objects to a JSON file in the documents directory.
    func saveWorldAnchorsObjectsMapToDisk() {
        var worldAnchorsToFileNames: [UUID: String] = [:]
        for (anchorID, object) in anchoredObjects {
            worldAnchorsToFileNames[anchorID] = object.fileName
        }

        let encoder = JSONEncoder()
        do {
            let jsonString = try encoder.encode(worldAnchorsToFileNames)
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filePath = documentsDirectory.appendingPathComponent(WorldDetection.objectsDatabaseFileName)

            do {
                try jsonString.write(to: filePath)
            } catch {
                print("save world anchors error: ", error)
            }
        } catch {
            print("save world anchors error: ", error)
        }
    }

    @MainActor
    func attachPersistedObjectToAnchor(_ modelFileName: String, anchor: WorldAnchor) {
        guard let placeableObject = placeableObjectsByFileName[modelFileName] else {
            print("No object available for '\(modelFileName)' - it will be ignored.")
            return
        }

        placeableObject.position = anchor.originFromAnchorTransform.translation
        placeableObject.orientation = anchor.originFromAnchorTransform.rotation
        placeableObject.isEnabled = anchor.isTracked
        rootEntity.addChild(placeableObject)

        anchoredObjects[anchor.id] = placeableObject
    }

    @MainActor
    func process(_ anchorUpdate: AnchorUpdate<WorldAnchor>) {
        // An anchor in the world that have been updated
        let anchor = anchorUpdate.anchor

//        logger.info("world anchor: \(self.worldAnchors.count)")
        // An event that indicates whether an anchor was added, updated, or removed.
        if anchorUpdate.event != .removed {
            worldAnchors[anchor.id] = anchor
        } else {
            worldAnchors.removeValue(forKey: anchor.id)
        }

        switch anchorUpdate.event {
        case .added:
            // Check whether there’s a persisted object attached to this added anchor -
            // it could be a world anchor from a previous run of the app.
            // ARKit surfaces all of the world anchors associated with this app
            // when the world tracking provider starts.
            if let objectBeingAnchored = objectsBeingAnchored[anchor.id] {
                objectsBeingAnchored.removeValue(forKey: anchor.id)
                anchoredObjects[anchor.id] = objectBeingAnchored

                // Now that the anchor has been successfully added, display the object.
                rootEntity.addChild(objectBeingAnchored)
            }
            fallthrough
        case .updated:
            // Keep the position of placed objects in sync with their corresponding
            // world anchor, and hide the object if the anchor isn’t tracked.
            let object = anchoredObjects[anchor.id]
            object?.position = anchor.originFromAnchorTransform.translation
            object?.orientation = anchor.originFromAnchorTransform.rotation
            object?.isEnabled = anchor.isTracked
        case .removed:
            // Remove the placed object if the corresponding world anchor was removed.
            let object = anchoredObjects[anchor.id]
            object?.removeFromParent()
            anchoredObjects.removeValue(forKey: anchor.id)
            print("removed")
        }
    }

    @MainActor
    func removeAllPlacedObjects() async {
        // To delete all placed objects, first delete all their world anchors.
        // The placed objects will then be removed after the world anchors
        // were successfully deleted.
        await deleteWorldAnchorsForAnchoredObjects()
    }

    private func deleteWorldAnchorsForAnchoredObjects() async {
        for anchorID in anchoredObjects.keys {
            await removeAnchorWithID(anchorID)
        }
    }

    func removeAnchorWithID(_ uuid: UUID) async {
        do {
            try await worldTracking.removeAnchor(forID: uuid)
        } catch {
            print("Failed to delete world anchor \(uuid) with error \(error).")
        }
    }

    @MainActor
    private func detachObjectFromWorldAnchor(_ object: PlacedObject) {
        guard let anchorID = anchoredObjects.first(where: { $0.value === object })?.key else {
            return
        }

        // Remove the object from the set of anchored objects because it’s about to be moved.
        anchoredObjects.removeValue(forKey: anchorID)
        Task {
            // The world anchor is no longer needed; remove it so that it doesn't
            // remain in the app’s list of world anchors forever.
            await removeAnchorWithID(anchorID)
        }
    }

    @MainActor
    func removeObject(_ object: PlacedObject) async {
        guard let anchorID = anchoredObjects.first(where: { $0.value === object })?.key else {
            return
        }
        await removeAnchorWithID(anchorID)
    }

    @MainActor
    func attachObjectToWorldAnchor(_ object: PlacedObject) async {
        let anchor = WorldAnchor(originFromAnchorTransform: object.transformMatrix(relativeTo: nil))
        objectsBeingAnchored[anchor.id] = object

        do {
            try await worldTracking.addAnchor(anchor)
        } catch {
            if let worldTrackingError = error as? WorldTrackingProvider.Error, worldTrackingError.code == .worldAnchorLimitReached {
                print(
"""
Unable to place object "\(object.name)". You’ve placed the maximum number of objects.
Remove old objects before placing new ones.
"""
                )
            } else {
                print("Failed to add world anchor \(anchor.id) with error: \(error).")
            }

            objectsBeingAnchored.removeValue(forKey: anchor.id)
            tableAnchor.removeValue(forKey: object.fileName)
            object.removeFromParent()
            return
        }
    }
}
