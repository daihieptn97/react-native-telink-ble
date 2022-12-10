package com.react.telink.ble

import com.telink.ble.mesh.core.message.NotificationMessage
import com.telink.ble.mesh.core.message.config.ModelPublicationStatusMessage
import com.telink.ble.mesh.core.message.generic.OnOffStatusMessage
import com.telink.ble.mesh.core.message.lighting.CtlTemperatureStatusMessage
import com.telink.ble.mesh.core.message.lighting.HslStatusMessage
import com.telink.ble.mesh.core.message.lighting.LightnessStatusMessage
import com.telink.ble.mesh.entity.AdvertisingDevice
import com.telink.ble.mesh.foundation.Event
import com.telink.ble.mesh.foundation.EventListener
import com.telink.ble.mesh.foundation.event.BindingEvent
import com.telink.ble.mesh.foundation.event.ProvisioningEvent
import com.telink.ble.mesh.foundation.event.ScanEvent
import com.telink.ble.mesh.foundation.event.StatusNotificationEvent

interface TelinkBleEventHandler : EventListener<String?> {
  fun onProvisionStart(event: ProvisioningEvent)

  fun onProvisionFail(event: ProvisioningEvent)

  fun onProvisionSuccess(event: ProvisioningEvent)

  fun onKeyBindSuccess(event: BindingEvent)

  fun onKeyBindFail(event: BindingEvent)

  fun onModelPublicationStatusMessage(event: Event<String?>?)

  fun onDeviceFound(advertisingDevice: AdvertisingDevice)

  fun onReceiveNotificationMessageUnknown(notificationEvent: NotificationMessage)

  fun onUnprovisionedDeviceScanningFinish()
}
