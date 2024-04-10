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
import RealityKit

/// This enum encapsulates all actions a player needs to do when making a decision
enum PlayerDecision {
    case hu(PlayerController, MahjongEntity?)
    case zimo(PlayerController, MahjongEntity?)
    case kang(PlayerController, MahjongEntity?)
    case selfKang(PlayerController, MahjongEntity?)
    case pong(PlayerController, MahjongEntity?)
    case pass(PlayerController, MahjongEntity?)
    
    func processDecision(for controller: PlayerController, tile: MahjongEntity? = nil) {
        switch self {
        case let .hu(controller, tile):
            let command = HuCommand(player: controller.basePlayer, mahjong: tile, zimo: false)
            Commands.ExecuteCommand(command)
            controller.playerState.transition(to: .end)
        case let .zimo(controller, _):
            let command = HuCommand(player: controller.basePlayer, mahjong: nil, zimo: true)
            Commands.ExecuteCommand(command)
            controller.playerState.transition(to: .end)
        case let .pong(controller, tile):
            let command = PongCommand(player: controller.basePlayer, mahjong: tile!)
            Commands.ExecuteCommand(command)
            // signal views that we are in roundDiscard for tile selection
            controller.playerState.transition(to: .roundDiscard)
        case let .kang(controller, tile):
            let command = KangCommand(player: controller.basePlayer, mahjong: tile!, selfkang: false)
            Commands.ExecuteCommand(command)
            controller.playerState.transition(to: .roundDraw)
        case let .selfKang(controller, tile):
            let command = KangCommand(player: controller.basePlayer, mahjong: tile!, selfkang: true)
            Commands.ExecuteCommand(command)
            controller.playerState.transition(to: .roundDraw)
        case .pass(_, _):
            return
        }
    }
}

protocol IPlayerTurnLogic {
    func takeTurn(completion: @escaping () -> Void)
}

/// This class controls and manipulates the states of the player instance.
/// All actions, including draw tiles are handled here, so that later when
/// we attempt to replace auto draw to manual, the logic in other scripts won't be affected
class PlayerController {
    let basePlayer: Player
    let mahjongSet: MahjongSet
    let playerID: String
    let decisionProcessor: IDecisionProcessor?
    
    // MARK: View flags
    var canPong = false
    var canHu = false
    var canKang = false
    var decisionNeeded: Bool { canHu || canKang || canPong }
    
    // FIXME: Bloody only logic
    var switchMahjongs: [MahjongEntity] = []
    var switchType: MahjongType?
    let switchTileNum = 3
    
    var playerState: PlayerState = .playerWaitToStart
    
    init(basePlayer: Player, decisionProcessor: IDecisionProcessor?) {
        self.basePlayer = basePlayer
        self.mahjongSet = basePlayer.mahjongSet
        self.playerID = basePlayer.playerID
        self.decisionProcessor = decisionProcessor
    }
    
    func processDecision(_ decision: PlayerDecision) {
        if decisionProcessor == nil {
            decision.processDecision(for: self)
        } else {
            decisionProcessor?.submitDecision(for: self, decision: decision)
        }
    }
    
    func setDiscardType(_ type: MahjongType) {
        basePlayer.setDiscardType(type)
    }
    
    func checkPlayerDrawDecision() {
        guard playerState == .roundDraw else { return }
        resetFlags()
        canHu = basePlayer.canZimo()
        canKang = basePlayer.canSelfKang()
        
        if !decisionNeeded {
            // signal views that we are in roundDiscard for tile selection
            playerState.transition(to: .roundDiscard)
        }
    }
    
    func checkPlayerDiscardDecision(discarded: MahjongEntity) {
        guard playerState == .roundDecision else { return }
        resetFlags()
        canHu = basePlayer.canHu(discarded)
        canPong = basePlayer.canPong(discarded)
        canKang = basePlayer.canKang(discarded)
        
        if !decisionNeeded {
            playerState.transition(to: .idle)
        }
    }
    
    // MARK: View interface
    public func onClickedMahjong(_ tile: MahjongEntity) {
        switch playerState {
        case .initDraw:
            return // will be draw
        case .decideSwitchTiles:
            processSwitchTiles(tile)
        case .roundDraw:
            processPlayerDraw(tile)
        case .roundDiscard:
            processDiscardTile(tile)
        default:
            return
        }
    }
    
    func processPlayerDraw(_ mahjong: MahjongEntity) {
        Commands.ExecuteCommand(DrawCommand(player: basePlayer, mahjong: mahjong))
    }
    
    private func processDiscardTile(_ mahjong: MahjongEntity) {
        if basePlayer.canDiscardTile(mahjong: mahjong) {
            let command = DiscardCommand(player: basePlayer, mahjong: mahjong)
            Commands.ExecuteCommand(command)
            playerState.transition(to: .idle)
        }
    }
    
    private func processSwitchTiles(_ mahjong: MahjongEntity) {
        guard playerState == .decideSwitchTiles else {
            return
        }
        
        // if idx is not nil, we remove the already selected mahjong
        if let idx = switchMahjongs.firstIndex(of:mahjong) {
            switchMahjongs.remove(at: idx)
            mahjong.isSelected = false
        } else {
            // else we add it in if it is the same as the other tile types
            // or if no tiles have been chosen
            if switchMahjongs.count == 0 {
                switchType = mahjong.mahjongType
            } else if mahjong.mahjongType != switchType {
                return // not valid, nothing to change
            }
            mahjong.isSelected = true
            switchMahjongs.append(mahjong)
        }
        
        if switchMahjongs.count >= switchTileNum {
            playerState.transition(to: .idle)
            return
        }
    }
    
    // MARK: Utils
    
    private func resetFlags() {
        canHu = false
        canKang = false
        canPong = false
    }
}
