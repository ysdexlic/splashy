//
//  GameScene.swift
//  splashy
//
//  Created by David Thompson on 19/11/2018.
//  Copyright © 2018 the beardy developer. All rights reserved.
//


import SpriteKit
import GameplayKit


struct PhysicsCategory {
    static let Player: UInt32 = 0x1 << 1
    static let Wall: UInt32 = 0x1 << 2
    static let Score: UInt32 = 0x1 << 3
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    // Defaults
    var score: Int = 0
    var died: Bool = false
    var gameStarted: Bool = false
    var enableUnderwaterPhysics: Bool = true

    // Sprites / Nodes
    var player: Player!
    var water: SBDynamicWaterNode!
    var wallPair: SKNode!
    var scoreNode: SKSpriteNode!
    var restartButton: SKSpriteNode!

    // Labels
    var scoreLabel: SKLabelNode!

    // Actions
    var spawnDelayForever: SKAction!
    var moveAndRemove: SKAction!

    // Player Animation
    var swimmingFrames: [SKTexture] = []

    // Water Animation
    var hasReferenceFrameTime: Bool = false
    var lastFrameTime: CFTimeInterval!
    let kFixedTimeStep = 1.0 / 500
    var kSurfaceHeight: CGFloat!

    // Water Physics
    let VISCOSITY: CGFloat = 4 // Increase to make the water "thicker/stickier," creating more friction.
    let BUOYANCY: CGFloat = 0.4 // Slightly increase to make the object "float up faster," more buoyant.
    var OFFSET: CGFloat!

    func restartScene() {
        self.removeAllChildren()
        self.removeAllActions()
        player.removeAllActions()
        died = false
        gameStarted = false
        score = 0
        createScene()
    }

    func createScene() {
        kSurfaceHeight = self.size.height / 2.5
        OFFSET = kSurfaceHeight / 3.5 // Decrease to make the object float to the surface higher.

        self.physicsWorld.contactDelegate = self


        // Background
        for i in 0..<2 {
            let background = SKSpriteNode(imageNamed: "ocean")
            background.anchorPoint = CGPoint(x: 0, y: 0)
            background.position = CGPoint(x:CGFloat(i) * self.frame.width, y: 0)
            background.size = CGSize(width: self.size.width, height: self.size.height)
            background.name = "background"
            background.zPosition = 0
            self.addChild(background)
        }

        // Score Label
        scoreLabel = SKLabelNode()
        scoreLabel.fontSize = 100
        scoreLabel.position = CGPoint(x: self.frame.width / 2, y: (self.frame.height / 2) + (self.frame.height / 2.5))
        scoreLabel.zPosition = 5
        scoreLabel.text = "\(score)"
        self.addChild(scoreLabel)

        // Player
        createPlayer()

        // Water
        water = SBDynamicWaterNode(width: Float(self.size.width), numJoints:150, surfaceHeight:Float(kSurfaceHeight), fillColour: UIColor(red:0, green:0, blue:1, alpha:0.5))
        water.position = CGPoint(x:self.size.width/2, y:0)
        self.addChild(water)
        water.setDefaultValues()

        // Walls
        let spawn = SKAction.run {
            () in
            self.createWalls()
        }

        let delay = SKAction.wait(forDuration: 2.0)
        let spawnDelay = SKAction.sequence([spawn, delay])
        spawnDelayForever = SKAction.repeatForever(spawnDelay)

        let distance = CGFloat(self.frame.width)
        let movePipes = SKAction.moveBy(x: -distance - 50, y: 0, duration: TimeInterval(0.0025 * distance))
        let removePipes = SKAction.removeFromParent()
        moveAndRemove = SKAction.sequence([movePipes, removePipes])

        // Scene
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    }

    override func didMove(to view: SKView) {
        createScene()
    }

    override func update(_ currentTime: CFTimeInterval) {

        // Background animation
        if gameStarted && !died {
            enumerateChildNodes(withName: "background", using: {
                (node, err) in
                let bg = node as! SKSpriteNode
                bg.position = CGPoint(x: bg.position.x - 1, y: bg.position.y)

                if bg.position.x <= -bg.size.width {
                    bg.position = CGPoint(x: bg.position.x + bg.size.width * 2, y: bg.position.y)
                }
            })
        }

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

        // Player is underwater
        if !player.isAboveWater && enableUnderwaterPhysics {
            player.applyUnderwaterPhysics(waterY: water.position.y, surfaceHeight: kSurfaceHeight)
        }

        self.lateUpdate(dt)
        self.lastFrameTime = currentTime
    }

    func fixedUpdate(_ currentTime: CFTimeInterval) {
        water.update(currentTime)

        let y = player.position.y
        let x = player.position.x
        let yVel = player.physicsBody?.velocity.dy

        // Player is going underwater
        if player.isAboveWater && Float(y) <= water.surfaceHeight {
            player.isAboveWater = false
            water.splashAt(x:Float(x), force:-yVel! * 0.075, width:20)
        }
        // Player is going above water
        if !player.isAboveWater && Float(y) > water.surfaceHeight {
            player.isAboveWater = true
            // lower multiplier due to velocity put on when jumping from water
            water.splashAt(x:Float(x), force:-yVel! * 0.05, width:20)
        }
    }

