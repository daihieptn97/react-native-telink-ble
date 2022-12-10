//
//  AddState.h
//  TelinkBleExample
//
//  Created by Thanh Tùng on 05/07/2021.
//

#ifndef AddState_h
#define AddState_h

typedef enum : NSUInteger {
    AddStateScan,
    AddStateProvisioning,
    AddStateProvisionFail,
    AddStateKeybinding,
    AddStateKeybound,
    AddStateUnbound,
} AddState;

#endif /* AddState_h */
