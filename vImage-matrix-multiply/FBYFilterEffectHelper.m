//
//  FBYFilterEffectHelper.m
//  FullBellyIntl
//
//  Created by Samuel Cai on 14-10-8.
//
//

#import "FBYFilterEffectHelper.h"

NSString* const kFilterEffectArrayName = @"effect";
NSString* const kFilterEffectGray = @"gray";
NSString* const kFilterEffectSepia = @"sepia";
NSString* const kEffectName = @"name";

@implementation FBYFilterEffectHelper

+ (NSMutableArray *)getEffectArray:(BOOL)grayed
{
    NSMutableArray *newEffect = [[NSMutableArray alloc] init];
    if (grayed) {
        NSMutableDictionary *grayEffect = [[NSMutableDictionary alloc] init];
        [grayEffect setObject:kFilterEffectGray forKey:kEffectName];
        [newEffect addObject:grayEffect];
    }
    return newEffect;
}

+ (NSMutableArray *)toggleFilterEffect:(NSArray *)effect
{
    NSMutableArray *newEffect = [[NSMutableArray alloc] init];
    BOOL grayed = [FBYFilterEffectHelper hasGrayFilter:effect];
    BOOL sepia = [FBYFilterEffectHelper hasSepiaFilter:effect];
    if (grayed)
    {
#if SEPIA
        NSMutableDictionary *sepiaEffect = [[[NSMutableDictionary alloc] init] autorelease];
        [sepiaEffect setObject:kFilterEffectSepia forKey:kEffectName];
        [newEffect addObject:sepiaEffect];
#endif
    }
    else if (sepia)
    {
        // Make no effect, this situation
    }
    else
    {
        NSMutableDictionary *grayEffect = [[NSMutableDictionary alloc] init];
        [grayEffect setObject:kFilterEffectGray forKey:kEffectName];
        [newEffect addObject:grayEffect];
    }
    return newEffect;
}

+ (BOOL)hasGrayFilter:(NSArray *)effect
{
    if (effect.count < 1) {
        return NO;
    }
    
    BOOL grayed = NO;
    for (NSDictionary *item in effect) {
        NSString *name = [item objectForKey:kEffectName];
        if ([name isEqualToString:kFilterEffectGray]) {
            grayed = YES;
            break;
        }
    }
    return grayed;
}

+ (BOOL)hasSepiaFilter:(NSArray *)effect
{
    if (effect.count < 1) {
        return NO;
    }
    
    BOOL sepia = NO;
    for (NSDictionary *item in effect) {
        NSString *name = [item objectForKey:kEffectName];
        if ([name isEqualToString:kFilterEffectSepia]) {
            sepia = YES;
            break;
        }
    }
    return sepia;
}

+ (BOOL)isEffect:(NSArray *)effectA equalWith:(NSArray *)effectB
{
    if (effectA.count == 0 && effectB.count == 0) {
        return YES;
    }
    BOOL isEqual = NO;
    
    BOOL grayedA = [FBYFilterEffectHelper hasGrayFilter:effectA];
    BOOL sepiaA = [FBYFilterEffectHelper hasSepiaFilter:effectA];
    BOOL grayedB = [FBYFilterEffectHelper hasGrayFilter:effectB];
    BOOL sepiaB = [FBYFilterEffectHelper hasSepiaFilter:effectB];
    
    isEqual = grayedA == grayedB && sepiaA == sepiaB;
    
    return isEqual;
}

+ (CGFloat) blendFrom:(CGFloat)from to:(CGFloat)to intensity:(CGFloat)t
{
    return (from * (1-t) + to * (t));
}

+ (UIImage *)sepiaImage:(UIImage *)image
{
    CGImageRef originalImage = [image CGImage];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       CGImageGetWidth(originalImage),
                                                       CGImageGetHeight(originalImage),
                                                       8,
                                                       CGImageGetWidth(originalImage)*4,
                                                       colorSpace,
                                                       (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext)), originalImage);
    UInt8 *data = CGBitmapContextGetData(bitmapContext);
    int numComponents = 4;
    NSInteger bytesInContext = CGBitmapContextGetHeight(bitmapContext) * CGBitmapContextGetBytesPerRow(bitmapContext);
    int redIn, greenIn, blueIn, redOut, greenOut, blueOut;
    for (int i = 0; i < bytesInContext; i += numComponents)
    {
        redIn = data[i];
        greenIn = data[i+1];
        blueIn = data[i+2];
        
        redOut = (int)(redIn * 0.291) + (greenIn * 0.569) + (blueIn * 0.140);
        greenOut = (int)(redIn * 0.258) + (greenIn * 0.508) + (blueIn * 0.124);
        blueOut = (int)(redIn * 0.201) + (greenIn * 0.395) + (blueIn * 0.097);
        
        CGFloat intensity = 1.0;
        redOut = [self blendFrom:redIn to:redOut intensity:intensity];
        greenOut = [self blendFrom:greenIn to:greenOut intensity:intensity];
        blueOut = [self blendFrom:blueIn to:blueOut intensity:intensity];
        
        if (redOut>255) redOut = 255;
        if (blueOut>255) blueOut = 255;
        if (greenOut>255) greenOut = 255;
        
        data[i] = (redOut);
        data[i+1] = (greenOut);
        data[i+2] = (blueOut);
    }
    
    CGImageRef outImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage *uiImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    CGContextRelease(bitmapContext);
    return uiImage;
}

