//
//  SBChartLineView.m
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import "SBChartLineView.h"

@implementation SBChartLineView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, _lineColor.CGColor);
    CGContextBeginPath(ctx);
    if (_lineStyle == dashedLineStyle) {//若是虚线
        
        CGFloat lengths[] = {1,3};
        CGContextSetLineDash(ctx, 1, lengths, 2);
    }
    
    CGPoint startPoint = CGPointMake(1, 1);
    CGPoint endPoint;
    if (_lineOrientation == LINE_ORIENTATION_HORIZON) {
        endPoint = CGPointMake(self.bounds.size.width, 1);
    }else
    {
        endPoint = CGPointMake(1, self.bounds.size.height);
    }
    
    CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
    CGContextStrokePath(ctx);
}


@end
