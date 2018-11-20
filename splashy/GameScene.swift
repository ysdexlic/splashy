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