    func lateUpdate(_ currentTime: CFTimeInterval) {
        water.render()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if died || !gameStarted {
            return
        }
        enableUnderwaterPhysics = false
        if !player.isAboveWater {
            player.physicsBody?.velocity = CGVector(dx: 0, dy: (player.physicsBody?.velocity.dy)! / 2)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameStarted {
            self.run(spawnDelayForever)
            gameStarted = true
            return
        }
        enableUnderwaterPhysics = true
        if !died && !player.isAboveWater {
            let playerY = player.position.y
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 6.25 * (kSurfaceHeight - playerY))
        }

        for touch in touches {
            let location = touch.location(in: self)

            if died {
                if restartButton.contains(location) {
                    restartScene()
                }
            }
        }
    }

    func createWalls() {
        scoreNode = SKSpriteNode()
        wallPair = SKNode()
        wallPair.name = "wallPair"

        let gapSize = CGFloat(350)
        let wallScale = CGFloat(0.5)

        let topWall = SKSpriteNode(texture: nil, color: UIColor.black, size: CGSize(width: 80, height: 1000))
        let bottomWall = SKSpriteNode(texture: nil, color: UIColor.black, size: CGSize(width: 80, height: 1000))

        scoreNode.size = CGSize(width: 1, height: (gapSize * 2) - (topWall.size.height * wallScale))
        scoreNode.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNode.size)
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
        scoreNode.physicsBody?.collisionBitMask = 0
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.isDynamic = false

        topWall.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2 + gapSize)
        bottomWall.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2 - gapSize)

        topWall.setScale(wallScale)
        bottomWall.setScale(wallScale)

        topWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        topWall.physicsBody?.collisionBitMask = PhysicsCategory.Player
        topWall.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        topWall.physicsBody?.affectedByGravity = false
        topWall.physicsBody?.isDynamic = false

        bottomWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        bottomWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        bottomWall.physicsBody?.collisionBitMask = PhysicsCategory.Player
        bottomWall.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        bottomWall.physicsBody?.affectedByGravity = false
        bottomWall.physicsBody?.isDynamic = false

        wallPair.addChild(topWall)
        wallPair.addChild(bottomWall)

        let randomPosition = CGFloat.random(min: -200, max: 200)
        wallPair.position.y = wallPair.position.y + randomPosition
        wallPair.zPosition = 1

        wallPair.addChild(scoreNode)

        wallPair.run(moveAndRemove)

        self.addChild(wallPair)
    }

    func createPlayer() {
        let animatedAtlas = SKTextureAtlas(named: "dolphin")
        var frames: [SKTexture] = []

        let numImages = animatedAtlas.textureNames.count
        for i in 1...numImages {
            let textureName = "dolphin\(i)"
            frames.append(animatedAtlas.textureNamed(textureName))
        }
        swimmingFrames = frames

        let firstFrameTexture = swimmingFrames[0]

        player = Player(texture: firstFrameTexture)
        player.position = CGPoint(x:300, y:kSurfaceHeight + 50)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.collisionBitMask = PhysicsCategory.Wall
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Wall | PhysicsCategory.Score
        player.zPosition = 2
        animatePlayer()
        self.addChild(player)
    }

    func animatePlayer() {
        player.run(SKAction.repeatForever(
            SKAction.animate(with: swimmingFrames,
                             timePerFrame: 0.05,
                             resize: false,
                             restore: true)
            ),
            withKey:"swimmingDolphin"
        )
    }

    func createRestartButton() {
        let restartText = SKLabelNode()
        restartText.text = "restart"
        restartText.fontSize = 60
        restartText.fontColor = UIColor.black
        restartButton = SKSpriteNode(color: UIColor.white, size: CGSize(width: 300, height: 200))
        restartButton.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        restartButton.zPosition = 6
        restartButton.setScale(0)
        restartButton.addChild(restartText)
        self.addChild(restartButton)
        restartButton.run(SKAction.scale(to: 1.0, duration: 0.25))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        if !died && (firstBody.categoryBitMask == PhysicsCategory.Score && secondBody.categoryBitMask == PhysicsCategory.Player || firstBody.categoryBitMask == PhysicsCategory.Player && secondBody.categoryBitMask == PhysicsCategory.Score) {
            score += 1
            scoreLabel.text = "\(score)"
        }

        if firstBody.categoryBitMask == PhysicsCategory.Player && secondBody.categoryBitMask == PhysicsCategory.Wall || firstBody.categoryBitMask == PhysicsCategory.Wall && secondBody.categoryBitMask == PhysicsCategory.Player {
            enumerateChildNodes(withName: "wallPair", using: { (node, error) in
                node.speed = 0
                self.removeAllActions()
            })
            if !died {
                died = true
                player.removeAllActions()
                // Keep appearance of forward movement
                player.physicsBody?.applyImpulse(CGVector(dx: 50, dy: 0))
                createRestartButton()
            }
        }
    }
}
