//
//  GameScene.m
//  game1
//
//  Created by Marcus Smith on 11/18/14.
//  Copyright (c) 2014 WOOOO. All rights reserved.
//

#import "GameScene.h"
#import "GameOverScene.h"

#define kArrowWidthMultiple 0.03
#define kDudeMultiple 0.09
#define kBaseGravity -2.0
#define kBaseTimeBetweenArrows 0.20
#define kGravitySpeedUp 50.0
#define kArrowSpeedUp 100.0
#define kEXPLOSION 3000.0

static const uint32_t dudeCategory = 0x1 << 0;
static const uint32_t arrowCategory = 0x1 << 1;

@interface GameScene ()
{
    CGFloat timeBetweenArrows;
    CFTimeInterval lastArrowTime;
    CFTimeInterval firstTime;
    UITouch *currentTouch;
    CFTimeInterval score;
    CFTimeInterval finalScore;
}

@property (nonatomic, strong) SKSpriteNode *dude;

@end

@implementation GameScene

- (void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    [self setBackgroundColor:[UIColor blackColor]];
    
    [self.physicsWorld setGravity:CGVectorMake(0.0, kBaseGravity)];
    [self.physicsWorld setContactDelegate:self];
    
    CGFloat dudeFloat = self.frame.size.width * kDudeMultiple;
    CGSize dudeSize = CGSizeMake(dudeFloat, dudeFloat);
    
    self.dude = [[SKSpriteNode alloc] initWithColor:[UIColor redColor] size:dudeSize];
    [self.dude setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:dudeSize]];
    [self.dude.physicsBody setCategoryBitMask:dudeCategory];
    [self.dude.physicsBody setContactTestBitMask:arrowCategory];
    [self.dude.physicsBody setCollisionBitMask:0];
    [self.dude.physicsBody setAffectedByGravity:NO];
    
    [self.dude setPosition:CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0)];
    [self addChild:self.dude];
    
    
    timeBetweenArrows = kBaseTimeBetweenArrows;
}

- (void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if (firstTime == 0.0) {
        firstTime = currentTime;
    }
    
    CFTimeInterval timeSinceLastArrow = currentTime - lastArrowTime;
    
    if (timeSinceLastArrow >= timeBetweenArrows) {
        CGFloat randomXPosition = (CGFloat)arc4random_uniform((u_int32_t)self.frame.size.width);
        CGFloat yPosition = self.frame.size.height * 1.2;
        
        [self makeArrowAtPoint:CGPointMake(randomXPosition, yPosition)];
        
        lastArrowTime = currentTime;
    }
    
    CGFloat gravity = kBaseGravity - ((currentTime - firstTime) / kGravitySpeedUp);
    
    [self.physicsWorld setGravity:CGVectorMake(0.0, gravity)];
    
    timeBetweenArrows = kBaseTimeBetweenArrows - ((currentTime - firstTime) / kArrowSpeedUp);
    
    score = currentTime - firstTime;
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        CGPoint touchPoint = [touch locationInNode:self];
        
        if ([self pointIsTouchingDude:touchPoint]) {
            currentTouch = touch;
            break;
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (currentTouch && [touches containsObject:currentTouch]) {
        CGPoint touchPoint = [currentTouch locationInNode:self];
        
        [self.dude setPosition:touchPoint];
    }
    else if (!currentTouch) {
        for (UITouch *touch in touches) {
            CGPoint touchPoint = [touch locationInNode:self];
            
            if ([self pointIsTouchingDude:touchPoint]) {
                currentTouch = touch;
                break;
            }
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches containsObject:currentTouch]) {
        currentTouch = nil;
    }
}

#pragma mark - SKPhysicsContactDelegate
- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if ((contact.bodyA.categoryBitMask == arrowCategory && contact.bodyB.categoryBitMask == dudeCategory) || (contact.bodyB.categoryBitMask == arrowCategory && contact.bodyA.categoryBitMask == dudeCategory)) {
        
        CGPoint contactPoint = contact.contactPoint;
        
        finalScore = score;
        
        [self makeExplosionAtPoint:contactPoint];
        
        //TODO: Make Arrows fucking fly EVERYWHERE
        [self.children enumerateObjectsUsingBlock:^(SKNode *node, NSUInteger idx, BOOL *stop) {
            if ([node.name isEqualToString:@"arrow"]) {
                CGPoint arrowPoint = node.position;
                
                CGPoint difference = CGPointMake(arrowPoint.x - contactPoint.x, arrowPoint.y - contactPoint.y);
                
                CGVector impulse = CGVectorMake(kEXPLOSION / difference.x, kEXPLOSION / difference.y);
                
                [node.physicsBody applyImpulse:impulse];
            }
        }];
        
        
        
        [self.dude removeFromParent];
        
        [self performSelector:@selector(gameOver) withObject:nil afterDelay:2.0];
    }
}

