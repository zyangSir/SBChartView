//
//  SBChartLineView.h
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  线型
 */
typedef enum{
    solidLineStyle, //实线
    dashedLineStyle //虚线
}BNLineStyle;

/**
 *  线的放置方向
 */
typedef enum{
    LINE_ORIENTATION_VERTICAL, //竖直
    LINE_ORIENTATION_HORIZON   //水平
} BNLineOrientation;

#define BASE_Y             20.0f

#define Y_AXIS_TRANSFER(__Y)   ( self.frame.size.height - (__Y) - BASE_Y )

@interface SBChartLineView : UIView

@property (nonatomic, assign) CGFloat yValue;
@property (nonatomic, assign) BNLineStyle lineStyle;
@property (nonatomic, assign) BNLineOrientation lineOrientation;
@property (nonatomic, retain) UIColor * lineColor;

@end
