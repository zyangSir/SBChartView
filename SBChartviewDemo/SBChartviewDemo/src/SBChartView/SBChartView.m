//
//  SBChartView.m
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import "SBChartView.h"
#import "SBChartGridView.h"
#import "SBChartLastGridView.h"
#import "SBChartLineView.h"
#import "UIColor+Hex.h"

#define DELTA_Y  13.5f
#define X_AXIS_ORIGIN_Y (self.frame.size.height - 25) //x轴线在视图中的y坐标值
#define Y_AXIS_ORIGIN_X 30 //y轴线在视图中的x坐标值
#define Y_AXIS_LABEL_NUM 4
#define Y_LABEL_HEIGHT 12.0f

#define MIN_VALUE_COLOR SBHexColor(0x5f9c41)
#define MAX_VALUE_COLOR SBHexColor(0xd44040)

//Y坐标轴上从下往上第一个数值刻度距离原点的垂直像素高度
#define FIRST_SCALE_OFFSET_ON_YAXIS 10.0f

#define MIN_VALUE_BUBLE_IMAGE  @"min_value_bg"
#define MAX_VALUE_BUBLE_IMAGE  @"max_value_bg"

@interface SBChartView()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) SBChartLastGridView *lastGridView;
@property (nonatomic, retain) NSMutableArray *gridViewArray;

@property (nonatomic, assign) float maxValue;
@property (nonatomic, assign) float minValue;

@property (nonatomic, assign) NSUInteger bottomValueInYAxis;
@property (nonatomic, assign) NSUInteger topValueInYAxis;

@property (nonatomic, assign) BOOL maxValueBubbleHasShown;
@property (nonatomic, assign) BOOL minValueBubbleHasShown;

@property (nonatomic, strong) SBChartLineView *maxLineView;
@property (nonatomic, strong) SBChartLineView *averageLineView;
@property (nonatomic, strong) SBChartLineView *minLineView;

@property (nonatomic, retain) NSMutableArray *yValueLabelArray;

@property (nonatomic, assign) CGFloat pixelPerRow;

@property (nonatomic, strong) UIView *xAxisView;
@property (nonatomic, strong) UIView *yAxisView;

@property (nonatomic, assign) BOOL isMinOrMaxValueAtIndex0;

@end

@implementation SBChartView

- (void)dealloc
{
    [self releaseAnimation];
    
    for (UIView *gridView in _gridViewArray) {
        [gridView removeFromSuperview];
    }
    self.scrollView = nil;
    
    [_gridViewArray removeAllObjects];
    self.gridViewArray = nil;
    
    
    self.maxLineView = nil;
    self.averageLineView = nil;
    self.minLineView = nil;
    
    [_yValueLabelArray removeAllObjects];
    self.yValueLabelArray = nil;
    self.xAxisView = nil;
    self.yAxisView = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(Y_AXIS_ORIGIN_X, 0, frame.size.width, frame.size.height)];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.contentSize = CGSizeMake(frame.size.width, frame.size.height);
        _scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_scrollView];
        
        self.gridViewArray = [NSMutableArray arrayWithCapacity:8];
        
        [self createBasicView];
        //默认图表配置
        _baseY = 20.0f;
        _coloumnWidth = 30;
        
        _needBgColor = YES;
    }
    return self;
}

