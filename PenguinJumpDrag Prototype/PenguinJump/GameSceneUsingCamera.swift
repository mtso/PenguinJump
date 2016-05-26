//
//  GameSceneUsingCamera.swift
//  PenguinJump
//
//  Created by Matthew Tso on 5/25/16.
//  Copyright © 2016 De Anza. All rights reserved.
//

import SpriteKit

// Overload minus operator to use on CGPoint
func -(first: CGPoint, second: CGPoint) -> CGPoint {
    let deltaX = first.x - second.x
    let deltaY = first.y - second.y
    return CGPoint(x: deltaX, y: deltaY)
}

class GameSceneUsingCamera: SKScene {
    
    var enableScreenShake = true
    
    var cam:SKCameraNode!
    
    let penguin = Penguin()
    var stage: IcebergGenerator!
//    var yIncrement: CGFloat!
    
    var gameStarted = false
    var gameOver = false
    var playerTouched = false
    
    var score: CGFloat = 0.0
    var intScore = 0
    var scoreLabel: SKLabelNode!
    
    let title = SKSpriteNode(texture: nil)
    let playButton = SKLabelNode(text: "Play")
    
    let jumpAir = SKShapeNode(circleOfRadius: 20.0)
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.9, blue: 0.9, alpha: 0.4)

        newGame()
        
        title.position = CGPointZero
        title.position.y += view.frame.height / 3
        title.zPosition = 10000
        cam.addChild(title)
        
        let titleLabel = SKLabelNode(text: "PENGUIN")
        titleLabel.fontName = "Helvetica Neue Condensed Black"
        titleLabel.fontSize = 80
        titleLabel.position = CGPointZero
        
        let subtitleLabel = SKLabelNode(text: "JUMP")
        subtitleLabel.fontName = "Helvetica Neue Condensed Black"
        subtitleLabel.fontSize = 122
        subtitleLabel.position = CGPointZero
        subtitleLabel.position.y -= subtitleLabel.frame.height
        
        title.addChild(titleLabel)
        title.addChild(subtitleLabel)
        
        playButton.name = "playButton"
        playButton.fontName = "Helvetica Neue Condensed Black"
        playButton.fontSize = 60
        playButton.fontColor = SKColor.blackColor()
        playButton.position = CGPointZero
        playButton.position.y -= view.frame.height / 3
//        playButton.position.x = CGRectGetMidX(cam.frame)
//        playButton.position.y = CGRectGetMidY(cam)
        playButton.zPosition = 10000
        cam.addChild(playButton)
        
        let shrinkDown = SKAction.scaleTo(0.95, duration: 0.1)
        let bumpUp = SKAction.scaleTo(1.05, duration: 0.1)
        let bumpDown = SKAction.scaleTo(1.0, duration: 0.1)
        let bumpWait = SKAction.waitForDuration(2.0)
        let bump = SKAction.sequence([shrinkDown, bumpUp, bumpDown, bumpWait])
        playButton.runAction(SKAction.repeatActionForever(bump))
        
        
        cam.position = penguin.position
        cam.position.y += view.frame.height * 0.06
        let zoomedIn = SKAction.scaleTo(0.4, duration: 0.0)
        cam.runAction(zoomedIn)
        
        
