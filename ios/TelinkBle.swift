import AVFoundation
import CoreBluetooth
import React
import UIKit

extension TelinkBle {
    @objc(setDelegateForIOS)
    func setDelegateForIOS() -> Void {
        SigMeshLib.share().delegateForDeveloper = self;
    }

    @objc(getOnlineState)
    func getOnlineState() -> Void {
        var responseMaxCount: Int32 = 0
        for case let node as SigNodeModel in SigDataSource.share().curNodes {
            if (!node.isSensor() && node.isKeyBindSuccess) {
                responseMaxCount += 1
            }
        }
        DemoCommand.getOnlineStatus(
                withResponseMaxCount: responseMaxCount,
                successCallback: { (source, destination, responseMessage) -> Void in
                    //
                    DispatchQueue.main.async {
                        self.sendEvent(withName: EVENT_DEVICE_ONLINE, body: [
                            "deviceAddress": source,
                            "destination": destination,
                            "responseMessage": responseMessage
                        ])
                    }
                },
                resultCallback: { (isResponseAll, error) -> Void in
                    //
                }
        )

    }

    @objc(setStatus:withStatus:)
    func setStatus(meshAddress: NSNumber, status: NSNumber) -> Void {
        DemoCommand.switchOnOffWithIs(on: status.boolValue,
                address: meshAddress.uint16Value,
                responseMaxCount: 1,
                ack: false,
                successCallback: nil,
                resultCallback: nil
        )
    }

    @objc(setBrightness:withBrightness:)
    func setBrightness(meshAddress: NSNumber, brightness: NSNumber) -> Void {
        DemoCommand.changeBrightness(
                withBrightness100: brightness.uint8Value,
                address: meshAddress.uint16Value,
                retryCount: 0,
                responseMaxCount: 1,
                ack: false,
                successCallback: nil,
                resultCallback: nil
        )
    }

    @objc(setTemperature:withTemperature:)
    func setTemperature(meshAddress: NSNumber, temperature: NSNumber) -> Void {
        var address = meshAddress.uint16Value
        if (address < 0xC000) {
            address += 1
        }
        DemoCommand.changeTemprature(
                withTemprature100: temperature.uint8Value,
                address: address,
                retryCount: 0,
                responseMaxCount: 1,
                ack: false,
                successCallback: nil,
                resultCallback: nil
        )
    }

    @objc(setHSL:withHSL:)
    func setHSL(meshAddress: NSNumber, hsl: [String: NSNumber]!) -> Void {
        let h: Float = hsl["h"]!.floatValue / 360
        let s: Float = hsl["s"]!.floatValue / 100
        let l: Float = hsl["l"]!.floatValue / 100
        DemoCommand.changeHSL(
                withAddress: meshAddress.uint16Value,
                hue: h,
                saturation: s,
                brightness: l,
                responseMaxCount: 1,
                ack: false,
                successCallback: nil,
                resultCallback: nil
        )

    }

    @objc(sendRawString:)
    func sendRawString(command: String) -> Void {
        var sendString = command.uppercased().removeAllSpacesAndNewLines()
        sendString = sendString!.insertSpaceNum(1, charNum: 2)
        sendString = command.uppercased().removeAllSpacesAndNewLines()
        let data = LibTools.nsstring(toHex: sendString!)
        SDKLibCommand.sendOpINIData(
                data,
                successCallback: { (source, destination, responseMessage) -> Void in
                    //
                },
                resultCallback: { (isResponseAll, error) -> Void in
                    //
                }
        )
    }

    @objc(recallScene:)
    func recallScene(sceneAddress: NSNumber) -> Void {
        DemoCommand.recallScene(withAddress: 0xFFFF, sceneId: sceneAddress.uint16Value, responseMaxCount: 0, ack: false, successCallback: nil, resultCallback: nil);
    }


