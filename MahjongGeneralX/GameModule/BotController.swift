//
//  BotController.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/10/24.
//

import Foundation
import MahjongCore
import MahjongCommons

class BotController: IPlayerController {
    let playerID: String
    let basePlayer: Player
    let mahjongSet: MahjongSet
    let decisionProcessor: IDecisionProcessor
    var playerState: PlayerState = .playerWaitToStart
    
    // FIXME: Bloody only logic
    var switchTiles: [MahjongEntity] = []
    var switchType: MahjongType?
    let switchTileNum = 3
    
    init(basePlayer: Player, decisionProcessor: IDecisionProcessor) {
        self.basePlayer = basePlayer
        self.mahjongSet = basePlayer.mahjongSet
        self.decisionProcessor = decisionProcessor
        self.playerID = basePlayer.playerID
    }
    
    func askPlayerToChooseSwitchTiles() {
        guard playerState.transition(to: .decideSwitchTiles) else { return }
        var suitCount : [MahjongType?:Int] = [:]
        for tile in basePlayer.closeHand {
            suitCount[tile.mahjongType] = suitCount[tile.mahjongType, default: 0] + 1
        }
        // this should never be null
        let suit = suitCount.sorted(by: {$0.value < $1.value}).first(where: {$0.value >= 3})?.key
        
        // pick 3 tiles
        switchTiles = Array(basePlayer.closeHand.filter({$0.mahjongType == suit})[...2])
        
        decisionProcessor.submitCompletion(for: self)
    }
    
    func askPlayerToChooseDiscardType() {
        guard playerState.transition(to: .decideDiscardSuit) else { return }
        var suitCount : [MahjongType?:Int] = [:]
        for tile in basePlayer.closeHand {
            suitCount[tile.mahjongType] = suitCount[tile.mahjongType, default: 0] + 1
        }
        
        // this should never be null
        let type = suitCount.sorted(by: {$0.value < $1.value}).first?.key ?? .Tiao
        setDiscardType(type)
        
        decisionProcessor.submitCompletion(for: self)
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
            _checkThenProcessBotDrawDecision()
        default:
            print("\(playerID) has nothing to take turn in \(playerState)")
            break
        }
        completion()
    }
    
    /// This method should be called WITHIN .roundDraw state AFTER drawing action
    /// Therefore the playerState should already be in .roundDraw
    func _checkThenProcessBotDrawDecision() {
        guard playerState == .roundDraw else {
            print("\(playerID) \(playerState) Not equal roundDraw state!")
            return
        }
        
        // save decision in a variable and pass to the process function
        // nothing declared here will run!
        let decision: PlayerDecision
        if basePlayer.canZimo() {
            decision = PlayerDecision(.hu) {
                self._createThenExecuteCommand(.zimo)
                self.playerState.transition(to: .end)
            }
        } else if basePlayer.canSelfKang() {
            decision = PlayerDecision(.kang) {
                guard let tile = self.mahjongSet.drawLastTile() else {
                    print("Game ended")
                    return
                }
                self._createThenExecuteCommand(.selfKang, tile: self.basePlayer.possibleKangTiles[0])
                
                self.playerState.transition(to: .roundDraw)
                self._createThenExecuteCommand(.draw, tile: tile)
                self._checkThenProcessBotDrawDecision()
            }
        } else {
            decision = PlayerDecision(.pass) {
                // if nothing to do, proceed to discard
                self._processBotDiscard()
            }
        }
        _processDecision(decision)
    }
    
    /// This function is used internally to process all the decisions player made
    /// When a decisionProcessor is present, the function will pass the decision to the processor
    func _processDecision(_ decision: PlayerDecision) {
        // if .roundDraw, only this player will decide
        if playerState == .roundDraw {
            decision.decision()
            return
        }
        decisionProcessor.submitDecision(for: self, decision: decision)
    }
    
    func askPlayerToDecide(discarded: MahjongEntity) {
        guard playerState.transition(to: .roundDecision) else {
            print("\(playerID) \(playerState) Not equal roundDecision state!")
            return
        }
        
        // save decision in a variable and pass to the process function
        // nothing declared here will run!
        let decision: PlayerDecision
        if basePlayer.canHu(discarded) {
            decision = PlayerDecision(.hu) {
                self._createThenExecuteCommand(.hu, tile: discarded)
                self.playerState.transition(to: .end)
            }
        } else if basePlayer.canKang(discarded) {
            decision = PlayerDecision(.kang) {
                self._createThenExecuteCommand(.kang, tile: discarded)
                guard let tile = self.mahjongSet.drawLastTile() else {
                    print("Game ended")
                    return
                }
                self.playerState.transition(to: .roundDraw)
                self._createThenExecuteCommand(.draw, tile: tile)
                self._checkThenProcessBotDrawDecision()
            }
        } else if basePlayer.canPong(discarded) {
            decision = PlayerDecision(.pong) {
                self._createThenExecuteCommand(.pong, tile: discarded)
                self._processBotDiscard()
            }
        } else {
            decision =  PlayerDecision(.pass) {}
        }
        _processDecision(decision)
    }
    
    func _processBotDiscard() {
        guard playerState.transition(to: .roundDiscard) else { return }
        
        let tile = _botFindDiscard()
        _createThenExecuteCommand(.discard, tile: tile)
    }
    
    private func _botFindDiscard()-> MahjongEntity {
        if basePlayer.discardTypeTiles.count != 0 {
            return basePlayer.discardTypeTiles[0]
        }
        var tempHand = Array(basePlayer.closeHand)
        //FIXME: change the complete set part
        var shanten = basePlayer.style.calculateShanten(closeHand: tempHand, completeSets: basePlayer.numCompleteSet)
        var t = tempHand.randomElement()!
        for tile in basePlayer.closeHand {
            tempHand.removeAll(where: {$0 == tile})
            let newShanten = basePlayer.style.calculateShanten(closeHand: tempHand, completeSets: basePlayer.numCompleteSet)
            // the <= ensures that at least bots will not worsen their hand
            if newShanten <= shanten {
                t = tile
                shanten = newShanten
            }
            tempHand.append(tile)
        }
        return t
    }
}
