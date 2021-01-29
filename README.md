# SKAiBackground
#前言
 >实现：根据一张输入的图片，获取图片上的所有像素分析，并计算出一个颜色数组。具体步骤有：
输入图片→图片转换→颜色获取→颜色筛选→我们要的颜色数组
[简书地址](https://www.jianshu.com/p/9001d6f5508e)

#####Demo展示
![demo.jpg](https://upload-images.jianshu.io/upload_images/2013062-a2ba21345dec9062.jpg?imageMogr2/auto-orient/strip|imageView2/2/w/512)

##输入图片
输入图片后，由于图片太大，所有我们先将图片进行缩放操作，减少计算量。

```
// 1.此处缩放图片，缩小图片大小，提升计算速度
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize thumbSize = CGSizeMake(kImgW, image.size.height/image.size.width*kImgW);
    UIGraphicsBeginImageContextWithOptions(thumbSize, NO, scale);
    [image drawInRect:CGRectMake(0, 0, thumbSize.width, thumbSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
```
##图片转换
我们要计算图片，需要将图片像素通过颜色空间转换为二进制数据，再将二进制数据转换为颜色，从而获取到这张图片的所有颜色数据。
```
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
    if (data == NULL) return nil;
```
##颜色获取
从获取到的二进制data数据中分别生成对应颜色，并通过LimitCount（现在颜色重复限制），去除颜色过少的颜色，并获得大于等于LimitCount数量的颜色。下一步，我们将除去重复颜色以及相近颜色。
```
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
```
##除去颜色
>去除颜色我们分两步，上一步获取到的颜色，在数组中，每一种颜色数量都是LimitCount。我们先去除重复的颜色。
#####1.颜色去重
```
    NSArray *curColor = nil;
    NSUInteger tempcount = 0;
    NSEnumerator *enumerator = [cls objectEnumerator];
    // 4.1除去重复颜色，获取单一颜色数组
    while ((curColor = [enumerator nextObject]) != nil ){
        if ([moreCls containsObject:curColor] > 0) continue;
        tempcount = [cls countForObject:curColor];
        if (tempcount < LimitCount) continue;
        [moreCls addObject:curColor];
    }
```
#####2.颜色去重
>到这一步，我们就可以根据自己的项目需求再次剔除颜色，获取我们想要的颜色结果了。
这一步，我们首先需要了解HSV颜色空间模型，这样我们才能更好的筛选出我们想要的颜色。
![HSV颜色空间模型](https://upload-images.jianshu.io/upload_images/2013062-ae176d6067d08553.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
观察模型，我们发现Value值较小的全是黑色的。Saturation值较小的全是白色灰色，所有我们首先去除的就是这类颜色。
然后，某一个颜色的立体颜色，周围都是相近的颜色，我们也需要剔除，具体代码如下。
```
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
```
