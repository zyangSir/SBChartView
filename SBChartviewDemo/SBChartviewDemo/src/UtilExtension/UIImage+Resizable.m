//
//  UIImage+Resizable.m
//  SBChartviewDemo
//
//  Created by Yangtsing.Zhang on 15/9/25.
//  Copyright © 2015年 SingBird. All rights reserved.
//

#import "UIImage+Resizable.h"

@implementation UIImage (Resizable)

- (UIImage *) resizableImageInCenter
{
    float left = (self.size.width)/2;//The middle points rarely vary anyway
    float top = (self.size.height)/2;
    
    if ([self respondsToSelector:@selector(resizableImageWithCapInsets:)])
    {
        return [self resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, top, left)];
    }
    else
    {
        return [self stretchableImageWithLeftCapWidth:left topCapHeight:top];
    }
}

@end
