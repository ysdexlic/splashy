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
    let VISCOSITY: CGFloat = 4 // Increase to make the water "thicker/stickier," creating more friction.
    let BUOYANCY: CGFloat = 0.4 // Slightly increase to make the object "float up faster," more buoyant.
    var OFFSET: CGFloat!

    init() {
        super.init(texture: nil, color: UIColor.red, size: CGSize(width: 50, height: 50))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyUnderwaterPhysics(waterY: CGFloat, surfaceHeight: CGFloat) {
        OFFSET = surfaceHeight / 7 // Decrease to make the object float to the surface higher.
        let rate: CGFloat = 0.01 //Controls rate of applied motion. You shouldn't really need to touch this.
        let x = (waterY+(surfaceHeight - OFFSET))+surfaceHeight/2.0
        let y = (self.position.y)-self.size.height/2.0
        let disp = (x-y) * BUOYANCY
        let targetPos = CGPoint(x: self.position.x, y: self.position.y+disp)
        let targetVel = CGPoint(x: (targetPos.x-self.position.x)/(1.0/60.0), y: (targetPos.y-self.position.y)/(1.0/60.0))
        let relVel: CGVector = CGVector(dx:targetVel.x-(self.physicsBody?.velocity.dx)!*VISCOSITY, dy:targetVel.y-(self.physicsBody?.velocity.dy)!*VISCOSITY)
        self.physicsBody?.velocity=CGVector(dx:(self.physicsBody?.velocity.dx)!+relVel.dx*rate, dy:(self.physicsBody?.velocity.dy)!+relVel.dy*rate)
    }

}
