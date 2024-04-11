//
//  LocalPlayerController.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/10/24.
//

import Foundation
import MahjongCore
import MahjongCommons

class LocalPlayerController: IPlayerController {
    let playerID: String
    let basePlayer: Player
    let mahjongSet: MahjongSet
    let decisionProcessor: IDecisionProcessor
    var playerState: PlayerState = .playerWaitToStart
    var delayedCompletion: ()->Void = {}
    
    // FIXME: Bloody only logic
    var switchTiles: [MahjongEntity] = []
    var switchType: MahjongType?
    let switchTileNum = 3
    
    // MARK: View flags
    var canPong = false
    var canHu = false
    var canKang = false
    var decisionNeeded: Bool { canHu || canKang || canPong }
    
    init(basePlayer: Player, decisionProcessor: IDecisionProcessor) {
        self.basePlayer = basePlayer
        self.mahjongSet = basePlayer.mahjongSet
        self.decisionProcessor = decisionProcessor
        self.playerID = basePlayer.playerID
    }
    
    func takeTurn(state: PlayerState, completion: @escaping () -> Void) {
        switch state {
        case .initDraw:
            playerState.transition(to: .initDraw)
            for _ in 0..<4 {
                if basePlayer.closeHand.count == 13 {
                    decisionProcessor.submitCompletion(for: self)
                }
                guard let tile = mahjongSet.draw() else {
                    fatalError("init draw not possible to be nil!")
                }
                _createThenExecuteCommand(.draw, tile: tile)
            }
        case .roundDraw:
            guard let tile = mahjongSet.draw() else {
                print("Game ended")
                return
            }
            playerState.transition(to: .roundDraw)
            _createThenExecuteCommand(.draw, tile: tile)
            _checkPlayerDrawDecision()
        default:
            print("\(playerID) has nothing to take turn in \(playerState)")
            break
        }
        
        // delay the completion for later
        delayedCompletion = completion
    }
    
    func askPlayerToDecide(discarded: MahjongEntity) {
        guard playerState.transition(to: .roundDecision) else { return }
        
        resetFlags()
        canHu = basePlayer.canHu(discarded)
        canPong = basePlayer.canPong(discarded)
        canKang = basePlayer.canKang(discarded)
        
        if !decisionNeeded {
            // pass, but still needs to submit!
            _processDecision(PlayerDecision(.pass){})
        }
    }
    
    func askPlayerToChooseDiscardType() {
        guard playerState.transition(to: .decideDiscardSuit) else { return }
    }
    
    func askPlayerToChooseSwitchTiles() {
        // switch state, then the view will be notified and starts picking
        // switch tiles.
        guard playerState.transition(to: .decideSwitchTiles) else { return }
    }
    
    func _checkPlayerDrawDecision() {
        guard playerState == .roundDraw else { return }
        
        resetFlags()
        canHu = basePlayer.canZimo()
        canKang = basePlayer.canSelfKang()
        
        if !decisionNeeded {
            _askPlayerToDiscardTile()
        }
    }
    
    func _askPlayerToDiscardTile() {
        // signal the view for a discard tile
        guard playerState.transition(to: .roundDiscard) else { return }
    }
    
    // MARK: View interface
    public func processDiscardDecision(ofType type: PlayerCommand, discarded: MahjongEntity?) {
        // save decision in a variable and pass to the process function
        // nothing declared here will run!
        let decision: PlayerDecision
        switch type {
        case .hu:
            decision = PlayerDecision(.hu) {
                self._createThenExecuteCommand(.hu, tile: discarded)
                self.playerState.transition(to: .end)
            }
        case .kang:
            decision = PlayerDecision(.kang) {
                self._createThenExecuteCommand(.kang, tile: discarded)
                guard let tile = self.mahjongSet.drawLastTile() else {
                    print("Game ended")
                    return
                }
                self.playerState.transition(to: .roundDraw)
                self._createThenExecuteCommand(.draw, tile: tile)
                self._checkPlayerDrawDecision()
            }
        case .pong:
            decision = PlayerDecision(.pong) {
                self._createThenExecuteCommand(.pong, tile: discarded)
                self._askPlayerToDiscardTile()
            }
        case .pass:
            decision =  PlayerDecision(.pass) {}
        default:
            return
        }
        _processDecision(decision)
    }
    
    public func processDrawDecision(ofType type: PlayerCommand, tile: MahjongEntity?) {
        // save decision in a variable and pass to the process function
        // nothing declared here will run!
        let decision: PlayerDecision
        switch type {
        case .zimo:
            decision = PlayerDecision(.zimo) {
                self._createThenExecuteCommand(.zimo)
                self.playerState.transition(to: .end)
            }
        case .selfKang:
            decision = PlayerDecision(.selfKang) {
                self._createThenExecuteCommand(.kang, tile: tile)
                guard let drawTile = self.mahjongSet.drawLastTile() else {
                    print("Game ended")
                    return
                }
                self.playerState.transition(to: .roundDraw)
                self._createThenExecuteCommand(.draw, tile: drawTile)
                self._checkPlayerDrawDecision()
            }
        case .pass:
            decision =  PlayerDecision(.pass) {}
        default:
            return
        }
        _processDecision(decision)
    }
    
    public func processDecideType(_ type: MahjongType) {
        basePlayer.setDiscardType(type)
        decisionProcessor.submitCompletion(for: self)
    }
    
    public func onClickedMahjong(_ tile: MahjongEntity) {
        switch playerState {
        case .initDraw:
            return // will be draw
        case .decideSwitchTiles:
            processSwitchTiles(tile)
        case .roundDraw:
            return // will be draw
        case .roundDiscard:
            processDiscardTile(tile)
        default:
            return
        }
    }
    
    private func processDiscardTile(_ mahjong: MahjongEntity) {
        if basePlayer.canDiscardTile(mahjong: mahjong) {
            _createThenExecuteCommand(.discard, tile: mahjong)
            // discard a tile signals the end of a turn
            delayedCompletion()
            delayedCompletion = {}
        }
    }
    
    private func processSwitchTiles(_ mahjong: MahjongEntity) {
        guard playerState == .decideSwitchTiles else {
            return
        }
        
        // if idx is not nil, we remove the already selected mahjong
        if let idx = switchTiles.firstIndex(of:mahjong) {
            switchTiles.remove(at: idx)
            mahjong.isSelected = false
        } else {
            // else we add it in if it is the same as the other tile types
            // or if no tiles have been chosen
            if switchTiles.count == 0 {
                switchType = mahjong.mahjongType
            } else if mahjong.mahjongType != switchType {
                return // not valid, nothing to change
            }
            mahjong.isSelected = true
            switchTiles.append(mahjong)
        }
        
        if switchTiles.count >= switchTileNum {
            decisionProcessor.submitCompletion(for: self)
        }
    }
    
    private func resetFlags() {
        canHu = false
        canKang = false
        canPong = false
    }
}
