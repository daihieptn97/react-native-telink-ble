package com.react.telink.ble

val ByteArray.hexString: String
  get() = joinToString(":") {
    String.format("%02x", it)
  }
