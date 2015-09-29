//
//  ViewController.m
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import "ViewController.h"
#import "SBChartView.h"

@interface ViewController ()<SBChartViewDataSource,SBChartViewDelegate>

@property (nonatomic, strong) SBChartView *chartView;
@property (nonatomic, strong) NSArray *chartValueArray;
@property (nonatomic, strong) UIButton *replayBtn;

@end

@implementation ViewController

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self constructDemoDataSource];
    [self constructChartView];
    [self constructBtns];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    [_chartView reloadData];
    [_chartView playAnimation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//create some data for demonstration
- (void)constructDemoDataSource
{
    if (!_chartValueArray) {
        NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:20];
        NSUInteger val = 0;
        for (int i = 0; i < 20; ++i) {
            val = arc4random()%100;
            [tmpArray addObject: @(val)];
        }
        self.chartValueArray = [NSArray arrayWithArray: tmpArray];
    }
}

- (void)constructChartView
{
    CGRect frame = CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 150);
    self.chartView = [[SBChartView alloc] initWithFrame: frame];
    _chartView.delegate = self;
    _chartView.dataSource = self;
    [self.view addSubview: _chartView];
}

- (void)constructBtns
{
    self.replayBtn = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [_replayBtn setTitle:@"play" forState: UIControlStateNormal];
    [_replayBtn setFrame: CGRectMake(0, 0, 60, 40)];
    _replayBtn.center = self.view.center;
    [_replayBtn addTarget:self action:@selector(replayBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_replayBtn setBackgroundColor: [UIColor yellowColor]];
    [self.view addSubview: _replayBtn];
}

#pragma mark - action methods

- (void)replayBtnClicked:(UIButton *)btn
{
    [_chartView playAnimation];
}

#pragma mark - SBChartViewDelegate

- (NSUInteger)numberOfPointsInChartView:(SBChartView *)chartView
{
    return _chartValueArray.count;
}

#pragma mark - SBChartViewDataSource

- (float)chartView:(SBChartView *)chartView valueForIndex:(NSUInteger)index
{
    return [_chartValueArray[index] floatValue];
}

- (NSString *)chartView:(SBChartView *)chartView titleOnXAxisForIndex:(NSUInteger)index
{
    return [NSString stringWithFormat:@"%ld", index];
}

@end
