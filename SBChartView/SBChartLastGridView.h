//
//  SBChartLastGridView.h
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import "SBChartGridView.h"

@interface SBChartLastGridView : SBChartGridView

@property (nonatomic, retain) UIColor * extraYValueColor;
@property (nonatomic, assign) BNLineStyle extraLineStyle;
@property (nonatomic, retain) NSString *rightValueText;
@property (nonatomic, retain) NSString *extraXAxisTitle;
@property (nonatomic, assign) BOOL needShowExtraBubbleView;
@property (nonatomic, retain) NSString *extraBubbleText;

@property (nonatomic, retain) NSString *extraBubbleBgImageName;

@end
