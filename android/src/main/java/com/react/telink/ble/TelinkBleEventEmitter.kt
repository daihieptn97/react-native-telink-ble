package com.react.telink.ble

import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.modules.core.DeviceEventManagerModule

interface TelinkBleEventEmitter {
  val eventEmitter: DeviceEventManagerModule.RCTDeviceEventEmitter

  fun sendEventWithName(event: TelinkBleEvent, body: WritableNativeMap?) {
    eventEmitter.emit(event.name, body)
  }

  fun sendEventWithName(event: TelinkBleEvent, body: WritableNativeArray) {
    eventEmitter.emit(event.name, body)
  }

  fun sendEventWithName(event: TelinkBleEvent, body: String) {
    eventEmitter.emit(event.name, body)
  }

  fun sendEventWithName(event: TelinkBleEvent, body: Int) {
    eventEmitter.emit(event.name, body)
  }

  fun sendEventWithName(event: TelinkBleEvent, body: Double) {
    eventEmitter.emit(event.name, body)
  }

  fun sendEventWithName(event: TelinkBleEvent, body: Float) {
    eventEmitter.emit(event.name, body)
  }

  fun sendEventWithName(event: TelinkBleEvent, body: Boolean) {
    eventEmitter.emit(event.name, body)
  }
}
