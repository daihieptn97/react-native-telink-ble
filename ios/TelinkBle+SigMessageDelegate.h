//
//  TelinkBle+SigMessageDelegate.h
//  TelinkBle
//
//  Created by Thanh Tùng on 09/10/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#ifndef TelinkBle_SigMessageDelegate_h
#define TelinkBle_SigMessageDelegate_h

#import "TelinkBle.h"

@interface TelinkBle (SigMessageDelegate)

- (NSString* _Nullable)getUUIDFromMeshAddress:(UInt16)meshAddress;

@end


#endif /* TelinkBle_SigMessageDelegate_h */