-(void)createBasicView
{
    //x轴线
    _xAxisView = [[UIView alloc] initWithFrame:CGRectMake(21, X_AXIS_ORIGIN_Y ,self.frame.size.width - 21, 0.5)];
    _xAxisView.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:_xAxisView];
    _xAxisView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    //y轴线
    _yAxisView = [[UIView alloc] initWithFrame:CGRectMake(Y_AXIS_ORIGIN_X, 6, 0.5, self.frame.size.height - 21)];
    _yAxisView.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:_yAxisView];
    
    //y轴上的数值标注
    self.yValueLabelArray = [NSMutableArray arrayWithCapacity:4];
    //CGRect frame = CGRectMake(0, xAxisView.frame.origin.y - 15 , 28, 10);
    
    for (int i = 0; i< Y_AXIS_LABEL_NUM; ++i) {
        UILabel *label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentRight;
        label.text = [NSString stringWithFormat:@"%d",20];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor grayColor];
        label.font = [UIFont systemFontOfSize:12.0f];
        [self addSubview:label];
        [_yValueLabelArray addObject:label];
    }
    
    UIColor * refLineColor = [UIColor lightGrayColor];
    
    //最低点参考线
    self.minLineView = [[SBChartLineView alloc] init];
    _minLineView.lineColor = refLineColor;
    _minLineView.lineStyle = dashedLineStyle;
    _minLineView.lineOrientation = LINE_ORIENTATION_HORIZON;
    [self insertSubview:_minLineView atIndex:0];
    
    //平均值参考线
    self.averageLineView = [[SBChartLineView alloc] init];
    _averageLineView.lineColor = refLineColor;
    _averageLineView.lineStyle = dashedLineStyle;
    _averageLineView.lineOrientation = LINE_ORIENTATION_HORIZON;
    [self insertSubview:_averageLineView aboveSubview:_minLineView];
    
    //最低点参考线
    self.maxLineView = [[SBChartLineView alloc] init];
    _maxLineView.lineColor = refLineColor;
    _maxLineView.lineStyle = dashedLineStyle;
    _maxLineView.lineOrientation = LINE_ORIENTATION_HORIZON;
    [self insertSubview:_maxLineView aboveSubview: _averageLineView];
}

-(void)layoutSubviews
{
    //[self reloadData];
}



