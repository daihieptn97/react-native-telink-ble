#import <TelinkSigMeshLib/TelinkSigMeshLib.h>
#import <UIKit/UIImage.h>
#import <React/RCTBridgeModule.h>
#import "TelinkBle.h"
#import "DemoCommand.h"
#import "NSString+extension.h"
#import "NSData+Conversion.h"
#import "SigDataSource.h"

@implementation TelinkBle

RCT_EXPORT_MODULE(TelinkBle)

RCT_EXTERN_METHOD(getNodes:(RCTPromiseResolveBlock _Nonnull)resolve withRejecter:(RCTPromiseRejectBlock _Nonnull)reject)

RCT_EXTERN_METHOD(sendRawString:(nonnull NSString*)command)

RCT_EXTERN_METHOD(stopScanning)

RCT_EXTERN_METHOD(autoConnect)

RCT_EXTERN_METHOD(setStatus:(nonnull NSNumber*)meshAddress withStatus:(nonnull NSNumber*)status)

RCT_EXTERN_METHOD(setBrightness:(nonnull NSNumber*)meshAddress withBrightness:(nonnull NSNumber*)brightness)

RCT_EXTERN_METHOD(setTemperature:(nonnull NSNumber*)meshAddress withTemperature:(nonnull NSNumber*)temperature)

RCT_EXTERN_METHOD(setHSL:(nonnull NSNumber*)meshAddress withHSL:(nonnull NSDictionary*)hsl)

RCT_EXTERN_METHOD(addDeviceToGroup:(nonnull NSNumber*)deviceAddress withGroupAddress:(nonnull NSNumber*)groupAddress)

RCT_EXTERN_METHOD(removeDeviceFromGroup:(nonnull NSNumber*)deviceAddress withGroupAddress:(nonnull NSNumber*)groupAddress)

RCT_EXTERN_METHOD(resetNode:(nonnull NSNumber*)deviceAddress);

RCT_EXTERN_METHOD(recallScene:(nonnull NSNumber*)sceneAddress);

RCT_EXTERN_METHOD(setDelegateForIOS)

RCT_EXTERN_METHOD(getOnlineState)

RCT_EXTERN_METHOD(startAddingAllDevices)

RCT_EXTERN_METHOD(openBluetoothSubSetting)

RCT_EXPORT_METHOD(getMeshNetwork:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    SigAppkeyModel* appKeyModel = SigDataSource.share.curAppkeyModel;
    SigNetkeyModel* netKeyModel = SigDataSource.share.curNetkeyModel;

    NSString* appKey = appKeyModel.key;
    NSString* netKey = netKeyModel.key;

    if (appKey && netKey) {
        resolve(@{
            @"appKey": appKey,
            @"netKey": netKey,
        });
    } else {
        reject(@"get_mesh_network_failure", @"no mesh network information returned", nil);
    }
}

RCT_EXPORT_METHOD(getMeshNetworkString:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    NSDictionary *jsonDict = [SigDataSource.share getFormatDictionaryFromDataSource];
    NSString* jsonString = [LibTools getJSONStringWithDictionary:jsonDict];
    
    if (jsonString) {
        resolve(jsonString);
    } else {
        reject(@"get_mesh_network_string_failure", @"no mesh network string information returned", nil);
    }
}

RCT_EXPORT_METHOD(resetMeshNetwork:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
//    AppKey
    SigAppkeyModel *appKey = [[SigAppkeyModel alloc] init];
    appKey.oldKey = @"00000000000000000000000000000000";
    appKey.key = [LibTools convertDataToHexStr:[LibTools initAppKey]];
    appKey.index = 0;
    appKey.name = [NSString stringWithFormat:@"appkey%ld",(long)appKey.index];
    appKey.boundNetKey = SigDataSource.share.curNetkeyModel.index;
    SigDataSource.share.curAppkeyModel = appKey;

//    NetKey
    NSString *timestamp = [LibTools getNowTimeStringOfJson];
    SigNetkeyModel *netKey = [[SigNetkeyModel alloc] init];
    netKey.index = 0;
    netKey.phase = 0;
    netKey.timestamp = timestamp;
    netKey.oldKey = @"00000000000000000000000000000000";
    netKey.key = [LibTools convertDataToHexStr:[LibTools createNetworkKey]];
    netKey.name = [NSString stringWithFormat:@"netkey%ld",(long)netKey.index];
    netKey.minSecurity = @"secure";
    SigDataSource.share.curNetkeyModel = netKey;


    if (appKey && netKey) {
        resolve(@{
            @"appKey": appKey,
            @"netKey": netKey,
        });
    } else {
        reject(@"reset_mesh_network_failure", @"no mesh network information returned", nil);
    }
}

