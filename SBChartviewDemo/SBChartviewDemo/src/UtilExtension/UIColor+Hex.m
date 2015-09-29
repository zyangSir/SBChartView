//
//  UIColor+Hex.m
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+(UIColor *)colorWithHex:(int)hexVal
{
    return [self colorWithHex: hexVal alpha: 1];
}

+(UIColor *)colorWithHex:(int)hexVal alpha:(CGFloat)alphaVal
{
    CGFloat redVal = ((hexVal >> 16) & 0xFF) / 255.0f;
    CGFloat greenVal = ((hexVal >> 8) & 0xFF) / 255.0f;
    CGFloat blueVal = (hexVal & 0xFF) / 255.0f;
    return [UIColor colorWithRed: redVal green: greenVal blue: blueVal alpha: alphaVal];
}

@end