+ (UIImage *)applySepiaToImage:(UIImage *)image
{
    //UIImage *image = [[self class] applyGrayToImage:image];
    
    return [[self class] sepiaImage:image];
    
    //CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    //
    //CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
    //[filter setDefaults];
    //[filter setValue:ciImage forKey:@"inputImage"];
    //[filter setValue:[NSNumber numberWithFloat: 0.9f] forKey:@"inputIntensity"];
    //CIImage *outputImage = filter.outputImage;
    //
    //CIContext *context = [CIContext contextWithOptions: nil];
    //CGImageRef cgImage = [context createCGImage: outputImage fromRect: outputImage.extent];
    //UIImage *resultUIImage = [UIImage imageWithCGImage:cgImage];
    //CGImageRelease(cgImage);
    //[ciImage release];
    //
    //return resultUIImage;
}

+ (UIImage *)greyscaleImage:(UIImage *)image {
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, image.size.width * image.scale, image.size.height * image.scale);
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width * image.scale, image.size.height * image.scale, 8, 0, colorSpace, kCGImageAlphaNone);
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [image CGImage]);
    // Create bitmap image info from pixel data in current context
    CGImageRef grayImage = CGBitmapContextCreateImage(context);
    // release the colorspace and graphics context
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    // make a new alpha-only graphics context
    context = CGBitmapContextCreate(nil, CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage), 8, 0, nil, kCGImageAlphaOnly);
    // draw image into context with no colorspace
    CGContextDrawImage(context, imageRect, [image CGImage]);
    // create alpha bitmap mask from current context
    CGImageRef mask = CGBitmapContextCreateImage(context);
    // release graphics context
    CGContextRelease(context);
    // make UIImage from grayscale image with alpha mask
    CGImageRef cgImage = CGImageCreateWithMask(grayImage, mask);
    UIImage *grayScaleImage = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:image.imageOrientation];
    // release the CG images
    CGImageRelease(cgImage);
    CGImageRelease(grayImage);
    CGImageRelease(mask);
    // return the new grayscale image
    return grayScaleImage;
}

+ (UIImage *)greyscaleImageNew:(UIImage *)anImage type:(int)type {
    CGImageRef imageRef = anImage.CGImage;
    
    size_t width  = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    
    bool shouldInterpolate = CGImageGetShouldInterpolate(imageRef);
    
    CGColorRenderingIntent intent = CGImageGetRenderingIntent(imageRef);
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    
    UInt8 *buffer = (UInt8*)CFDataGetBytePtr(data);
    
    NSUInteger  x, y;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            UInt8 *tmp;
            tmp = buffer + y * bytesPerRow + x * 4;
            
            UInt8 red,green,blue;
            red = *(tmp + 0);
            green = *(tmp + 1);
            blue = *(tmp + 2);
            
            UInt8 brightness;
            switch (type) {
                case 1:
                    brightness = (77 * red + 28 * green + 151 * blue) / 256;
                    *(tmp + 0) = brightness;
                    *(tmp + 1) = brightness;
                    *(tmp + 2) = brightness;
                    break;
                case 2:
                    *(tmp + 0) = red;
                    *(tmp + 1) = green * 0.7;
                    *(tmp + 2) = blue * 0.4;
                    break;
                case 3:
                    *(tmp + 0) = 255 - red;
                    *(tmp + 1) = 255 - green;
                    *(tmp + 2) = 255 - blue;
                    break;
                case 4:
                    // Declare the three coefficients that model the eye's sensitivity to color.
                    // 0.2126 * 256 = 54.4256
                {
                    CGFloat scale = 1.0;
                    brightness = (54.4256 * scale * red + 183.0912 * scale * green + 18.4832 * scale * blue) / 256.0;
                    *(tmp + 0) = brightness;
                    *(tmp + 1) = brightness;
                    *(tmp + 2) = brightness;
                }
                    break;
                default:
                    *(tmp + 0) = red;
                    *(tmp + 1) = green;
                    *(tmp + 2) = blue;
                    break;
            }
        }
    }
    
    
    CFDataRef effectedData = CFDataCreate(NULL, buffer, CFDataGetLength(data));
    
    CGDataProviderRef effectedDataProvider = CGDataProviderCreateWithCFData(effectedData);
    
    CGImageRef effectedCgImage = CGImageCreate(
                                               width, height,
                                               bitsPerComponent, bitsPerPixel, bytesPerRow,
                                               colorSpace, bitmapInfo, effectedDataProvider,
                                               NULL, shouldInterpolate, intent);
    
    UIImage *effectedImage = [[UIImage alloc] initWithCGImage:effectedCgImage];
    
    CGImageRelease(effectedCgImage);
    
    CFRelease(effectedDataProvider);
    
    CFRelease(effectedData);
    
    CFRelease(data);
    
    return effectedImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    @autoreleasepool {
//        CGRect rcEdge = CGRectMake(0.f, 0.f, newSize.width, newSize.height);
//        CGRect rcImage = CGRectMake(0.f, 0.f, CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
//        rcImage = [MDPhotoSlotUtil calcProperRectWith:rcEdge and:rcImage usingOption:eFBYRect2AspectRatioScaleToFitRect1];
//        newSize = rcImage.size;
        //UIGraphicsBeginImageContext(newSize);
        // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
        // Pass 1.0 to force exact pixel size.
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
}

@end