RCT_EXPORT_METHOD(exportMeshNetwork:(NSString*)database
                  resolve:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    NSDate *date = [NSDate date];
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy_MM_dd-HH_mm_ss";
    f.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"vn_VN"];
    NSString *dstr = [f stringFromDate:date];
    NSString *jsonName = [NSString stringWithFormat:@"mesh-%@.json",dstr];

    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:jsonName];

    NSFileManager *manager = [[NSFileManager alloc] init];
    BOOL exist = [manager fileExistsAtPath:path];
    if (!exist) {
        BOOL ret = [manager createFileAtPath:path contents:nil attributes:nil];
        if (ret) {
            NSDictionary *jsonDict = [SigDataSource.share getFormatDictionaryFromDataSource];
            NSDictionary *jsonDatabase = [LibTools getDictionaryWithJsonString:database];

            NSMutableDictionary * exportDic = [jsonDict mutableCopy];
            [exportDic addEntriesFromDictionary:jsonDatabase];

            NSData *tempData = [LibTools getJSONDataWithDictionary:exportDic];

            NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
            [handle truncateFileAtOffset:0];
            [handle writeData:tempData];
            [handle closeFile];

            NSString *tipString = [NSString stringWithFormat:@"export %@ success!",jsonName];
            resolve(@{
                @"fileName": jsonName,
                @"filePath": path,
            });
            TeLogDebug(@"%@",tipString);
        } else {
            NSString *tipString = [NSString stringWithFormat:@"export %@ fail!",jsonName];
            reject(@"export_failure", tipString, nil);
            TeLogDebug(@"%@",tipString);
        }
    }
}

RCT_EXPORT_METHOD(importMeshNetworkIOS:(NSString*)fileContent
                  resolve:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    if(fileContent != nil) {
        NSString* name = @"mesh.json";

        NSOperationQueue *operation = [[NSOperationQueue alloc] init];

        [operation addOperationWithBlock:^{
            NSString *str = fileContent;

            NSString *oldMeshUUID = SigDataSource.share.meshUUID;
            NSDictionary *dict = [LibTools getDictionaryWithJsonString:str];
            [SigDataSource.share setDictionaryToDataSource:dict];
            BOOL result = dict != nil;
            if (result) {
                NSString *tipString = [NSString stringWithFormat:@"import %@ success!",name];
                resolve(@(true));
                TeLogDebug(@"%@",tipString);

            } else {
                NSString *tipString = [NSString stringWithFormat:@"import %@ fail!",name];
                reject(@"import_failure", tipString, nil);
                TeLogDebug(@"%@",tipString);
                return;
            }

            BOOL needChangeProvisionerAddress = NO;//修改手机本地节点的地址
            BOOL reStartSequenceNumber = NO;//修改手机本地节点使用的发包序列号sno
            BOOL hasPhoneUUID = NO;
            NSString *curPhoneUUID = [SigDataSource.share getCurrentProvisionerUUID];
            NSArray *provisioners = [NSArray arrayWithArray:SigDataSource.share.provisioners];
            for (SigProvisionerModel *provision in provisioners) {
                if ([provision.UUID isEqualToString:curPhoneUUID]) {
                    hasPhoneUUID = YES;
                    break;
                }
            }
            if (hasPhoneUUID) {
                // v3.1.0, 存在
                BOOL isSameMesh = [SigDataSource.share.meshUUID isEqualToString:oldMeshUUID];
                if (isSameMesh) {
                    // v3.1.0, 存在，且为相同mesh网络，覆盖JSON，且使用本地的sno和ProvisionerAddress
                    needChangeProvisionerAddress = NO;
                    reStartSequenceNumber = NO;
                } else {
                    // v3.1.0, 存在，但为不同mesh网络，获取provision，修改为新的ProvisionerAddress，sno从0开始
                    needChangeProvisionerAddress = YES;
                    reStartSequenceNumber = YES;
                }
            } else {
                // v3.1.0, 不存在，覆盖并新建provisioner
                needChangeProvisionerAddress = NO;
                reStartSequenceNumber = YES;
            }

            //重新计算sno
            if (reStartSequenceNumber) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentMeshProvisionAddress_key];
                [SigDataSource.share setLocationSno:0];
            }

            UInt16 maxAddr = SigDataSource.share.curProvisionerModel.allocatedUnicastRange.firstObject.lowIntAddress;
            NSArray *nodes = [NSArray arrayWithArray:SigDataSource.share.nodes];
            for (SigNodeModel *node in nodes) {
                NSInteger curMax = node.address + node.elements.count - 1;
                if (curMax > maxAddr) {
                    maxAddr = curMax;
                }
            }
            if (needChangeProvisionerAddress) {
                //修改手机的本地节点的地址
                UInt16 newProvisionAddress = maxAddr + 1;
                [SigDataSource.share changeLocationProvisionerNodeAddressToAddress:newProvisionAddress];
                TeLogDebug(@"已经使用了address=0x%x作为本地地址",newProvisionAddress);
                //修改下一次添加设备使用的地址
                [SigDataSource.share saveLocationProvisionAddress:maxAddr + 1];
            } else {
                //修改下一次添加设备使用的地址
                [SigDataSource.share saveLocationProvisionAddress:maxAddr];
            }
            TeLogDebug(@"下一次添加设备可以使用的地址address=0x%x",SigDataSource.share.provisionAddress);

    //        SigDataSource.share.curNetkeyModel = nil;
    //        SigDataSource.share.curAppkeyModel = nil;
            [SigDataSource.share checkExistLocationProvisioner];
            [SigDataSource.share saveLocationData];
            [SigDataSource.share.scanList removeAllObjects];
        }];

    } else {
        reject(@"import_failure", @"File not exits", nil);
        NSLog(@"File not exits");
    }
}

