"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
var _exportNames = {
  RNTelinkBle: true
};
Object.defineProperty(exports, "RNTelinkBle", {
  enumerable: true,
  get: function () {
    return _RNTelinkBle.RNTelinkBle;
  }
});
exports.default = void 0;
var _reactNative = require("react-native");
var _RNTelinkBle = require("./RNTelinkBle");
var _native = require("./helpers/native");
Object.keys(_native).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _native[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _native[key];
    }
  });
});
const TelinkBle = _reactNative.NativeModules.TelinkBle;
TelinkBle.eventEmitter = new _reactNative.NativeEventEmitter(TelinkBle);
Object.setPrototypeOf(TelinkBle, _RNTelinkBle.RNTelinkBle.prototype);
if (_reactNative.Platform.OS === 'ios') {
  TelinkBle.setDelegateForIOS();
}
var _default = TelinkBle;
exports.default = _default;
//# sourceMappingURL=index.js.map