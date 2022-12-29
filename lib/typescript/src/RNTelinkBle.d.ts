import type { NativeEventEmitter } from 'react-native';
import type { DeviceInfo } from './DeviceInfo';
import { TelinkBleModule } from './TelinkBleModule';
import type { NotificationMessage } from './NotificationMessage';
export declare abstract class RNTelinkBle extends TelinkBleModule {
    /**
     * Native module event emitter
     *
     * @type {NativeEventEmitter}
     */
    eventEmitter: NativeEventEmitter;
    /**
     * This class should be prototyped only, not for creating new instance
     *
     * @param eventEmitter {NativeEventEmitter}
     */
    protected constructor(eventEmitter: NativeEventEmitter);
    /**
     * Turn on all devices
     */
    setAllOn(): void;
    /**
     * Turn off all devices
     */
    setAllOff(): void;
    /**
     * Set a scene for all devices
     *
     * @param sceneAddress {number} - Scene mesh address
     * @param groupAddress {number} - Group mesh address
     */
    setScene(sceneAddress: number, groupAddress: number): void;
    /**
     * Remove an existing scene
     *
     * @param sceneAddress {number} - Scene mesh address
     * @param groupAddress {number} - Group mesh address
     */
    removeScene(sceneAddress: number, groupAddress: number): void;
    /**
     * Set a scene for all devices
     *
     * @param deviceAddress {number} - Scene mesh address
     * @param groupAddress {number} - Group mesh address
     */
    addDeviceIntoGroupRaw(deviceAddress: number, groupAddress: number): void;
    /**
     * Remove an existing scene
     *
     * @param deviceAddress {number} - Scene mesh address
     * @param groupAddress {number} - Group mesh address
     */
    removeDeviceFromGroupRaw(deviceAddress: number, groupAddress: number): void;
    /**
     * Recall a scene on mesh network
     *
     * @param sceneAddress {number} - Scene mesh address
     */
    abstract recallScene(sceneAddress: number): void;
    /**
     * Node reset success event handler
     *
     * @param callback {() => void | Promise<void>} - Node reset callback
     * @returns {() => void}
     */
    onNodeResetSuccess(callback: () => void | Promise<void>): () => void;
    /**
     * Node reset failure event handler
     *
     * @param callback {() => void | Promise<void>} - Node reset callback
     * @returns {() => void}
     */
    onNodeResetFailed(callback: () => void | Promise<void>): () => void;
    /**
     * Setup handler for new unprovisioned device found event
     *
     * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
     */
    onDeviceFound(callback: (device: DeviceInfo) => void | Promise<void>): () => void;
    /**
     * Setup handler for scanning timeout event
     *
     * @param callback {() => void | Promise<void>} - Scanning timeout handler
     */
    onScanningTimeout(callback: () => void | Promise<void>): () => void;
    /**
     * Setup handler for mesh network connection changes
     *
     * @param callback {(connected: boolean) => void | Promise<void>} - Mesh network handler
     */
    onMeshConnected(callback: (connected: boolean) => void | Promise<void>): () => void;
    /**
     * Group success event handler
     *
     * @param callback
     * @returns
     */
    onSetGroupSuccess(callback: (data: {
        groupAddress: number;
        deviceAddress: number;
        opcode: number;
    }) => void | Promise<void>): () => void;
    /**
     * Group success event handler
     *
     * @param callback
     * @returns
     */
    onSetGroupFailed(callback: (data: {
        groupAddress: number;
        deviceAddress: number;
        opcode: number;
    }) => void | Promise<void>): () => void;
    /**
     * Unprovisioned device scanning finish
     *
     * @param callback {() => void | Promise<void>}
     * @returns {() => void}
     */
    onAndroidScanFinish(callback: () => void | Promise<void>): () => void;
    /**
     * Handle Receive Notification Unknown Message
     *
     * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
     */
    onReceiveUnknownNotificationMessage(callback: (device: NotificationMessage) => void | Promise<void>): () => void;
    /**
     * Handle OTA Device Success
     *
     * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
     */
    onOtaDeviceSuccess(callback: (data: {
        description: string;
        progress: number;
    }) => void | Promise<void>): () => void;
    /**
     * Handle OTA Device Fail
     *
     * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
     */
    onOtaDeviceFail(callback: (data: {
        description: string;
        progress: number;
    }) => void | Promise<void>): () => void;
    /**
     * Handle OTA Device Progress
     *
     * @param callback {(description: string, progress: number) => void | Promise<void>} - Unprovisioned device handler
     */
    onOtaDeviceProgress(callback: (data: {
        description: string;
        progress: number;
    }) => void | Promise<void>): () => void;
    /**
     * Handle Receive Device Online (iOS)
     *
     * @param callback {(device: DeviceInfo) => void | Promise<void>} - Unprovisioned device handler
     */
    onGetDeviceOnline(callback: (data: {
        destination: number;
        deviceAddress: number;
        responseMessage: string;
    }) => void | Promise<void>): () => void;
}
//# sourceMappingURL=RNTelinkBle.d.ts.map