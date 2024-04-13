/*
  AppState.swift
  MahjongDemo2
  Created by Katherine Xiong on 4/6/24.
 
  This class is responsible for handling the states of the entire app.
  It keeps track of the app state and connects all parts of the app together.
 */

import Foundation
import OSLog
import ARKit
import MahjongCore

let logger = Logger(subsystem: "com.example.MahjongDemo2", category: "general")

@Observable
public class AppState {

    // MARK: - App State

    public var appPhase: AppPhase = .welcome
    public var immersiveViewOpened = false

    var immersiveSpaceOpened: Bool { placementManager != nil }
    private(set) weak var placementManager: PlacementManager?
    private(set) weak var gameManager: GameManager?

    @MainActor
    func immersiveSpaceOpened(with placementManager: PlacementManager, and gameManager: GameManager) {
        self.placementManager = placementManager
        self.gameManager = gameManager
        let table = ModelLoader.getTable()
        placementManager.onModelLoaded(table: table)
        gameManager.onModelLoaded(table: table)
        placementManager.appState = self
    }

    func cleanUpAfterLeavingImmersiveSpace() {
        // Remember which placed object is attached to which persistent world anchor when leaving the immersive space.
        if let placementManager {
            placementManager.saveWorldAnchorsObjectsMapToDisk()
            // Stop the providers. The providers that just ran in the
            // immersive space are paused now, but the session doesn’t need them anymore.
            // When the user reenters the immersive space, the app runs a new set of providers.
            arkitSession.stop()
        }
        placementManager?.cleanUpData()
        gameManager?.cleanUpGameData()
        placementManager = nil
        gameManager = nil
        appPhase = .mainMenu
    }

    // MARK: - ARKit authorization

    var arkitSession = ARKitSession()
    var providersStoppedWithError = false
    var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined

    var allRequiredAuthorizationsAreGranted: Bool {
        worldSensingAuthorizationStatus == .allowed
    }

    var allRequiredProvidersAreSupported: Bool {
        WorldTrackingProvider.isSupported && PlaneDetectionProvider.isSupported
    }

    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredProvidersAreSupported
    }

    func requestWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }

    func queryWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.queryAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }

    func monitorSessionEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(_, let newState, let error):
                switch newState {
                case .initialized:
                    break
                case .running:
                    break
                case .paused:
                    break
                case .stopped:
                    if let error {
                        print("An error occurred: \(error)")
                        providersStoppedWithError = true
                    }
                @unknown default:
                    break
                }
            case .authorizationChanged(let type, let status):
                print("Authorization type \(type) changed to \(status)")
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                }
            default:
                print("An unknown event occured \(event)")
            }
        }
    }

    // MARK: - Music

    // MARK: - Settings
}