- (NSData *)getDataWithBinName:(NSString *)filePath{
    NSData *data;
    NSError *err = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:[NSURL URLWithString:filePath] error:&err];
    data = fileHandle.readDataToEndOfFile;
    return data;
}

RCT_EXPORT_METHOD(otaDevice:(nonnull NSNumber*)meshAddress
                  filePath:(NSString*)filePath
                  resolve:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    //
    SigNodeModel *model = [[SigNodeModel alloc] init];
    model.address =  meshAddress.intValue;
	
    NSLog(@"mesh Address %04X", meshAddress.intValue);
    NSData *localData = [self getDataWithBinName:filePath];

    if (localData) {
        resolve(@"file ok");
    } else {
        reject(@"ota_failure", @"OTA Device Failure", nil);
    }


    __weak typeof(self) weakSelf = self;

    BOOL result = [OTAManager.share startOTAWithOtaData:localData models:@[model] singleSuccessAction:^(SigNodeModel *device) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf otaSuccessAction];
        });
    } singleFailAction:^(SigNodeModel *device) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf otaFailAction];
        });
    } singleProgressAction:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf otaProgressAction:progress];
        });
    } finishAction:^(NSArray<SigNodeModel *> *successModels, NSArray<SigNodeModel *> *fileModels) {
        TeLogDebug(@"");
    }];

    TeLogDebug(@"result = %d",result);


}




RCT_EXPORT_METHOD(otaDeviceByMacAddress:(nonnull NSNumber*)meshAddress
				  filePath:(NSString*)filePath
				  mac:(NSString *)mac
//				  nameBluetoothDevice:(NSString *)nameBluetoothDevice
				  resolve:(RCTPromiseResolveBlock)resolve
				  rejecter:(RCTPromiseRejectBlock)reject)
{

	SigNodeModel *model = [[SigNodeModel alloc] init];
	model.address =  meshAddress.intValue;
	model.macAddress = mac;
//	model.name = nameBluetoothDevice;


	milestone = 0.0;

	[SigDataSource.share addAndSaveNodeToMeshNetworkWithDeviceModel:model];

	NSLog(@"mesh Address %04X", meshAddress.intValue);
	NSData *localData = [self getDataWithBinName:filePath];

	if (localData) {
		resolve(@"file ok");
	} else {
		reject(@"ota_failure", @"OTA Device Failure", nil);
	}


	__weak typeof(self) weakSelf = self;

	BOOL result = [OTAManager.share startOTAWithOtaData:localData models:@[model] singleSuccessAction:^(SigNodeModel *device) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf otaSuccessAction];
		});
	} singleFailAction:^(SigNodeModel *device) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf otaFailAction];
		});
	} singleProgressAction:^(float progress) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf otaProgressAction:progress];
		});
	} finishAction:^(NSArray<SigNodeModel *> *successModels, NSArray<SigNodeModel *> *fileModels) {
		TeLogDebug(@"");
	}];

	TeLogDebug(@"result = %d",result);


}


