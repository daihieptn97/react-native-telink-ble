import {
  EventSubscriptionVendor,
  NativeEventEmitter,
  NativeModule,
  NativeModules,
  Platform,
} from 'react-native';
import { RNTelinkBle } from './RNTelinkBle';

const TelinkBle: RNTelinkBle & EventSubscriptionVendor & NativeModule =
  NativeModules.TelinkBle;

TelinkBle.eventEmitter = new NativeEventEmitter(TelinkBle);

Object.setPrototypeOf(TelinkBle, RNTelinkBle.prototype);

if (Platform.OS === 'ios') {
  TelinkBle.setDelegateForIOS();
}

export default TelinkBle;
export type { DeviceInfo } from './DeviceInfo';
export * from './helpers/native';
export type { HSL } from './HSL';
export { RNTelinkBle };
