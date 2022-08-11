//
//  LPFGuideViewManager.m
//  BXLego
//
//  Created by lipengfei on 2020/3/7.
//

#import "LPFGuideViewManager.h"
#define kGuideTipViewMargin 0
#define kHighlightRectRadius 5

@implementation LPFGuideViewBorder
@end

@interface LPFGuideViewManager ()
{
    //TableView滚动视图需要
    UITableView * _tableView;
    NSArray * _indexPathArr;
}
//背景容器
@property (nonatomic, strong) UIView *bgView;

//背景图片，默认为半透明灰黑色
@property (nonatomic, strong) UIImageView *bgImageView;

//镜像提示图片
@property (nonatomic, strong) UIImageView *tipImageView;

//自定义提示图片
@property (nonatomic, strong) UIImageView *customImageView;

//当前提示的索引，例如0为第一个提示
@property (nonatomic, assign) NSInteger currentIndex;

//需要高亮的控件
@property (nonatomic, strong) NSArray<UIView *> *guideViewsArray;

//用来替换高亮显示的view字典（key:需要替换位置@"0" value：展示的view。如不需要替换传nil）
@property (nonatomic, strong) NSDictionary<NSString *,UIView *> *diyGuideViews;

//对应的提示图片
@property (nonatomic, strong) NSArray<NSString *> *tipImageNames;

///自定义点击button
@property (nonatomic, strong) UIButton *customClickBtn;
@end

@implementation LPFGuideViewManager

-(void)dealloc {
}

- (instancetype)initGuideManager {
    
    self = [super init];
    if (self) {
        UIView *bView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.bgView = bView;
        //添加背景遮罩图层
        UIImageView *maskImageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
        [bView addSubview:maskImageView];
        
        //添加镜像提示图片
        UIImageView *tipImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
        [bView addSubview:tipImageView];
        
        //添加自定义高亮视图
        UIImageView *customImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
        customImageView.contentMode = UIViewContentModeScaleAspectFit;
        [bView addSubview:customImageView];
        
        //自定义点击按钮
        UIButton *customClickBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        customClickBtn.frame = CGRectZero;
        [customClickBtn addTarget:self action:@selector(tap) forControlEvents:(UIControlEventTouchUpInside)];
        [bView addSubview:customClickBtn];
        
        self.customImageView = customImageView;
        self.bgImageView = maskImageView;
        self.tipImageView = tipImageView;
        self.customClickBtn = customClickBtn;
        
        self.currentIndex = 0;
        self.cornerRadius = 8.0;
        self.isGuideImageRemove = YES;
    }
    return self;
}
-(void)addGuideViews:(NSArray<UIView *> *)guideViews tipImageNames:(NSArray<NSString *> *)tipImageNames diyGuideViews:(nullable NSDictionary<NSString *,UIView *> *)diyGuideViews{
    if(guideViews.count == 0)return;
    //添加到视图
    [[UIApplication sharedApplication].keyWindow addSubview:self.bgView];
    self.guideViewsArray = guideViews;
    self.tipImageNames = tipImageNames;
    self.diyGuideViews = diyGuideViews;
    //更换背景和提示图片
    [self changeTips];
}

