import type { DeviceInfo } from './DeviceInfo';

export abstract class TelinkBleModule {
  /**
   * Start mesh network connection
   */
  public abstract autoConnect(): void;

  /**
   * Get provisioned node list
   */
  public abstract getNodes(): Promise<DeviceInfo[]>;

  /**
   * Send raw command in hex string to BLE network
   *
   * @param command {string} - Raw BLE command
   */
  public abstract sendRawString(command: string): void;

  /**
   * Start unprovisioned device scanning
   */
  public abstract startScanning(): void;

  /**
   * Stop unprovisioned device scanning
   */
  public abstract stopScanning(): void;

  /**
   * Start adding all unprovisioned devices and bind them with mesh application key
   */
  public abstract startAddingAllDevices(): void;

  /**
   *
   * @param meshAddress {number} - Node address
   * @param status {boolean} - On-off status
   */
  public abstract setStatus(meshAddress: number, status: boolean): void;

  /**
   *
   */
  public abstract getOnlineState(): void;

  /**
   *
   * @param meshAddress {number} - Node address
   */
  public abstract getStatus(meshAddress: number): Promise<number>;

  /**
   *
   * @param meshAddress {number} - Node address
   * @param brightness {number} - Brightness (0..100)
   */
  public abstract setBrightness(meshAddress: number, brightness: number): void;

  /**
   *
   * @param meshAddress {number} - Node address
   * @param temperature {number} - Light temperature (0..100)
   */
  public abstract setTemperature(
    meshAddress: number,
    temperature: number
  ): void;

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
  public abstract setHSL(
    meshAddress: number,
    hsl: {
      h: number;
      s: number;
      l: number;
    }
  ): void;

  /**
   * Share mesh data as QR code
   *
   * @param path {string}
   */
  public abstract shareQRCode(path: string): Promise<string>;

  /**
   * Reset BLE node
   *
   * @param meshAddress {number} - Node address
   */
  public abstract resetNode(meshAddress: number): void;

  /**
   * Set message delegate for native module on iOS
   *
   * (iOS Only)
   *
   * @return {void}
   */
  public abstract setDelegateForIOS(): void;

  /**
   * Open bluetooth sub-setting
   *
   * (iOS Only)
   */
  public abstract openBluetoothSubSetting(): void;

  /**
   * Turn on bluetooth
   *
   * (Android only)
   */
  public abstract turnOnBluetooth(): void;

  /**
   * Add device to group
   *
   * @param groupAddress {number} - Group address
   * @param deviceAddress {number} - Device address
   */
  public abstract addDeviceToGroup(
    deviceAddress: number,
    groupAddress: number
  ): Promise<any>;

  /**
   * Remove device from group
   *
   * @param groupAddress {number} - Group address
   * @param deviceAddress {number} - Device address
   */
  public abstract removeDeviceFromGroup(
    deviceAddress: number,
    groupAddress: number
  ): Promise<any>;

  /**
   * Reset Mesh Network
   *
   */
  public abstract resetMeshNetwork(): Promise<any>;

  /**
   * Get Mesh Network
   *
   */
  public abstract getMeshNetwork(): Promise<{
    appKey: string;
    netKey: string;
  }>;

  /**
   * (Android Only)
   * Request File Permission
   *
   */
  public abstract requestFilePermission(
    error: (err: any) => void,
    success: (success: boolean) => void
  ): void;

  /**
   * Export Mesh Network
   *
   */
  public abstract exportMeshNetwork(database: string): Promise<{
    fileName: string;
    filePath: string;
  }>;

  /**
   * Import Mesh Network
   * {For Android}
   *
   */
  public abstract importMeshNetworkAndroid(filePath: string): Promise<string>;

  /**
   * Import Mesh Network from Content String & QR Scan
   * {For iOS}
   *
   */
  public abstract importMeshNetworkIOS(fileContent: string): Promise<string>;

  /**
   * Handle OTA Device
   *
   */
  public abstract otaDevice(
    meshAddress: number,
    filePath: string
  ): Promise<string>;

  /**
   * Handle OTA Device by mac device
   *
   */
  public abstract otaDeviceByMacAddress(
    meshAddress: number,
    filePath: string,
    macForIos: string
  ): Promise<string>;

  /**
   * Get Mesh Network for QR Scan
   *
   */
  public abstract getMeshNetworkString(): Promise<string>;

  /**
   * Import Mesh Network for QR Scan
   * {For Android}
   */
  public abstract importMeshNetworkString(meshJson: string): Promise<boolean>;
}
