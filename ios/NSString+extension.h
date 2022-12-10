/********************************************************************************************************
 * @file     NSString+extension.h
 *
 * @brief    for TLSR chips
 *
 * @author     telink
 * @date     Sep. 30, 2010
 *
 * @par      Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 *           All rights reserved.
 *
 *             The information contained herein is confidential and proprietary property of Telink
 *              Semiconductor (Shanghai) Co., Ltd. and is available under the terms
 *             of Commercial License Agreement between Telink Semiconductor (Shanghai)
 *             Co., Ltd. and the licensee in separate contract or the terms described here-in.
 *           This heading MUST NOT be removed from this file.
 *
 *              Licensees are granted free, non-transferable use of the information in this
 *             file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided.
 *
 *******************************************************************************************************/
//
//  NSString+extension.h
//  SigMeshOCDemo
//
//  Created by 梁家誌 on 2018/8/2.
//  Copyright © 2018年 Telink. All rights reserved.
//

#ifndef NSString_extension_h
#define NSString_extension_h

#import <Foundation/Foundation.h>

@interface NSString (extension)

/*
 * Remove leading and trailing spaces
 */
- (NSString*)removeHeadAndTailSpaces;

/*
 * Remove leading and trailing spaces, including the following newline \n
 */
- (NSString*)removeHeadAndTailSpacesPro;

/*
 * Remove all spaces
 */
- (NSString*)removeAllSpaces;

/*
 * Remove all spaces and the final carriage return
 */
- (NSString *)removeAllSpacesAndNewLines;

/// Remove all spaces and the last carriage return, and add "0" in front of the string to meet the length length
/// @param length The length of the string to be returned, if it is greater than this length, it will be returned directly, without adding "0"
- (NSString*)formatToLength:(UInt8)length;

/*
 * Add m spaces between n characters in a loop
 */
- (NSString*)insertSpaceNum:(int)spaceNum charNum:(int)charNum;

/// Convert JSON string to dictionary
+ (NSDictionary*)dictionaryWithJsonString:(NSString *)jsonString;

@end

#endif /* NSString_extension_h */
