"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.uint16ToHexString = uint16ToHexString;
exports.uint16ToHexStringReverse = uint16ToHexStringReverse;
function uint16ToHexString(x) {
  return Array.from([x & 0x00ff, x >> 8 & 0x00ff], function (byte) {
    return ('0' + (byte & 0xff).toString(16)).slice(-2);
  }).join(' ');
}
function uint16ToHexStringReverse(x) {
  return Array.from([x & 0x00ff, x >> 8 & 0x00ff].reverse(), function (byte) {
    return ('0' + (byte & 0xff).toString(16)).slice(-2);
  }).join(' ');
}
//# sourceMappingURL=native.js.map