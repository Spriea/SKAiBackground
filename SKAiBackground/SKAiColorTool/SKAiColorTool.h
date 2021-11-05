//
//  SKAiColorTool.h
//  SKAiBackground
//
//  Created by Somer.King on 2021/1/29.
//

#import <UIKit/UIKit.h>

#define kImgW 60  // 计算图片的大小，值越大计算越大，相应颜色越多。
NS_ASSUME_NONNULL_BEGIN

@interface SKAiColorTool : NSObject

// 根据图片获取图片的主色调,返回智能颜色数组
+ (NSMutableArray *)mostColor:(UIImage *)image;

// 根据一张图片获取图片中最多的颜色
+ (UIColor *)mostColorSingle:(UIImage*)image;

@end

NS_ASSUME_NONNULL_END