//        let lightningAtlas = SKTextureAtlas(named: "lightning")
//        var lightningFrames = [SKTexture]()
//        for number in 1...3 {
//            let texture = SKTexture(imageNamed: "lightning\(number)")
//            lightningFrames.append(texture)
//        }
//        
//        let lightning = SKSpriteNode(texture: lightningFrames.first)
//        lightning.position = view.center
//        lightning.zPosition = 3000
//        let lightningAnim = SKAction.animateWithTextures(lightningFrames, timePerFrame: 0.2)
//        lightning.runAction(SKAction.repeatActionForever(lightningAnim))
//        
//        addChild(lightning)
    }
    
    // MARK: - Gameplay logic
    
    func trackScore() {
        if penguin.position.y > score {
            score = penguin.position.y / 10
        }
    }
    
    // MARK: - Background
    
    func bob(node: SKSpriteNode) {
        let bobDepth = 2.0
        let bobDuration = 2.0
        
        let down = SKAction.moveBy(CGVector(dx: 0.0, dy: bobDepth), duration: bobDuration)
        let wait = SKAction.waitForDuration(bobDuration / 2)
        let up = SKAction.moveBy(CGVector(dx: 0.0, dy: -bobDepth), duration: bobDuration)
        
        let bobSequence = SKAction.sequence([down, wait, up, wait])
        let bob = SKAction.repeatActionForever(bobSequence)
        
        node.removeAllActions()
        node.runAction(bob)
    }
    
    // MARK: - Controls
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for touch in touches {
            let positionInScene = touch.locationInNode(self)
            let touchedNodes = self.nodesAtPoint(positionInScene)
            for touchedNode in touchedNodes {
                if let name = touchedNode.name
                {
                    if name == "restartButton" {
                        view!.paused = false
                        restart()
                    }
                    if touchedNode.name == "playButton" {

                        beginGame()
                    }
                }
            }
            if penguin.inAir && !penguin.doubleJumped {
                penguin.doubleJumped = true
                
                let delta = positionInScene - penguin.position
                
                let jumpAir = SKShapeNode(circleOfRadius: 20.0)
                jumpAir.fillColor = SKColor.clearColor()
                jumpAir.strokeColor = SKColor.whiteColor()
                
                jumpAir.xScale = 1.0
                jumpAir.yScale = 1.0
                
                jumpAir.position = penguin.position
                addChild(jumpAir)
                
                let airExpand = SKAction.scaleBy(2.0, duration: 0.4)
                let airFade = SKAction.fadeAlphaTo(0.0, duration: 0.4)
                
                airExpand.timingMode = .EaseOut
                airFade.timingMode = .EaseIn
                
                jumpAir.runAction(airExpand)
                jumpAir.runAction(airFade, completion: {
                    self.jumpAir.removeFromParent()
                })
                
                doubleJump(CGVector(dx: -delta.x * 2.5, dy: -delta.y * 2.5))
            }
        }
        
    }
    
    
    
    func doubleJump(velocity: CGVector) {
        let nudgeRate: CGFloat = 180
        let nudgeDistance = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        let nudgeDuration = Double(nudgeDistance / nudgeRate)
        
        let nudge = SKAction.moveBy(velocity, duration: nudgeDuration)
        penguin.runAction(nudge)
    }
    
    // MARK: - Initialize game
    
    func beginGame() {
        let zoomOut = SKAction.scaleTo(1.0, duration: 2.0)
        
        let cameraFinalDestX = penguin.position.x
        let cameraFinalDestY = penguin.position.y + frame.height / 4
        
        let pan = SKAction.moveTo(CGPoint(x: cameraFinalDestX, y: cameraFinalDestY), duration: 2.0)
        pan.timingMode = .EaseInEaseOut
        zoomOut.timingMode = .EaseInEaseOut
        
        
        cam.runAction(zoomOut)
        cam.runAction(pan, completion: {
            self.cam.addChild(self.scoreLabel)
            
            self.scoreLabel.position.y += 300
            
            let scoreLabelDown = SKAction.moveBy(CGVector(dx: 0, dy: -300), duration: 1.0)
            scoreLabelDown.timingMode = .EaseOut
            self.scoreLabel.runAction(scoreLabelDown)
            
            self.gameStarted = true
        })
        
        let playButtonDown = SKAction.moveBy(CGVector(dx: 0, dy: -300), duration: 1.0)
        playButtonDown.timingMode = .EaseIn
        playButton.runAction(playButtonDown, completion: {
            self.playButton.removeFromParent()
        })
        
        let titleUp = SKAction.moveBy(CGVector(dx: 0, dy: 400), duration: 1.0)
        titleUp.timingMode = .EaseIn
        title.runAction(titleUp, completion: {
            self.title.removeFromParent()
        })
    }
    
    func newGame() {
        gameOver = false
        
        cam = SKCameraNode()
        cam.xScale = 1.0
        cam.yScale = 1.0
        
        camera = cam
        addChild(cam)
        
        cam.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        
        stage = IcebergGenerator(view: view!, camera: cam)
        stage.position = view!.center
        addChild(stage)

//        backgroundColor = SKColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 0.4)
        backgroundColor = SKColor(red: 0/255, green: 151/255, blue: 255/255, alpha: 1.0)
        
        scoreLabel = SKLabelNode(text: "Score: " + String(Int(score)))
        scoreLabel.fontName = "Helvetica Neue Condensed Black"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.position = CGPoint(x: 0, y: view!.frame.height * 0.45)
        scoreLabel.zPosition = 30000
        
//        yIncrement = size.height / 5

        // Create penguin
        let penguinPositionInScene = CGPoint(x: size.width * 0.5, y: size.height * 0.3)
        
        penguin.position = penguinPositionInScene
//        penguin.name = "penguin"
        penguin.zPosition = 2100
        penguin.userInteractionEnabled = true
        addChild(penguin)
        
        stage.newGame(convertPoint(penguinPositionInScene, toNode: stage))
        
        
    }
    
    func restart() {
        removeAllChildren()
        removeAllActions()
        cam.removeAllChildren()
        
        newGame()
        intScore = 0
        cam.addChild(scoreLabel)
    }
    
    // MARK: - Updates
    
    override func update(currentTime: NSTimeInterval) {
        
        stage.update()
        
        
        if gameStarted {
            //            scoreLabel.text = "Score: " + String(Int(score))
            scoreLabel.text = "Score: " + String(intScore)
            
            centerCamera()
            trackScore()
            penguinUpdate()
            
            checkGameOver()
            if gameOver {
                runGameOver()
            }
        }
        
    }
    
    func checkGameOver() {
        if !penguin.inAir && !onBerg() {
            gameOver = true            
        }
    }
    
    func runGameOver() {
        if gameOver {
            view?.paused = true
            
            backgroundColor = SKColor.redColor()
            
            let restartButton = SKLabelNode(text: "Restart")
            restartButton.name = "restartButton"
            restartButton.userInteractionEnabled = false
            restartButton.fontName = "Helvetica Neue Condensed Black"
            restartButton.fontSize = 48
            restartButton.fontColor = SKColor.whiteColor()
            restartButton.position = CGPointZero // CGPoint(x: view!.frame.width * 0.5, y: view!.frame.height * 0.5)
            restartButton.zPosition = 30000
            cam.addChild(restartButton)
        }
    }
    
    func penguinUpdate() {
        for child in stage.children {
            let berg = child as! Iceberg
            if penguin.shadow.intersectsNode(berg) {
                if !berg.landed && !penguin.inAir {
                    if berg.name != "firstBerg" {
                        berg.land()
                        stage.updateCurrentBerg(berg)
                        shakeScreen()
                        
                        berg.sink(7.0, completion: {})
                        
                        intScore += 1
                        
                        let scoreBumpUp = SKAction.scaleTo(1.2, duration: 0.1)
                        let scoreBumpDown = SKAction.scaleTo(1.0, duration: 0.1)
                        
                        scoreLabel.runAction(SKAction.sequence([scoreBumpUp, scoreBumpDown]))
                    }
                    
                   
                }
            }
        }

    }
    
    func onBerg() -> Bool {
        for child in stage.children {
            let berg = child as! Iceberg
            if penguin.shadow.intersectsNode(berg) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Camera control
    
    func centerCamera() {
        let cameraFinalDestX = penguin.position.x
        let cameraFinalDestY = penguin.position.y + frame.height / 4
        
        let pan = SKAction.moveTo(CGPoint(x: cameraFinalDestX, y: cameraFinalDestY), duration: 0.25)
        pan.timingMode = .EaseInEaseOut
        
        cam.runAction(pan)
    }
    
    // MARK: - Utilities
    
    func shakeScreen() {
        if enableScreenShake {
            let shakeAnimation = CAKeyframeAnimation(keyPath: "transform")
            let randomIntensityOne = CGFloat(random() % 4 + 1)
            let randomIntensityTwo = CGFloat(random() % 4 + 1)
            shakeAnimation.values = [
                NSValue( CATransform3D:CATransform3DMakeTranslation(-randomIntensityOne, 0, 0 ) ),
                NSValue( CATransform3D:CATransform3DMakeTranslation( randomIntensityOne, 0, 0 ) ),
                NSValue( CATransform3D:CATransform3DMakeTranslation( 0, -randomIntensityTwo, 0 ) ),
                NSValue( CATransform3D:CATransform3DMakeTranslation( 0, randomIntensityTwo, 0 ) ),
            ]
            shakeAnimation.repeatCount = 1
            shakeAnimation.duration = 10/100
            
            view!.layer.addAnimation(shakeAnimation, forKey: nil)
        }
    }
}
