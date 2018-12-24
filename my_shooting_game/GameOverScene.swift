//
//  GameOverScene.swift
//  my_shooting_game
//
//  Created by huangyuhsin on 2018/12/22.
//  Copyright © 2018 None Co., Ltd. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene
{
    
    
    init(size: CGSize, won:Bool)
    {
        super.init(size: size)
        
        // 1
        backgroundColor = SKColor.white
        
        // 2
        let message = won ? "You Won!" : "You Lose :["
        
        // 3
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.black
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        // 4
        //只要怪物跑到你的後面，你就輸了，等三秒再回來重新玩
        run(
         SKAction.sequence(
          [
            SKAction.wait(forDuration: 3.0),
            SKAction.run
                {
                //[weak self]in guard let `self` = self else { return } //筆者耍帥用
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition:reveal)
                }
          ]
          )
        )
    }
    
    //如果你自己寫建構子，以下的建構子叫做"必要(補充)建構子"
    required init(coder aDecoder: NSCoder)
    {
        //在必要(補充)建構子中最小一定要寫下面這個全域函數
        //fatalError會在類別建構
        fatalError("init(coder:) has not been implemented")
    }
}

