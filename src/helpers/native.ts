export function uint16ToHexString(x: number): string {
  return Array.from([x & 0x00ff, (x >> 8) & 0x00ff], function (byte) {
    return ('0' + (byte & 0xff).toString(16)).slice(-2);
  }).join(' ');
}

export function uint16ToHexStringReverse(x: number): string {
  return Array.from([x & 0x00ff, (x >> 8) & 0x00ff].reverse(), function (byte) {
    return ('0' + (byte & 0xff).toString(16)).slice(-2);
  }).join(' ');
}
