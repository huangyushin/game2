//
//  GameScene.swift
//  my_shooting_game
//
//  Created by huangyuhsin on 2018/12/14.
//  Copyright © 2018 None Co., Ltd. All rights reserved.
//

import SpriteKit
import GameplayKit

//沒有寫在class內的函數是"全域函數"
//重函數的名字如果是"運算子符號"這表示:這個函數將要重新定義那個運算子的處理資料方式!!
//這在物件導向程式中稱為:"運算子重載"--->operator overload

//以下我"運算子重載"了+,-,*,三個運算子!讓它們能幫我處理向量
//"運算子"通常在程式裡處理"運算元"

//對 + 運算子來說，把它當成函數來重新定義的話: + 左邊的運算元就是left參數，右邊的運算元就是right參數
//回傳值就是運算結果(二元運算子就是這樣的)
func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

//向量的乘法-->兩個向量乘起來是什麼??你要想清楚!!在此我向量的乘法定義成:某個向量放大某倍
func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

/*
//只要沒有把函數寫在class裡面，就是全域函數
func length(vector:CGPoint) -> CGFloat {
        return sqrt(vector.x*vector.x + vector.y*vector.y)
    }
    
    func normalized(vector:CGPoint) -> CGPoint {
        return vector / length(vector:vector)
    }
*/
//以下是C語言用法，前面帶 # 的指令叫做"先行處理器"-->preprocess
//arch()為全域函數，檢查cpu系統，
#if !(arch(x86_64) || arch(arm64))  //如果你的cpu不是桌上型電腦x86的64bit或掌上型arm的64bit，那麼你傳sqrt(a: CGFloat)等於CGFloat(sqrtf(Float(a)))---->算得很精細，非常節省效能
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

//類別的函數，一定有隱藏看不見的物件(self)---->rita自己加的，應該是這個意思
extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    struct PhysicsCategory {
        static let none      : UInt32 = 0
        static let all       : UInt32 = UInt32.max
        static let monster   : UInt32 = 0b1       // 1
        static let projectile: UInt32 = 0b10      // 2
    }
    
    //1主角太空船
    let player = SKSpriteNode(imageNamed: "player4")
    //1.1太空背景
    let space = SKSpriteNode(imageNamed: "space1")
    
    var monstersDestroyed = 0

    
    override func didMove(to view: SKView)
    {
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.mp3")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)


    //2準備背景顏色物件
    backgroundColor = SKColor.white
    //3將太空背景放入
    space.position = CGPoint(x:size.width * 0.5, y:size.height * 0.5)
    addChild(space)
    //3將太空船位置放到螢幕左邊1/100(寬)中間(高)的地方
    player.position = CGPoint(x:size.width * 0.1, y:size.height * 0.5)
    //放入場景中
    addChild(player)
        
    self.run(SKAction.repeatForever(
        SKAction.sequence([
            SKAction.run(addMonster),
            SKAction.wait(forDuration: 1.0)
            ])
        ))
    }
    
    //觸控函數
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 1 - Choose one of the touches to work with
        guard/*跟if相反，當條件為false才會執行後面的*/ let touch = touches.first else {
            return  /*表示在函數中執行，return沒有回傳值的話，就會離開函數(不往下繼續)*/
        }
        let touchLocation = touch.location(in: self)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "bullet")
        projectile.position = player.position
        
        // 3 - Determine offset of location to projectile
        //因為我在上面重新定義 - 可以減向量(CGPoint)
        //手指觸點的那個向量 - 子彈位置的點的向量 = 可以得到兩個向量的差(也是一個向量)
        let offset = touchLocation - projectile.position
        
        // 4 - Bail out if you are shooting down or backwards
        //檢查新向量的x值若小於0，表示點在主角後面---->return不用作了
        if offset.x < 0 { return }
        
        // 5 - OK to add now - you've double checked position
        addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        //計算法向量(單位向量)
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        //子彈要去的新點(只要保證走到螢幕外就好了)
        //再度利用我重載的*運算子
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        //上面只是得到子彈角度遠度，別忘了子彈發射點在主角身上
        //所以子彈最終要去的點還得加上主角的位置(相向量)
        let realDest = shootAmount + projectile.position
        
        // 9 - Create the actions
        //製造子彈射出的SKAction了
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
        //projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        projectile.physicsBody?.usesPreciseCollisionDetection = true    //精密碰撞
        
        projectile.run(SKAction.playSoundFileNamed("BU.mp3", waitForCompletion: false))


    }

    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    //MARK: - 自製方便函數
    func random() -> CGFloat {//產生一個0~1之間的亂數
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {//多型
        return random() * (max - min) + min //此演算法=>產生一個介於:min與max
    }
    
    func addMonster() //加入怪物的程式碼另作一個函數
    {
        
        // 建立怪物
        let monster = SKSpriteNode(imageNamed: "monster1")
        
        // 怪物沿y軸，最上面不能突出畫面
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        // 把怪物加入場景，位置的y是上面隨機算出來的(但不會上下超過畫面)x則是剛好在畫面外
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        // 加入場景
        addChild(monster)
        
        // 怪物衝過來的速度不一定(比較難)
        // 再用亂數SKAction的Move動作函數時，要指定移動的時間，所以在此用亂數出一個時間(短-->move快)
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // SKAction的move函數可以執行角色的"移動"
        // 第一個參數:移動目標的"點"
        // 第二個參數:移動所花的時間
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY),duration: TimeInterval(actualDuration))
        //SKAction的removeFromParent函數可以執行角色的"移出"(摧毀)"場景(避免太多角色造成lag)
        let actionMoveDone = SKAction.removeFromParent()
        //SKAction的sequence函數可以執行角色的"一系列SKAction"(用陣列裝起來依序執行)
        
        //monster.run(SKAction.sequence([actionMove, actionMoveDone]))
        

        let loseAction = SKAction.run
        {
            [weak self]
            in
            guard let `self` = self else { return }
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))

        
        
        //縮小點
        monster.xScale = 0.7
        monster.yScale = 0.6
        player.xScale = 0.3
        player.yScale = 0.3
        
        //monster.run(SKAction.scale(by:0.5,duration:0.0)
        //以monster做物理體
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
        monster.physicsBody?.isDynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4要跟誰發生碰撞:子彈
        //monster.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
    }

    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        //加入贏的規則
        monstersDestroyed += 1
        if monstersDestroyed > 30 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }

    
    //MARK: - 碰撞委託處理函數
    func didBegin(_ contact: SKPhysicsContact) {
        print("撞到了")
        //處理打仃的後續
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask /*兩值相比，定義誰是子彈誰是怪物*/ {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2 一個 & →處理bit級，二個 & →以結果論
        if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.projectile != 0))
        {
            if let monster = firstBody.node as? SKSpriteNode,let projectile = secondBody.node as? SKSpriteNode
            {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
        
        /*  上面是很乖寶寶(精細)的寫法，下面是老師(粗燥)的寫法
        let 管你是誰A:SKSpriteNode = (contact.bodyA).node as! SKSpriteNode
        let 管你是誰B:SKSpriteNode = (contact.bodyB).node as! SKSpriteNode
        管你是誰A.removeFromParent()
        管你是誰B.removeFromParent()
        */
        
        
    }
}
