//
//  ViewController.m
//  SKAiBackground
//
//  Created by Somer.King on 2021/1/29.
//

#import "ViewController.h"
#import "SKAiColorTool.h"

#define kTagIndex 1000
#define kSCALE_X(x) (([UIScreen mainScreen].bounds.size.width/375.f)*x) // 适配屏幕
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *choseImg;
@property (weak, nonatomic) IBOutlet UIScrollView *contentV;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;

@property (strong, nonatomic) NSMutableArray *colorArr;
@property (strong, nonatomic) NSMutableArray *aiColorArr;

@end

@implementation ViewController

#pragma mark - 从相册选择图片
- (IBAction)choseImage:(UIButton *)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - 选中某一个颜色
- (void)aiColorClick:(UIButton *)sender{
    // 移除上次添加的渐变色
    for (CALayer *subLayer in self.view.layer.sublayers) {
        if ([subLayer isKindOfClass:[CAGradientLayer class]]) {
            [subLayer removeFromSuperlayer];
            break;
        }
    }
    if (sender.tag >= kTagIndex) {// 渐变色
        NSArray *colorA = self.aiColorArr[sender.tag-kTagIndex];
        [self setupGridColor:self.view colorArr:colorA];
    }else{ // 单色
        self.view.backgroundColor = self.colorArr[sender.tag];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.choseImg.contentMode = UIViewContentModeScaleAspectFit;
    self.loading.hidden = YES;
    self.choseImg.image =  [UIImage imageNamed:@"601611904045_.pic_hd.jpg"];
    [self setupAiColor:self.choseImg.image];
}

#pragma mark - 获取到图片开始计算颜色数组，并绘制颜色
- (void)setupAiColor:(UIImage *)image{
    self.loading.hidden = NO;
    self.view.userInteractionEnabled = NO;
    [self.loading startAnimating];
    
    // 由于计算颜色耗时，需要异步执行，可响应修改算法，改变耗时时间。
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        weakSelf.colorArr = [SKAiColorTool mostColor:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.loading stopAnimating];
            weakSelf.loading.hidden = YES;
            weakSelf.view.userInteractionEnabled = YES;
            [weakSelf setupColorView];
        });
    });
}

#pragma mark - 初始化颜色组
- (void)setupColorView{
    for (UIView *tempV in self.contentV.subviews) {
        [tempV removeFromSuperview];
    }
    // 绘制单色组。
    for (int i = 0; i < self.colorArr.count; i ++) {
        UIButton *cellBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cellBtn.frame = CGRectMake(kSCALE_X(10)+i*kSCALE_X(46), kSCALE_X(3), kSCALE_X(28), kSCALE_X(28));
        cellBtn.layer.cornerRadius = kSCALE_X(14);
        [self.contentV addSubview:cellBtn];
        UIColor *bgC = self.colorArr[i];
        cellBtn.backgroundColor = bgC;
        cellBtn.tag = i;
        [cellBtn addTarget:self action:@selector(aiColorClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // 遍历计算量量颜色组成，渐变色。
    NSMutableArray *smartArr = [NSMutableArray array];
    for (int i = 0; i < self.colorArr.count; i ++) {
        UIColor *tempC = self.colorArr[i];
        int index = i + 2;
        if (index >= self.colorArr.count) {
            break;
        }

        UIColor *towC = self.colorArr[index];
        [smartArr addObject:@[tempC,towC]];
        if (index > i + 1) {
            UIColor *addC = self.colorArr[index-1];
            [smartArr addObject:@[addC,towC]];
        }
    }
    
    // 绘制渐变色组
    self.aiColorArr = smartArr;
    for (int i = 0; i < self.aiColorArr.count; i ++) {
        UIButton *cellBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cellBtn.frame = CGRectMake(kSCALE_X(10)+i*kSCALE_X(46), kSCALE_X(40), kSCALE_X(28), kSCALE_X(28));
        cellBtn.layer.cornerRadius = kSCALE_X(14);
        [self.contentV addSubview:cellBtn];
        NSArray *bgCArr = self.aiColorArr[i];
        cellBtn.tag = i+kTagIndex;
        [cellBtn addTarget:self action:@selector(aiColorClick:) forControlEvents:UIControlEventTouchUpInside];
        [self setupGridColor:cellBtn colorArr:bgCArr];
        
        if (i == self.aiColorArr.count-1) {
            self.contentV.contentSize = CGSizeMake(cellBtn.frame.origin.x+cellBtn.frame.size.width + kSCALE_X(15), 0);
        }
    }
}

/// 绘制渐变layer
/// @param contentV 需要绘制的View
/// @param colorA 渐变色数组
- (void)setupGridColor:(UIView *)contentV colorArr:(NSArray *)colorA{
    UIColor *fromColor = colorA[0],*toColor = colorA[1];
    CAGradientLayer *grad1 = [CAGradientLayer layer];
    grad1.colors = @[(__bridge id)fromColor.CGColor, (__bridge id)toColor.CGColor];
    grad1.locations = @[@0, @1.0];
    grad1.startPoint = CGPointMake(0, -0.5);
    grad1.endPoint = CGPointMake(0, 1.5);
    grad1.frame = contentV.bounds;
    grad1.cornerRadius = contentV.layer.cornerRadius;
    [contentV.layer insertSublayer:grad1 atIndex:0];
}

//获取到图片
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.choseImg.image = image;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self setupAiColor:image];
}

- (NSMutableArray *)colorArr{
    if (!_colorArr) {
        _colorArr = [NSMutableArray array];
    }
    return _colorArr;
}
@end