-(void)reloadData
{
    if (_dataSource ==nil || _delegate == nil) {
        return;
    }
    NSUInteger valueCount = [_delegate numberOfPointsInChartView:self];
    
    if (valueCount == 0) {
        return;
    }
    
    [self findMinAndMaxValueFromDataSource];
    
    [self refreshYAxisLabels];
    //[self layoutReferLineView];
    
    if (_gridViewArray != nil&&[_gridViewArray count] > 0) {
        [self releaseAnimation];
        for (UIView *subView in _gridViewArray) {
            [subView removeFromSuperview];
        }
        [_gridViewArray removeAllObjects];
    }
    
    _minValueBubbleHasShown = NO;
    _maxValueBubbleHasShown = NO;
    
    NSUInteger totalPixelNumInYAxis = _pixelPerRow * (Y_AXIS_LABEL_NUM - 1);
    
    _scrollView.contentSize = CGSizeMake(_coloumnWidth * (valueCount + 1), self.frame.size.height);
    
    CGFloat startX = 10;
    if (_isMinOrMaxValueAtIndex0 == YES) {
        //如果最大值或最小值在第一个，导致气泡在第一个点，就让第一个点后挪一些距离以免气泡显示不全
        startX = 45;
    }
    
    CGRect gridFrame = CGRectMake(startX, 0, _coloumnWidth, self.frame.size.height - 5);
    
    for (int i = 0; i < (valueCount - 2); ++i) {
        SBChartGridView *gridView = [[SBChartGridView alloc] initWithFrame:gridFrame];
        float firstValue = [_dataSource chartView:self valueForIndex:i];
        float secondValue = [_dataSource chartView:self valueForIndex:i+1];
        
        //gridView.leftValueText = [NSString stringWithFormat:@"%.0f",firstValue];
        if (firstValue == _minValue && _minValueBubbleHasShown == NO) {
            gridView.bubbleBgImageName = MIN_VALUE_BUBLE_IMAGE;
            gridView.needShowBubbleView = YES;
            //gridView.bubbleColor = [UIColor greenColor];
            NSString *bubbleText = [NSString stringWithFormat:@"%.1f", firstValue];
            bubbleText = [NSString stringWithFormat:@"最低%@",bubbleText];
            gridView.bubbleText = bubbleText;
            gridView.yValueColor = MIN_VALUE_COLOR;
            gridView.lineStyle = solidLineStyle;
            _minValueBubbleHasShown = YES;
        }else if (firstValue == _maxValue && _maxValueBubbleHasShown == NO)
        {
            
            gridView.bubbleBgImageName = MAX_VALUE_BUBLE_IMAGE;
            gridView.needShowBubbleView = YES;
            //gridView.bubbleColor = [UIColor redColor];
            NSString *bubbleText = [NSString stringWithFormat:@"%.1f", firstValue];
            bubbleText = [NSString stringWithFormat:@"最高%@",bubbleText];
            gridView.bubbleText = bubbleText;
            gridView.yValueColor = MAX_VALUE_COLOR;
            gridView.lineStyle = solidLineStyle;
            _maxValueBubbleHasShown = YES;
        }
        gridView.firstValue  = [self pixelHeightInYAxisOfValue:firstValue totalPixelNum:totalPixelNumInYAxis];
        
        gridView.secondValue = [self pixelHeightInYAxisOfValue:secondValue totalPixelNum:totalPixelNumInYAxis];
        
        if ([_dataSource respondsToSelector:@selector(chartView:titleOnXAxisForIndex:)]) {
            NSString *xAxisTitle = [_dataSource chartView:self titleOnXAxisForIndex:i];
            [gridView setXAxisTitle:xAxisTitle];
        }
        
        gridView.animationDelay = i * ANIMATION_DURATION;
        
        
        [_scrollView addSubview:gridView];
        [_gridViewArray addObject:gridView];
        gridFrame.origin.x += _coloumnWidth;
        
    }
    
    //最后一个grid,因为略有不同,所以要特殊处理
    _lastGridView = [[SBChartLastGridView alloc] initWithFrame:gridFrame];
    
    float firstValue = [_dataSource chartView:self valueForIndex:(valueCount - 2)];
    if (firstValue == _minValue && _minValueBubbleHasShown == NO) {
        _lastGridView.bubbleBgImageName = MIN_VALUE_BUBLE_IMAGE;
        _lastGridView.needShowBubbleView = YES;
        //lastGridView.bubbleColor = [UIColor greenColor];
        NSString *bubbleText = [NSString stringWithFormat:@"%.1f", firstValue];
        bubbleText = [NSString stringWithFormat:@"最低%@",bubbleText];
        _lastGridView.bubbleText  = bubbleText;
        _lastGridView.lineStyle = solidLineStyle;
        _lastGridView.yValueColor = MIN_VALUE_COLOR;
        _minValueBubbleHasShown  = YES;
    }else if(firstValue == _maxValue && _maxValueBubbleHasShown == NO)
    {
        _lastGridView.bubbleBgImageName = MAX_VALUE_BUBLE_IMAGE;
        _lastGridView.needShowBubbleView = YES;
        //lastGridView.bubbleColor = [UIColor redColor];
        NSString *bubbleText = [NSString stringWithFormat:@"%.1f", firstValue];
        bubbleText = [NSString stringWithFormat:@"最高%@",bubbleText];
        _lastGridView.bubbleText  = bubbleText;
        _lastGridView.lineStyle = solidLineStyle;
        _lastGridView.yValueColor = MAX_VALUE_COLOR;
        _maxValueBubbleHasShown = YES;
    }
    _lastGridView.firstValue = [self pixelHeightInYAxisOfValue:firstValue  totalPixelNum:totalPixelNumInYAxis];
    _lastGridView.leftValueText = [NSString stringWithFormat:@"%.0f",firstValue];
    if ([_dataSource respondsToSelector:@selector(chartView:titleOnXAxisForIndex:)]) {
        NSString *xAxisTitle = [_dataSource chartView:self titleOnXAxisForIndex:(valueCount - 2)];
        [_lastGridView setXAxisTitle:xAxisTitle];
    }
    
    
    float secondValue = [_dataSource chartView:self valueForIndex:(valueCount - 1)];
    if (secondValue == _minValue && _minValueBubbleHasShown == NO) {
        _lastGridView.extraBubbleBgImageName = MIN_VALUE_BUBLE_IMAGE;
        _lastGridView.needShowExtraBubbleView = YES;
        NSString *bubbleText = [NSString stringWithFormat:@"%.1f", secondValue];
        bubbleText = [NSString stringWithFormat:@"最低%@",bubbleText];
        _lastGridView.extraBubbleText = bubbleText;
        _lastGridView.extraLineStyle = solidLineStyle;
        _lastGridView.extraYValueColor = MIN_VALUE_COLOR;
        _minValueBubbleHasShown = YES;
    }else if(secondValue == _maxValue && _maxValueBubbleHasShown == NO)
    {
        _lastGridView.extraBubbleBgImageName = MAX_VALUE_BUBLE_IMAGE;
        _lastGridView.needShowExtraBubbleView = YES;
        NSString *bubbleText = [NSString stringWithFormat:@"%.1f", secondValue];
        bubbleText = [NSString stringWithFormat:@"最高%@",bubbleText];
        _lastGridView.extraBubbleText = bubbleText;
        _lastGridView.extraLineStyle = solidLineStyle;
        _lastGridView.extraYValueColor = MAX_VALUE_COLOR;
        _maxValueBubbleHasShown = YES;
    }
    _lastGridView.secondValue = [self pixelHeightInYAxisOfValue:secondValue  totalPixelNum:totalPixelNumInYAxis];
    _lastGridView.rightValueText = [NSString stringWithFormat:@"%.0f",secondValue];
    if ([_dataSource respondsToSelector:@selector(chartView:titleOnXAxisForIndex:)]) {
        NSString *xAxisTitle = [_dataSource chartView:self titleOnXAxisForIndex:(valueCount - 1)];
        [_lastGridView setExtraXAxisTitle:xAxisTitle];
    }
    
    
    _lastGridView.animationDelay = (valueCount - 2) * ANIMATION_DURATION;
    //[lastGridView setXAxisTitle:@"15:00"];
    //[lastGridView setExtraXAxisTitle:@"15:00"];
    
    //lastGridView.animationDelay = i * ANIMATION_DURATION;
    [_scrollView addSubview:_lastGridView];
    [_gridViewArray addObject:_lastGridView];

}

