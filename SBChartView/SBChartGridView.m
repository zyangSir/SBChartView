//
//  SBChartGridView.m
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import "SBChartGridView.h"

#import "UIImage+Resizable.h"
#import "UIColor+Hex.h"

#define POINT_BOUNCE_ANIMATION @"pointBounce"
#define LINE_DRAW_ANIMATION    @"lineDraw"

#define TREND_LINE_X_OFFSET  5 //为了营造走势线相对于圈点中心x轴方向的偏移
@interface SBChartGridView()

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) BNChartBubbleView *bubbleView;

@property (nonatomic, assign) BOOL needShowScaleLine;
@property (nonatomic, retain) CAKeyframeAnimation *bounceAnimation;
@property (nonatomic, retain) CABasicAnimation *lineDrawAnimation;
@property (nonatomic, retain) CAAnimationGroup *bubbleAnimationGroup;
@property (nonatomic, retain) CABasicAnimation *gradientColorDrawAnimation;


@end

@implementation SBChartGridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
        CGRect layerFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        UIViewAutoresizing autoSize = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        //创建 渐变色层
        self.gradientColorLayer = [CAGradientLayer layer];
        _gradientColorLayer.frame = layerFrame;
        _gradientColorLayer.colors = @[(id)[UIColor colorWithRed:52.0/255 green:119.0/255 blue:235.0/255 alpha:0.8].CGColor,
                                       (id)[UIColor colorWithRed:52.0/255 green:119.0/255 blue:235.0/255 alpha:0.2].CGColor];
        _gradientColorLayer.opacity = 0.5f;
        [self.layer addSublayer:_gradientColorLayer];
        [self drawGradientColorArea];
        
        //创建 点层
        self.pointShapeView = [[SBShapeView alloc] initWithFrame: layerFrame];
        _pointShapeView.autoresizingMask = autoSize;
        _pointShapeView.shapeLayer.fillColor = nil;
        _pointShapeView.backgroundColor = [UIColor clearColor];
        _pointShapeView.opaque = NO;
        //_pointShapeView.hidden = YES; //默认一开始是隐藏的
        _pointShapeView.translatesAutoresizingMaskIntoConstraints = NO;
        //_pointShapeView.backgroundColor = [UIColor blueColor];
        [self addSubview:_pointShapeView];
        
        //创建线层(y值走势线)
        self.lineShapeView = [[SBShapeView alloc] initWithFrame:layerFrame];
        _lineShapeView.autoresizingMask = autoSize;
        _lineShapeView.shapeLayer.fillColor = nil;
        _lineShapeView.backgroundColor = [UIColor clearColor];
        _lineShapeView.opaque = NO;
        _lineShapeView.translatesAutoresizingMaskIntoConstraints = NO;
        [self insertSubview:_lineShapeView atIndex:0];
        
        CGFloat width = frame.size.width;
        //CGFloat height = frame.size.height;
        
        // y值标题和x轴刻度值标题
        _xAxisLabel = [[UILabel alloc] init];
        _xAxisLabel.backgroundColor = [UIColor clearColor];
        _xAxisLabel.textAlignment = NSTextAlignmentCenter;
        _xAxisLabel.font =  X_AXIS_TITLE_FONT;
        //        _xAxisLabel.textColor = [UIColor grayColor];
        //_xAxisLabel.adjustsFontSizeToFitWidth = YES;
        //_xAxisLabel.hidden = YES;
        //_xAxisLabel.alpha = 0.0f;
        _xAxisLabel.frame = CGRectMake(-(width/2), Y_AXIS_TRANSFER(0) + 10 , width, 14);
        [self addSubview:_xAxisLabel];
        
        
        //默认的线条配色,及线型
        self.yValueColor = [UIColor lightGrayColor];
        _lineStyle = dashedLineStyle;
        self.backgroundColor = [UIColor clearColor];
        
        _animationDelay = 0.0f;
        _needShowScaleLine = NO;
        
        self.clipsToBounds = NO;
    }
    return self;
}