- (void)addGuideViewToTableView:(UITableView *)tableview tipImageNames:(NSArray<NSString *> *)tipImageNames indexPathArr:( NSArray<NSIndexPath *> *)indexPathArr {
    if(indexPathArr.count == 0 || ![tableview isKindOfClass:[UITableView class]])return;
    //添加到视图
    [[UIApplication sharedApplication].keyWindow addSubview:self.bgView];
    _tableView = tableview;
    _indexPathArr = indexPathArr;
    self.tipImageNames = tipImageNames;
    //更换背景和提示图片
    [self changeTableViewTips];
    
}
#pragma mark - 更换背景和提示图片
-(void)changeTips{
    if(self.currentIndex >= self.guideViewsArray.count || self.currentIndex >= self.tipImageNames.count ){
        [self.bgView removeFromSuperview];
        return;
    }
    UIView *tempView = (UIView *)self.guideViewsArray[self.currentIndex];
    if (![tempView isKindOfClass:[UIView class]]) {
        return;
    }
    //如果是cell需要把cell滚动到可见范围
    if ([tempView isKindOfClass:[UITableViewCell class]]) {
        UIView *view = tempView.superview;
        while (![view isKindOfClass:[UITableView class]] ) {
            view = view.superview;
            if (view == nil || [view isKindOfClass:[UITableView class]]) {
                break;
            }
        }
        UITableView *currentTableView = (UITableView *)view;
        NSIndexPath *indexPath = [currentTableView indexPathForCell:(UITableViewCell *)tempView];
        [self scrollTableView:currentTableView indexPath:indexPath];
    }
    
    //坐标转换,以提示控件的坐标原点为原点，且和提示控件一样大小（bounds）的图案在window中的位置
    CGRect rect = [tempView convertRect:tempView.bounds toView:[UIApplication sharedApplication].keyWindow];
    rect = [self handelHightLightEdge:rect];
    if (self.diyGuideViews) {
        UIView *diyView = (UIView *)self.diyGuideViews[@(self.currentIndex).stringValue];
        if (diyView && [diyView isKindOfClass:[UIView class]]) {
            CGSize diySize = diyView.frame.size;
            UIImage *diyImage = [self imageWithView:diyView];
            CGRect frame = rect;
            frame.size = diySize;
            self.customImageView.frame = frame;
            self.customImageView.center = CGPointMake(rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height/2);
            self.customImageView.image = diyImage;
            UIImage* maskImage = [self imageWithTipRect:rect tipRectRadius:self.cornerRadius];
            self.bgImageView.image = maskImage;
            
        } else {
            UIImage* originalImage = [self imageWithTipRect:rect tipRectRadius:self.cornerRadius];
            self.bgImageView.image = originalImage;
        }
    } else {
        UIImage *originalImage = [self imageWithTipRect:rect tipRectRadius:self.cornerRadius];
        self.bgImageView.image = originalImage;
    }
    
    [self adjustTipImage:rect];
    
}

- (void)changeTableViewTips {
    if(self.currentIndex >= _indexPathArr.count || self.currentIndex >= self.tipImageNames.count ){
        [self.bgView removeFromSuperview];
        return;
    }
    NSIndexPath *indexPath = (NSIndexPath *)_indexPathArr[self.currentIndex];
    if (![indexPath isKindOfClass:[NSIndexPath class]]) {
        return;
    }
    //获取高亮cell并把cell滚动到可见范围
    [self scrollTableView:_tableView indexPath:indexPath];
    //坐标转换,以提示控件的坐标原点为原点，且和提示控件一样大小（bounds）的图案在window中的位置
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    CGRect rect = [cell convertRect:cell.bounds toView:[UIApplication sharedApplication].keyWindow];
    rect = [self handelHightLightEdge:rect];
    UIImage *originalImage = [self imageWithTipRect:rect tipRectRadius:self.cornerRadius];
    self.bgImageView.image = originalImage;
    [self adjustTipImage:rect];
}
#pragma mark - Public Method
- (void)removeGuideView {
    [_bgView removeFromSuperview];
}

///高亮引导区域edge处理
- (CGRect)handelHightLightEdge:(CGRect)rect {
    NSString *edgeKey = [NSString stringWithFormat:@"%@",@(self.currentIndex)];
    if (edgeKey.length > 0) {
        NSString *edgeValue = [self.hightLightEdgeDict objectForKey:edgeKey];
        if (edgeValue.length > 0) {
            UIEdgeInsets edge = UIEdgeInsetsFromString(edgeValue);
            rect = CGRectMake(rect.origin.x + edge.left, rect.origin.y + edge.top, rect.size.width-(edge.left+edge.right), rect.size.height-(edge.top+edge.bottom));
        }
    }
    
    return rect;
}

