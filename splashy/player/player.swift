//
//  player.swift
//  splashy
//
//  Created by David Thompson on 20/11/2018.
//  Copyright © 2018 the beardy developer. All rights reserved.
//

import Foundation
import SpriteKit

class Player: SKSpriteNode {
    var isAboveWater: Bool = true

    init() {
        super.init(texture: nil, color: UIColor.red, size: CGSize(width: 50, height: 50))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
