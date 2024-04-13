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

/// The interface that GameManager interacts with
protocol IPlayerController {
    var playerID: String {get}
    var playerState: PlayerState {get}
    var basePlayer: Player {get}
    var switchTiles: [MahjongEntity] {get}
    var decisionProcessor: IDecisionProcessor {get}
    func takeTurn(state: PlayerState)
    func askPlayerToDecide(discarded: MahjongEntity)
    func askPlayerToChooseSwitchTiles()
    func askPlayerToChooseDiscardType()
}

/// Some shared logics for all player controllers are defined here
/// Some default implementation for protocol methods also defined here
extension IPlayerController {
    fileprivate func _createThenExecuteCommand(_ type: PlayerCommand, tile: MahjongEntity? = nil) {
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
        case .pass:
            return
        default:
            print("\(type.name) not handled")
            return
        }
    }

    /// This function is used internally to process all the decisions player made
    /// When a decisionProcessor is present, the function will pass the decision to the processor
    fileprivate func _processDecision(_ decision: PlayerDecision) {
        // if .roundDraw, only this player will decide
        if playerState == .roundDraw {
            decision.decision()
            return
        }
        decisionProcessor.submitDecision(for: self, decision: decision)
    }
}

class BotController: IPlayerController {
    let playerID: String
    let basePlayer: Player
    let mahjongSet: MahjongSet
    let decisionProcessor: IDecisionProcessor
    var playerState: PlayerState = .playerWaitToStart

    // TODO: Bloody only logic
    var switchTiles: [MahjongEntity] = []
    var switchType: MahjongType?
    let switchTileNum = 3

    init(basePlayer: Player, decisionProcessor: IDecisionProcessor) {
        self.basePlayer = basePlayer
        self.mahjongSet = basePlayer.mahjongSet
        self.decisionProcessor = decisionProcessor
        self.playerID = basePlayer.playerID
    }

    // MARK: protocol implementation
    
    func askPlayerToChooseSwitchTiles() {
        guard playerState.transition(to: .decideSwitchTiles) else { return }
        var suitCount: [MahjongType?: Int] = [:]
        for tile in basePlayer.closeHand {
            suitCount[tile.mahjongType] = suitCount[tile.mahjongType, default: 0] + 1
        }
        // this should never be null
        let suit = suitCount.sorted(by: {$0.value < $1.value}).first(where: {$0.value >= 3})?.key

        // pick 3 tiles
        switchTiles = Array(basePlayer.closeHand.filter({$0.mahjongType == suit})[...2])

        decisionProcessor.submitCompletion(for: self, type: .switchTile)
    }

    func askPlayerToChooseDiscardType() {
        guard playerState.transition(to: .decideDiscardSuit) else { return }
        var suitCount: [MahjongType?: Int] = [:]
        for tile in basePlayer.closeHand {
            suitCount[tile.mahjongType] = suitCount[tile.mahjongType, default: 0] + 1
        }

        // this should never be null
        let type = suitCount.sorted(by: {$0.value < $1.value}).first?.key ?? .Tiao
        basePlayer.setDiscardType(type)

        decisionProcessor.submitCompletion(for: self, type: .chooseDiscard)
    }
    