#pragma mark - Animation

-(void)playAnimtion
{
    [self drawPoint];
    [self drawLine];
    [self drawGradientColorArea];
    _valueLabel.alpha = 0;
    _needShowScaleLine = NO;
    [self setNeedsDisplay];
    
    
    CGAffineTransform zoomIn = CGAffineTransformMakeScale(1.5f, 1.5f);
    _valueLabel.transform = zoomIn;
    
    //点圈的弹跳动画
    CFTimeInterval localLayerTime = [_pointShapeView.shapeLayer
                                     convertTime: CACurrentMediaTime()
                                     fromLayer: nil];
    self.bounceAnimation.beginTime = localLayerTime + _animationDelay;
    [_pointShapeView.shapeLayer addAnimation: _bounceAnimation
                                      forKey: @"show"];
    //气泡标注淡入动画
    if (_needShowBubbleView == YES) {
        _bubbleView.layer.opacity = 0.0f;
        [self bringSubviewToFront:_bubbleView];
        
        NSString *bubbleText = _bubbleView.textLabel.text;
        CGSize size = [bubbleText sizeWithFont:[UIFont systemFontOfSize:10] constrainedToSize:CGSizeMake(100, 19) lineBreakMode:NSLineBreakByCharWrapping];
        size.width += 8;
        _bubbleView.frame = CGRectMake(-(size.width / 2), _firstValue - size.height - 13, size.width, size.height + 5);
        
        [self bubbleAnimation];
        self.bubbleAnimationGroup.beginTime = _bounceAnimation.beginTime + 0.3f;
        
        [_bubbleView.layer addAnimation:_bubbleAnimationGroup forKey:@"bubbleShow"];
        
    }
    
    localLayerTime = [_lineShapeView.shapeLayer
                      convertTime: CACurrentMediaTime()
                      fromLayer: nil];
    
    self.lineDrawAnimation.beginTime = localLayerTime + _animationDelay + 0.05;
    
    [_lineShapeView.shapeLayer addAnimation: _lineDrawAnimation forKey:NSStringFromSelector(@selector(strokeEnd))];
    
    self.gradientColorDrawAnimation.beginTime = localLayerTime + _animationDelay +0.05;
    CAShapeLayer *maskLayer = (CAShapeLayer*)_gradientColorLayer.mask;
    [maskLayer addAnimation:_gradientColorDrawAnimation forKey:@"drawGradient"];
}

- (void)releaseAnimation
{
    _bounceAnimation.delegate = nil;
    _bubbleAnimationGroup.delegate = nil;
    _lineDrawAnimation.delegate = nil;
    _gradientColorDrawAnimation.delegate = nil;
    
    
    self.bounceAnimation = nil;
    self.bubbleAnimationGroup = nil;
    self.lineDrawAnimation = nil;
    self.gradientColorDrawAnimation = nil;
}

#pragma mark - Animation constructors

-(CABasicAnimation*)drawGradientAreaAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    UIBezierPath *fromPath = [self gradientFromPath];
    UIBezierPath *toPath   = [self gradientToPath];
    animation.fromValue    = (__bridge id)fromPath.CGPath;
    animation.toValue      = (__bridge id)toPath.CGPath;
    animation.duration     = ANIMATION_DURATION;
    animation.fillMode     = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    return animation;
}

/**
 *  创建弹跳动画
 *
 *  @return 弹跳动画
 */
-(CAKeyframeAnimation*)pointBounceAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.4;
    
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.4, 1.4, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.6, 0.6, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    
    animation.values = values;
    animation.fillMode = kCAFillModeBackwards;
    
    return animation;
}

/**
 *  创建画线动画
 *
 *  @return 画线动画
 */
