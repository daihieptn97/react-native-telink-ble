package com.react.telink.ble

val String.byteArray: ByteArray
  get() {
    return this
      .replace(" ", "")
      .chunked(2)
      .map {
        it.toInt(16).toByte()
      }
      .toByteArray()
  }
