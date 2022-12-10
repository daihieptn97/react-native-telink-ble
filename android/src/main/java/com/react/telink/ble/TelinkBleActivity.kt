package com.react.telink.ble

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import com.facebook.react.ReactActivity
import com.react.telink.ble.model.AppSettings
import com.react.telink.ble.model.MeshInfo
import com.react.telink.ble.model.UnitConvert
import com.telink.ble.mesh.core.MeshUtils
import com.telink.ble.mesh.core.message.generic.OnOffGetMessage
import com.telink.ble.mesh.core.message.time.TimeSetMessage
import com.telink.ble.mesh.foundation.Event
import com.telink.ble.mesh.foundation.EventListener
import com.telink.ble.mesh.foundation.MeshConfiguration
import com.telink.ble.mesh.foundation.MeshService
import com.telink.ble.mesh.foundation.event.AutoConnectEvent
import com.telink.ble.mesh.foundation.event.MeshEvent
import com.telink.ble.mesh.foundation.parameter.AutoConnectParameters
import com.telink.ble.mesh.util.MeshLogger

abstract class TelinkBleActivity : ReactActivity(), EventListener<String> {
  private val mHandler = Handler(Looper.getMainLooper())

  private val classTag = javaClass.simpleName

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    app.addEventListener(AutoConnectEvent.EVENT_TYPE_AUTO_CONNECT_LOGIN, this)
    app.addEventListener(MeshEvent.EVENT_TYPE_DISCONNECTED, this)
    app.addEventListener(MeshEvent.EVENT_TYPE_MESH_EMPTY, this)
    startMeshService()
    resetNodeState()

    //Bluetooth
    checkBluetooth()

    //Location
  }

  private fun checkBluetooth() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      ActivityCompat.requestPermissions(this, arrayOf(
              Manifest.permission.BLUETOOTH_SCAN,
              Manifest.permission.BLUETOOTH_CONNECT),
              1
      )
    }
    else{
      val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
      if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
        // TODO: Consider calling
        //    ActivityCompat#requestPermissions
        // here to request the missing permissions, and then overriding
        //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
        //                                          int[] grantResults)
        // to handle the case where the user grants the permission. See the documentation
        // for ActivityCompat#requestPermissions for more details.
        return
      }
      startActivityForResult(enableBtIntent, 1)
    }
  }


  override fun onDestroy() {
    super.onDestroy()
    app.removeEventListener(this)
    MeshService.getInstance().clear()
  }

  private fun autoConnect() {
    MeshLogger.log("main auto connect")
    MeshService.getInstance().autoConnect(AutoConnectParameters())
  }

  override fun onResume() {
    super.onResume()
    this.autoConnect()
  }

  private fun startMeshService() {
    MeshService.getInstance().init(this, app)
    val meshConfiguration: MeshConfiguration = app.getMeshInfo()!!.convertToConfiguration()
    MeshService.getInstance().setupMeshNetwork(meshConfiguration)
    MeshService.getInstance().checkBluetoothState()
    // set DLE enable
    MeshService.getInstance().resetDELState(SharedPreferenceHelper.isDleEnable(this))
  }

  private fun resetNodeState() {
    val mesh: MeshInfo = app.getMeshInfo()!!
    if (mesh.nodes != null) {
      for (deviceInfo in mesh.nodes) {
        deviceInfo.onOff = -1
        deviceInfo.lum = 0
        deviceInfo.temp = 0
      }
    }
  }

  override fun performed(event: Event<String>) {
    when (event.type) {
      MeshEvent.EVENT_TYPE_MESH_EMPTY -> {
        MeshLogger.log("$classTag#EVENT_TYPE_MESH_EMPTY")
      }
      AutoConnectEvent.EVENT_TYPE_AUTO_CONNECT_LOGIN -> {
        // get all device on off status when auto connect success
        AppSettings.ONLINE_STATUS_ENABLE = MeshService.getInstance().onlineStatus
        if (!AppSettings.ONLINE_STATUS_ENABLE) {
          MeshService.getInstance().onlineStatus
          val rspMax: Int = app.getMeshInfo()!!.onlineCountInAll
          val appKeyIndex: Int =
            app.getMeshInfo()!!.defaultAppKeyIndex
          val message = OnOffGetMessage.getSimple(MeshUtils.ADDRESS_BROADCAST, appKeyIndex, rspMax)
          MeshService.getInstance().sendMeshMessage(message)
        }
        sendTimeStatus()
      }
      MeshEvent.EVENT_TYPE_DISCONNECTED -> {
        mHandler.removeCallbacksAndMessages(null)
      }
    }
  }

  open fun sendTimeStatus() {
    mHandler.postDelayed({
      val time = MeshUtils.getTaiTime()
      val offset: Int = UnitConvert.getZoneOffset()
      val address = MeshUtils.ADDRESS_BROADCAST
      val meshInfo: MeshInfo = app.getMeshInfo()!!
      val timeSetMessage =
        TimeSetMessage.getSimple(address, meshInfo.defaultAppKeyIndex, time, offset, 1)
      timeSetMessage.setAck(false)
      MeshService.getInstance().sendMeshMessage(timeSetMessage)
    }, 1500)
  }

  companion object {
    private lateinit var reactActivity: TelinkBleActivity

    fun getInstance(): TelinkBleActivity {
      return reactActivity
    }

    val app: TelinkBleApplication
      get() = TelinkBleApplication.getInstance()
  }
}