-(CABasicAnimation*)drawLineAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:NSStringFromSelector(@selector(strokeEnd))];
    animation.fromValue = @(0.0);
    animation.toValue = @(1.0);
    animation.duration = ANIMATION_DURATION;
    animation.fillMode = kCAFillModeBackwards;
    
    return animation;
}

//淡入
-(CABasicAnimation*)fadeInAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(0);
    animation.toValue = @(1);
    //animation.duration = 0.8f;
    animation.fillMode = kCAFillModeBackwards;
    
    return animation;
}

//放大
-(CABasicAnimation*)zoomInAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @(1);
    animation.toValue   = @(1.2);
    //animation.duration  = 0.3f;
    animation.fillMode  = kCAFillModeBackwards;
    animation.autoreverses = YES;
    
    return animation;
}

#pragma mark - Animation delegate
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    _needShowScaleLine = YES;
    
    if ([anim isKindOfClass:[CAAnimationGroup class]]) {
        _bubbleView.layer.opacity = 1.0f;
        
    }
    [self setNeedsDisplay];
}

#pragma mark - Math
/**
 *  在由point1,point2组成的直线上, 根据x轴上的偏移值求y轴上的偏移值
 *
 *  @param xOffSet x轴方向的偏移
 *  @param point1  直线上点1
 *  @param point2  直线上点2
 *
 *  @return 对应的y轴方向偏移值
 */
-(CGFloat)yOffsetOfXOffset:(CGFloat)xOffSet point1:(CGPoint)point1 point2:(CGPoint)point2
{
    CGFloat deltaY = point2.y - point1.y;
    CGFloat deltaX = point2.x - point1.x;
    return (deltaY / deltaX) * xOffSet;
}

#pragma mark - Setters

-(void)setXAxisTitle:(NSString *)xAxisTitle
{
    _xAxisLabel.text = xAxisTitle;
}

-(void)setYValueColor:(UIColor*)yValueColor
{
    _yValueColor = yValueColor;
    _valueLabel.textColor = yValueColor;
}

-(void)setFirstValue:(float)firstValue
{
    
    _firstValue = Y_AXIS_TRANSFER(firstValue);
    
    CGFloat width = self.bounds.size.width;
    
    //数值label
    _valueLabel.frame = CGRectMake(-(width/2), _firstValue - 5 - 16 , width, 16);
    _valueLabel.textColor = [UIColor colorWithCGColor:_yValueColor.CGColor];
    //_valueLabel.text = [NSString stringWithFormat:@"%.0f",firstValue];
    
    //坐标点
    _pointShapeView.center = CGPointMake(0, _firstValue);
}

-(void)setLeftValueText:(NSString *)leftValueText
{
    _valueLabel.text = leftValueText;
}

-(void)setSecondValue:(float)secondValue
{
    _secondValue = Y_AXIS_TRANSFER(secondValue);
    
}

-(void)setNeedShowBubbleView:(BOOL)needShowBubbleView
{
    _needShowBubbleView = needShowBubbleView;
    if (needShowBubbleView == YES) {
        if (_bubbleView == nil) {
            self.bubbleView = [[BNChartBubbleView alloc] initWithFrame:CGRectZero];
            //_bubbleView.backgroundColor = [UIColor yellowColor];
            UIImage *image = [UIImage imageNamed:_bubbleBgImageName];
            image = [image resizableImageInCenter];
            _bubbleView.image = image;
            _bubbleView.textLabel.text = @"18分钟";
            _bubbleView.layer.opacity = 0.0f;
            
            NSString *arrowImageName = [_bubbleBgImageName stringByAppendingString:@"_arrow"];
            _bubbleView.arrowImageView.image = [UIImage imageNamed:arrowImageName];
            //_bubbleView.layer.opacity
            //streched image load code...
            [self addSubview:_bubbleView];
        }
    }
    [self setNeedsDisplay];
}

-(void)setBubbleText:(NSString *)bubbleText
{
    _bubbleView.textLabel.text = bubbleText;
}