#pragma mark - logic

-(void)findMinAndMaxValueFromDataSource
{
    _isMinOrMaxValueAtIndex0 = NO;
    _minValue = FLT_MAX;
    _maxValue = 0;
    
    unsigned int minValueIndex = INT_MIN;
    unsigned int maxValueIndex = INT_MAX;
    
    NSUInteger valueNum = [_delegate numberOfPointsInChartView:self];
    for (int i = 0; i<valueNum ; ++i) {
        float value = [_dataSource chartView:self valueForIndex:i];
        if (_minValue > value) {
            _minValue = value;
            minValueIndex = i;
        }
        if (_maxValue < value) {
            _maxValue = value;
            maxValueIndex = i;
        }
    }
    if (_maxValue == _minValue) {//所有值相等时,当做最大值处理
        _minValue = FLT_MIN;
    }
    
    if (minValueIndex == 0 || maxValueIndex == 0) {
        _isMinOrMaxValueAtIndex0 = YES;
    }
    
}

/**
 *  寻找数轴上,与num最接近且能被5整除的数(如果num能被5整除则num)
 *
 *  @param num
 *
 *  @return 与num最接近且能被5整除的数
 */
-(NSUInteger)closestNumCanBeDividedByFive:(NSUInteger)num
{
    NSUInteger mod = num % 5;
    if (mod == 0) {
        return num;
    }else if (mod > 2)
    {
        return (num - mod + 5);
    }else
    {
        return (num - mod);
    }
}

-(NSUInteger)pixelHeightInYAxisOfValue:(float)value totalPixelNum:(NSUInteger)totalPixels
{
    float deltaY = _topValueInYAxis - _bottomValueInYAxis;
    int absoluteValue = value - _bottomValueInYAxis;
    float percentageInYValueSpace = 0;
    float pixelHeight = 0;
    
    if (absoluteValue < 0) {
        percentageInYValueSpace = value / _bottomValueInYAxis;
        pixelHeight = _pixelPerRow * percentageInYValueSpace;
        
    }else if(absoluteValue == 0)
    {
        pixelHeight = _pixelPerRow;
    }else
    {
        percentageInYValueSpace = (float)(value - _bottomValueInYAxis) / deltaY;
        pixelHeight = totalPixels * percentageInYValueSpace;
        pixelHeight += _pixelPerRow;
        
    }
    
    return pixelHeight;
}

