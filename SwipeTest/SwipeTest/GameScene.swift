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
    
    let numberOfJumps = 2
    var jumpCount = 0
    var okToJump = true
    
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
        if jumpCount < numberOfJumps && okToJump {
            jumpCount += 1
            okToJump = false
            
            player.removeAllActions()
            for child in children {
                if child.name == "target" {
                    child.removeFromParent()
                }
            }
            
            let target = SKSpriteNode(imageNamed: "targetcircle")
            target.name = "target"
            target.position = CGPoint(x: player.position.x - deltaX, y: player.position.y - deltaY)
            target.setScale(0.5)
            target.zPosition = 100
            addChild(target)
            
            let flashDown = SKAction.fadeAlphaTo(0, duration: 0.1)
            let flashUp = SKAction.fadeAlphaTo(1, duration: 0.1)
            let wait = SKAction.waitForDuration(0.1)
            target.runAction(SKAction.repeatActionForever(SKAction.sequence([flashUp, flashDown, wait])))
            
            let scaleUp = SKAction.scaleTo(1.5, duration: 0.5)
            scaleUp.timingMode = .EaseOut
            let scaleDown = SKAction.scaleTo(1, duration: 0.5)
            scaleDown.timingMode = .EaseIn
            let scale = SKAction.sequence([scaleUp, scaleDown])
            
            let moveFirst = SKAction.moveBy(CGVector(dx: -deltaX * 0.9, dy: -deltaY * 0.9), duration: 0.5)
            let moveSecond = SKAction.moveBy(CGVector(dx: -deltaX * 0.1, dy: -deltaY * 0.1), duration: 0.5)
            let move = SKAction.sequence([moveFirst, moveSecond])
            //move.timingMode = .EaseOut
            
            player.runAction(SKAction.group([moveFirst, scaleUp]), completion: {
                self.okToJump = true
                self.player.runAction(SKAction.group([moveSecond, scaleDown]), completion: {
                    target.removeFromParent()
                    self.jumpCount = 0
                })
            })
        }
    }
}
