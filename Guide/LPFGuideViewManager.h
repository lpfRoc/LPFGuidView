//
//  LPFGuideViewManager.h
//  BXLego
//
//  Created by lipengfei on 2020/3/7.
//

#import <Foundation/Foundation.h>
#import "LPFGuideCustomButtonModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LPFGuideTipViewPosition) {
    /// 上
    LPFGuideTipViewPositionUp,
    /// 下
    LPFTipViewPositionDown,
    /// 左
    LPFGuideTipViewPositionLeft,
    /// 右
    LPFGuideTipViewPositionRight,
    /// 左上
    LPFGuideTipViewPositionLeftUp,
    /// 左下
    LPFGuideTipViewPositionLeftDown,
    /// 右上
    LPFGuideTipViewPositionRightUp,
    /// 右下
    LPFGuideTipViewPositionRightDown,
    /// 中心对齐
    LPFGuideTipViewPositionCenter,
    /// 全屏覆盖
    LPFGuideTipViewPositionFullScreen
};
typedef void(^LPFGuideFinishBlock)(void);


@interface LPFGuideViewBorder : NSObject
/**
 高亮引导图边框宽度
*/
@property (nonatomic, assign) CGFloat borderWidth;
/**
 高亮引导图边框背景色
*/
@property (nonatomic, strong) UIColor *borderColor;
///边框圆角
@property (nonatomic, assign) CGFloat cornerRadius;
@end


@interface LPFGuideViewManager : NSObject

#pragma marek - 初始化设置

//实例方法
- (instancetype)initGuideManager;

/**
 创建遮罩提示层
 @param guideViews 需要高亮的控件数组
 @param tipImageNames 对应的提示图片数组
 @param diyGuideViews 用来替换高亮显示的view字典（key:需要替换位置 value：展示的view。如不需要替换传nil）
 */
- (void)addGuideViews:(NSArray<UIView *> *)guideViews tipImageNames:(NSArray<NSString *> *)tipImageNames diyGuideViews:(nullable NSDictionary<NSString *,UIView *> *)diyGuideViews;

/**
 @param tableview  需要引导的tableview
 @param tipImageNames 对应的提示图片数组
 @param indexPathArr 需要高亮cell的indexPath
 注：暂不支持自定义高亮cell样式。默认取真实cell，如果需要自定义后续可拓展。
 */
- (void)addGuideViewToTableView:(UITableView *)tableview tipImageNames:(NSArray<NSString *> *)tipImageNames indexPathArr:( NSArray<NSIndexPath *> *)indexPathArr;

///移除引导视图
- (void)removeGuideView;
#pragma marek - 自定义设置

/**
 * 高亮引导图边框数组
 */
@property (nonatomic, strong) NSArray<LPFGuideViewBorder *> *hightLightBorderArr;

/**
 高亮引导图圆角: 默认8.0
*/
@property (nonatomic, assign) CGFloat cornerRadius;
/**
 背景色，默认为黑色(Alpha=0.5)的背景色
*/
@property (nonatomic, strong) UIColor *bgColor;

/**
 提示图片的位置数组，放入枚举例如@[@(LPFGuideTipViewPositionUp),@(LPFGuideTipViewPositionRightDown)]
*/
@property (nonatomic, strong) NSArray<NSNumber *> *tipImageLocation;

/**
 * 提示高亮引导图位置微调；@{@"位置0,1,2..":@"{top, left, bottom, right}}
 * 以数组元素索引为key，UIEdgeInsets为value
 */
@property (nonatomic, strong) NSDictionary<NSString *,NSString *> *hightLightEdgeDict;

/**
 * 提示图片位置微调；@{@"位置0,1,2..":@"{水平偏移,竖直偏移}"}
 * 以数组元素索引为key，UIOffset(horizontal, vertical)为偏移量
 * eg:@{@"2":@"{10, -5}"}表示第3张提示图片水平方向向右偏移10，竖直防线向上偏移5
 */
@property (nonatomic, strong) NSDictionary<NSString *,NSString *> *offsetDict;

/**
 是否支持点击全屏区域移除遮罩,默认点击tip图片移除
 */
@property (nonatomic, assign) BOOL isFullScreenRemove;

/**
 是否支持点击引导图移除/切换遮罩：默认YES
 */
@property (nonatomic, assign) BOOL isGuideImageRemove;

/**
 本次引导结束回调
*/
@property (nonatomic, copy) LPFGuideFinishBlock guideFinishBlock;

/**
 自定义按钮位置相对于整个屏幕布局。（位置，titile，圆角，背景色，frame, image）
*/
@property (nonatomic, strong) NSArray<LPFGuideCustomButtonModel *> *customButtonArr;
@end

NS_ASSUME_NONNULL_END
