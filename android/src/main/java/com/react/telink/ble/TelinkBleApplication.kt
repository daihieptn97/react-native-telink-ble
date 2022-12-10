package com.react.telink.ble

import android.os.Handler
import android.os.HandlerThread
import com.facebook.react.ReactApplication
import com.react.telink.ble.model.AppSettings
import com.react.telink.ble.model.MeshInfo
import com.react.telink.ble.model.NodeInfo
import com.react.telink.ble.model.NodeStatusChangedEvent
import com.telink.ble.mesh.core.message.NotificationMessage
import com.telink.ble.mesh.foundation.MeshApplication
import com.telink.ble.mesh.foundation.event.MeshEvent
import com.telink.ble.mesh.foundation.event.NetworkInfoUpdateEvent
import com.telink.ble.mesh.foundation.event.OnlineStatusEvent
import com.telink.ble.mesh.foundation.event.StatusNotificationEvent
import com.telink.ble.mesh.util.FileSystem
import com.telink.ble.mesh.util.MeshLogger

abstract class TelinkBleApplication : MeshApplication(), ReactApplication {
  private var meshInfo: MeshInfo? = null

  private var mOfflineCheckHandler: Handler? = null

  open fun getOfflineCheckHandler(): Handler? {
    return mOfflineCheckHandler
  }

  override fun onCreate() {
    super.onCreate()
    reactApplication = this
    // 2018-11-20T10:05:20-08:00
    // 2020-07-27T15:15:29+08:00
    val offlineCheckThread = HandlerThread("offline check thread")
    offlineCheckThread.start()
    mOfflineCheckHandler = Handler(offlineCheckThread.looper)
    initMesh()
    MeshLogger.enableRecord(SharedPreferenceHelper.isLogEnable(this))
    MeshLogger.d(meshInfo.toString())
  }

  private fun initMesh() {
    val configObj = FileSystem.readAsObject(this, MeshInfo.FILE_NAME)
    if (configObj == null) {
      meshInfo = MeshInfo.createNewMesh(this)
      meshInfo!!.saveOrUpdate(this)
    } else {
      meshInfo = configObj as MeshInfo
    }
  }

  open fun getMeshInfo(): MeshInfo? {
    return meshInfo
  }

  override fun onNetworkInfoUpdate(networkInfoUpdateEvent: NetworkInfoUpdateEvent?) {
    meshInfo!!.ivIndex = networkInfoUpdateEvent!!.ivIndex
    meshInfo!!.sequenceNumber = networkInfoUpdateEvent.sequenceNumber
    meshInfo!!.saveOrUpdate(this)
  }

  open fun setupMesh(mesh: MeshInfo?) {
    MeshLogger.d("setup mesh info: " + meshInfo.toString())
    meshInfo = mesh
    dispatchEvent(MeshEvent(this, MeshEvent.EVENT_TYPE_MESH_RESET, "mesh reset"))
  }

  override fun onStatusNotificationEvent(statusNotificationEvent: StatusNotificationEvent?) {
    //
    val notificationEvent = NotificationMessage(
      statusNotificationEvent?.notificationMessage?.src!!,
      statusNotificationEvent?.notificationMessage?.dst!!,
      statusNotificationEvent?.notificationMessage?.opcode!!,
      statusNotificationEvent?.notificationMessage?.params!!
    );

    dispatchEvent(
      StatusNotificationEvent(
        this,
        StatusNotificationEvent.EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN,
        notificationEvent
      )
    )

  }

  override fun onOnlineStatusEvent(onlineStatusEvent: OnlineStatusEvent?) {
    val infoList = onlineStatusEvent!!.onlineStatusInfoList
    if (infoList != null && meshInfo != null) {
      var statusChangedNode: NodeInfo? = null
      for (onlineStatusInfo in infoList) {
        if (onlineStatusInfo.status == null || onlineStatusInfo.status.size < 3) break
        val deviceInfo = meshInfo!!.getDeviceByMeshAddress(onlineStatusInfo.address)
          ?: continue
        val onOff: Int = if (onlineStatusInfo.sn.toInt() == 0) {
          -1
        } else {
          if (onlineStatusInfo.status[0].toInt() == 0) {
            0
          } else {
            1
          }
        }
        if (deviceInfo.onOff != onOff) {
          statusChangedNode = deviceInfo
        }
        deviceInfo.onOff = onOff
        if (deviceInfo.lum != onlineStatusInfo.status[0].toInt()) {
          statusChangedNode = deviceInfo
          deviceInfo.lum = onlineStatusInfo.status[0].toInt()
        }
        if (deviceInfo.temp != onlineStatusInfo.status[1].toInt()) {
          statusChangedNode = deviceInfo
          deviceInfo.temp = onlineStatusInfo.status[1].toInt()
        }
      }
      statusChangedNode?.let { onNodeInfoStatusChanged(it) }
    }
  }

  /**
   * node info status changed for UI refresh
   */
  private fun onNodeInfoStatusChanged(nodeInfo: NodeInfo) {
    dispatchEvent(
      NodeStatusChangedEvent(
        this,
        NodeStatusChangedEvent.EVENT_TYPE_NODE_STATUS_CHANGED,
        nodeInfo
      )
    )
  }

  override fun onMeshEvent(meshEvent: MeshEvent?) {
    val eventType: String = meshEvent!!.type
    if (MeshEvent.EVENT_TYPE_DISCONNECTED == eventType) {
      AppSettings.ONLINE_STATUS_ENABLE = false
      for (nodeInfo in meshInfo!!.nodes) {
        nodeInfo.onOff = NodeInfo.ON_OFF_STATE_OFFLINE
      }
    }
  }

  companion object {
    private lateinit var reactApplication: TelinkBleApplication

    fun getInstance(): TelinkBleApplication {
      return reactApplication
    }
  }
}
