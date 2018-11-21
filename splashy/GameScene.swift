//
//  GameScene.swift
//  splashy
//
//  Created by David Thompson on 19/11/2018.
//  Copyright © 2018 the beardy developer. All rights reserved.
//


import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var hasReferenceFrameTime: Bool = false
    var lastFrameTime: CFTimeInterval!
    let kFixedTimeStep = 1.0 / 500
    let kSurfaceHeight = 235

    let VISCOSITY: CGFloat = 4 //Increase to make the water "thicker/stickier," creating more friction.
    let BUOYANCY: CGFloat = 0.4 //Slightly increase to make the object "float up faster," more buoyant.
    let OFFSET: CGFloat = 50 //Decrease to make the object float to the surface higher.

    var player: Player!
    var water: SBDynamicWaterNode!
    override func didMove(to view: SKView) {
//        Player
        player = Player()
        player.position = CGPoint(x:50, y:250)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        self.addChild(player)
//        Water
        water = SBDynamicWaterNode(width: Float(self.size.width), numJoints:150, surfaceHeight:235, fillColour: UIColor(red:0, green:0, blue:1, alpha:0.5))
        water.position = CGPoint(x:self.size.width/2, y:0)
        self.addChild(water)
        water.setDefaultValues()
//        Scene
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    }

    override func update(_ currentTime: CFTimeInterval) {
        if (!self.hasReferenceFrameTime) {
            self.lastFrameTime = currentTime
            self.hasReferenceFrameTime = true
            return
        }

        let dt: CFTimeInterval = currentTime - self.lastFrameTime!

        var accumilator: CFTimeInterval = 0
        accumilator += dt

        while (accumilator >= kFixedTimeStep) {
            self.fixedUpdate(kFixedTimeStep)
            accumilator -= kFixedTimeStep
        }
        self.fixedUpdate(accumilator)

        self.lateUpdate(dt)

        let minX = CGFloat(0)
        let minY = CGFloat(0)
        let maxX = CGFloat(water.getWidth())
        let maxY = CGFloat(water.surfaceHeight)

        let playerX = player.position.x
        let playerY = player.position.y

        if (minX <= playerX && playerX <= maxX) && (minY <= playerY && playerY <= maxY) {

            let rate: CGFloat = 0.01; //Controls rate of applied motion. You shouldn't really need to touch this.
            let waterY = water.position.y
            let x = (waterY+(CGFloat(kSurfaceHeight) - OFFSET))+CGFloat(kSurfaceHeight)/2.0
            let y = (player.position.y)-player.size.height/2.0
            let disp = (x-y) * BUOYANCY
            let targetPos = CGPoint(x: player.position.x, y: player.position.y+disp)
            let targetVel = CGPoint(x: (targetPos.x-player.position.x)/(1.0/60.0), y: (targetPos.y-player.position.y)/(1.0/60.0))
            let relVel: CGVector = CGVector(dx:targetVel.x-(player.physicsBody?.velocity.dx)!*VISCOSITY, dy:targetVel.y-(player.physicsBody?.velocity.dy)!*VISCOSITY);
            player.physicsBody?.velocity=CGVector(dx:(player.physicsBody?.velocity.dx)!+relVel.dx*rate, dy:(player.physicsBody?.velocity.dy)!+relVel.dy*rate);
        }

        self.lastFrameTime = currentTime
    }

    func fixedUpdate(_ currentTime: CFTimeInterval) {
        water.update(currentTime)

        let y = player.position.y
        let x = player.position.x
        let yVel = player.physicsBody?.velocity.dy

        if (player.isAboveWater && Float(y) <= water.surfaceHeight) {
            player.isAboveWater = false
            water.splashAt(x:Float(x), force:-yVel! * 0.125, width:20)
        }
        if (!player.isAboveWater && Float(y) > water.surfaceHeight) {
            player.isAboveWater = true
        }
    }

    func lateUpdate(_ currentTime: CFTimeInterval) {
        water.render()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        player.position = touch.location(in: self)
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
    }
}
