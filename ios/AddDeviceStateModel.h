//
//  AddDeviceStateModel.h
//  TelinkBleExample
//
//  Created by Thanh Tùng on 05/07/2021.
//

#ifndef AddDeviceStateModel_h
#define AddDeviceStateModel_h

#import <CoreBluetooth/CoreBluetooth.h>
#import "AddState.h"

@interface AddDeviceStateModel : NSObject

@property (nonatomic,strong) CBPeripheral *peripheral;

@property (nonatomic,assign) AddState state;

- (BOOL)isEqual:(id)object;

@end

#endif /* AddDeviceStateModel_h */
