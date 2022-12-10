//
//  AddDeviceStateModel.m
//  TelinkBleExample
//
//  Created by Thanh Tùng on 05/07/2021.
//

#import <Foundation/Foundation.h>
#import "AddDeviceStateModel.h"

@implementation AddDeviceStateModel
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[AddDeviceStateModel class]]) {
        return [_peripheral.identifier.UUIDString isEqualToString:((AddDeviceStateModel *)object).peripheral.identifier.UUIDString];
    } else {
        return NO;
    }
}
@end
