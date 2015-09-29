//
//  SBChartLastGridView.m
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import "SBChartLastGridView.h"
#import "UIColor+Hex.h"

@interface SBChartLastGridView()

@property (nonatomic, strong) SBShapeView *extraPointView;
@property (nonatomic, strong) UILabel *extraXAxisLabel;

//额外的y值描述虚线,用于最后一点的展示
@property (nonatomic, assign) BOOL canShowExtraYLine;

@property (nonatomic, strong) BNChartBubbleView *extraBubbleView;

@property (nonatomic, strong) CAKeyframeAnimation *extraBounceAnimation;

@end

@implementation SBChartLastGridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGFloat width = self.bounds.size.width;
        
        CGRect layerFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        self.extraPointView = [[SBShapeView alloc] initWithFrame: layerFrame];
        _extraPointView.backgroundColor = [UIColor clearColor];
        _extraPointView.shapeLayer.fillColor = nil;
        _extraPointView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_extraPointView];
        //[_extraPointView setBackgroundColor:[UIColor yellowColor]];
        
        _extraXAxisLabel = [[UILabel alloc] init];
        _extraXAxisLabel.backgroundColor = [UIColor clearColor];
        _extraXAxisLabel.textAlignment = NSTextAlignmentCenter;
        _extraXAxisLabel.font = X_AXIS_TITLE_FONT;
        _extraXAxisLabel.textColor = [UIColor grayColor];
        _extraXAxisLabel.frame = CGRectMake( width / 2 , Y_AXIS_TRANSFER(0) + 10 , width, 14);
        [self addSubview:_extraXAxisLabel];
        
        _extraLineStyle = dashedLineStyle;
        self.extraYValueColor = SBHexColor(0x428eff);
        
    }
    return self;
}

#pragma mark - setters
-(void)setSecondValue:(float)secondValue
{
    [super setSecondValue:secondValue];
    //CGFloat width = self.frame.size.width;
    _extraPointView.center = CGPointMake(self.bounds.size.width, [super secondValue]);
    //_extraValueLabel.frame = CGRectMake( width/2, [super secondValue] - 5 - 16 , width, 16);
    //_extraValueLabel.text = [NSString stringWithFormat:@"%.f", secondValue];
}

-(void)setExtraBubbleText:(NSString *)extraBubbleText
{
    _extraBubbleView.textLabel.text = extraBubbleText;
}



-(void)setRightValueText:(NSString *)rightValueText
{
    //_extraValueLabel.text = rightValueText;
}

-(void)setNeedShowExtraBubbleView:(BOOL)needShowExtraBubbleView
{
    _needShowExtraBubbleView = needShowExtraBubbleView;
    if (needShowExtraBubbleView == YES) {
        if (_extraBubbleView == nil) {
            self.extraBubbleView = [[BNChartBubbleView alloc] initWithFrame:CGRectZero];
            _extraBubbleView.image = [UIImage imageNamed: _extraBubbleBgImageName];
            //_extraBubbleView.textLabel.text = @"60分钟";
            _extraBubbleView.layer.opacity = 0.0f;
            
            NSString *arrowImageName = [_extraBubbleBgImageName stringByAppendingString:@"_arrow"];
            _extraBubbleView.arrowImageView.image = [UIImage imageNamed:arrowImageName];
            [self addSubview:_extraBubbleView];
        }
    }
}

-(void)setExtraXAxisTitle:(NSString *)extraXAxisTitle
{
    _extraXAxisLabel.text = extraXAxisTitle;
}

#pragma mark - animation
-(void) playAnimtion
{
    _extraBubbleView.layer.opacity = 0;
    [super playAnimtion];
    [self drawExtraPoint];
    _canShowExtraYLine = NO;
    [self setNeedsDisplay];
    
    CFTimeInterval layerTime = [_extraPointView.shapeLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    
    if (_extraBounceAnimation == nil) {
        self.extraBounceAnimation = [super performSelector:@selector(pointBounceAnimation) withObject:nil];
        _extraBounceAnimation.beginTime = layerTime + [super animationDelay] + ANIMATION_DURATION;
        _extraBounceAnimation.delegate = self;
    }
    [_extraPointView.shapeLayer addAnimation: _extraBounceAnimation forKey:@"transform"];
}

- (void)releaseAnimation
{
    _extraBounceAnimation.delegate = self;
    self.extraBounceAnimation = nil;
    
    //call super's release mehtods at last
    [super releaseAnimation];
}



-(void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    
    [super animationDidStop:anim finished:flag];
    if ([anim isKindOfClass:[CABasicAnimation class]]) {//画完走势线
        _canShowExtraYLine = YES;
        [self setNeedsDisplay];
        
        if (_needShowExtraBubbleView == YES) {
            _extraBubbleView.layer.opacity = 1.0f;
            [self bringSubviewToFront:_extraBubbleView];
            
            NSString *text = _extraBubbleView.textLabel.text;
            CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:10] constrainedToSize:CGSizeMake(100, 19) lineBreakMode:NSLineBreakByCharWrapping];
            size.width += 8;
            _extraBubbleView.frame = CGRectMake(self.frame.size.width - size.width/2, [super secondValue] - size.height - 13, size.width, size.height + 5);
            CAAnimationGroup *bubbleAnimation = [super performSelector:@selector(bubbleAnimation) withObject:nil];
            [_extraBubbleView.layer addAnimation:bubbleAnimation forKey:@"bubble"];
        }
    }
    
}



#pragma mark - graphic draw
- (void) drawExtraPoint
{
    if (_extraLineStyle == solidLineStyle) {
        _extraPointView.shapeLayer.fillColor = _extraYValueColor.CGColor;
    }else
    {
        _extraPointView.shapeLayer.strokeColor = _extraYValueColor.CGColor;
    }
    _extraPointView.shapeLayer.lineWidth  = 1.0f;
    
    CGPoint point = CGPointMake(_extraPointView.frame.size.width/2, _extraPointView.frame.size.height/2);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:point radius: POINT_DIMATER / 2.0 startAngle:0.0 endAngle:2 * M_PI clockwise:YES];
    _extraPointView.shapeLayer.path = path.CGPath;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (_canShowExtraYLine == YES) {
        CGPoint secondPoint = CGPointMake(self.bounds.size.width, [super secondValue]);
        
        CGContextSetLineWidth(ctx, 3.0f);
        CGContextBeginPath(ctx);
        
        
        //描述y值的垂虚线
        CGContextMoveToPoint(ctx, self.bounds.size.width, Y_AXIS_TRANSFER(0));
        
        if (_extraLineStyle == dashedLineStyle) {//若是虚线,则需要切换线型
            CGFloat lengths[] = {1,3};
            CGContextSetLineDash(ctx, 1, lengths, 2);
        }

        //选择颜色
        if (_needShowExtraBubbleView == YES) {
            CGContextSetStrokeColorWithColor(ctx, _extraYValueColor.CGColor);
            CGContextAddLineToPoint(ctx, secondPoint.x, secondPoint.y + 4);
            
            CGContextStrokePath(ctx);
        }
    }else
    {
        CGContextClearRect(ctx, CGRectMake(self.frame.size.width - 3, 0, 3, self.frame.size.height));
    }
}


@end
