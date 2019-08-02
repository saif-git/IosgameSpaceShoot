//
//  GameScene.swift
//  ShootGame
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK :- Declarations
    var starfield:SKEmitterNode!
    var player:SKSpriteNode!
    var scoreLabel:SKLabelNode!
    var score: Int=0{
        didSet{
            scoreLabel.text = "Score : \(score)"
        }
    }
    var gameTimer : Timer!
    var possibleAlien = ["alien","alien2","alien3"]
    let alienCategory : UInt32 = 0x1 << 1
    let photonTorpedoCategory : UInt32 = 0x1 << 0

    let motionManager = CMMotionManager()

    var xAccelerate: CGFloat = 0
    
    override func didMove(to view: SKView) {
        
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: 1472)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        
       // starfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "shuttle")
        
//        player.position = CGPoint(x: self.frame.size.width , y: )
        debugPrint(self.frame.size.width/2)
        debugPrint(player.frame.size.height / 2 + 20)
        player.position = CGPoint(x:0  , y:-500)
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        scoreLabel = SKLabelNode(text: "Score : 0")
      //  debugPrint(self.frame.height - 100)
        scoreLabel.position = CGPoint(x:0,y:550)
        scoreLabel.fontName = "AmeriecanTypeWriter-Bold"
        scoreLabel.fontSize = 35
        scoreLabel.fontColor = UIColor.white
        score = 0
        self.addChild(scoreLabel)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAccelerate = CGFloat(acceleration.x) * 0.75 + self.xAccelerate * 0.25
            }
        }
    }
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    // MARK : - function to create
    @objc func addAlien() {
        possibleAlien = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAlien) as! [String]
        let alien = SKSpriteNode(imageNamed: possibleAlien[0])
        let randomAlienPossition = GKRandomDistribution(lowestValue: -500, highestValue: 414)
        let possition = CGFloat(randomAlienPossition.nextInt())
        
        alien.position = CGPoint(x:possition, y:self.frame.size.height + alien.size.height + 800)
       // debugPrint(possition , " " , self.frame.size.height , " " ,alien.size.height)
        var sizeAlien = alien.size
        //debugPrint(sizeAlien)
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        let animationDuration = 5
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x :possition , y: -alien.size.height-450), duration: TimeInterval(animationDuration)))
        
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        FireTorpedo()
    }
    
    
    
    func FireTorpedo() {
        
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position.y += 5
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        self.addChild(torpedoNode)
        
        let animationDuration = 0.6
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x :player.position.x , y:
            self.frame.size.height+2000), duration: TimeInterval(animationDuration)))
        
        debugPrint(self.frame.size.height)
        debugPrint(player.position.x)
        actionArray.append(SKAction.removeFromParent())
        torpedoNode.run(SKAction.sequence(actionArray))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody = SKPhysicsBody()
        var secondBody = SKPhysicsBody()
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    func torpedoDidCollideWithAlien (torpedoNode:SKSpriteNode, alienNode:SKSpriteNode) {
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        score += 5
        
        
    }
    override func didSimulatePhysics() {
        
        player.position.x += xAccelerate * 50
        
        if player.position.x < -20 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        }else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
        
    }
}
