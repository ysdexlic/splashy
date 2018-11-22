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
    static let Water: UInt32 = 0x1 << 4
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    // Defaults
    var highScore: Int = UserDefaults.standard.integer(forKey: "splashy_highscore")
    var score: Int = 0
    var died: Bool = false
    var gameStarted: Bool = false
    var restartCount: Int = 0
    var isFirstTouch: Bool = false
    var enableUnderwaterPhysics: Bool = true
    var ranDeathAnimation: Bool = false

    let limitWaterFPS: Bool = false
    let waterFPS: Double = 1.0 / 20

    // Sprites / Nodes
    var player: Player!
    var water: SBDynamicWaterNode!
    var waterNode: SKSpriteNode!
    var wallPair: SKNode!
    var scoreNode: SKSpriteNode!
    var restartButton: SKSpriteNode!

    // Labels
    var textLabel: SKLabelNode!
    var scoreLabel: SKLabelNode!

    // Player Animation
    var swimmingFrames: [SKTexture] = []

    // Water Animation
    var hasReferenceFrameTime: Bool = false
    var lastFrameTime: CFTimeInterval!
    var lastUpdated: CFTimeInterval!
    let kFixedTimeStep = 1.0 / 500
    var kSurfaceHeight: CGFloat!

    func restartScene() {
        self.removeAllChildren()
        self.removeAllActions()
        player.removeAllActions()
        died = false
        ranDeathAnimation = false
        gameStarted = true
        restartCount += 1
        score = 0
        isFirstTouch = false
        createScene()
    }

    func createScene() {
        self.physicsWorld.contactDelegate = self

        kSurfaceHeight = self.size.height / 2.5

        // Background
        for i in 0..<2 {
            let background = SKSpriteNode(imageNamed: "sky")
            background.anchorPoint = CGPoint(x: 0, y: 0)
            background.position = CGPoint(x:CGFloat(i) * self.frame.width, y: 0)
            background.size = CGSize(width: self.size.width, height: self.size.height)
            background.name = "background"
            background.zPosition = 0
            self.addChild(background)
        }

        // Tap to start label
        textLabel = SKLabelNode()
        textLabel.fontSize = 100
        textLabel.position = CGPoint(x: self.frame.width / 2, y: (self.frame.height / 2) - (self.frame.height / 4))
        textLabel.zPosition = 5
        textLabel.text = "Tap anywhere to start"

        // Score Label
        scoreLabel = SKLabelNode()
        scoreLabel.fontSize = 100
        scoreLabel.position = CGPoint(x: self.frame.width / 2, y: (self.frame.height / 2) + (self.frame.height / 2.5))
        scoreLabel.zPosition = 5
        scoreLabel.text = gameStarted ? "\(score)" : "High Score: \(highScore)"
        self.addChild(scoreLabel)

        // Player
        createPlayer()

        // Water
        createWater()

        // Scene
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        if restartCount > 0 {
            startGame()
        } else {
            self.addChild(textLabel)
        }
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
                bg.position = CGPoint(x: bg.position.x - 2, y: bg.position.y)

                if bg.position.x <= -bg.size.width {
                    bg.position = CGPoint(x: bg.position.x + bg.size.width * 2, y: bg.position.y)
                }
            })
        }

        if (!self.hasReferenceFrameTime) {
            self.lastUpdated = currentTime
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
         if !player.isAboveWater {
            if enableUnderwaterPhysics {
                player.applyUnderwaterPhysics(waterY: water.position.y, surfaceHeight: kSurfaceHeight)
            } else {
                player.goDown(surfaceHeight: kSurfaceHeight)
            }
        }

        self.lateUpdate(currentTime)
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
        if limitWaterFPS {
            if currentTime - lastUpdated >= waterFPS {
                water.render()
                lastUpdated = currentTime
            }
        } else {
            water.render()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameStarted {
            isFirstTouch = true
            gameStarted = true
            if restartCount == 0 {
                textLabel.run(SKAction.removeFromParent())
                startGame()
                return
            }
        }
        if died || !gameStarted {
            return
        }
        enableUnderwaterPhysics = false
        if !player.isAboveWater {
            player.physicsBody?.velocity = CGVector(dx: 0, dy: (player.physicsBody?.velocity.dy)! / 2)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        enableUnderwaterPhysics = true
        if isFirstTouch && restartCount == 0 {
            isFirstTouch = false
            return
        }
        for touch in touches {
            let location = touch.location(in: self)

            if died {
                if restartButton.contains(location) {
                    restartScene()
                }
            }
        }

        if died || !gameStarted {
            return
        }

        if !died && !player.isAboveWater {
            let playerY = player.position.y
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 6.25 * (kSurfaceHeight - playerY))
        }
    }

    func createWalls() {
        // wall actions
        let distance = CGFloat(self.frame.width)
        let movePipes = SKAction.moveBy(x: -distance - 50, y: 0, duration: TimeInterval(0.0025 * distance))
        let removePipes = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([movePipes, removePipes])

        scoreNode = SKSpriteNode()
        wallPair = SKNode()
        wallPair.name = "wallPair"

        let gapSize = CGFloat(350)
        let wallScale = CGFloat(0.5)

        let topWall = SKSpriteNode(texture: nil, color: UIColor.yellow, size: CGSize(width: 80, height: 1000))
        let bottomWall = SKSpriteNode(texture: nil, color: UIColor.yellow, size: CGSize(width: 80, height: 1000))

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

    func createWater() {
        water = SBDynamicWaterNode(width: Float(self.size.width), numJoints:150, surfaceHeight:Float(kSurfaceHeight), fillColour: UIColor(red:0.05, green:0, blue:1, alpha:0.4))
        water.position = CGPoint(x:self.size.width/2, y:0)
        water.zPosition = 3
        water.setDefaultValues()

        waterNode = SKSpriteNode()
        waterNode.size = CGSize(width: self.size.width, height: 1)
        waterNode.position = CGPoint(x: 0, y: kSurfaceHeight)
        waterNode.physicsBody = SKPhysicsBody(rectangleOf: waterNode.size)
        waterNode.physicsBody?.categoryBitMask = PhysicsCategory.Water
        waterNode.physicsBody?.collisionBitMask = 0
        waterNode.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        waterNode.physicsBody?.affectedByGravity = false
        waterNode.physicsBody?.isDynamic = false

        water.addChild(waterNode)

        self.addChild(water)
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
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: player.size.width * 0.8, height: player.size.height * 0.8))
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.collisionBitMask = PhysicsCategory.Wall
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Wall | PhysicsCategory.Score | PhysicsCategory.Water
        player.zPosition = 2
        animatePlayer()
        self.addChild(player)
    }

    func animatePlayer(key: String = "swimmingDolphin", duration: TimeInterval = 0.05) {
        player.removeAction(forKey: key)
        player.run(SKAction.repeatForever(
            SKAction.animate(with: swimmingFrames,
                             timePerFrame: duration,
                             resize: false,
                             restore: true)
            ),
            withKey: key
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

        textLabel.text = "High Score: \(highScore)"
        self.addChild(textLabel)
    }

    func startGame() {
        scoreLabel.text = "\(score)"
        let spawn = SKAction.run {
            () in
            self.createWalls()
        }
        let delay = SKAction.wait(forDuration: 2.0)
        let spawnDelay = SKAction.sequence([spawn, delay])
        let spawnDelayForever = SKAction.repeatForever(spawnDelay)
        self.run(spawnDelayForever)
    }

    func onDeath() {
        died = true
        ranDeathAnimation = false
        enableUnderwaterPhysics = true
        // Keep appearance of forward movement
        player.physicsBody?.applyImpulse(CGVector(dx: 20, dy: 0))
        player.removeAllActions()

        if score > highScore {
            highScore = score
            UserDefaults.standard.set(score, forKey: "splashy_highscore")
            UserDefaults.standard.synchronize()
        }

        createRestartButton()
    }

    func runDeathAnimation() {
        if !ranDeathAnimation {
            ranDeathAnimation = true
            player.physicsBody?.angularVelocity = 0
            let rotateAction = SKAction.rotate(toAngle: .pi, duration: 1.5, shortestUnitArc: true)
            player.run(rotateAction)
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        // Player scored a point
        if !died && (firstBody.categoryBitMask == PhysicsCategory.Score && secondBody.categoryBitMask == PhysicsCategory.Player || firstBody.categoryBitMask == PhysicsCategory.Player && secondBody.categoryBitMask == PhysicsCategory.Score) {
            score += 1
            scoreLabel.text = "\(score)"
        }

        // Player hits wall
        if firstBody.categoryBitMask == PhysicsCategory.Player && secondBody.categoryBitMask == PhysicsCategory.Wall || firstBody.categoryBitMask == PhysicsCategory.Wall && secondBody.categoryBitMask == PhysicsCategory.Player {
            enumerateChildNodes(withName: "wallPair", using: { (node, error) in
                node.speed = 0
                self.removeAllActions()
            })
            if !died {
                onDeath()
            }
        }

        // Player hits water
        if (firstBody.categoryBitMask == PhysicsCategory.Player && secondBody.categoryBitMask == PhysicsCategory.Water || firstBody.categoryBitMask == PhysicsCategory.Water && secondBody.categoryBitMask == PhysicsCategory.Player) {
            if died {
                runDeathAnimation()
            }
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        // Player hits water
        if (firstBody.categoryBitMask == PhysicsCategory.Player && secondBody.categoryBitMask == PhysicsCategory.Water || firstBody.categoryBitMask == PhysicsCategory.Water && secondBody.categoryBitMask == PhysicsCategory.Player) {
            if player.isAboveWater {
                // Jumping
                if !died {
                    animatePlayer(duration: 0.2)
                }
            } else {
                // Swimming
                if !died {
                    animatePlayer(duration: 0.05)
                }
            }
        }
    }
}
