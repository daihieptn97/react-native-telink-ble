import { EventSubscriptionVendor, NativeModule } from 'react-native';
import { RNTelinkBle } from './RNTelinkBle';
declare const TelinkBle: RNTelinkBle & EventSubscriptionVendor & NativeModule;
export default TelinkBle;
export type { DeviceInfo } from './DeviceInfo';
export * from './helpers/native';
export type { HSL } from './HSL';
export { RNTelinkBle };
//# sourceMappingURL=index.d.ts.map