#pragma mark - Convenience Methods
- (void)makeArrowAtPoint:(CGPoint)point
{
    CGFloat screenwidth = self.frame.size.width;
    
    CGSize arrowSize = CGSizeMake(screenwidth * kArrowWidthMultiple, screenwidth * kArrowWidthMultiple * 3);
    
    SKSpriteNode *arrow = [[SKSpriteNode alloc] initWithColor:[UIColor blueColor] size:arrowSize];
    
    [arrow setName:@"arrow"];
    
    [arrow setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:arrowSize]];
    [arrow.physicsBody setCategoryBitMask:arrowCategory];
    [arrow.physicsBody setContactTestBitMask:dudeCategory];
    [arrow.physicsBody setCollisionBitMask:arrowCategory];
    
    [self addChild:arrow];
    
    [arrow setPosition:point];
}

- (BOOL)pointIsTouchingDude:(CGPoint)point
{
    return CGRectContainsPoint(self.dude.frame, point);
}

- (void)makeExplosionAtPoint:(CGPoint)point
{
    SKEmitterNode *explosion = [self makeExplosionEmitter];
    [explosion setName:@"explosion"];
    
    [self addChild:explosion];
    [explosion setPosition:point];
}

-(SKEmitterNode *)makeExplosionEmitter
{
    SKEmitterNode *explosion = [[SKEmitterNode alloc] init];
    
    [explosion setParticleTexture:[SKTexture textureWithImageNamed:@"spark.png"]];
    [explosion setParticleColor:[UIColor brownColor]];
    [explosion setNumParticlesToEmit:1000];
    [explosion setParticleBirthRate:4500];
    [explosion setParticleLifetime:2];
    [explosion setEmissionAngleRange:360];
    [explosion setParticleSpeed:1000];
    [explosion setParticleSpeedRange:500];
    [explosion setXAcceleration:0];
    [explosion setYAcceleration:0];
    [explosion setParticleAlpha:0.8];
    [explosion setParticleAlphaRange:0.2];
    [explosion setParticleAlphaSpeed:-0.5];
    [explosion setParticleScale:0.75];
    [explosion setParticleScaleRange:0.4];
    [explosion setParticleScaleSpeed:-0.5];
    [explosion setParticleRotation:0];
    [explosion setParticleRotationRange:0];
    [explosion setParticleRotationSpeed:0];
    
    [explosion setParticleColorBlendFactor:1];
    [explosion setParticleColorBlendFactorRange:0];
    [explosion setParticleColorBlendFactorSpeed:0];
    [explosion setParticleBlendMode:SKBlendModeAdd];
    
    return explosion;
}

- (void)gameOver
{
    GameOverScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size andFinalScore:finalScore];
    
    SKTransition *transition = [SKTransition doorsCloseHorizontalWithDuration:0.5];
    
    [self.view presentScene:gameOverScene transition:transition];
}

@end