RCT_EXPORT_METHOD(stopAutoConnect2){
	[SigBearer.share startMeshConnectWithComplete:nil];
	[SigBearer.share stopAutoConnect];
}

- (void)otaSuccessAction{
    [self sendEventWithName:EVENT_TYPE_OTA_SUCCESS body: @{
        @"description": @"ota success",
        @"progress": @(100),
    }];

    NSLog(@"ota success");

    [SigBearer.share startMeshConnectWithComplete:nil];
	[SigBearer.share stopAutoConnect];
    TeLogVerbose(@"otaSuccess");
}

- (void)otaFailAction{
    [self sendEventWithName:EVENT_TYPE_OTA_FAIL body: @{
        @"description": @"ota fail",
        @"progress": @(0),
    }];

    NSLog(@"ota fail");

    [SigBearer.share startMeshConnectWithComplete:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });

    TeLogVerbose(@"otaFail");
}

float milestone = 0;

- (void)otaProgressAction:(float)progress{

    float diff = progress - milestone;
	NSLog(@"DEBUG123 --------------------------------- %0.1f - progress: %0.1f - milestone:  %0.1f", diff, progress, milestone);
    if (diff >= 1) {
        milestone = milestone + 1;

        [self sendEventWithName:EVENT_TYPE_OTA_PROGRESS body: @{
            @"description": @"ota progress",
            @"progress": @(progress),
        }];

    }


    NSString *tips = [NSString stringWithFormat:@"OTA:%.1f%%", progress];

    if (progress == 100.0) {
        tips = [tips stringByAppendingString:@",reboot..."];
    }

    NSLog(@"ota progress %.2f", progress);
    TeLogVerbose(@"@", tips);
}

- (NSDictionary*)getJSModel:(SigScanRspModel*)scanModel
{
    NSData* manufacturerData = (NSData*) [scanModel.advertisementData valueForKey:@"kCBAdvDataManufacturerData"];
    NSString* manufacturerDataString = [manufacturerData hexadecimalString];

    if (manufacturerDataString != nil) {
        return @{
            @"meshAddress": [NSNumber numberWithUnsignedShort:[scanModel address]],
            @"macAddress": [scanModel macAddress],
            @"uuid": [scanModel uuid],
            @"manufacturerData": manufacturerDataString,
            @"provisioned": [NSNumber numberWithBool:[scanModel provisioned]],
            @"deviceType": [manufacturerDataString substringWithRange:NSMakeRange(54, 8)],
            @"version": [manufacturerDataString substringWithRange:NSMakeRange(72, 5)],
        };
    }
    return nil;
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[
        EVENT_MESH_NETWORK_CONNECTION,
        // Unprovisioned devices
        EVENT_DEVICE_FOUND,
        EVENT_SCANNING_TIMEOUT,
        EVENT_NEW_DEVICE_ADDED,
        // Device provisioning events
        EVENT_PROVISIONING_SUCCESS,
        EVENT_PROVISIONING_FAILED,
        // Device binding events
        EVENT_BINDING_SUCCESS,
        EVENT_BINDING_FAILED,
        // Group setting events
        EVENT_SET_GROUP_SUCCESS,
        EVENT_SET_GROUP_FAILED,
        // Scene setting events
        EVENT_SET_SCENE_SUCCESS,
        EVENT_SET_SCENE_FAILED,
        // Device status
        EVENT_DEVICE_STATUS,
        // Device online
        EVENT_DEVICE_ONLINE,
        // Node reset
        EVENT_NODE_RESET_SUCCESS,
        EVENT_NODE_RESET_FAILED,
        // Unknown message
        EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN,
        // OTA Device
        EVENT_TYPE_OTA_FAIL,
        EVENT_TYPE_OTA_SUCCESS,
        EVENT_TYPE_OTA_PROGRESS,
    ];
}

@end