#pragma mark - layout
//参考线布局
-(void)layoutReferLineView
{
    //最小值参考线
    NSUInteger totalPixelNum = _pixelPerRow * Y_AXIS_LABEL_NUM;
    
    float minValuePixelHeight = [self pixelHeightInYAxisOfValue:_minValue totalPixelNum:totalPixelNum];
    _minLineView.frame = CGRectMake(Y_AXIS_ORIGIN_X, X_AXIS_ORIGIN_Y - minValuePixelHeight, _scrollView.frame.size.width, 1);
    
    float averageValue = (_minValue + _maxValue) / 2;
    float averageValuePixelHeight = [self pixelHeightInYAxisOfValue:averageValue totalPixelNum:totalPixelNum];
    _averageLineView.frame = CGRectMake(Y_AXIS_ORIGIN_X, X_AXIS_ORIGIN_Y - averageValuePixelHeight, _scrollView.frame.size.width, 1);
    
    float maxValuePixelHeight = [self pixelHeightInYAxisOfValue:_maxValue totalPixelNum:totalPixelNum];
    
    _maxLineView.frame = CGRectMake(Y_AXIS_ORIGIN_X, X_AXIS_ORIGIN_Y - maxValuePixelHeight, _scrollView.frame.size.width, 1);
}

-(void)refreshYAxisLabels
{
    NSUInteger startValue = [self closestNumCanBeDividedByFive:_minValue];
    startValue = (startValue < 5)? 5 : startValue;
    self.bottomValueInYAxis = startValue;
    NSUInteger valueSpace = _maxValue - _minValue;
    NSUInteger deltaY = (NSUInteger)valueSpace / 4;
    if (deltaY < 5) {
        deltaY = 5;
    }else
    {
        deltaY = [self closestNumCanBeDividedByFive:deltaY];
    }
    deltaY = [self bestDeltaYWith:deltaY startYValue:startValue];
    
    for (int i = 0; i< self.yValueLabelArray.count; ++i) {
        UILabel *label = _yValueLabelArray[i];
        label.text = [NSString stringWithFormat:@"%ld", startValue];
        startValue += deltaY;
    }
    startValue -= deltaY;
    self.topValueInYAxis = startValue;
    
    if (_maxValue > startValue) {
        _pixelPerRow = 13.5f;
    }else
    {
        _pixelPerRow = 16.0f;
    }
    
    CGRect frame = CGRectMake(0, X_AXIS_ORIGIN_Y - _pixelPerRow - (Y_LABEL_HEIGHT / 2) , 28, Y_LABEL_HEIGHT);
    for (int i = 0; i < self.yValueLabelArray.count; ++i) {
        UILabel *label = _yValueLabelArray[i];
        label.frame = frame;
        frame.origin.y -= _pixelPerRow;
    }
    
}

- (float)bestDeltaYWith:(float)deltaY startYValue:(float)startValue
{
    int num = Y_AXIS_LABEL_NUM - 1;
    while (_maxValue > (startValue + deltaY * num)) {
        deltaY += 5;
    }
    return deltaY;
}

#pragma mark- animation

-(void)playAnimation
{
    CGRect beginFrame = CGRectMake(0, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
    [_scrollView scrollRectToVisible: beginFrame animated: NO];
    for(UIView *gridView in _gridViewArray)
    {
        if ([gridView isKindOfClass:[SBChartGridView class]] ||
            [gridView isKindOfClass:[SBChartLastGridView class]]) {
            SBChartGridView *tmpGridView = (SBChartGridView *)gridView;
            [tmpGridView playAnimtion];
        }
    }
}

-(void)releaseAnimation
{
    for (SBChartGridView *gridView in _gridViewArray) {
        [gridView releaseAnimation];
    }
}

@end
