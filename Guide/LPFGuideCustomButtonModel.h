//
//  LPFGuideCustomButtonModel.h
//
//  Created by lipengfei on 2020/10/30.
//

#import <UIKit/UIKit.h>

@interface LPFGuideCustomButtonModel : NSObject
/**
 圆角
 */
@property (nonatomic, assign) CGFloat cornerRadius;
/**
  边线颜色
 */
@property (nonatomic, strong) UIColor *borderColor;
/**
  背景颜色
 */
@property (nonatomic, strong) UIColor *backgroundColor;
/**
 边线宽度
 */
@property (nonatomic, assign) CGFloat borderWidth;
/**
 button文案
 */
@property (nonatomic, strong) NSString *title;
/**
 文案颜色
 */
@property (nonatomic, strong) UIColor *textColor;
/**
 字体大小
 */
@property (nonatomic, strong) UIFont *font;
/**
 背景图
 */
@property (nonatomic, strong) UIImage *backgroundImage;

/**
 相对屏幕位置
 */
@property (nonatomic, assign) CGRect frame;

@end
