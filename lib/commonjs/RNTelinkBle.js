"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.RNTelinkBle = void 0;
var _reactNative = require("react-native");
var _BleEvent = require("./BleEvent");
var _native = require("./helpers/native");
var _TelinkBleModule = require("./TelinkBleModule");
function _defineProperty(obj, key, value) { key = _toPropertyKey(key); if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
function _toPropertyKey(arg) { var key = _toPrimitive(arg, "string"); return typeof key === "symbol" ? key : String(key); }
function _toPrimitive(input, hint) { if (typeof input !== "object" || input === null) return input; var prim = input[Symbol.toPrimitive]; if (prim !== undefined) { var res = prim.call(input, hint || "default"); if (typeof res !== "object") return res; throw new TypeError("@@toPrimitive must return a primitive value."); } return (hint === "string" ? String : Number)(input); }
class RNTelinkBle extends _TelinkBleModule.TelinkBleModule {
  /**
   * Native module event emitter
   *
   * @type {NativeEventEmitter}
   */

  /**
   * This class should be prototyped only, not for creating new instance
   *
   * @param eventEmitter {NativeEventEmitter}
   */
  constructor(eventEmitter) {
    super();
    _defineProperty(this, "eventEmitter", void 0);
    this.eventEmitter = eventEmitter;
  }

  /**
   * Turn on all devices
   */
  setAllOn() {
    this.setStatus(0xffff, true);
  }

  /**
   * Turn off all devices
   */
  setAllOff() {
    this.setStatus(0xffff, false);
  }

  /**
   * Set a scene for all devices
   *
   * @param sceneAddress {number} - Scene mesh address
   * @param groupAddress {number} - Group mesh address
   */
  setScene(sceneAddress, groupAddress) {
    const groupHex = (0, _native.uint16ToHexString)(groupAddress);
    const sceneHex = (0, _native.uint16ToHexString)(sceneAddress);
    this.sendRawString(`a3 ff 00 00 00 00 02 00 ${groupHex} 82 46 ${sceneHex} 00`);
  }

  /**
   * Remove an existing scene
   *
   * @param sceneAddress {number} - Scene mesh address
   * @param groupAddress {number} - Group mesh address
   */
  removeScene(sceneAddress, groupAddress) {
    const groupHex = (0, _native.uint16ToHexString)(groupAddress);
    const sceneHex = (0, _native.uint16ToHexString)(sceneAddress);
    this.sendRawString(`a3 ff 00 00 00 00 00 00 ${groupHex} 82 9E ${sceneHex} 00`);
  }

  /**
   * Set a scene for all devices
   *
   * @param deviceAddress {number} - Scene mesh address
   * @param groupAddress {number} - Group mesh address
   */
  addDeviceIntoGroupRaw(deviceAddress, groupAddress) {
    const groupHex = (0, _native.uint16ToHexString)(groupAddress);
    const deviceHex = (0, _native.uint16ToHexString)(deviceAddress);
    this.sendRawString(`A3 FF 00 00 00 00 02 01 02 00 80 1B 02 ${deviceHex} ${groupHex} 10`);
  }

  /**
   * Remove an existing scene
   *
   * @param deviceAddress {number} - Scene mesh address
   * @param groupAddress {number} - Group mesh address
   */
  removeDeviceFromGroupRaw(deviceAddress, groupAddress) {
    const groupHex = (0, _native.uint16ToHexString)(groupAddress);
    const deviceHex = (0, _native.uint16ToHexString)(deviceAddress);
    this.sendRawString(`A3 FF 00 00 00 00 02 01 02 00 80 1C 02 ${deviceHex} ${groupHex} 10`);
  }

  /**
   * Recall a scene on mesh network
   *
   * @param sceneAddress {number} - Scene mesh address
   */

  /**
   * Node reset success event handler
   *
   * @param callback {() => void | Promise<void>} - Node reset callback
   * @returns {() => void}
   */
  onNodeResetSuccess(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_NODE_RESET_SUCCESS, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Node reset failure event handler
   *
   * @param callback {() => void | Promise<void>} - Node reset callback
   * @returns {() => void}
   */
  onNodeResetFailed(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_NODE_RESET_FAILED, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Setup handler for new unprovisioned device found event
   *
   * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
   */
  onDeviceFound(callback) {
    const subscription = this.eventEmitter.addListener(_reactNative.Platform.OS === 'android' ? _BleEvent.BleEvent.EVENT_DEVICE_FOUND : _BleEvent.BleEvent.EVENT_BINDING_SUCCESS, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Setup handler for scanning timeout event
   *
   * @param callback {() => void | Promise<void>} - Scanning timeout handler
   */
  onScanningTimeout(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_SCANNING_TIMEOUT, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Setup handler for mesh network connection changes
   *
   * @param callback {(connected: boolean) => void | Promise<void>} - Mesh network handler
   */
  onMeshConnected(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_MESH_NETWORK_CONNECTION, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Group success event handler
   *
   * @param callback
   * @returns
   */
  onSetGroupSuccess(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_SET_GROUP_SUCCESS, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Group success event handler
   *
   * @param callback
   * @returns
   */
  onSetGroupFailed(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_SET_GROUP_FAILED, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Unprovisioned device scanning finish
   *
   * @param callback {() => void | Promise<void>}
   * @returns {() => void}
   */
  onAndroidScanFinish(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_ANDROID_SCAN_FINISH, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle Receive Notification Unknown Message
   *
   * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
   */
  onReceiveUnknownNotificationMessage(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle OTA Device Success
   *
   * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
   */
  onOtaDeviceSuccess(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_TYPE_OTA_SUCCESS, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle OTA Device Fail
   *
   * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
   */
  onOtaDeviceFail(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_TYPE_OTA_FAIL, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle OTA Device Progress
   *
   * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
   */
  onOtaDeviceProgress(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_TYPE_OTA_PROGRESS, callback);
    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle Receive Device Online (iOS)
   *
   * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
   */
  onGetDeviceOnline(callback) {
    const subscription = this.eventEmitter.addListener(_BleEvent.BleEvent.EVENT_DEVICE_ONLINE, callback);
    return () => {
      subscription.remove();
    };
  }
}
exports.RNTelinkBle = RNTelinkBle;
//# sourceMappingURL=RNTelinkBle.js.map