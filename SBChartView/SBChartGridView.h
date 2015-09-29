//
//  SBChartGridView.h
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBShapeView.h"
#import "SBChartLineView.h"

#define ANIMATION_DURATION 0.30
#define POINT_DIMATER      6.0f

#define X_AXIS_TITLE_FONT [UIFont systemFontOfSize:10.0]

@interface SBChartGridView : UIView


@property (nonatomic, strong) SBShapeView *pointShapeView;
@property (nonatomic, strong) SBShapeView *lineShapeView;

/**
 *  渐变色层
 */
@property (nonatomic, strong) CAGradientLayer *gradientColorLayer;

/**
 *  气泡的背景图片名称
 */
@property (nonatomic, retain) NSString *bubbleBgImageName;

//@property (nonatomic, strong) UIColor *bubbleColor;
@property (nonatomic, assign) BOOL needShowBubbleView;
@property (nonatomic, strong) NSString *bubbleText;
@property (nonatomic, strong) UILabel *xAxisLabel;



/**
 *  描述y值的垂线风格
 */
@property (nonatomic, assign) BNLineStyle lineStyle;

/**
 *  y值标题label的文本和描述y值垂线的颜色
 */
@property (nonatomic, retain) UIColor * yValueColor;

/**
 *  该格栅走势线左端点的y值(像素高度,不代表真实数值)
 */
@property (nonatomic, assign) float firstValue;

/**
 *  该格栅走势线右端点的y值(像素高度,不代表真实数值)
 */
@property (nonatomic, assign) float secondValue;

@property (nonatomic, retain) NSString *leftValueText;

@property (nonatomic, assign) CFTimeInterval animationDelay;

/**
 *  执行动画效果
 */
-(void)playAnimtion;

/**
 *  该格栅x轴刻度线下方对应的标题
 *
 *  @param xAxisTitle 标题内容,如"15:00"
 *  传入nil不显示
 */
-(void)setXAxisTitle:(NSString *)xAxisTitle;

/**
 *  释放所有已创建的显式动画
 */
-(void)releaseAnimation;

@end


/**
 *  气泡标注视图
 */
@interface BNChartBubbleView : UIImageView

@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) UIImageView *arrowImageView;

@end
