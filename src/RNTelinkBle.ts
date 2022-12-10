import type { EventSubscription, NativeEventEmitter } from 'react-native';
import { Platform } from 'react-native';
import { BleEvent } from './BleEvent';
import type { DeviceInfo } from './DeviceInfo';
import { uint16ToHexString } from './helpers/native';
import { TelinkBleModule } from './TelinkBleModule';
import type { NotificationMessage } from './NotificationMessage';

export abstract class RNTelinkBle extends TelinkBleModule {
  /**
   * Native module event emitter
   *
   * @type {NativeEventEmitter}
   */
  public eventEmitter: NativeEventEmitter;

  /**
   * This class should be prototyped only, not for creating new instance
   *
   * @param eventEmitter {NativeEventEmitter}
   */
  protected constructor(eventEmitter: NativeEventEmitter) {
    super();
    this.eventEmitter = eventEmitter;
  }

  /**
   * Turn on all devices
   */
  public setAllOn(): void {
    this.setStatus(0xffff, true);
  }

  /**
   * Turn off all devices
   */
  public setAllOff(): void {
    this.setStatus(0xffff, false);
  }

  /**
   * Set a scene for all devices
   *
   * @param sceneAddress {number} - Scene mesh address
   * @param groupAddress {number} - Group mesh address
   */
  public setScene(sceneAddress: number, groupAddress: number): void {
    const groupHex = uint16ToHexString(groupAddress);
    const sceneHex = uint16ToHexString(sceneAddress);
    this.sendRawString(
      `a3 ff 00 00 00 00 02 00 ${groupHex} 82 46 ${sceneHex} 00`
    );
  }

  /**
   * Remove an existing scene
   *
   * @param sceneAddress {number} - Scene mesh address
   * @param groupAddress {number} - Group mesh address
   */
  public removeScene(sceneAddress: number, groupAddress: number): void {
    const groupHex = uint16ToHexString(groupAddress);
    const sceneHex = uint16ToHexString(sceneAddress);
    this.sendRawString(
      `a3 ff 00 00 00 00 00 00 ${groupHex} 82 9E ${sceneHex} 00`
    );
  }

  /**
   * Set a scene for all devices
   *
   * @param deviceAddress {number} - Scene mesh address
   * @param groupAddress {number} - Group mesh address
   */
  public addDeviceIntoGroupRaw(
    deviceAddress: number,
    groupAddress: number
  ): void {
    const groupHex = uint16ToHexString(groupAddress);
    const deviceHex = uint16ToHexString(deviceAddress);
    this.sendRawString(
      `A3 FF 00 00 00 00 02 01 02 00 80 1B 02 ${deviceHex} ${groupHex} 10`
    );
  }

  /**
   * Remove an existing scene
   *
   * @param deviceAddress {number} - Scene mesh address
   * @param groupAddress {number} - Group mesh address
   */
  public removeDeviceFromGroupRaw(
    deviceAddress: number,
    groupAddress: number
  ): void {
    const groupHex = uint16ToHexString(groupAddress);
    const deviceHex = uint16ToHexString(deviceAddress);
    this.sendRawString(
      `A3 FF 00 00 00 00 02 01 02 00 80 1C 02 ${deviceHex} ${groupHex} 10`
    );
  }

  /**
   * Recall a scene on mesh network
   *
   * @param sceneAddress {number} - Scene mesh address
   */
  public abstract recallScene(sceneAddress: number): void;

  /**
   * Node reset success event handler
   *
   * @param callback {() => void | Promise<void>} - Node reset callback
   * @returns {() => void}
   */
  public onNodeResetSuccess(callback: () => void | Promise<void>): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_NODE_RESET_SUCCESS,
      callback
    );

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
  public onNodeResetFailed(callback: () => void | Promise<void>): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_NODE_RESET_FAILED,
      callback
    );

    return () => {
      subscription.remove();
    };
  }

  /**
   * Setup handler for new unprovisioned device found event
   *
   * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
   */
  public onDeviceFound(
    callback: (device: DeviceInfo) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      Platform.OS === 'android'
        ? BleEvent.EVENT_DEVICE_FOUND
        : BleEvent.EVENT_BINDING_SUCCESS,
      callback
    );

    return () => {
      subscription.remove();
    };
  }

  /**
   * Setup handler for scanning timeout event
   *
   * @param callback {() => void | Promise<void>} - Scanning timeout handler
   */
  public onScanningTimeout(callback: () => void | Promise<void>): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_SCANNING_TIMEOUT,
      callback
    );

    return () => {
      subscription.remove();
    };
  }

  /**
   * Setup handler for mesh network connection changes
   *
   * @param callback {(connected: boolean) => void | Promise<void>} - Mesh network handler
   */
  public onMeshConnected(
    callback: (connected: boolean) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_MESH_NETWORK_CONNECTION,
      callback
    );

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
  public onSetGroupSuccess(
    callback: (data: {
      groupAddress: number;
      deviceAddress: number;
      opcode: number;
    }) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_SET_GROUP_SUCCESS,
      callback
    );

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
  public onSetGroupFailed(
    callback: (data: {
      groupAddress: number;
      deviceAddress: number;
      opcode: number;
    }) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_SET_GROUP_FAILED,
      callback
    );

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
  public onAndroidScanFinish(callback: () => void | Promise<void>): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_ANDROID_SCAN_FINISH,
      callback
    );

    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle Receive Notification Unknown Message
   *
   * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
   */
  public onReceiveUnknownNotificationMessage(
    callback: (device: NotificationMessage) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN,
      callback
    );

    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle OTA Device Success
   *
   * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
   */
  public onOtaDeviceSuccess(
    callback: (data: {
      description: string;
      progress: number;
    }) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_TYPE_OTA_SUCCESS,
      callback
    );

    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle OTA Device Fail
   *
   * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
   */
  public onOtaDeviceFail(
    callback: (data: {
      description: string;
      progress: number;
    }) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_TYPE_OTA_FAIL,
      callback
    );

    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle OTA Device Progress
   *
   * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
   */
  public onOtaDeviceProgress(
    callback: (data: {
      description: string;
      progress: number;
    }) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_TYPE_OTA_PROGRESS,
      callback
    );

    return () => {
      subscription.remove();
    };
  }

  /**
   * Handle Receive Device Online (iOS)
   *
   * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
   */
  public onGetDeviceOnline(
    callback: (data: {
      destination: number;
      deviceAddress: number;
      responseMessage: string;
    }) => void | Promise<void>
  ): () => void {
    const subscription: EventSubscription = this.eventEmitter.addListener(
      BleEvent.EVENT_DEVICE_ONLINE,
      callback
    );

    return () => {
      subscription.remove();
    };
  }
}
