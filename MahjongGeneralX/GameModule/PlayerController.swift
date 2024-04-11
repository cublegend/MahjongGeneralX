//
//  PlayerController.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/9/24.
//

import Foundation
import MahjongCommons
import MahjongCore
import MahjongAnalyzer

/// This enum encapsulates common actions a player needs to do when making a decision
enum PlayerCommand {
    case draw
    case discard
    case hu
    case zimo
    case kang
    case selfKang
    case pong
}

/// Some shared logics for all player controllers are defined here
/// Some default implementation for protocol methods also defined here
extension IPlayerController {
    func _createThenExecuteCommand(_ type: PlayerCommand, tile: MahjongEntity? = nil) {
        switch type {
        case .hu:
            let command = HuCommand(player: basePlayer, mahjong: tile!, zimo: false)
            Commands.executeCommand(command)
        case .zimo:
            let command = HuCommand(player: basePlayer, mahjong: nil, zimo: true)
            Commands.executeCommand(command)
        case .pong:
            let command = PongCommand(player: basePlayer, mahjong: tile!)
            Commands.executeCommand(command)
        case .kang:
            let command = KangCommand(player: basePlayer, mahjong: tile!, selfkang: false)
            Commands.executeCommand(command)
        case .selfKang:
            let command = KangCommand(player: basePlayer, mahjong: tile!, selfkang: true)
            Commands.executeCommand(command)
        case .draw:
            Commands.executeCommand(DrawCommand(player: basePlayer, mahjong: tile!))
        case .discard:
            Commands.executeCommand(DiscardCommand(player: basePlayer, mahjong: tile!))
        }
    }
    
    func setDiscardType(_ type: MahjongType) {
        basePlayer.setDiscardType(type)
    }
}
