//
//  FBYFilterEffectHelper.h
//  FullBellyIntl
//
//  Created by Samuel Cai on 14-10-8.
//
//

#import <UIKit/UIKit.h>

extern NSString* const kFilterEffectArrayName;
extern NSString* const kFilterEffectGray;
extern NSString* const kFilterEffectSepia;
extern NSString* const kEffectName;

@interface FBYFilterEffectHelper : NSObject

+ (NSMutableArray *)getEffectArray:(BOOL)grayed;
+ (NSMutableArray *)toggleFilterEffect:(NSArray *)effect;
+ (BOOL)hasGrayFilter:(NSArray *)effect;
+ (BOOL)hasSepiaFilter:(NSArray *)effect;
+ (BOOL)isEffect:(NSArray *)effectA equalWith:(NSArray *)effectB;

+ (UIImage *)applySepiaToImage:(UIImage *)image;
//+ (UIImage *)applyGrayToImage:(UIImage *)image;
+ (UIImage *)greyscaleImage:(UIImage *)image;
+ (UIImage *)greyscaleImageNew:(UIImage *)anImage type:(int)type;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
