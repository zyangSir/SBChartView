//
//  UIColor+Hex.h
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SBHexColor(h) [UIColor colorWithHex: h]

@interface UIColor (Hex)

+(UIColor *)colorWithHex:(int)hexVal alpha:(CGFloat)alphaVal;

+(UIColor *)colorWithHex:(int)hexVal;

@end
