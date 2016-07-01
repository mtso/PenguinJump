//
//  GameScene.swift
//  SwipeTest
//
//  Created by Matthew Tso on 6/29/16.
//  Copyright (c) 2016 Matthew Tso. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var touching = false
    var beganLocation: CGPoint!
    var endLocation: CGPoint!
    var player: SKSpriteNode! //(color: UIColor.blackColor(), size: CGSize(width: 100, height: 100) )
    var cam: SKCameraNode!
    
    let maxJumps = 2
    var jumpCount = 0
    var okToJump = true
    var useSavedJump = false
    
    var swipeTrail: SKEmitterNode!
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        backgroundColor = UIColor.blueColor()
        
        cam = SKCameraNode()
        cam.zPosition = 2000
        camera = cam
        addChild(cam)
        
        player = SKSpriteNode(imageNamed: "penguin-back")
        player.size = CGSize(width: 80, height: 100)
        player.position = CGPoint(x: CGRectGetMidX(view.frame), y: CGRectGetMidY(view.frame))
        player.zPosition = 1000
        
        addChild(player)
        
        for i in 0...50 {
            let platform = SKSpriteNode(color: UIColor.orangeColor(), size: CGSize(width: 200, height: 200) )
            platform.position = CGPoint(x: player.position.x, y: player.position.y * CGFloat(i) )
            addChild(platform)
        }
        
        if let swipeParticle = SKEmitterNode(fileNamed: "SwipeTrail") {
            swipeTrail = swipeParticle
            swipeTrail.name = "swipeTrail"
            swipeTrail.targetNode = cam
            
            cam.addChild(swipeTrail)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        guard let touch = touches.first else {
            return
        }
        
        if !touching {
            beganLocation = touch.locationInNode(self)

            touching = true
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let wait = SKAction.waitForDuration(0.1)
        
        swipeTrail.removeAllActions()
        swipeTrail.runAction(wait, completion: {
            self.swipeTrail.position = CGPoint(x: 0, y: -2000)
        })
        
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.locationInNode(self)
        let touchLocationInCamera = cam.convertPoint(touchLocation, fromNode: self)
        swipeTrail.position = touchLocationInCamera
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        
        if touching {
            touching = false
            
            endLocation = touch.locationInNode(self)
            
            var deltaX = beganLocation.x - endLocation!.x
            var deltaY = beganLocation.y - endLocation!.y
            let deltaHyp = sqrt(deltaX * deltaX + deltaY * deltaY)
            let maxHyp = CGFloat(300)
            if deltaHyp > maxHyp {
                let scaleFactor = maxHyp / deltaHyp
                deltaX = deltaX * scaleFactor
                deltaY = deltaY * scaleFactor
            }
            jump(deltaX, deltaY)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        cam.position = CGPoint(x: player.position.x - view!.frame.width * 2 / 2.75, y: player.position.y + view!.frame.height / 4)
    }
    
    func jump(deltaX: CGFloat, _ deltaY: CGFloat) {
        
        if okToJump {
            jumpCount += 1
            okToJump = false
            
            player.removeAllActions()
            
            childNodeWithName("target")?.removeFromParent()
            let jumpDestination = CGPoint(x: player.position.x - deltaX, y: player.position.y - deltaY)
            addChild( newTargetAt( jumpDestination ) )
            
            // Movement and scale `SKActions`
            let scaleUp = SKAction.scaleTo(1.5, duration: 0.5)
            scaleUp.timingMode = .EaseOut
            let scaleDown = SKAction.scaleTo(1, duration: 0.3)
            scaleDown.timingMode = .EaseIn
            
            let moveFirst = SKAction.moveBy(CGVector(dx: -deltaX * 0.9, dy: -deltaY * 0.9), duration: 0.5)
            let moveSecond = SKAction.moveBy(CGVector(dx: -deltaX * 0.1, dy: -deltaY * 0.1), duration: 0.3)
            moveFirst.timingMode = .EaseOut
            
            player.runAction(SKAction.group([moveFirst, scaleUp]), completion: {
                
                if self.useSavedJump {
                    
                    self.secondJump(nil, nil, saveDelta: false)
                    
                } else if self.jumpCount < self.maxJumps {
                    
                    // If double jump during landing, set `okToJump` to true before completion
                    self.okToJump = true

                    self.player.runAction(SKAction.group([moveSecond, scaleDown]), completion: {
                        self.childNodeWithName("target")?.removeFromParent()
                        self.jumpCount = 0
                    })
                } else {
                    
                    self.player.runAction(SKAction.group([moveSecond, scaleDown]), completion: {
                        
                        // If already double jumped once, set `okToJump` to true after completion
                        self.okToJump = true

                        self.childNodeWithName("target")?.removeFromParent()
                        self.jumpCount = 0
                    })
                }
            })
            
        } else if jumpCount < maxJumps {
            jumpCount += 1
            
            secondJump(deltaX, deltaY, saveDelta: true)
            useSavedJump = true
        }
    }
    
    func secondJump(deltaX: CGFloat?, _ deltaY: CGFloat?, saveDelta saving: Bool) {
        
        struct SavedDelta {
            static var deltaX: CGFloat = 0
            static var deltaY: CGFloat = 0
        }
        
        if saving {
            if let dx = deltaX { SavedDelta.deltaX = dx }
            if let dy = deltaY { SavedDelta.deltaY = dy }
        } else {
            player.removeAllActions()
            childNodeWithName("target")?.removeFromParent()
            
            let deltaX2 = SavedDelta.deltaX
            let deltaY2 = SavedDelta.deltaY
            
            let jumpDestination = CGPoint(x: player.position.x - deltaX2, y: player.position.y - deltaY2)
            addChild( newTargetAt( jumpDestination ) )
            
            // Movement and scale `SKActions`
            let scaleUp = SKAction.scaleTo(1.5, duration: 0.5)
            let scaleDown = SKAction.scaleTo(1, duration: 0.3)
            scaleUp.timingMode = .EaseOut
            scaleDown.timingMode = .EaseIn
            let moveFirst = SKAction.moveBy(CGVector(dx: -deltaX2 * 0.9, dy: -deltaY2 * 0.9), duration: 0.5)
            let moveSecond = SKAction.moveBy(CGVector(dx: -deltaX2 * 0.1, dy: -deltaY2 * 0.1), duration: 0.3)
            moveFirst.timingMode = .EaseOut
            
            let scale = SKAction.sequence([scaleUp, scaleDown])
            let move = SKAction.sequence([moveFirst, moveSecond])
            
            player.runAction(SKAction.group([scale, move]), completion: {
                self.childNodeWithName("target")?.removeFromParent()
                self.okToJump = true
                self.jumpCount = 0
                self.useSavedJump = false
            })
        }
    }
    
    func newTargetAt(position: CGPoint) -> SKSpriteNode {
        
        let target = SKSpriteNode(imageNamed: "targetcircle")
        target.name = "target"
        target.position = position // CGPoint(x: player.position.x - deltaX, y: player.position.y - deltaY)
        target.setScale(0.5)
        target.zPosition = 100
        
        let flashDown = SKAction.fadeAlphaTo(0, duration: 0.1)
        let flashUp = SKAction.fadeAlphaTo(1, duration: 0.1)
        let wait = SKAction.waitForDuration(0.1)
        target.runAction(SKAction.repeatActionForever(SKAction.sequence([flashUp, flashDown, wait])))
        
        return target
    }
}