//提示图调整添加手势
- (void)adjustTipImage:(CGRect)rect {
            
    //获取提示图片
    NSString *imgName = self.tipImageNames[self.currentIndex];
    UIImage *tipImg = [UIImage imageNamed:imgName];
    //设置提示图片
    self.tipImageView.image = tipImg;
    if (tipImg != nil) {
        //提示图片位置，可根据图片尺寸计算，与提示框居中对齐
        CGFloat tipW = tipImg.size.width;
        CGFloat tipH = tipImg.size.height;
        //中心对齐
        CGFloat tipX = rect.origin.x + (rect.size.width - tipW) * 0.5;
        CGFloat tipY = rect.origin.y + rect.size.height + kGuideTipViewMargin;
        //如果设置了自定义位置，就按照设定的位置
        if (self.tipImageLocation.count > 0) {
            [self changeTipImageViewLocation:CGRectMake(tipX, tipY, tipW, tipH) guideRect:rect];
        }else{
            //默认在下方
            self.tipImageView.frame = [self checkOverEdge:CGRectMake(tipX, tipY, tipW, tipH)];
        }
    }else{
        self.tipImageView.frame = CGRectZero;
    }
    
    //设置自定义按钮
    [self setUpCustomButton];
    
    //给遮罩添加手势，点击切换
    if (_isFullScreenRemove || tipImg == nil ) {
        UITapGestureRecognizer *bgImageGesture;
        if (!self.bgImageView.gestureRecognizers) {
             bgImageGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        }else{
            bgImageGesture = self.bgImageView.gestureRecognizers[0];
        }
        self.bgImageView.userInteractionEnabled = YES;
        [self.bgImageView addGestureRecognizer:bgImageGesture];
    } else if (_isGuideImageRemove) {
        UITapGestureRecognizer *tipImageGesture;
        if (!self.tipImageView.gestureRecognizers) {
             tipImageGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        }else{
            tipImageGesture = self.tipImageView.gestureRecognizers[0];
        }
        self.tipImageView.userInteractionEnabled = YES;
        [self.tipImageView addGestureRecognizer:tipImageGesture];
    }
    
}

//把当前index的cell滚动到屏幕可见范围
- (void)scrollTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
    CGRect rectInSuperview = [tableView convertRect:rectInTableView toView:_tableView.superview];
    CGRect tableViewFrame = tableView.frame;
    if (rectInSuperview.origin.y < tableViewFrame.origin.y) {
        //超出上面
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        return;
    }else if(rectInSuperview.origin.y + rectInSuperview.size.height > tableViewFrame.origin.y + tableViewFrame.size.height){
        //超出下面
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        
        //强制tableView往上滚，预留出自定义按钮位置
        if (self.currentIndex >= self.customButtonArr.count) {
            return;
        }
        LPFGuideCustomButtonModel * buttonModel = self.customButtonArr[self.currentIndex];
        if ([buttonModel isMemberOfClass:[LPFGuideCustomButtonModel class]]) {
            CGFloat padding = UIScreen.mainScreen.bounds.size.height - buttonModel.frame.origin.y;
            [tableView setContentOffset:CGPointMake(0, tableView.contentOffset.y + padding)];
        }
        return;
    }
    
    //如果目标cell刚好显示出来，需要预留出自定义按钮位置
    if (self.currentIndex >= self.customButtonArr.count) {
        return;
    }
    LPFGuideCustomButtonModel * buttonModel = self.customButtonArr[self.currentIndex];
    CGFloat maxTargetCellY = CGRectGetMaxY(rectInSuperview);
    if (maxTargetCellY > buttonModel.frame.origin.y) {
        CGFloat padding = maxTargetCellY - buttonModel.frame.origin.y + 25;
        [tableView setContentOffset:CGPointMake(0, tableView.contentOffset.y + padding)];
    }
    
}