#pragma mark - Getters
-(CABasicAnimation*)lineDrawAnimation
{
    if (_lineDrawAnimation == nil) {
        self.lineDrawAnimation = [self drawLineAnimation];
        _lineDrawAnimation.delegate = self;
    }
    
    return _lineDrawAnimation;
}

-(CAKeyframeAnimation*)bounceAnimation
{
    if (_bounceAnimation == nil) {
        self.bounceAnimation = [self pointBounceAnimation];
        _bounceAnimation.delegate = self;
    }
    
    return _bounceAnimation;
}

/**
 *  创建气泡标注动画
 *
 *  @return 气泡标注组合(淡入+放大)动画
 */
-(CAAnimationGroup*)bubbleAnimation
{
    if (_bubbleAnimationGroup == nil) {
        CABasicAnimation *fadeInAnimation = [self fadeInAnimation];
        CABasicAnimation *zoomInAnimation = [self zoomInAnimation];
        self.bubbleAnimationGroup = [CAAnimationGroup animation];
        _bubbleAnimationGroup.duration = 0.2f;
        _bubbleAnimationGroup.delegate = self;
        _bubbleAnimationGroup.fillMode = kCAFillModeForwards;
        _bubbleAnimationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        //_bubbleAnimationGroup.removedOnCompletion = YES;
        _bubbleAnimationGroup.autoreverses = YES;
        _bubbleAnimationGroup.animations = [NSArray arrayWithObjects:fadeInAnimation, zoomInAnimation,nil];
        
    }
    return _bubbleAnimationGroup;
}


/**
 *  创建渐变区域绘制动画
 *
 *  @return 渐变绘制动画
 */
-(CABasicAnimation*)gradientColorDrawAnimation
{
    if (_gradientColorDrawAnimation == nil) {
        self.gradientColorDrawAnimation = [self drawGradientAreaAnimation];
    }
    return _gradientColorDrawAnimation;
}


#pragma mark - Graphic draw

/**
 *  绘制渐变色区域
 */
-(void)drawGradientColorArea
{
    
    CAShapeLayer *gradientAreaMask = nil;
    if (_gradientColorLayer.mask == NULL) {
        gradientAreaMask = [CAShapeLayer layer];
        gradientAreaMask.frame = _gradientColorLayer.bounds;
        _gradientColorLayer.mask = gradientAreaMask;
    }else
    {
        gradientAreaMask = (CAShapeLayer*)_gradientColorLayer.mask;
    }
    gradientAreaMask.path = [UIBezierPath bezierPath].CGPath;
}


-(void)drawPoint
{
    if (_lineStyle == solidLineStyle) {
        [_pointShapeView.shapeLayer setFillColor:_yValueColor.CGColor];
    }else
    {
        _pointShapeView.shapeLayer.strokeColor = SBHexColor(0x428eff).CGColor;
    }
    _pointShapeView.shapeLayer.lineWidth  = 1.0f;
    
    CGPoint point = _lineShapeView.center;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:point radius: POINT_DIMATER / 2.0 startAngle:0.0 endAngle:2 * M_PI clockwise:YES];
    _pointShapeView.shapeLayer.path = path.CGPath;
}

-(void)drawLine
{
    //走势线
    _lineShapeView.shapeLayer.strokeColor = SBHexColor(0x428eff).CGColor;
    _lineShapeView.shapeLayer.lineWidth = 1.0f;
    
    CGPoint orignLeftPoint = CGPointMake(0, _firstValue);
    CGPoint orignRightPoint = CGPointMake(self.bounds.size.width, _secondValue);
    CGFloat firstPointYOffset = [self yOffsetOfXOffset:TREND_LINE_X_OFFSET point1:orignLeftPoint point2:orignRightPoint];
    CGFloat secondPointYOffset = [self yOffsetOfXOffset: -TREND_LINE_X_OFFSET point1:orignLeftPoint point2:orignRightPoint];
    
    CGPoint leftPoint = CGPointMake(TREND_LINE_X_OFFSET, _firstValue + firstPointYOffset);
    CGPoint rightPoint = CGPointMake(self.bounds.size.width - TREND_LINE_X_OFFSET, _secondValue + secondPointYOffset);
    
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:leftPoint];
    [path addLineToPoint:rightPoint];
    _lineShapeView.shapeLayer.path = path.CGPath;
    
}

