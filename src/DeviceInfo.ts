export interface DeviceInfo {
  uuid?: string;

  macAddress?: string;

  meshAddress?: number;

  deviceType?: string;

  manufacturerData?: string;

  version?: string;

  rssi?: number;

  name?: string;
}