//提示图片越界检查
-(CGRect)checkOverEdge:(CGRect)orginRect{
    CGFloat GuideScreenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat GuideScreenH = [UIScreen mainScreen].bounds.size.height;
    
    CGFloat tipW = orginRect.size.width;
    CGFloat tipH = orginRect.size.height;
    CGFloat tipX = orginRect.origin.x;
    CGFloat tipY = orginRect.origin.y;
    //越界计算
    tipX = tipX < 0 ? 0 : tipX;
    tipX = tipX + tipW > GuideScreenW ? GuideScreenW - tipW : tipX;
    tipY = tipY < 0 ? 0 : tipY;
    tipY = tipY + tipH > GuideScreenH ? GuideScreenH - tipH : tipY;
    //如果设置了偏移量，则根据偏移量微调
    NSString *offsetKey = [NSString stringWithFormat:@"%@",@(self.currentIndex)];
    if (offsetKey.length > 0) {
        NSString *offsetValue = [self.offsetDict objectForKey:offsetKey];
        if (offsetValue.length > 0) {
            UIOffset offset = UIOffsetFromString(offsetValue);
            tipX = tipX + offset.horizontal;
            tipY = tipY + offset.vertical;
        }
    }
    return CGRectMake(tipX, tipY, tipW, tipH);
}


/**
 改变提示图片的位置

 @param tipRect 提示图片位置
 @param guideRect 被提示的位置
 */
