package com.react.telink.ble

import com.react.telink.ble.supportedDeviceTypes
import java.nio.ByteBuffer
import java.nio.ByteOrder

fun getInt(byteArray: ByteArray): Short {
  val bb: ByteBuffer = ByteBuffer.allocate(2)
  bb.order(ByteOrder.LITTLE_ENDIAN)
  bb.put(byteArray[0])
  bb.put(byteArray[1])
  return bb.getShort(0)
}

fun getIntWith3Bytes(byteArray: ByteArray): Int {
  val bb: ByteBuffer = ByteBuffer.allocate(4)
  bb.order(ByteOrder.LITTLE_ENDIAN)
  bb.put(byteArray[0])
  bb.put(byteArray[1])
  bb.put(byteArray[2])
  bb.put(0x00)
  return bb.getInt(0)
}

fun isSupportedDevice(deviceType: String): Boolean {
  return supportedDeviceTypes.contains(deviceType)
}
