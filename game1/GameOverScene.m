//
//  GameOverScene.m
//  game1
//
//  Created by Marcus Smith on 11/18/14.
//  Copyright (c) 2014 WOOOO. All rights reserved.
//

#import "GameOverScene.h"
#import "GameScene.h"

@interface GameOverScene ()

@property (nonatomic, readwrite) NSInteger finalScore;

@end

@implementation GameOverScene

- (instancetype)initWithSize:(CGSize)size andFinalScore:(NSInteger)finalScore
{
    self = [super initWithSize:size];
    
    if (self) {
        _finalScore = finalScore;
    }
    
    return self;
}

- (void)didMoveToView:(SKView *)view
{
    [self setBackgroundColor:[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0]];
    
    SKLabelNode *gameOverLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    [gameOverLabel setFontSize:30.0];
    [gameOverLabel setText:@"Game Over"];
    [self addChild:gameOverLabel];
    [gameOverLabel setPosition:CGPointMake(self.frame.size.width / 2.0, self.frame.size.height * 0.6)];

    SKLabelNode *scoreOverLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    [scoreOverLabel setFontSize:30.0];
    [scoreOverLabel setText:[NSString stringWithFormat:@"Score: %ld", self.finalScore]];
    [self addChild:scoreOverLabel];
    [scoreOverLabel setPosition:CGPointMake(self.frame.size.width / 2.0, self.frame.size.height * 0.4)];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    GameScene *gameScene = [[GameScene alloc] initWithSize:self.size];
    
    SKTransition *transition = [SKTransition doorsOpenHorizontalWithDuration:0.5];
    
    [self.view presentScene:gameScene transition:transition];
}

@end
