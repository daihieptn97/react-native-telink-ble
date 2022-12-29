import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import { RNTelinkBle } from './RNTelinkBle';
const TelinkBle = NativeModules.TelinkBle;
TelinkBle.eventEmitter = new NativeEventEmitter(TelinkBle);
Object.setPrototypeOf(TelinkBle, RNTelinkBle.prototype);
if (Platform.OS === 'ios') {
  TelinkBle.setDelegateForIOS();
}
export default TelinkBle;
export * from './helpers/native';
export { RNTelinkBle };
//# sourceMappingURL=index.js.map