-(UIBezierPath*)gradientFromPath
{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGPoint leftTopPoint = CGPointMake(0, _firstValue);
    CGPoint rightTopPoint = CGPointMake(0, _firstValue);
    CGPoint rightBottomPoint = CGPointMake(0, Y_AXIS_TRANSFER(0));
    CGPoint leftBottomPoint = CGPointMake(0, Y_AXIS_TRANSFER(0));
    
    [path moveToPoint:leftTopPoint];
    [path addLineToPoint:rightTopPoint];
    [path addLineToPoint:rightBottomPoint];
    [path addLineToPoint:leftBottomPoint];
    [path closePath];
    return path;
}

-(UIBezierPath*)gradientToPath
{
    CGPoint leftTopPoint = CGPointMake(0, _firstValue);
    CGPoint rightTopPoint = CGPointMake(self.bounds.size.width , _secondValue);
    CGPoint rightBottomPoint = CGPointMake(self.bounds.size.width, Y_AXIS_TRANSFER(0));
    CGPoint leftBottomPoint = CGPointMake(0, Y_AXIS_TRANSFER(0));
    
    //画一个四边形的区域
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:leftTopPoint];
    [path addLineToPoint:rightTopPoint];
    [path addLineToPoint:rightBottomPoint];
    [path addLineToPoint:leftBottomPoint];
    [path closePath];
    
    return path;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    
    if (_needShowScaleLine == YES) {
        CGPoint firstPoint = CGPointMake(0, _firstValue);
        
        CGContextSetLineWidth(ctx, 3.0f);
        CGContextBeginPath(ctx);
        
        
        //描述y值的垂虚线
        CGContextMoveToPoint(ctx, 0, Y_AXIS_TRANSFER(0));
        
        if (_lineStyle == dashedLineStyle) {//若是虚线,则需要切换线型
            CGFloat lengths[] = {1,3};
            CGContextSetLineDash(ctx, 1, lengths, 2);
            //选择颜色
        }
        //选择颜色
        if (_needShowBubbleView == YES) {
            CGContextSetStrokeColorWithColor(ctx, _yValueColor.CGColor);
            CGContextAddLineToPoint(ctx, firstPoint.x, firstPoint.y + 4);
            
            CGContextStrokePath(ctx);
        }
    }else
    {
        CGContextClearRect(ctx, CGRectMake(0, 0, 3, self.frame.size.height));
    }
    
}


@end

@implementation BNChartBubbleView

-(id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.font = [UIFont systemFontOfSize:10.0f];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.numberOfLines = 0;
        //_textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:_textLabel];
        
        _arrowImageView = [[UIImageView alloc] init];
        [self addSubview:_arrowImageView];
        
        self.clipsToBounds = NO;
    }
    return self;
}

-(void)layoutSubviews
{
    if (self.bounds.size.width == 0||self.bounds.size.height == 0) {
        return;
    }
    CGSize size = [_textLabel.text sizeWithFont:[UIFont systemFontOfSize:10] constrainedToSize:CGSizeMake(self.bounds.size.width, 100) lineBreakMode:NSLineBreakByWordWrapping];
    CGRect rect = CGRectMake(0, 2, self.bounds.size.width, size.height);
    _textLabel.frame = rect;
    
    _arrowImageView.frame = CGRectMake(self.bounds.size.width/2 - 3.5, self.bounds.size.height, 6.5, 3);
}

@end