    @objc(autoConnect)
    func autoConnect() -> Void {
        SigBearer.share().startMeshConnect { successful in
            self.sendEvent(withName: EVENT_MESH_NETWORK_CONNECTION, body: [successful])
        }
    }

    @objc(stopScanning)
    func stopScanning() -> Void {
        SDKLibCommand.stopScan()
    }

    @objc(getNodes:withRejecter:)
    func getNodes(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        let curNodes: NSMutableArray = SigDataSource.share().curNodes
        let result = NSMutableArray()
        for case let node as SigNodeModel in curNodes {
            result.add([
                "name": node.name,
                "uuid": node.uuid,
                "macAddress": node.macAddress,
                "meshAddress": node.address(),
                "deviceKey": node.deviceKey,
                "hasHSL": NSNumber.init(value: node.hslAddresses.count > 0),
                "hasLightness": NSNumber.init(value: node.temperatureAddresses.count > 0)
            ])
        }
        resolve(result)
    }

    @objc(addDeviceToGroup:withGroupAddress:)
    func addDevice(deviceAddress: NSNumber, groupAddress: NSNumber) -> Void {
        DemoCommand.editSubscribeListWith(
                withDestination: deviceAddress.uint16Value,
                isAdd: true,
                groupAddress: groupAddress.uint16Value,
                elementAddress: deviceAddress.uint16Value,
                modelIdentifier: 4096,
                companyIdentifier: 0,
                retryCount: 0,
                responseMaxCount: 1,
                successCallback: { (source, destination, responseMessage) -> Void in
                    DispatchQueue.main.async {
                        self.sendEvent(withName: EVENT_SET_GROUP_SUCCESS, body: [
                            "deviceAddress": deviceAddress,
                            "groupAddress": responseMessage.address,
                            "opcode": responseMessage.opCode
                        ])
                    }
                },
                resultCallback: { (isResponseAll, error) -> Void in
                    //
                    DispatchQueue.main.async {
                        self.sendEvent(withName: EVENT_SET_GROUP_FAILED, body: [
                            "deviceAddress": deviceAddress,
                        ])
                    }

                }
        )
    }

    @objc(removeDeviceFromGroup:withGroupAddress:)
    func removeDevice(deviceAddress: NSNumber, groupAddress: NSNumber) -> Void {
        DemoCommand.editSubscribeListWith(
                withDestination: deviceAddress.uint16Value,
                isAdd: false,
                groupAddress: groupAddress.uint16Value,
                elementAddress: deviceAddress.uint16Value,
                modelIdentifier: 4096,
                companyIdentifier: 0,
                retryCount: 1,
                responseMaxCount: 1,
                successCallback: { (source, destination, responseMessage) -> Void in
                    DispatchQueue.main.async {
                        let eventName = responseMessage.isSuccess ? EVENT_SET_GROUP_SUCCESS : EVENT_SET_GROUP_FAILED
                        self.sendEvent(withName: eventName, body: [
                            "deviceAddress": source,
                            "groupAddress": responseMessage.address,
                            "opcode": responseMessage.opCode
                        ])
                    }
                },
                resultCallback: { (isResponseAll, error) -> Void in
                    //
                }
        )
    }

    @objc(resetNode:)
    func resetNode(meshAddress: NSNumber) -> Void {
        DemoCommand.kickoutDevice(
                meshAddress.uint16Value,
                retryCount: 0,
                responseMaxCount: 1,
                successCallback: { (source, destination, responseMessage) -> Void in
                    SigDataSource.share().deleteNodeFromMeshNetwork(withDeviceAddress: source)
                    self.sendEvent(withName: EVENT_NODE_RESET_SUCCESS, body: source)
                },
                resultCallback: { (isResponseAll, error) -> Void in
                    //
                }
        )
    }

    @objc(openBluetoothSubSetting)
    func openBluetoothSubSetting() -> Void {
        _ = CBCentralManager(delegate: nil, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey:true])
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map {
            String(format: format, $0)
        }.joined(separator: ":")
    }
}
