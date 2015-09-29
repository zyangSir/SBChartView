//
//  SBChartView.h
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SBChartView;

@protocol SBChartViewDataSource <NSObject>

@required
- (float)chartView:(SBChartView*)chartView valueForIndex:(NSUInteger)index;

@optional
- (NSString*) chartView:(SBChartView*)chartView titleOnXAxisForIndex:(NSUInteger)index;

@end

@protocol SBChartViewDelegate <NSObject>

@required
-(NSUInteger)numberOfPointsInChartView:(SBChartView*)chartView;

@end

@interface SBChartView : UIView

@property (nonatomic,weak) id<SBChartViewDataSource> dataSource;
@property (nonatomic,weak) id<SBChartViewDelegate> delegate;

@property (nonatomic,assign) CGFloat coloumnWidth;
@property (nonatomic,assign) CGFloat baseY;
@property (nonatomic,assign) BOOL needBgColor;

-(void)reloadData;

-(void)playAnimation;

@end
