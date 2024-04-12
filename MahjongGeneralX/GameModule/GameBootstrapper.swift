//
//  GameBootstrapper.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/11/24.
//

import Foundation
import MahjongCore

@Observable
class GameBootstrapper {
    public var isReady: Bool = false
    private var _placementManager: PlacementManager?
    private var _gameManager: GameManager?
    public var placementManager: PlacementManager { _placementManager! }
    public var gameManager: GameManager { _gameManager! }
    
    public func bootstrap() async {
        if isReady { return }
        await ModelLoader.loadObjects()
        self._placementManager = PlacementManager()
        await self._gameManager = GameManager(table: ModelLoader.getTable())
        isReady = true
    }
}
