//
//  SKAiColorTool.m
//  SKAiBackground
//
//  Created by Somer.King on 2021/1/29.
//

#import "SKAiColorTool.h"

@implementation SKAiColorTool

//根据图片获取图片的主色调
+ (NSMutableArray *)mostColor:(UIImage*)image{
    CGSize thumbSize = CGSizeMake(kImgW, image.size.height/image.size.width*kImgW);
    
    // 1.此处缩放图片，缩小图片大小，提升计算速度
    CGFloat scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(thumbSize, NO, scale);
    [image drawInRect:CGRectMake(0, 0, thumbSize.width, thumbSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 2.将图片通过颜色空间转换为二进制数据。
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 thumbSize.width,
                                                 thumbSize.height,
                                                 8,//bits per component
                                                 thumbSize.width*4,
                                                 colorSpace,
                                                 bitmapInfo);
    
    CGRect drawRect = CGRectMake(0, 0, thumbSize.width, thumbSize.height);
    CGContextDrawImage(context, drawRect, image.CGImage);
    CGColorSpaceRelease(colorSpace);
    unsigned char* data = CGBitmapContextGetData (context);
    
    if (data == NULL){
        CGContextRelease(context);
        return nil;
    };
    
    NSUInteger LimitCount = 5; // 限制颜色数量，总颜色数量小于LimitCount则抛弃
//    NSUInteger MaxCount = 0;
    NSMutableArray *colorArr = [NSMutableArray array];// 结果数组
    
    // NSCountedSet 是主要耗时的原因，由于要计算每个颜色的数量，故采用
    NSCountedSet *moreCls = [NSCountedSet setWithCapacity:thumbSize.width*thumbSize.height*0.25];
    NSCountedSet *huarr =[NSCountedSet setWithCapacity:thumbSize.width*thumbSize.height*0.25];
    
    NSCountedSet *cls = [NSCountedSet setWithCapacity:thumbSize.width*thumbSize.height];
    
    // 3.分析二进制数据，并创建每个像素对应的颜色（图片颜色空间）
    for (int x = 0; x < thumbSize.width; x ++) {
        for (int y = 0; y < thumbSize.height; y ++) {
            int offset = 4 * (x * y);
            int red = data[offset];
            int green = data[offset+1];
            int blue = data[offset+2];
            int alpha =  data[offset+3];
        
            // 过滤掉白色
            if (red!=255 & green!=255 & blue!=255) {
                NSArray *clr = @[@(red),@(green),@(blue),@(alpha)];
                // 当前颜色数量超过限制后，不再加入cls集合，如果需要计算最多颜色数量，则需要加入每一个大于LimitCount的颜色
                if ([cls containsObject:clr] >= LimitCount)continue;
                [cls addObject:clr];
            }
        }
    }
    
    // 4.取色算法，计算颜色数组
    NSArray *curColor = nil;
    NSUInteger tempcount = 0;
    NSEnumerator *enumerator = [cls objectEnumerator];
    // 4.1除去重复颜色，获取单一颜色数组
    while ((curColor = [enumerator nextObject]) != nil ){
        if ([moreCls containsObject:curColor] > 0) continue;
        tempcount = [cls countForObject:curColor];
        if (tempcount < LimitCount) continue;
//        if (tempcount > MaxCount) {
//            MaxCount = tempcount;
//            MaxColor = curColor;
//        }
        [moreCls addObject:curColor];
    }
    
    // 4.2除去相近颜色算法。
    NSArray *currentH = nil;
    enumerator = [moreCls objectEnumerator];
    while ((curColor = [enumerator nextObject]) != nil ){
        int red = [curColor[0] intValue];
        int green = [curColor[1] intValue];
        int blue = [curColor[2] intValue];
    //        int alpha =  [curColor[3] intValue];
        
        // RGB转HSV算法
        CGFloat max = MAX(MAX(red, blue), green);
        CGFloat min = MIN(MIN(red, blue), green);
        CGFloat hue = 0,s,value;
        value = max;
        s     = (max-min)/max;
        if (red == max) hue = (green-blue)/(max-min)* 60;
        if (green == max) hue = 120+(blue-red)/(max-min)* 60;
        if (blue == max) hue = 240 +(red-green)/(max-min)* 60;
        if (hue < 0) hue = hue + 360;

        NSEnumerator *moreenur = [huarr objectEnumerator];
        BOOL isAdd = YES;
        // HSV模型可参考https://baike.baidu.com/item/HSV/547122?fr=aladdin
        while ((currentH = [moreenur nextObject]) != nil ){
            // 抛弃灰白色，和暗黑色颜色，可参考HSV模型
            if (s > 0.2 && value > 0.3*255) {
                if (value < 0.5*255) { // 根据value大小抛弃范围不同
                    // 抛弃某一个颜色周围的相近颜色
                    if (fabs(hue-[currentH[0] floatValue]) < 180 && fabs(s-[currentH[1] floatValue])*255 < 125 && fabs(value-[currentH[2] floatValue]) < 0.5*255) {
                        isAdd = NO;
                        break;
                    }
                }else{
                    // 抛弃某一个颜色周围的相近颜色
                    if (fabs(hue-[currentH[0] floatValue]) < 20 && fabs(s-[currentH[1] floatValue])*255 < 25 && fabs(value-[currentH[2] floatValue]) < 25) {

                        isAdd = NO;
                        break;
                    }
                }
            }else{
                isAdd = NO;
            }
        }

        if (isAdd) {
            // 确认的颜色HSV转RGB算法。注意，直接用RGB颜色部分颜色会出问题，建议还是再转换一次。
            [huarr addObject:@[@(hue),@(s),@(value)]];
            if (s == 0)
            red = green = blue = value;
            else{
            hue /= 60;
            int i = hue;
            CGFloat f = hue - i;
            CGFloat a = value * ( 1 - s );
            CGFloat b = value * ( 1 - s * f );
            CGFloat c = value * ( 1 - s * (1 - f ) );
                switch (i) {
                    case 0: red = value; green = c; blue = a;
                        break;
                    case 1: red = b; green = value; blue = a;
                        break;
                    case 2: red = a; green = value; blue = c;
                        break;
                    case 3: red = a; green = b; blue = value;
                        break;
                    case 4: red = c; green = a; blue = value;
                        break;
                        case 5: red = value; green = a; blue = b;
                    default:
                        break;
                }
            }
            UIColor *c = [UIColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:([curColor[3] intValue]/255.0f)];
            [colorArr addObject:c];
        }
    }
    
    return colorArr;
}


//根据图片获取图片的主色调
+ (UIColor *)mostColorSingle:(UIImage*)image{
    CGSize thumbSize = CGSizeMake(kImgW, image.size.height/image.size.width*kImgW);
    
    // 1.此处缩放图片，缩小图片大小，提升计算速度
    CGFloat scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(thumbSize, NO, scale);
    [image drawInRect:CGRectMake(0, 0, thumbSize.width, thumbSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 2.将图片通过颜色空间转换为二进制数据。
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 thumbSize.width,
                                                 thumbSize.height,
                                                 8,//bits per component
                                                 thumbSize.width*4,
                                                 colorSpace,
                                                 bitmapInfo);
    
    CGRect drawRect = CGRectMake(0, 0, thumbSize.width, thumbSize.height);
    CGContextDrawImage(context, drawRect, image.CGImage);
    CGColorSpaceRelease(colorSpace);
    unsigned char* data = CGBitmapContextGetData (context);
    
    if (data == NULL){
        CGContextRelease(context);
        return nil;
    };
    
    NSUInteger LimitCount = 10; // 限制颜色数量，总颜色数量小于LimitCount则抛弃
    NSCountedSet *cls = [NSCountedSet setWithCapacity:thumbSize.width*thumbSize.height];
    
    // 3.分析二进制数据，并创建每个像素对应的颜色（图片颜色空间）
    for (int x = 0; x < thumbSize.width; x ++) {
        for (int y = 0; y < thumbSize.height; y ++) {
            int offset = 4 * (x * y);
            int red = data[offset];
            int green = data[offset+1];
            int blue = data[offset+2];
            int alpha =  data[offset+3];
        
            // 过滤掉白色
            if (red!=255 & green!=255 & blue!=255) {
                NSArray *clr = @[@(red),@(green),@(blue),@(alpha)];
                // 当前颜色数量超过限制后，不再加入cls集合，如果需要计算最多颜色数量，则需要加入每一个大于LimitCount的颜色
                if ([cls containsObject:clr] >= LimitCount)continue;
                [cls addObject:clr];
            }
        }
    }
    CGContextRelease(context);
   NSEnumerator *enumerator = [cls objectEnumerator];
   NSArray *curColor = nil;
   NSArray *MaxColor=nil;
   NSUInteger MaxCount=0;
   while ( (curColor = [enumerator nextObject]) != nil ){
       NSUInteger tmpCount = [cls countForObject:curColor];
       if (tmpCount < MaxCount) continue;
        MaxCount=tmpCount;
        MaxColor=curColor;
    }
    
    return [UIColor colorWithRed:([MaxColor[0]intValue]/255.0f)green:([MaxColor[1]intValue]/255.0f)blue:([MaxColor[2]intValue]/255.0f)alpha:([MaxColor[3]intValue]/255.0f)];
    
}

@end
