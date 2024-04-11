/*
  AppConfig.swift
  MahjongDemo2
  Created by Katherine Xiong on 4/7/24.

  This file keeps all the configurations of the entire app.
*/

import Foundation

public var shouldAnchorTable = true
public var shouldCancelGame = true
public var shouldPauseGame = true

public enum AppPhase: String, Codable, Sendable, Equatable {
    case welcome
    case mainMenu
    case game

    /// Returns `True` if it's possible to transition to the specified phase from the currrent one.
    func canProgress(to phase: AppPhase) -> Bool {
        switch self {
        case .welcome:
            return phase == .mainMenu
        case .mainMenu:
//            return phase == .placingTable
//        case .placingTable:
            return phase == .game
        case .game:
            return phase == .welcome
        }
    }

    /// Requests a phase transition.
    @discardableResult
    mutating public func transition(to newPhase: AppPhase) -> Bool {
        guard self != newPhase else {
            logger.debug("Attempting to change game state to \(newPhase.rawValue) but already in that state. Treating as a no-op.")
            return false
        }
        guard canProgress(to: newPhase) else {
            logger.error("Requested transition to \(newPhase.rawValue), but that's not a valid transition.")
            return false
        }
        self = newPhase
        return true
    }
}
