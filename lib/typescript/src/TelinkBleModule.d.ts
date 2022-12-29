import type { DeviceInfo } from './DeviceInfo';
export declare abstract class TelinkBleModule {
    /**
     * Start mesh network connection
     */
    abstract autoConnect(): void;
    /**
     * Get provisioned node list
     */
    abstract getNodes(): Promise<DeviceInfo[]>;
    /**
     * Send raw command in hex string to BLE network
     *
     * @param command {string} - Raw BLE command
     */
    abstract sendRawString(command: string): void;
    /**
     * Start unprovisioned device scanning
     */
    abstract startScanning(): void;
    /**
     * Stop unprovisioned device scanning
     */
    abstract stopScanning(): void;
    /**
     * Start adding all unprovisioned devices and bind them with mesh application key
     */
    abstract startAddingAllDevices(): void;
    /**
     *
     * @param meshAddress {number} - Node address
     * @param status {boolean} - On-off status
     */
    abstract setStatus(meshAddress: number, status: boolean): void;
    /**
     *
     */
    abstract getOnlineState(): void;
    /**
     *
     * @param meshAddress {number} - Node address
     */
    abstract getStatus(meshAddress: number): Promise<number>;
    /**
     *
     * @param meshAddress {number} - Node address
     * @param brightness {number} - Brightness (0..100)
     */
    abstract setBrightness(meshAddress: number, brightness: number): void;
    /**
     *
     * @param meshAddress {number} - Node address
     * @param temperature {number} - Light temperature (0..100)
     */
    abstract setTemperature(meshAddress: number, temperature: number): void;
    /**
     * Set HSL for RGB lamps
     *
     * @param meshAddress {number} - Node address
     * @param hsl {{
         h: number;
         s: number;
         l: number;
       }} - HSL object (h: 0..360, s: 0..100, l: 0..100)
     */
    abstract setHSL(meshAddress: number, hsl: {
        h: number;
        s: number;
        l: number;
    }): void;
    /**
     * Share mesh data as QR code
     *
     * @param path {string}
     */
    abstract shareQRCode(path: string): Promise<string>;
    /**
     * Reset BLE node
     *
     * @param meshAddress {number} - Node address
     */
    abstract resetNode(meshAddress: number): void;
    /**
     * Set message delegate for native module on iOS
     *
     * (iOS Only)
     *
     * @return {void}
     */
    abstract setDelegateForIOS(): void;
    /**
     * Open bluetooth sub-setting
     *
     * (iOS Only)
     */
    abstract openBluetoothSubSetting(): void;
    /**
     * Turn on bluetooth
     *
     * (Android only)
     */
    abstract turnOnBluetooth(): void;
    /**
     * Add device to group
     *
     * @param groupAddress {number} - Group address
     * @param deviceAddress {number} - Device address
     */
    abstract addDeviceToGroup(deviceAddress: number, groupAddress: number): Promise<any>;
    /**
     * Remove device from group
     *
     * @param groupAddress {number} - Group address
     * @param deviceAddress {number} - Device address
     */
    abstract removeDeviceFromGroup(deviceAddress: number, groupAddress: number): Promise<any>;
    /**
     * Reset Mesh Network
     *
     */
    abstract resetMeshNetwork(): Promise<any>;
    /**
     * Get Mesh Network
     *
     */
    abstract getMeshNetwork(): Promise<{
        appKey: string;
        netKey: string;
    }>;
    /**
     * (Android Only)
     * Request File Permission
     *
     */
    abstract requestFilePermission(error: (err: any) => void, success: (success: boolean) => void): void;
    /**
     * Export Mesh Network
     *
     */
    abstract exportMeshNetwork(database: string): Promise<{
        fileName: string;
        filePath: string;
    }>;
    /**
     * Import Mesh Network
     * {For Android}
     *
     */
    abstract importMeshNetworkAndroid(filePath: string): Promise<string>;
    /**
     * Import Mesh Network from Content String & QR Scan
     * {For iOS}
     *
     */
    abstract importMeshNetworkIOS(fileContent: string): Promise<string>;
    /**
     * Handle OTA Device
     *
     */
    abstract otaDevice(meshAddress: number, filePath: string): Promise<string>;
    /**
     * Handle OTA Device by mac device
     *
     */
    abstract otaDeviceByMacAddress(meshAddress: number, filePath: string, macForIos: string): Promise<string>;
    /**
     * Get Mesh Network for QR Scan
     *
     */
    abstract getMeshNetworkString(): Promise<string>;
    /**
     * Import Mesh Network for QR Scan
     * {For Android}
     */
    abstract importMeshNetworkString(meshJson: string): Promise<boolean>;
}
//# sourceMappingURL=TelinkBleModule.d.ts.map