-(void)changeTipImageViewLocation:(CGRect)tipRect guideRect:(CGRect)guideRect{
    if(self.currentIndex >= self.tipImageLocation.count) return;
    LPFGuideTipViewPosition currentP = [self.tipImageLocation[self.currentIndex] integerValue];
    switch (currentP) {
        case LPFGuideTipViewPositionUp:{
            tipRect.origin.y = guideRect.origin.y - tipRect.size.height - kGuideTipViewMargin;
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionDown:{
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionLeft:{
            tipRect.origin.y = guideRect.origin.y + (guideRect.size.height - tipRect.size.height) * 0.5;
            tipRect.origin.x = guideRect.origin.x - tipRect.size.width - kGuideTipViewMargin;
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionRight:{
            tipRect.origin.y = guideRect.origin.y + (guideRect.size.height - tipRect.size.height) * 0.5;
            tipRect.origin.x = guideRect.origin.x +guideRect.size.width + kGuideTipViewMargin;
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionLeftUp:{
            tipRect.origin.y = guideRect.origin.y - tipRect.size.height - kGuideTipViewMargin;
            tipRect.origin.x = guideRect.origin.x + guideRect.size.width * 0.5 - tipRect.size.width;
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionLeftDown:{
            tipRect.origin.x = guideRect.origin.x + guideRect.size.width * 0.5 - tipRect.size.width;
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionRightUp:{
            tipRect.origin.y = guideRect.origin.y - tipRect.size.height - kGuideTipViewMargin;
            tipRect.origin.x = guideRect.origin.x + guideRect.size.width * 0.5;
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionRightDown:{
            tipRect.origin.x = guideRect.origin.x + guideRect.size.width * 0.5;
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionCenter:{
            tipRect.origin.y = guideRect.origin.y + (guideRect.size.height - tipRect.size.height) * 0.5;
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
        case LPFGuideTipViewPositionFullScreen:{
            self.tipImageView.frame = [UIScreen mainScreen].bounds;
        }
            break;
        default:{
            self.tipImageView.frame = [self checkOverEdge:tipRect];
        }
            break;
    }
    
}
///设置自定义button
- (void)setUpCustomButton {
    if (self.currentIndex >= self.customButtonArr.count) {
        self.customClickBtn.hidden = YES;
        return;
    }
    LPFGuideCustomButtonModel * buttonModel = self.customButtonArr[self.currentIndex];
    if (![buttonModel isMemberOfClass:[LPFGuideCustomButtonModel class]]) {
        self.customClickBtn.hidden = YES;
        return;
    }
    self.customClickBtn.hidden = NO;

    if (buttonModel.backgroundImage) {
        [self.customClickBtn setBackgroundImage:buttonModel.backgroundImage forState:UIControlStateNormal];
    } else {
        self.customClickBtn.backgroundColor = buttonModel.backgroundColor;
        self.customClickBtn.layer.cornerRadius = buttonModel.cornerRadius;
        self.customClickBtn.layer.borderColor = buttonModel.borderColor.CGColor;
        self.customClickBtn.layer.borderWidth = buttonModel.borderWidth;
        self.customClickBtn.titleLabel.font = buttonModel.font;
        [self.customClickBtn setTitleColor:buttonModel.textColor forState:UIControlStateNormal];
        [self.customClickBtn setTitle:buttonModel.title forState:UIControlStateNormal];
    }
    self.customClickBtn.frame = buttonModel.frame;
}

#pragma mark - 识别遮罩图层点击手势的回调方法
- (void)tap {
    //如果自定义tip存在隐藏当前tip
    if (self.customImageView.frame.size.width) {
        self.customImageView.frame = CGRectZero;
    }
    //如果当前展示的提示未到最后一个，继续遍历
    if ( (self.guideViewsArray && self.currentIndex < self.guideViewsArray.count - 1) || (_indexPathArr && self.currentIndex < _indexPathArr.count - 1)) {
        self.currentIndex += 1;
        //更换背景和提示图片
        if (_tableView) {
            [self changeTableViewTips];
        } else {
            [self changeTips];
        }
    }else{
        self.currentIndex = 0; //复位
        [self.bgView removeFromSuperview];
        if (self.guideFinishBlock) {
            self.guideFinishBlock();
        }
    }
}

#pragma mark - 重写set，防止设置顺序引起的异常
-(void)setBgColor:(UIColor *)bgColor{
    _bgColor = bgColor;
    if (self.guideViewsArray.count > 0 || _indexPathArr.count > 0) {
        //重新生成背景
        UIView *tempView = (UIView *)self.guideViewsArray[self.currentIndex];
        //坐标转换,以提示控件的坐标原点为原点，且和提示控件一样大小（bounds）的图案在window中的位置
        CGRect rect = [tempView convertRect:tempView.bounds toView:[UIApplication sharedApplication].delegate.window];
        //获取遮罩图形
        UIImage *maskImg = [self imageWithTipRect:rect tipRectRadius:self.cornerRadius];
        self.bgImageView.image = maskImg;
    }
}

-(void)setTipImageLocation:(NSArray *)tipImageLocation{
    _tipImageLocation = tipImageLocation;
    if (self.guideViewsArray.count > 0 || _indexPathArr.count > 0) {
        //如果设置了自定义位置，就按照设定的位置
        if (tipImageLocation.count > 0) {f
            if(self.currentIndex >= tipImageLocation.count) return;
            //如果设置了位置，首次需要刷新一下位置
            if (_tableView) {
                [self changeTableViewTips];
            } else {
                [self changeTips];
            }
        }
    }
}

-(void)setOffsetDict:(NSDictionary<NSString *,NSString *> *)offsetDict{
    _offsetDict = offsetDict;
    if (offsetDict.count > 0) {
        if ([offsetDict.allKeys containsObject:@"0"]) {
            //如果设置了偏移，第0个首次时需要刷新一下位置
            if (_tableView) {
                [self changeTableViewTips];
            } else {
                [self changeTips];
            }
        }
    }
}

-(void)setCustomButtonArr:(NSArray<LPFGuideCustomButtonModel *> *)customButtonArr{
    _customButtonArr = customButtonArr;
    if (customButtonArr.count) {
        //如果设置了自定义按钮，首次需要重置位置（避免现初始化后设置customButtonArr）
        if (self.guideViewsArray.count > 0 || _indexPathArr.count > 0) {
            [self setUpCustomButton];
        }
    }
}

-(void)setHightLightEdgeDict:(NSDictionary<NSString *,NSString *> *)hightLightEdgeDict {
    _hightLightEdgeDict = hightLightEdgeDict;
    if (hightLightEdgeDict.count > 0) {
        if ([hightLightEdgeDict.allKeys containsObject:@"0"]) {
            //如果设置edge，第0个首次时需要刷新一下位置
            if (_tableView) {
                [self changeTableViewTips];
            } else {
                [self changeTips];
            }
        }
    }
}

- (void)setIsFullScreenRemove:(BOOL)isFullScreenRemove {
    if (isFullScreenRemove == _isFullScreenRemove) {
        return;
    }
    _isFullScreenRemove = isFullScreenRemove;
    if (self.guideViewsArray.count > 0 || _indexPathArr.count > 0) {
        if (_isFullScreenRemove) {
            UITapGestureRecognizer *bgImageGesture;
            if (!self.bgImageView.gestureRecognizers) {
                bgImageGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
            }else{
                bgImageGesture = self.bgImageView.gestureRecognizers[0];
            }
            self.bgImageView.userInteractionEnabled = YES;
            [self.bgImageView addGestureRecognizer:bgImageGesture];
        } else {
            self.bgImageView.userInteractionEnabled = NO;
        }
    }
}

- (void)setIsGuideImageRemove:(BOOL)isGuideImageRemove {
    if (isGuideImageRemove == _isGuideImageRemove) {
        return;
    }
    _isGuideImageRemove = isGuideImageRemove;
    if (self.guideViewsArray.count > 0 || _indexPathArr.count > 0) {
        if (_isGuideImageRemove) {
            UITapGestureRecognizer *tipImageGesture;
            if (!self.tipImageView.gestureRecognizers) {
                 tipImageGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
            }else{
                tipImageGesture = self.tipImageView.gestureRecognizers[0];
            }
            self.tipImageView.userInteractionEnabled = YES;
            [self.tipImageView addGestureRecognizer:tipImageGesture];
        } else {
            self.tipImageView.userInteractionEnabled = NO;
        }
    }
}

#pragma mark - destinationView快照
- (UIImage *)imageWithView:(UIView *)destinationView{
   
    UIGraphicsImageRenderer *render = [[UIGraphicsImageRenderer alloc] initWithBounds:destinationView.bounds];
    return [render imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [destinationView.layer renderInContext:rendererContext.CGContext];
    }];
}

#pragma mark - 提示的遮罩背景图片
-(UIImage *)imageWithTipRect:(CGRect)tipRect tipRectRadius:(CGFloat)tipRectRadius{
    
    //开启当前的图形上下文
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, 0.0);
    
    // 获取图形上下文，画板
    CGContextRef cxtRef = UIGraphicsGetCurrentContext();
    
    //将提示框增大，并保持居中显示，默认增大尺寸为切圆角的半径，需要特殊处理改下面尺寸
    CGFloat plusSize = self.hightLightEdgeDict ? 0.0 : tipRectRadius;
    CGRect tipRectPlus = CGRectMake(tipRect.origin.x - plusSize * 0.5, tipRect.origin.y - plusSize * 0.5, tipRect.size.width + plusSize, tipRect.size.height + plusSize);
    
    ///是否存在自定义高亮边框
    LPFGuideViewBorder *highLightBorder = nil;
    if (self.currentIndex < self.hightLightBorderArr.count) {
        LPFGuideViewBorder *border = self.hightLightBorderArr[self.currentIndex];
        if (border.borderColor) {
            highLightBorder = border;
            tipRectRadius = border.cornerRadius ?: tipRectRadius;
        }
    }
    
    //绘制提示路径
    UIBezierPath *tipRectPath = [UIBezierPath bezierPathWithRoundedRect:tipRectPlus cornerRadius:tipRectRadius];
    
    //高亮边框设置
    if (highLightBorder) {
        tipRectPath.lineWidth = highLightBorder.borderWidth;
        [highLightBorder.borderColor setStroke];
        [tipRectPath stroke];
    }

    //绘制蒙版
    UIBezierPath *screenPath = [UIBezierPath bezierPathWithRect:[UIScreen mainScreen].bounds];
    
    //填充色，默认为半透明，灰黑色背景
    if (self.bgColor) {
        CGContextSetFillColorWithColor(cxtRef, self.bgColor.CGColor);
    }else{
        CGContextSetFillColorWithColor(cxtRef, [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.5].CGColor);
    }
    
    //添加路径到图形上下文
    CGContextAddPath(cxtRef, tipRectPath.CGPath);
    CGContextAddPath(cxtRef, screenPath.CGPath);
    
    //渲染，选择奇偶模式
    CGContextDrawPath(cxtRef, kCGPathEOFill);
    
    //从画布总读取图形
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    //关闭图形上下文
    UIGraphicsEndImageContext();
    
    return image;
}
@end