    func askPlayerToDecide(discarded: MahjongEntity) {
        guard playerState.transition(to: .roundDecision) else { return }

        // save decision in a variable and pass to the process function
        // nothing declared here will run!
        let decision: PlayerDecision
        if basePlayer.canHu(discarded) {
            decision = PlayerDecision(.hu) { [weak self] in
                guard let self = self else { return }
                self._createThenExecuteCommand(.hu, tile: discarded)
                self.playerState.transition(to: .end)
            }
        } else if basePlayer.canKang(discarded) {
            decision = PlayerDecision(.kang) { [weak self] in
                guard let self = self else { return }
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
            decision = PlayerDecision(.pong) { [weak self] in
                guard let self = self else { return }
                self._createThenExecuteCommand(.pong, tile: discarded)
                self._processBotDiscard()
            }
        } else {
            decision =  PlayerDecision(.pass) {}
        }
        _processDecision(decision)
    }

    func takeTurn(state: PlayerState) {
        switch state {
        case .initDraw:
            guard playerState.transition(to: .initDraw) else { return }
            for _ in 0..<4 {
                if basePlayer.closeHand.count == 13 {
                    break
                }
                guard let tile = mahjongSet.draw() else {
                    fatalError("init draw not possible to be nil!")
                }
                print("\(playerID) draw \(tile.name)")
                _createThenExecuteCommand(.draw, tile: tile)
            }
            decisionProcessor.submitCompletion(for: self, type: .draw)
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
        }
    }
    
    // MARK: private methods

    /// This method should be called WITHIN .roundDraw state AFTER drawing action
    /// Therefore the playerState should already be in .roundDraw
    private func _checkThenProcessBotDrawDecision() {
        guard playerState == .roundDraw else {
            print("\(playerID) \(playerState) Not equal roundDraw state!")
            return
        }

        // save decision in a variable and pass to the process function
        // nothing declared here will run!
        let decision: PlayerDecision
        if basePlayer.canZimo() {
            decision = PlayerDecision(.zimo) { [weak self] in
                guard let self = self else { return }
                self._createThenExecuteCommand(.zimo)
                self.playerState.transition(to: .end)
                self.decisionProcessor.submitCompletion(for: self, type: .hu)
            }
        } else if basePlayer.canSelfKang() {
            decision = PlayerDecision(.selfKang) { [weak self] in
                guard let self = self else { return }
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

    private func _processBotDiscard() {
        guard playerState.transition(to: .roundDiscard) else { return }

        let tile = _botFindDiscard()
        _createThenExecuteCommand(.discard, tile: tile)
        decisionProcessor.submitCompletion(for: self, type: .discard)
    }

    private func _botFindDiscard() -> MahjongEntity {
        if !basePlayer.discardTypeTiles.isEmpty {
            return basePlayer.discardTypeTiles[0]
        }
        var tempHand = Array(basePlayer.closeHand)
        let numCompleteSet = basePlayer.numCompleteSet
        var shanten = basePlayer.style.calculateShanten(closeHand: tempHand, completeSets: numCompleteSet)
        var bestTile = tempHand.randomElement()!
        for tile in basePlayer.closeHand {
            tempHand.removeAll(where: {$0 == tile})
            let newShanten = basePlayer.style.calculateShanten(closeHand: tempHand, completeSets: numCompleteSet)
            // the <= ensures that at least bots will not worsen their hand
            if newShanten <= shanten {
                bestTile = tile
                shanten = newShanten
            }
            tempHand.append(tile)
        }
        return bestTile
    }
}

@Observable
class LocalPlayerController: IPlayerController {
    let playerID: String
    let basePlayer: Player
    let mahjongSet: MahjongSet
    let decisionProcessor: IDecisionProcessor
    var playerState: PlayerState = .playerWaitToStart {
        didSet {
            switch playerState {
            case .decideSwitchTiles, .roundDiscard:
                for tile in basePlayer.closeHand {
                    tile.isClickable = true
                }
            default:
                for tile in basePlayer.closeHand {
                    tile.isClickable = false
                }
            }
        
        }
    }

    // TODO: Bloody only logic
    var switchTiles: [MahjongEntity] = []
    var switchType: MahjongType?
    let switchTileNum = 3

    // MARK: View flags
    var canPong = false
    var canHu = false
    var canKang = false
    var decisionNeeded: Bool { canHu || canKang || canPong }
    var possibleKangTiles: [MahjongEntity] { basePlayer.possibleKangTiles }

    init(basePlayer: Player, decisionProcessor: IDecisionProcessor) {
        self.basePlayer = basePlayer
        self.mahjongSet = basePlayer.mahjongSet
        self.decisionProcessor = decisionProcessor
        self.playerID = basePlayer.playerID
    }
    
    // MARK: protocol methods

    func takeTurn(state: PlayerState) {
        switch state {
        case .initDraw:
            guard playerState.transition(to: .initDraw) else { return }
            for _ in 0..<4 {
                if basePlayer.closeHand.count == 13 {
                    break
                }
                guard let tile = mahjongSet.draw() else {
                    fatalError("init draw not possible to be nil!")
                }
                print("\(playerID) draw \(tile.name), \(basePlayer.closeHand.count)")
                _createThenExecuteCommand(.draw, tile: tile)
            }
            decisionProcessor.submitCompletion(for: self, type: .draw)
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
        }
    }

    func askPlayerToDecide(discarded: MahjongEntity) {
        guard playerState.transition(to: .roundDecision) else { return }
        
        canHu = basePlayer.canHu(discarded)
        canPong = basePlayer.canPong(discarded)
        canKang = basePlayer.canKang(discarded)

        if !decisionNeeded {
            // pass, but still needs to submit!
            print("local player no decision")
            _processDecision(PlayerDecision(.pass) {})
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
    
    // MARK: private methods

    private func _checkPlayerDrawDecision() {
        guard playerState == .roundDraw else { return }

        resetFlags()
        canHu = basePlayer.canZimo()
        canKang = basePlayer.canSelfKang()

        if !decisionNeeded {
            print("\(playerID) no decision needed")
            _askPlayerToDiscardTile()
        }
    }

    private func _askPlayerToDiscardTile() {
        // signal the view for a discard tile
        guard playerState.transition(to: .roundDiscard) else { return }
        print("\(playerID) wait to discard!")
    }
    
    private func resetFlags() {
        canHu = false
        canKang = false
        canPong = false
    }

    // MARK: View interface
    public func processDiscardDecision(ofType type: PlayerCommand, discarded: MahjongEntity?) {
        // save decision in a variable and pass to the process function
        // nothing declared here will run!
        let decision: PlayerDecision
        switch type {
        case .hu:
            decision = PlayerDecision(.hu) { [weak self] in
                guard let self = self else { return }
                self._createThenExecuteCommand(.hu, tile: discarded)
                self.playerState.transition(to: .end)
            }
        case .kang:
            decision = PlayerDecision(.kang) { [weak self] in
                guard let self = self else { return }
                self._createThenExecuteCommand(.kang, tile: discarded)
                guard let tile = self.mahjongSet.drawLastTile() else {
                    print("Game ended")
                    return
                }
                print("\(playerID) kanged!")
                self.playerState.transition(to: .roundDraw)
                self._createThenExecuteCommand(.draw, tile: tile)
                print("\(playerID) draw last tile!")
                self._checkPlayerDrawDecision()
            }
        case .pong:
            decision = PlayerDecision(.pong) { [weak self] in
                guard let self = self else { return }
                self._createThenExecuteCommand(.pong, tile: discarded)
                self._askPlayerToDiscardTile()
            }
        case .pass:
            decision =  PlayerDecision(.pass) {}
        default:
            return
        }
        
        resetFlags()
        _processDecision(decision)
    }

    public func processDrawDecision(ofType type: PlayerCommand, tile: MahjongEntity?) {
        // save decision in a variable and pass to the process function
        // nothing declared here will run!
        let decision: PlayerDecision
        switch type {
        case .zimo:
            decision = PlayerDecision(.zimo) { [weak self] in
                guard let self = self else { return }
                self._createThenExecuteCommand(.zimo)
                self.playerState.transition(to: .end)
                self.decisionProcessor.submitCompletion(for: self, type: .hu)
            }
        case .selfKang:
            decision = PlayerDecision(.selfKang) { [weak self] in
                guard let self = self else { return }
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
        
        resetFlags()
        _processDecision(decision)
    }

    public func processDecideType(_ type: MahjongType) {
        print("process local player decide discard: \(type.text)")
        basePlayer.setDiscardType(type)
        decisionProcessor.submitCompletion(for: self, type: .chooseDiscard)
    }

    public func onClickedMahjong(_ tile: MahjongEntity) {
        switch playerState {
        case .initDraw:
            return // will be draw
        case .decideSwitchTiles:
            tile.isSelected.toggle()
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
            decisionProcessor.submitCompletion(for: self, type: .discard)
        } else {
            print("can't discard this tile!")
        }
    }

    private func processSwitchTiles(_ mahjong: MahjongEntity) {
        guard playerState == .decideSwitchTiles else {
            return
        }

        // if idx is not nil, we remove the already selected mahjong
        if let idx = switchTiles.firstIndex(of: mahjong) {
            switchTiles.remove(at: idx)
            mahjong.isSelected = false
        } else {
            // else we add it in if it is the same as the other tile types
            // or if no tiles have been chosen
            if switchTiles.isEmpty {
                switchType = mahjong.mahjongType
            } else if mahjong.mahjongType != switchType {
                return // not valid, nothing to change
            }
            mahjong.isSelected = true
            switchTiles.append(mahjong)
        }

        if switchTiles.count >= switchTileNum {
            for mahjong in switchTiles {
                mahjong.isSelected = false
            }
            decisionProcessor.submitCompletion(for: self, type: .switchTile)
        }
    }
}
