/********************************************************************************************************
 * @file     SigBluetooth.m
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
//  SigBluetooth.m
//  TelinkSigMeshLib
//
//  Created by 梁家誌 on 2019/8/16.
//  Copyright © 2019年 Telink. All rights reserved.
//

#import "SigBluetooth.h"
#import "CBPeripheral+Extensions.h"
#import "NSData+Conversion.h"



@interface SigBluetooth ()<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic,strong) CBCentralManager *manager;
@property (nonatomic,strong,nullable) CBPeripheral *currentPeripheral;
@property (nonatomic,strong) NSMutableArray <CBPeripheral *>*connectedPeripherals;
@property (nonatomic,strong) CBCharacteristic *currentCharacteristic;
@property (nonatomic,strong) CBCharacteristic *OTACharacteristic;
@property (nonatomic,strong) CBCharacteristic *PBGATT_OutCharacteristic;
@property (nonatomic,strong) CBCharacteristic *PBGATT_InCharacteristic;
@property (nonatomic,strong) CBCharacteristic *PROXY_OutCharacteristic;
@property (nonatomic,strong) CBCharacteristic *PROXY_InCharacteristic;
@property (nonatomic,strong) CBCharacteristic *OnlineStatusCharacteristic;//私有定制，上报节点的状态的特征
@property (nonatomic,strong) CBCharacteristic *MeshOTACharacteristic;

@property (nonatomic,assign) BOOL isInitFinish;
@property (nonatomic,strong) NSMutableArray <CBUUID *>*scanServiceUUIDs;
@property (nonatomic,assign) BOOL checkNetworkEnable;
@property (nonatomic,strong) NSString *scanPeripheralUUID;

@property (nonatomic,copy) bleInitSuccessCallback bluetoothInitSuccessCallback;
@property (nonatomic,copy) bleEnableCallback bluetoothEnableCallback;
@property (nonatomic,copy) bleScanPeripheralCallback bluetoothScanPeripheralCallback;
@property (nonatomic,copy) bleScanSpecialPeripheralCallback bluetoothScanSpecialPeripheralCallback;
@property (nonatomic,copy) bleConnectPeripheralCallback bluetoothConnectPeripheralCallback;
@property (nonatomic,copy) bleDiscoverServicesCallback bluetoothDiscoverServicesCallback;
@property (nonatomic,copy) bleChangeNotifyCallback bluetoothOpenNotifyCallback;
@property (nonatomic,copy) bleReadOTACharachteristicCallback bluetoothReadOTACharachteristicCallback;
@property (nonatomic,copy) bleCancelConnectCallback bluetoothCancelConnectCallback;
@property (nonatomic,copy) bleCentralUpdateStateCallback bluetoothCentralUpdateStateCallback;
@property (nonatomic,copy) bleDisconnectCallback bluetoothDisconnectCallback;
@property (nonatomic,copy) bleIsReadyToSendWriteWithoutResponseCallback bluetoothIsReadyToSendWriteWithoutResponseCallback;
@property (nonatomic,copy) bleDidUpdateValueForCharacteristicCallback bluetoothDidUpdateValueForCharacteristicCallback;
@property (nonatomic,copy) bleDidUpdateValueForCharacteristicCallback bluetoothDidUpdateOnlineStatusValueCallback;
 
@end

@implementation SigBluetooth

+ (SigBluetooth *)share {
    static SigBluetooth *shareBLE = nil;
    static dispatch_once_t tempOnce=0;
    dispatch_once(&tempOnce, ^{
        shareBLE = [[SigBluetooth alloc] init];
        shareBLE.manager = [[CBCentralManager alloc] initWithDelegate:shareBLE queue:dispatch_get_main_queue()];
        shareBLE.isInitFinish = NO;
        shareBLE.waitScanRseponseEnabel = NO;
        shareBLE.checkNetworkEnable = NO;
        shareBLE.connectedPeripherals = [NSMutableArray array];
        shareBLE.scanServiceUUIDs = [NSMutableArray array];
    });
    return shareBLE;
}

#pragma  mark - Public

- (void)bleInit:(bleInitSuccessCallback)result {
    TeLogInfo(@"start init SigBluetooth.");
    self.bluetoothInitSuccessCallback = result;
}

- (BOOL)isBLEInitFinish {
    return self.manager.state == CBCentralManagerStatePoweredOn;
}

- (void)setBluetoothCentralUpdateStateCallback:(_Nullable bleCentralUpdateStateCallback)bluetoothCentralUpdateStateCallback {
    _bluetoothCentralUpdateStateCallback = bluetoothCentralUpdateStateCallback;
}

- (void)setBluetoothDisconnectCallback:(_Nullable bleDisconnectCallback)bluetoothDisconnectCallback {
    _bluetoothDisconnectCallback = bluetoothDisconnectCallback;
}

- (void)setBluetoothIsReadyToSendWriteWithoutResponseCallback:(bleIsReadyToSendWriteWithoutResponseCallback)bluetoothIsReadyToSendWriteWithoutResponseCallback {
    _bluetoothIsReadyToSendWriteWithoutResponseCallback = bluetoothIsReadyToSendWriteWithoutResponseCallback;
}

- (void)setBluetoothDidUpdateValueForCharacteristicCallback:(bleDidUpdateValueForCharacteristicCallback)bluetoothDidUpdateValueForCharacteristicCallback {
    _bluetoothDidUpdateValueForCharacteristicCallback = bluetoothDidUpdateValueForCharacteristicCallback;
}

- (void)setBluetoothDidUpdateOnlineStatusValueCallback:(bleDidUpdateValueForCharacteristicCallback)bluetoothDidUpdateOnlineStatusValueCallback {
    _bluetoothDidUpdateOnlineStatusValueCallback = bluetoothDidUpdateOnlineStatusValueCallback;
}

- (void)scanUnprovisionedDevicesWithResult:(bleScanPeripheralCallback)result {
//    TeLogInfo(@"");
    [self scanWithServiceUUIDs:@[[CBUUID UUIDWithString:kPBGATTService]] checkNetworkEnable:NO result:result];
}

- (void)scanProvisionedDevicesWithResult:(bleScanPeripheralCallback)result {
//    TeLogInfo(@"");
    [self scanWithServiceUUIDs:@[[CBUUID UUIDWithString:kPROXYService]] checkNetworkEnable:YES result:result];
}

/// 自定义扫描接口，checkNetworkEnable表示是否对已经入网的1828设备进行NetworkID过滤，过滤则只能扫描到当前手机的本地mesh数据里面的设备。
- (void)scanWithServiceUUIDs:(NSArray <CBUUID *>* _Nonnull)UUIDs checkNetworkEnable:(BOOL)checkNetworkEnable result:(bleScanPeripheralCallback)result {
    if (self.isInitFinish) {
        self.checkNetworkEnable = checkNetworkEnable;
        self.scanServiceUUIDs = [NSMutableArray arrayWithArray:UUIDs];
        self.bluetoothScanPeripheralCallback = result;
        [self.manager scanForPeripheralsWithServices:UUIDs options:nil];
    } else {
        TeLogError(@"Bluetooth is not power on.")
    }
}

- (void)scanMeshNodeWithPeripheralUUID:(NSString *)peripheralUUID timeout:(NSTimeInterval)timeout resultBlock:(bleScanSpecialPeripheralCallback)block {
    self.bluetoothScanSpecialPeripheralCallback = block;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scanWithPeripheralUUIDTimeout) object:nil];
        [self performSelector:@selector(scanWithPeripheralUUIDTimeout) withObject:nil afterDelay:timeout];
    });
    [self scanProvisionedDevicesWithResult:^(CBPeripheral * _Nonnull peripheral, NSDictionary<NSString *,id> * _Nonnull advertisementData, NSNumber * _Nonnull RSSI, BOOL unprovisioned) {
        if ([peripheral.identifier.UUIDString isEqualToString:peripheralUUID]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(scanWithPeripheralUUIDTimeout) object:nil];
            });
            [weakSelf stopScan];
            if (block) {
                block(peripheral,advertisementData,RSSI,YES);
            }
            weakSelf.bluetoothScanSpecialPeripheralCallback = nil;
        }
    }];
}

- (void)stopScan {
	NSLog(@"DEBUG123 stopScan Bluetooth");
    [self.scanServiceUUIDs removeAllObjects];
    self.scanPeripheralUUID = nil;
    self.bluetoothScanPeripheralCallback = nil;
    if (self.manager.isScanning) {
        TeLogVerbose(@"");
        [self.manager stopScan];

    } else {
        TeLogVerbose(@"Bluetooth is not scanning.")
    }


}

- (void)connectPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(bleConnectPeripheralCallback)block {
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        TeLogError(@"Bluetooth is not power on.")
        if (block) {
            block(peripheral,NO);
        }
        return;
    }
    if (peripheral.state == CBPeripheralStateConnected) {
        if (block) {
            block(peripheral,YES);
        }
        return;
    }
    self.bluetoothConnectPeripheralCallback = block;
    self.currentPeripheral = peripheral;
    TeLogVerbose(@"call system connectPeripheral: uuid=%@",peripheral.identifier.UUIDString);
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectPeripheralTimeout) object:nil];
        [self performSelector:@selector(connectPeripheralTimeout) withObject:nil afterDelay:timeout];
    });
    [self.manager connectPeripheral:peripheral options:nil];
}

/// if timeout is 0,means will not timeout forever.
- (void)discoverServicesOfPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(bleDiscoverServicesCallback)block {
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        TeLogError(@"Bluetooth is not power on.")
        if (block) {
            block(peripheral,NO);
        }
        return;
    }
    if (peripheral.state != CBPeripheralStateConnected) {
        TeLogError(@"peripheral is not connected.")
        if (block) {
            block(peripheral,NO);
        }
        return;
    }
    self.bluetoothDiscoverServicesCallback = block;
    self.currentPeripheral = peripheral;
    self.currentPeripheral.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(discoverServicesOfPeripheralTimeout) object:nil];
        [self performSelector:@selector(discoverServicesOfPeripheralTimeout) withObject:nil afterDelay:timeout];
    });
    [self.currentPeripheral discoverServices:nil];
}

- (void)changeNotifyToState:(BOOL)state Peripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic timeout:(NSTimeInterval)timeout resultBlock:(bleChangeNotifyCallback)block {
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        TeLogError(@"Bluetooth is not power on.")
        if (block) {
            block(peripheral,NO);
        }
        return;
    }
    if (peripheral.state != CBPeripheralStateConnected) {
        TeLogError(@"peripheral is not connected.")
        if (block) {
            block(peripheral,NO);
        }
        return;
    }
    self.bluetoothOpenNotifyCallback = block;
    self.currentPeripheral = peripheral;
    self.currentCharacteristic = characteristic;
    self.currentPeripheral.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(openNotifyOfPeripheralTimeout) object:nil];
        [self performSelector:@selector(openNotifyOfPeripheralTimeout) withObject:nil afterDelay:timeout];
    });
    [peripheral setNotifyValue:state forCharacteristic:characteristic];
}

- (void)cancelAllConnecttionWithComplete:(bleCancelAllConnectCallback)complete{
    TeLogVerbose(@"");
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        TeLogError(@"Bluetooth is not power on.")
    }
    self.bluetoothConnectPeripheralCallback = nil;
    __weak typeof(self) weakSelf = self;
    NSOperationQueue *oprationQueue = [[NSOperationQueue alloc] init];
    [oprationQueue addOperationWithBlock:^{
        //这个block语句块在子线程中执行
        NSArray *tem = [NSArray arrayWithArray:weakSelf.connectedPeripherals];
        for (CBPeripheral *p in tem) {
            if (p.state == CBPeripheralStateConnected || p.state == CBPeripheralStateConnecting) {
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                [weakSelf cancelConnectionPeripheral:p timeout:2-0.1 resultBlock:^(CBPeripheral * _Nonnull peripheral, BOOL successful) {
                    dispatch_semaphore_signal(semaphore);
                }];
                //Most provide 2 seconds to disconnect bluetooth connection
                dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 2.0));
            }
        }
        if (weakSelf.currentPeripheral) {
            [weakSelf cancelConnectionPeripheral:weakSelf.currentPeripheral timeout:2.0 resultBlock:^(CBPeripheral * _Nonnull peripheral, BOOL successful) {
                [weakSelf ressetParameters];
                weakSelf.currentPeripheral = nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (complete) {
                        complete();
                    }
                });
            }];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) {
                    complete();
                }
            });
        }
    }];
}

- (void)cancelConnectionPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(bleCancelConnectCallback)block{
    self.bluetoothCancelConnectCallback = block;
//    if (peripheral && peripheral.state != CBPeripheralStateDisconnected && peripheral.state != CBPeripheralStateDisconnecting) {
    if (peripheral && peripheral.state != CBPeripheralStateDisconnected) {
        TeLogDebug(@"cancel single connection");
        self.currentPeripheral = peripheral;
        self.currentPeripheral.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelConnectPeripheralTimeout) object:nil];
            [self performSelector:@selector(cancelConnectPeripheralTimeout) withObject:nil afterDelay:timeout];
        });
        [self.manager cancelPeripheralConnection:peripheral];
    }else{
        if (peripheral.state == CBPeripheralStateDisconnected) {
            if (self.bluetoothCancelConnectCallback) {
                self.bluetoothCancelConnectCallback(peripheral,YES);
            }
            self.bluetoothCancelConnectCallback = nil;
        }
    }
}

- (void)readOTACharachteristicWithTimeout:(NSTimeInterval)timeout complete:(bleReadOTACharachteristicCallback)complete {
    if (self.OTACharacteristic) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readOTACharachteristicTimeout) object:nil];
            [self performSelector:@selector(readOTACharachteristicTimeout) withObject:nil afterDelay:timeout];
        });
        self.bluetoothReadOTACharachteristicCallback = complete;
        [self.currentPeripheral readValueForCharacteristic:self.OTACharacteristic];
    }else{
        TeLogInfo(@"app don't found OTACharacteristic");
    }
}

- (void)cancelReadOTACharachteristic {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readOTACharachteristicTimeout) object:nil];
    });
    self.bluetoothReadOTACharachteristicCallback = nil;
}

- (CBPeripheral *)getPeripheralWithUUID:(NSString *)uuidString {
    NSMutableArray *identiferArray = [[NSMutableArray alloc] init];
    
    [identiferArray addObject:[CBUUID UUIDWithString:uuidString]];
    NSArray *knownPeripherals = [self.manager retrievePeripheralsWithIdentifiers:identiferArray];
    if (knownPeripherals.count > 0) {
        TeLogInfo(@"get peripherals from uuid:%@ count: %lu",uuidString,(unsigned long)knownPeripherals.count);
        return knownPeripherals.firstObject;
    }
    return nil;
}

- (CBCharacteristic *)getCharacteristicWithUUIDString:(NSString *)uuid OfPeripheral:(CBPeripheral *)peripheral {
    CBCharacteristic *tem = nil;
    for (CBService *s in peripheral.services) {
        for (CBCharacteristic *c in s.characteristics) {
            if ([c.UUID.UUIDString isEqualToString:uuid.uppercaseString]) {
                tem = c;
                break;
            }
        }
        if (tem != nil) {
            break;
        }
    }
    return tem;
}

- (BOOL)isWorkNormal {
    if (self.OTACharacteristic != nil && self.PBGATT_InCharacteristic != nil && self.PROXY_InCharacteristic != nil && self.PBGATT_OutCharacteristic != nil && self.PROXY_OutCharacteristic != nil) {
        return YES;
    }
    return NO;
}

#pragma mark - new gatt api since v3.2.3
- (BOOL)readCharachteristic:(CBCharacteristic *)characteristic ofPeripheral:(CBPeripheral *)peripheral {
    if (peripheral.state != CBPeripheralStateConnected) {
        TeLogError(@"peripheral is not CBPeripheralStateConnected, can't read.")
        return NO;
    }
    TeLogInfo(@"%@--->read",characteristic.UUID.UUIDString);
    self.currentPeripheral = peripheral;
    self.currentPeripheral.delegate = self;
    [self.currentPeripheral readValueForCharacteristic:characteristic];
    return YES;
}

- (BOOL)writeValue:(NSData *)value toPeripheral:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type {
    if (peripheral.state != CBPeripheralStateConnected) {
        TeLogError(@"peripheral is not CBPeripheralStateConnected, can't write.")
        return NO;
    }
    TeLogInfo(@"%@--->0x%@",characteristic.UUID.UUIDString,[LibTools convertDataToHexStr:value]);
    self.currentPeripheral = peripheral;
    self.currentPeripheral.delegate = self;
    [self.currentPeripheral writeValue:value forCharacteristic:characteristic type:type];
    return YES;
}

#pragma  mark - Private

- (void)scanWithPeripheralUUIDTimeout {
    TeLogInfo(@"peripheral connect fail.")
    if (self.currentPeripheral) {
        [self.manager cancelPeripheralConnection:self.currentPeripheral];
    }
    if (self.bluetoothScanSpecialPeripheralCallback) {
        CBPeripheral *tem = nil;
        self.bluetoothScanSpecialPeripheralCallback(tem,@{},@0,NO);
    }
    self.bluetoothScanSpecialPeripheralCallback = nil;
}

- (void)connectPeripheralFail {
    [self connectPeripheralTimeout];
}

- (void)connectPeripheralTimeout {
    if (self.currentPeripheral) {
        [self.manager cancelPeripheralConnection:self.currentPeripheral];
    }
    if (self.bluetoothConnectPeripheralCallback) {
        TeLogInfo(@"peripheral connect fail.")
        self.bluetoothConnectPeripheralCallback(self.currentPeripheral,NO);
    }
    self.bluetoothConnectPeripheralCallback = nil;
}

- (void)connectPeripheralFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectPeripheralTimeout) object:nil];
    });
    if (self.bluetoothConnectPeripheralCallback) {
        self.bluetoothConnectPeripheralCallback(self.currentPeripheral, YES);
    }
    self.bluetoothConnectPeripheralCallback = nil;
}

- (void)discoverServicesOfPeripheralTimeout {
    TeLogInfo(@"peripheral discoverServices fail.")
    if (self.bluetoothDiscoverServicesCallback) {
        self.bluetoothDiscoverServicesCallback(self.currentPeripheral,NO);
    }
    self.bluetoothDiscoverServicesCallback = nil;
}

- (void)discoverServicesFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(discoverServicesOfPeripheralTimeout) object:nil];
    });
    if (self.bluetoothDiscoverServicesCallback) {
        self.bluetoothDiscoverServicesCallback(self.currentPeripheral, YES);
    }
    self.bluetoothDiscoverServicesCallback = nil;
}

- (void)openNotifyOfPeripheralTimeout {
    TeLogInfo(@"peripheral open notify fail.")
    if (self.bluetoothOpenNotifyCallback) {
        self.bluetoothOpenNotifyCallback(self.currentPeripheral,self.currentCharacteristic.isNotifying);
    }
//    self.bluetoothOpenNotifyCallback = nil;
}

- (void)openNotifyOfPeripheralFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(openNotifyOfPeripheralTimeout) object:nil];
    });
    if (self.bluetoothOpenNotifyCallback) {
        self.bluetoothOpenNotifyCallback(self.currentPeripheral, self.currentCharacteristic.isNotifying);
    }
//    self.bluetoothOpenNotifyCallback = nil;
}

- (void)cancelConnectPeripheralTimeout {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelConnectPeripheralTimeout) object:nil];
    });
    if (self.bluetoothCancelConnectCallback && self.currentPeripheral) {
        TeLogInfo(@"cancelConnect peripheral fail.")
        self.bluetoothCancelConnectCallback(self.currentPeripheral,NO);
    }
    self.bluetoothCancelConnectCallback = nil;
}

- (void)cancelConnectPeripheralFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelConnectPeripheralTimeout) object:nil];
    });
    if (self.bluetoothCancelConnectCallback && self.currentPeripheral) {
        self.bluetoothCancelConnectCallback(self.currentPeripheral, YES);
    }
    self.bluetoothCancelConnectCallback = nil;
}

- (void)readOTACharachteristicTimeout {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readOTACharachteristicTimeout) object:nil];
    });
    if (self.bluetoothReadOTACharachteristicCallback) {
        self.bluetoothReadOTACharachteristicCallback(self.OTACharacteristic, NO);
        self.bluetoothReadOTACharachteristicCallback = nil;
    }
}

- (void)readOTACharachteristicFinish:(CBCharacteristic *)characteristic {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readOTACharachteristicTimeout) object:nil];
    });
    if (self.bluetoothReadOTACharachteristicCallback) {
        self.bluetoothReadOTACharachteristicCallback(characteristic, YES);
        self.bluetoothReadOTACharachteristicCallback = nil;
    }
}

- (void)addConnectedPeripheralToLocations:(CBPeripheral *)peripheral {
    if (![self.connectedPeripherals containsObject:peripheral]) {
        [self.connectedPeripherals addObject:peripheral];
    }
}

- (void)removeConnectedPeripheralFromLocations:(CBPeripheral *)peripheral {
    if ([self.connectedPeripherals containsObject:peripheral]) {
        [self.connectedPeripherals removeObject:peripheral];
    }
}

- (void)ressetParameters {
    self.OTACharacteristic = nil;
    self.PBGATT_InCharacteristic = nil;
    self.PBGATT_OutCharacteristic = nil;
    self.PROXY_InCharacteristic = nil;
    self.PROXY_OutCharacteristic = nil;
}

- (void)callbackDisconnectOfPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    if (self.bluetoothDisconnectCallback) {
        self.bluetoothDisconnectCallback(peripheral,error);
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
//    TeLogInfo(@"state=%ld",(long)central.state)
    if (self.manager.state == CBCentralManagerStatePoweredOn) {
        if (_isInitFinish) {
            if (self.bluetoothEnableCallback) {
                self.bluetoothEnableCallback(central,YES);
            }
        }else{
            _isInitFinish = YES;
            if (self.bluetoothInitSuccessCallback) {
                self.bluetoothInitSuccessCallback(central);
            }
            self.bluetoothInitSuccessCallback = nil;
        }
    } else {
        if (self.bluetoothEnableCallback) {
            self.bluetoothEnableCallback(central,NO);
        }
        if (self.currentPeripheral) {
            NSError *err = [NSError errorWithDomain:@"CBCentralManager.state is not CBCentralManagerStatePoweredOn!" code:-1 userInfo:nil];
            [self callbackDisconnectOfPeripheral:self.currentPeripheral error:err];
        }
//            [self stopAutoConnect];
    }
    if (self.bluetoothCentralUpdateStateCallback) {
        self.bluetoothCentralUpdateStateCallback((CBCentralManagerState)central.state);
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    // 将127修正为-90，防止APP扫描不到设备。
    if (RSSI.intValue == 127) {
        RSSI = @(-90);
//        TeLogDebug(@"将127修正为-90，防止APP扫描不到设备。peripheral.identifier.UUIDString=%@",peripheral.identifier.UUIDString);
    }
    
    /// there is invalid node when RSSI is greater than or equal to 0.
    if (RSSI.intValue >=0) {
        return;
    }
    //=================test==================//
//    if (RSSI.intValue < -50) {
//        return;
//    }
    //=================test==================//

    if (![advertisementData.allKeys containsObject:CBAdvertisementDataServiceUUIDsKey]) {
        return;
    }
    
    NSArray *suuids = advertisementData[CBAdvertisementDataServiceUUIDsKey];
    if (!suuids || suuids.count == 0) {
        return;
    }
    
    NSString *suuidString = ((CBUUID *)suuids.firstObject).UUIDString;
    /// which means the device can be add to a new mesh(没有入网)
    BOOL provisionAble = [suuidString  isEqualToString:kPBGATTService];
    /// which means the device has been add to a mesh(已经入网)
    BOOL unProvisionAble = [suuidString isEqualToString:kPROXYService];
    
    if (!provisionAble && !unProvisionAble) {
        return;
    }
    
    BOOL shouldReturn = YES;
    if (self.scanServiceUUIDs && [self.scanServiceUUIDs containsObject:[CBUUID UUIDWithString:kPBGATTService]] && provisionAble) {
        shouldReturn = NO;
    }
    if (self.scanServiceUUIDs && [self.scanServiceUUIDs containsObject:[CBUUID UUIDWithString:kPROXYService]] && unProvisionAble) {
        shouldReturn = NO;
    }
    if (shouldReturn) {
        return;
    }

	SigNodeModel *node = [SigDataSource.share getNodeWithUUID:peripheral.identifier.UUIDString];
//	NSLog(@"DEBUG123 didDiscoverPeripheral %@ - %@", node, peripheral.identifier.UUIDString);



//	SigNodeModel *node  = nil;



	NSMutableDictionary *dict = [advertisementData mutableCopy];
	NSString *mac = @"";
	if(dict != nil) {
		NSArray *data = [[dict objectForKey:CBAdvertisementDataManufacturerDataKey] toArray];

		for(int i = 7; i > 1; i--){
			NSString *dec = [data objectAtIndex:i];
			long dec1 = (long )[dec integerValue];
			NSString *hex = [NSString stringWithFormat:@"%02lX", dec1];
			mac = [mac stringByAppendingFormat:@"%@", hex];
		}
		//		NSLog(@"DEBUG1233 mac = %@ - name= %@",mac , peripheral.name);
	}

//	node = [SigDataSource.share getNodeWithMacManufacturerData:mac];
	
	if(node == nil){
		node = [SigDataSource.share getNodeWithMacManufacturerData:mac];
		if(node != nil) {
			NSLog(@"DEBUG123 getNodeWithMacManufacturerData ok %@", mac);
		}
	}






	if(node == nil){
		return;
	}

	NSLog(@"DEBUG123 didDiscoverPeripheral %@ - %@ - name: %@", [peripheral asDictionary], peripheral.identifier.UUIDString, peripheral.name);

    SigScanRspModel *scanRspModel = [[SigScanRspModel alloc] initWithPeripheral:peripheral advertisementData:advertisementData];

	TeLogInfo(@"discover RSSI:%@ uuid:%@ mac：%@ state=%@ advertisementData=%@",RSSI,peripheral.identifier.UUIDString,scanRspModel.macAddress,provisionAble?@"1827":@"1828",advertisementData);
	[SigDataSource.share updateScanRspModelToDataSource:scanRspModel];

    if ([self.delegate respondsToSelector:@selector(needToBeFilteredNodeWithSigScanRspModel:provisioned:peripheral:advertisementData:RSSI:)]) {
        BOOL result = [self.delegate needToBeFilteredNodeWithSigScanRspModel:scanRspModel provisioned:unProvisionAble peripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
        if (result) {
            return;
        }
    }
    
    //=================test==================//
//    if (![scanRspModel.macAddress.uppercaseString isEqualToString:@"A4C138E44B94"]) {
//        return;
//    }
    //=================test==================//

//    TeLogInfo(@"discover RSSI:%@ uuid:%@ mac：%@ state=%@ advertisementData=%@",RSSI,peripheral.identifier.UUIDString,scanRspModel.macAddress,provisionAble?@"1827":@"1828",advertisementData);
    BOOL shouldDelay = scanRspModel.macAddress == nil || scanRspModel.macAddress.length == 0;
    if (shouldDelay && self.waitScanRseponseEnabel) {
        TeLogVerbose(@"this node uuid=%@ has not MacAddress, dalay and return.",peripheral.identifier.UUIDString);
        return;
    }

    if (unProvisionAble && self.checkNetworkEnable) {
        scanRspModel.uuid = peripheral.identifier.UUIDString;
        BOOL isExist = [SigDataSource.share existScanRspModelOfCurrentMeshNetwork:scanRspModel];
        // 注释该逻辑，假定设备都不广播MacAddress
//        if (isExist && scanRspModel.networkIDData && scanRspModel.networkIDData.length > 0) {
//            SigNodeModel *node = [SigDataSource.share getNodeWithAddress:scanRspModel.address];
//            isExist = node != nil;
//        }
        if (!isExist) {
            return;
        }
    }

//    TeLogInfo(@"discover RSSI:%@ uuid:%@ mac：%@ state=%@ advertisementData=%@",RSSI,peripheral.identifier.UUIDString,scanRspModel.macAddress,provisionAble?@"1827":@"1828",advertisementData);
//    [SigDataSource.share updateScanRspModelToDataSource:scanRspModel];
    
    if (self.bluetoothScanPeripheralCallback) {
        self.bluetoothScanPeripheralCallback(peripheral,advertisementData,RSSI,provisionAble);
    }
    
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    TeLogInfo(@"uuid:%@",peripheral.identifier.UUIDString);
    //v3.3.0,用于过滤重复的sequenceNumber，设备连接成功则清除当前缓存的设备返回的旧的最大sequenceNumber字典。(因为所有设备断电时设备端的sequenceNumber会归零。)
    [[NSUserDefaults standardUserDefaults] setValue:@{} forKey:SigDataSource.share.meshUUID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    SigMeshLib.share.secureNetworkBeacon = nil;
    if ([peripheral isEqual:self.currentPeripheral]) {
        [self addConnectedPeripheralToLocations:peripheral];
        [self connectPeripheralFinish];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    if ([peripheral isEqual:self.currentPeripheral]) {
        [self connectPeripheralFail];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    TeLogInfo(@"peripheral=%@,error=%@",peripheral,error);

	NSLog(@"DEBUG123 didDisconnectPeripheral %@", error );

//	UIViewController *viewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
//	if ( viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed ) {
//		viewController = viewController.presentedViewController;
//	}
//
//	UIAlertController * alert = [UIAlertController
//								 alertControllerWithTitle:@"Thông báo"
//								 message:[NSString stringWithFormat:@"Ngắt kết nối tới thiết bị \n %@", error]
//								 preferredStyle:UIAlertControllerStyleAlert];
//
//
//
//	UIAlertAction* yesButton = [UIAlertAction
//								actionWithTitle:@"Ok"
//								style:UIAlertActionStyleDefault
//								handler:^(UIAlertAction * action) {
//		//Handle your yes please button action here
//	}];
//
//
//	[alert addAction:yesButton];
//
//
//
//
//	NSLayoutConstraint *constraint = [NSLayoutConstraint
//									  constraintWithItem:alert.view
//									  attribute:NSLayoutAttributeHeight
//									  relatedBy:NSLayoutRelationLessThanOrEqual
//									  toItem:nil
//									  attribute:NSLayoutAttributeNotAnAttribute
//									  multiplier:1
//									  constant:viewController.view.frame.size.height*2.0f];
//
//	[alert.view addConstraint:constraint];
//	[viewController presentViewController:alert animated:YES completion:^{}];

//	[OTAManager.share stopOTA];


    if ([peripheral isEqual:self.currentPeripheral]) {
        [self connectPeripheralFail];
        [self cancelConnectPeripheralFinish];
        [self removeConnectedPeripheralFromLocations:peripheral];
        NSArray *curNodes = [NSArray arrayWithArray:SigDataSource.share.curNodes];
        for (SigNodeModel *node in curNodes) {
            if (node.hasOpenPublish) {
                [SigPublishManager.share stopCheckOfflineTimerWithAddress:@(node.address)];
            }
        }
        [self callbackDisconnectOfPeripheral:peripheral error:error];
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    TeLogInfo(@"");
    for (CBService *s in peripheral.services) {
        [self.currentPeripheral discoverCharacteristics:nil forService:s];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    for (CBCharacteristic *c in service.characteristics) {
        [peripheral discoverDescriptorsForCharacteristic:c];
        if ([c.UUID.UUIDString isEqualToString:kOTA_CharacteristicsID]) {
            self.OTACharacteristic = c;
        }else if ([c.UUID.UUIDString isEqualToString:kPBGATT_Out_CharacteristicsID]){
            self.PBGATT_OutCharacteristic = c;
        }else if ([c.UUID.UUIDString isEqualToString:kPBGATT_In_CharacteristicsID]){
            self.PBGATT_InCharacteristic = c;
        }else if ([c.UUID.UUIDString isEqualToString:kPROXY_Out_CharacteristicsID]){
            self.PROXY_OutCharacteristic = c;
        }else if ([c.UUID.UUIDString isEqualToString:kPROXY_In_CharacteristicsID]){
            self.PROXY_InCharacteristic = c;
        }else if ([c.UUID.UUIDString isEqualToString:kOnlineStatusCharacteristicsID]){
            [peripheral setNotifyValue:YES forCharacteristic:c];//不notify一下，APP获取不到onlineState数据
            self.OnlineStatusCharacteristic = c;
        }else if ([c.UUID.UUIDString isEqualToString:kMeshOTA_CharacteristicsID]){
            self.MeshOTACharacteristic = c;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if ([peripheral isEqual:self.currentPeripheral]) {
        CBCharacteristic *lastCharacteristic = nil;
        for (CBService *s in peripheral.services) {
            if (s.characteristics && s.characteristics.count > 0) {
                lastCharacteristic = s.characteristics.lastObject;
            }
        }
        if (lastCharacteristic == characteristic) {
            [self discoverServicesFinish];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (self.bluetoothDidWriteValueCallback) {
        self.bluetoothDidWriteValueCallback(peripheral,characteristic,error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
//    TeLogInfo(@"<--- from:uuid:%@, length:%d",characteristic.UUID.UUIDString,characteristic.value.length);
    if (self.bluetoothDidUpdateValueCallback) {
        self.bluetoothDidUpdateValueCallback(peripheral,characteristic,error);
    }
    if (([characteristic.UUID.UUIDString isEqualToString:kPROXY_Out_CharacteristicsID] && SigBearer.share.isProvisioned) || ([characteristic.UUID.UUIDString isEqualToString:kPBGATT_Out_CharacteristicsID] && !SigBearer.share.isProvisioned)) {
        if ([characteristic.UUID.UUIDString isEqualToString:kPROXY_Out_CharacteristicsID]) {
            TeLogInfo(@"<--- from:PROXY, length:%d",characteristic.value.length);
//            TeLogInfo(@"<--- from:PROXY, length:%d, data:%@",characteristic.value.length,[LibTools convertDataToHexStr:characteristic.value]);
        } else {
            TeLogInfo(@"<--- from:GATT, length:%d",characteristic.value.length);
        }
        if (self.bluetoothDidUpdateValueForCharacteristicCallback) {
            self.bluetoothDidUpdateValueForCharacteristicCallback(peripheral, characteristic,error);
        }
    }
    if ([characteristic.UUID.UUIDString isEqualToString:kOTA_CharacteristicsID]) {
        if (self.bluetoothReadOTACharachteristicCallback) {
            self.bluetoothReadOTACharachteristicCallback(characteristic,YES);
            self.bluetoothReadOTACharachteristicCallback = nil;
        }
    }
    if ([characteristic.UUID.UUIDString isEqualToString:kOnlineStatusCharacteristicsID]) {
        TeLogInfo(@"<--- from:OnlineStatusCharacteristics, length:%d",characteristic.value.length);
        if (self.bluetoothDidUpdateOnlineStatusValueCallback) {
            self.bluetoothDidUpdateOnlineStatusValueCallback(peripheral, characteristic,error);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    TeLogInfo(@"uuid=%@ didUpdateNotification state=%d",characteristic.UUID.UUIDString,characteristic.isNotifying);
    if ([peripheral isEqual:self.currentPeripheral] && [characteristic isEqual:self.currentCharacteristic]) {
        [self openNotifyOfPeripheralFinish];
    }
}

//since ios 11.0
- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
//    TeLogVerbose(@"since ios 11.0,peripheralIsReadyToSendWriteWithoutResponse");
    if ([peripheral isEqual:self.currentPeripheral]) {
        if (self.bluetoothIsReadyToSendWriteWithoutResponseCallback) {
            self.bluetoothIsReadyToSendWriteWithoutResponseCallback(peripheral);
        }else{
            TeLogError(@"bluetoothIsReadyToSendWriteWithoutResponseCallback = nil.");
        }
    }
}

@end
