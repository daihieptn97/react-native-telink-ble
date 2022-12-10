package com.react.telink.ble

import android.Manifest.permission.READ_EXTERNAL_STORAGE
import android.Manifest.permission.WRITE_EXTERNAL_STORAGE
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.*
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.IllegalViewOperationException
import com.react.telink.ble.model.*
import com.react.telink.ble.model.json.MeshStorageService
import com.telink.ble.mesh.core.MeshUtils
import com.telink.ble.mesh.core.access.BindingBearer
import com.telink.ble.mesh.core.message.MeshMessage
import com.telink.ble.mesh.core.message.MeshSigModel
import com.telink.ble.mesh.core.message.NotificationMessage
import com.telink.ble.mesh.core.message.config.*
import com.telink.ble.mesh.core.message.generic.OnOffGetMessage
import com.telink.ble.mesh.core.message.generic.OnOffSetMessage
import com.telink.ble.mesh.core.message.generic.OnOffStatusMessage
import com.telink.ble.mesh.core.message.lighting.*
import com.telink.ble.mesh.core.message.scene.SceneRecallMessage
import com.telink.ble.mesh.core.networking.AccessType
import com.telink.ble.mesh.entity.*
import com.telink.ble.mesh.foundation.Event
import com.telink.ble.mesh.foundation.MeshService
import com.telink.ble.mesh.foundation.event.*
import com.telink.ble.mesh.foundation.parameter.*
import com.telink.ble.mesh.util.Arrays
import com.telink.ble.mesh.util.FileSystem
import com.telink.ble.mesh.util.MeshLogger
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.io.InputStream
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.roundToInt

class TelinkBleModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext), TelinkBleEventEmitter, TelinkBleEventHandler {
    companion object {
        val app: TelinkBleApplication
            get() = TelinkBleApplication.getInstance()

        val meshInfo: MeshInfo
            get() = TelinkBleApplication.getInstance().getMeshInfo()!!
    }

    override fun getName(): String {
        return "TelinkBle"
    }

    private var foundDevice: AdvertisingDevice? = null

    override val eventEmitter: DeviceEventManagerModule.RCTDeviceEventEmitter
        get() = reactApplicationContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)

    private val delayHandler = Handler(Looper.getMainLooper())

    private var currentDevice: NetworkingDevice? = null

    private var targetResettingAddress: Int? = null

    private val timePubSetTimeoutTask =
        Runnable { onTimePublishComplete(false, "time pub set timeout") }

    private var isPubSetting = false


    private var deviceInfo: NodeInfo? = null

    /**
     * Device Group
     */

    private var groupAddress = 0

    private var deviceAddress = 0

    private var modelIndex = 0

    private var opType = 0

    private val models = MeshSigModel.getDefaultSubList()

    init {
        app.addEventListener(ProvisioningEvent.EVENT_TYPE_PROVISION_BEGIN, this)
        app.addEventListener(ProvisioningEvent.EVENT_TYPE_PROVISION_SUCCESS, this)
        app.addEventListener(ProvisioningEvent.EVENT_TYPE_PROVISION_FAIL, this)
        app.addEventListener(BindingEvent.EVENT_TYPE_BIND_SUCCESS, this)
        app.addEventListener(BindingEvent.EVENT_TYPE_BIND_FAIL, this)
        app.addEventListener(ScanEvent.EVENT_TYPE_SCAN_TIMEOUT, this)
        app.addEventListener(ScanEvent.EVENT_TYPE_DEVICE_FOUND, this)
        app.addEventListener(ModelPublicationStatusMessage::class.java.name, this)
        app.addEventListener(OnOffStatusMessage::class.java.name, this)
        app.addEventListener(LightnessStatusMessage::class.java.name, this)
        app.addEventListener(CtlTemperatureStatusMessage::class.java.name, this)
        app.addEventListener(HslStatusMessage::class.java.name, this)
        app.addEventListener(StatusNotificationEvent.EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN, this)
        app.addEventListener(GattOtaEvent.EVENT_TYPE_OTA_SUCCESS, this)
        app.addEventListener(GattOtaEvent.EVENT_TYPE_OTA_PROGRESS, this)
        app.addEventListener(GattOtaEvent.EVENT_TYPE_OTA_FAIL, this)
    }

    @ReactMethod
    fun autoConnect() {
        MeshLogger.log("main auto connect")
        MeshService.getInstance().autoConnect(AutoConnectParameters())
    }

    @ReactMethod
    fun sendRawString(command: String) {
        val meshMessage = MeshMessage()
        val bytes = command.byteArray
        meshMessage.sourceAddress = 0x0000
        meshMessage.destinationAddress = getInt(bytes.sliceArray(IntRange(8, 9))).toInt()
        if (bytes.size == 21) {
            meshMessage.opcode = getIntWith3Bytes(bytes.sliceArray(IntRange(10, 12)))
            meshMessage.params = bytes.sliceArray(IntRange(15, bytes.size - 1))
        } else {
            meshMessage.opcode = getInt(bytes.sliceArray(IntRange(10, 11))).toInt()
            meshMessage.params = bytes.sliceArray(IntRange(12, bytes.size - 1))
        }
        meshMessage.accessType = AccessType.APPLICATION
        meshMessage.appKeyIndex = meshInfo.defaultAppKeyIndex
        meshMessage.retryCnt = 0
        meshMessage.responseMax = meshInfo.onlineCountInAll
        MeshService.getInstance().sendMeshMessage(meshMessage)
    }

    private fun stopMeshScanning() {
        MeshService.getInstance().stopScan()
    }

    @ReactMethod
    fun stopScanning() {
        stopMeshScanning()
        autoConnect()
    }

    private fun startMeshScanning() {
        currentDevice = null;
        val parameters = ScanParameters.getDefault(false, false)
        parameters.setScanTimeout(10 * 1000L)
        MeshService.getInstance().startScan(parameters)
    }

    @ReactMethod
    fun startAddingAllDevices() {
        startMeshScanning()
    }

    @ReactMethod
    fun getNodes(promise: Promise) {
        val nodes = meshInfo.nodes
        val result = WritableNativeArray()
        if (nodes != null) {
            for (node in nodes) {
                if (node.onOffDesc != "OFFLINE") {
                    val nodeInfo = WritableNativeMap()
                    nodeInfo.putString("uuid", node.deviceUUID.hexString)
                    nodeInfo.putString("macAddress", node.macAddress)
                    nodeInfo.putInt("meshAddress", node.meshAddress)
                    nodeInfo.putString("deviceKey", "${node.deviceKey}")
                    result.pushMap(nodeInfo)
                }
            }
            promise.resolve(result)
            return
        }
        promise.resolve(result)
    }

    @ReactMethod
    fun setStatus(meshAddress: Int, status: Boolean) {
        val appKeyIndex: Int = meshInfo.defaultAppKeyIndex
        val onOff = if (status) 1 else 0
        val onOffSetMessage = OnOffSetMessage.getSimple(
            meshAddress,
            appKeyIndex,
            onOff,
            true,
            1
        )
        MeshService.getInstance().sendMeshMessage(onOffSetMessage)
    }

    @ReactMethod
    fun resetNode(meshAddress: Int) {
        // send reset message
        val cmdSent = MeshService.getInstance().sendMeshMessage(NodeResetMessage(meshAddress))
        val kickDirect = meshAddress == MeshService.getInstance().directConnectedNodeAddress
        targetResettingAddress = meshAddress
        if (!cmdSent || !kickDirect) {
            delayHandler.postDelayed(
                {
                    onNodeResetFinished()
                },
                3 * 1000L
            )
        }
    }

    private fun onNodeResetFinished() {
        delayHandler.removeCallbacksAndMessages(null)
        MeshService.getInstance().removeDevice(targetResettingAddress!!)
        meshInfo.removeDeviceByMeshAddress(targetResettingAddress!!)
        meshInfo.saveOrUpdate(reactApplicationContext)
        sendEventWithName(TelinkBleEvent.EVENT_NODE_RESET_SUCCESS, null)
    }

    override fun onDeviceFound(advertisingDevice: AdvertisingDevice) {
        val serviceData = MeshUtils.getMeshServiceData(advertisingDevice.scanRecord, true)

        if (serviceData == null || serviceData.size < 16) {
            MeshLogger.log("serviceData error", MeshLogger.LEVEL_ERROR)
            return
        }


        val uuidLen = 16
        val deviceUUID = ByteArray(uuidLen)
        System.arraycopy(serviceData, 0, deviceUUID, 0, uuidLen)

        val nodeInfo = NodeInfo()
        val scanRecord = advertisingDevice.scanRecord.hexString

        println("scan_provision scan record " + advertisingDevice.scanRecord.hexString)

        val deviceType = scanRecord.substring(147, 147 + 8)
        if (isSupportedDevice(deviceType)) {
            stopMeshScanning()
            nodeInfo.meshAddress = -1
            nodeInfo.deviceUUID = deviceUUID
            nodeInfo.macAddress = advertisingDevice.device.address

            val processingDevice = NetworkingDevice(nodeInfo)
            processingDevice.bluetoothDevice = advertisingDevice.device
            processingDevice.state = NetworkingState.IDLE
            processingDevice.addLog(NetworkingDevice.TAG_SCAN, "device found")
            processingDevice.advertisingDevice = advertisingDevice

            currentDevice = processingDevice
            meshInfo.saveOrUpdate(reactApplicationContext)

            startProvision(processingDevice)
        } else {
            foundDevice = null
            startMeshScanning()
        }

    }

    private fun startProvision(processingDevice: NetworkingDevice) {
        val address: Int = meshInfo.provisionIndex
        MeshLogger.d("alloc address: $address")
        if (!MeshUtils.validUnicastAddress(address)) {
            return
        }
        val deviceUUID = processingDevice.nodeInfo.deviceUUID
        val provisioningDevice = ProvisioningDevice(
            processingDevice.bluetoothDevice,
            processingDevice.nodeInfo.deviceUUID,
            address
        )
        provisioningDevice.oobInfo = processingDevice.oobInfo
        processingDevice.state = NetworkingState.PROVISIONING
        processingDevice.addLog(
            NetworkingDevice.TAG_PROVISION,
            "action start -> 0x" + String.format("%04X", address)
        )
        processingDevice.nodeInfo.meshAddress = address
        // TODO: Send to JS
        // check if oob exists
        val oob: ByteArray? = meshInfo.getOOBByDeviceUUID(deviceUUID)
        provisioningDevice.authValue = oob
        run {
            val autoUseNoOOB = SharedPreferenceHelper.isNoOOBEnable(reactApplicationContext)
            provisioningDevice.isAutoUseNoOOB = autoUseNoOOB
        }
        val provisioningParameters = ProvisioningParameters(provisioningDevice)
        MeshLogger.d("provisioning device: $provisioningDevice")
        MeshService.getInstance().startProvisioning(provisioningParameters)
    }

    override fun onProvisionStart(event: ProvisioningEvent) {
        currentDevice!!.addLog(NetworkingDevice.TAG_PROVISION, "begin")
    }

    override fun onProvisionFail(event: ProvisioningEvent) {
        currentDevice!!.state = NetworkingState.PROVISION_FAIL
        currentDevice!!.addLog(NetworkingDevice.TAG_PROVISION, event.desc)
        /**
         * Continue scanning for other devices
         */
        foundDevice = null
        startMeshScanning()
    }

    override fun onProvisionSuccess(event: ProvisioningEvent) {
        if (currentDevice!!.state == NetworkingState.PROVISIONING) {
            val remote = event.provisioningDevice
            currentDevice!!.state = NetworkingState.BINDING
            currentDevice!!.addLog(NetworkingDevice.TAG_PROVISION, "success")
            val nodeInfo: NodeInfo = currentDevice!!.nodeInfo
            val elementCnt = remote.deviceCapability.eleNum.toInt()
            nodeInfo.elementCnt = elementCnt
            nodeInfo.deviceKey = remote.deviceKey
            nodeInfo.netKeyIndexes.add(meshInfo.defaultNetKey.index)
            meshInfo.insertDevice(nodeInfo)
            meshInfo.increaseProvisionIndex(elementCnt)
            meshInfo.saveOrUpdate(reactApplicationContext)

            // check if private mode opened
            val privateMode = SharedPreferenceHelper.isPrivateMode(reactApplicationContext)

            // check if device support fast bind
            var defaultBound = false
            if (privateMode && remote.deviceUUID != null) {
                val device: PrivateDevice = PrivateDevice.filter(remote.deviceUUID)
                MeshLogger.d("private device")
                val cpsData: ByteArray = device.cpsData
                nodeInfo.compositionData = CompositionData.from(cpsData)
                defaultBound = true
            }
            nodeInfo.isDefaultBind = defaultBound
            currentDevice!!.addLog(NetworkingDevice.TAG_BIND, "action start")

            val appKeyIndex: Int = meshInfo.defaultAppKeyIndex
            val bindingDevice = BindingDevice(nodeInfo.meshAddress, nodeInfo.deviceUUID, appKeyIndex)
            bindingDevice.isDefaultBound = defaultBound
            bindingDevice.bearer = BindingBearer.GattOnly
            // bindingDevice.setDefaultBound(false);
            MeshService.getInstance().startBinding(BindingParameters(bindingDevice))
        }
    }

    override fun onKeyBindFail(event: BindingEvent) {
        currentDevice!!.state = NetworkingState.BIND_FAIL
        currentDevice!!.addLog(NetworkingDevice.TAG_BIND, "failed - " + event.desc)
        meshInfo.saveOrUpdate(reactApplicationContext)
        /**
         * Continue scanning for other devices
         */
        foundDevice = null
        startMeshScanning()
    }

    override fun onKeyBindSuccess(event: BindingEvent) {
        val remote = event.bindingDevice
        val pvDevice = currentDevice!!
        if (currentDevice!!.state == NetworkingState.BINDING) {
            pvDevice.addLog(NetworkingDevice.TAG_BIND, "success")
            pvDevice.nodeInfo.bound = true
            // if is default bound, composition data has been valued ahead of binding action
            if (!remote.isDefaultBound) {
                pvDevice.nodeInfo.compositionData = remote.compositionData
            }
            if (setTimePublish(pvDevice)) {
                pvDevice.state = NetworkingState.TIME_PUB_SETTING
                pvDevice.addLog(NetworkingDevice.TAG_PUB_SET, "action start")
                isPubSetting = true
                MeshLogger.d("waiting for time publication status")
            } else {
                // no need to set time publish
                pvDevice.state = NetworkingState.BIND_SUCCESS
            }

            val advertisingDevice = pvDevice.advertisingDevice
            val bleDevice = WritableNativeMap()
            val manufacturerData = advertisingDevice.scanRecord.hexString

            bleDevice.putString("manufacturerData", manufacturerData)
            bleDevice.putString("deviceType", manufacturerData.substring(147, 147 + 8))
            bleDevice.putString("version", manufacturerData.substring(165, 165 + 5))
            bleDevice.putString("uuid", pvDevice.nodeInfo.deviceUUID.hexString)
            bleDevice.putString("name", advertisingDevice.device.name)
            bleDevice.putString("macAddress", advertisingDevice.device.address)
            bleDevice.putInt("meshAddress", pvDevice.nodeInfo.meshAddress)
            bleDevice.putInt("rssi", advertisingDevice.rssi)
            sendEventWithName(TelinkBleEvent.EVENT_DEVICE_FOUND, bleDevice)
            meshInfo.saveOrUpdate(reactApplicationContext)

            /**
             * Continue scanning for other devices
             */
            foundDevice = null
            startMeshScanning()
        }
    }

    /**
     * There is no need to request permission here
     * Developer have to handle permission request on React Native side
     */
    @SuppressLint("MissingPermission")
    @ReactMethod
    fun turnOnBluetooth() {
        /**
         * TODO: replace deprecated API
         */
        val mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (!mBluetoothAdapter.isEnabled) {
            mBluetoothAdapter.enable()
        }
    }

    /**
     * set time publish after key bind success
     *
     * @param networkingDevice target
     * @return
     */
    private fun setTimePublish(networkingDevice: NetworkingDevice): Boolean {
        val modelId = MeshSigModel.SIG_MD_TIME_S.modelId
        val pubEleAdr = networkingDevice.nodeInfo.getTargetEleAdr(modelId)
        return if (pubEleAdr != -1) {
            val period = 30 * 1000L
            val pubAdr = MeshUtils.ADDRESS_BROADCAST
            val appKeyIndex: Int = meshInfo.defaultAppKeyIndex
            val modelPublication = ModelPublication.createDefault(
                pubEleAdr,
                pubAdr,
                appKeyIndex,
                period,
                modelId,
                true
            )
            val publicationSetMessage = ModelPublicationSetMessage(
                networkingDevice.nodeInfo.meshAddress,
                modelPublication
            )
            val result = MeshService.getInstance().sendMeshMessage(publicationSetMessage)
            if (result) {
                delayHandler.removeCallbacks(timePubSetTimeoutTask)
                delayHandler.postDelayed(timePubSetTimeoutTask, (5 * 1000).toLong())
            }
            result
        } else {
            false
        }
    }

    @ReactMethod
    fun getStatus(meshAddress: Int, promise: Promise) {
        MeshService.getInstance().onlineStatus
        val rspMax: Int = TelinkBleApplication.getInstance().getMeshInfo()!!.getOnlineCountInAll()
        val appKeyIndex: Int = meshInfo.defaultAppKeyIndex
        val onOffGetMessage = OnOffGetMessage.getSimple(
            meshAddress,
            appKeyIndex,
            rspMax
        )
        MeshService.getInstance().sendMeshMessage(onOffGetMessage)
        val response = onOffGetMessage.responseOpcode
        promise.resolve(response)
    }

    @ReactMethod
    fun setBrightness(meshAddress: Int, brightness: Int) {
        val message = LightnessSetMessage.getSimple(
            meshAddress,
            meshInfo.defaultAppKeyIndex,
            UnitConvert.lum2lightness(brightness),
            true,
            1
        )
        MeshService.getInstance().sendMeshMessage(message)
    }

    @ReactMethod
    fun setTemperature(meshAddress: Int, temperature: Int) {
        val temperatureSetMessage = CtlTemperatureSetMessage.getSimple(
            if (meshAddress >= 0xC000) meshAddress else meshAddress + 1,
            meshInfo.defaultAppKeyIndex,
            UnitConvert.temp100ToTemp(temperature),
            0,
            false,
            0
        )
        MeshService.getInstance().sendMeshMessage(temperatureSetMessage)
    }

    @ReactMethod
    fun setHSL(meshAddress: Int, hsl: ReadableMap) {
        val hue = (hsl.getDouble("h") * 65535 / 360).roundToInt()
        val sat = UnitConvert.lum2lightness(hsl.getDouble("s").roundToInt())
        val lum = UnitConvert.lum2lightness(hsl.getDouble("l").roundToInt())
        val hslSetMessage = HslSetMessage.getSimple(
            meshAddress,
            meshInfo.defaultAppKeyIndex,
            lum,
            hue,
            sat,
            false,
            0
        )
        MeshService.getInstance().sendMeshMessage(hslSetMessage)
    }

    @ReactMethod
    fun recallScene(sceneAddress: Int) {
        val sceneRecallMessage = SceneRecallMessage.getSimple(
            0xFFFF,
            meshInfo.defaultAppKeyIndex,
            sceneAddress,
            false,
            0
        )
        MeshService.getInstance().sendMeshMessage(sceneRecallMessage)
    }

    @ReactMethod
    fun addDeviceToGroup(deviceAddress: Int, groupAddress: Int, promise: Promise) {
        deviceInfo = meshInfo.getDeviceByMeshAddress(deviceAddress)
        this.groupAddress = groupAddress
        this.deviceAddress = deviceAddress
        opType = 0;
        modelIndex = 0
        setNextModel(promise)
    }

    @ReactMethod
    fun removeDeviceFromGroup(deviceAddress: Int, groupAddress: Int, promise: Promise) {
        deviceInfo = meshInfo.getDeviceByMeshAddress(deviceAddress)
        this.groupAddress = groupAddress
        this.deviceAddress = deviceAddress
        opType = 1
        setNextModel(promise)
    }

    private fun setNextModel(promise: Promise) {

        val failDevice = WritableNativeMap();

        failDevice.putString("uuid", deviceInfo?.deviceUUID?.hexString)
        failDevice.putString("macAddress", deviceInfo?.macAddress)
        failDevice.putInt("meshAddress", deviceAddress)
        failDevice.putInt("groupAddress", groupAddress)


        val eleAdr = deviceInfo!!.getTargetEleAdr(models[modelIndex].modelId)
        if (eleAdr == -1) {
            modelIndex++
            setNextModel(promise)
            return
        }
        val groupingMessage: MeshMessage = ModelSubscriptionSetMessage.getSimple(
            deviceAddress,
            opType,
            eleAdr,
            groupAddress,
            models[modelIndex].modelId,
            true
        )
        if (!MeshService.getInstance().sendMeshMessage(groupingMessage)) {
            delayHandler.removeCallbacksAndMessages(null)
            promise.reject("SetGroupFail", "SetGroupFail " + deviceAddress.toString(), failDevice)
        } else {
            if (opType == 0) {
                deviceInfo!!.subList.add(groupAddress)
            } else {
                deviceInfo!!.subList.remove(groupAddress as Int?)
            }
            promise.resolve(groupAddress)
            TelinkBleApplication.getInstance().getMeshInfo()?.saveOrUpdate(reactApplicationContext)
        }

    }

    @ReactMethod
    fun requestFilePermission(error: Callback, success: Callback) {
        try {
            if (!checkPermission()) {
                requestPermission();
                success.invoke(false)
            } else {
                success.invoke(true)
            }
        } catch (e: IllegalViewOperationException) {
            error.invoke(e.message)
        }
    }

    private fun checkPermission(): Boolean {
        return if (Build. VERSION.SDK_INT >= Build. VERSION_CODES.R) {
            Environment.isExternalStorageManager();
        } else {
            val read = ContextCompat.checkSelfPermission(reactApplicationContext, READ_EXTERNAL_STORAGE);
            val write = ContextCompat.checkSelfPermission(reactApplicationContext, WRITE_EXTERNAL_STORAGE);
            read == PackageManager.PERMISSION_GRANTED && write == PackageManager.PERMISSION_GRANTED;
        }
    }

    private fun requestPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                intent.addCategory("android.intent.category.DEFAULT");
                intent.data = Uri.parse(String.format("package:%s", reactApplicationContext.packageName));
                currentActivity!!.startActivityForResult(intent, 2256) ;
            } catch (e: Exception) {
                val intent = Intent();
                intent.action = Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION;
                currentActivity!!.startActivityForResult(intent, 2256) ;
            }
        } else {
            // Below Android 11
            ActivityCompat.requestPermissions(
                currentActivity!!,
                arrayOf(WRITE_EXTERNAL_STORAGE, READ_EXTERNAL_STORAGE),100);
        }
    }

    @ReactMethod
    fun resetMeshNetwork(promise: Promise) {
        MeshService.getInstance().idle(true)
        val meshInfo = MeshInfo.createNewMesh(reactApplicationContext)
        TelinkBleApplication.getInstance().setupMesh(meshInfo)
        MeshService.getInstance().setupMeshNetwork(meshInfo.convertToConfiguration())
        promise.resolve("reset success")
    }

    @ReactMethod
    fun getMeshNetwork(promise: Promise) {
        val meshNetwork = TelinkBleApplication.getInstance().getMeshInfo()
        val meshNetworkInfo = WritableNativeMap();

        meshNetworkInfo.putString("appKey",
            (Arrays.bytesToHexString(meshNetwork!!.appKeyList[0].key, "")))
        meshNetworkInfo.putString("netKey", Arrays.bytesToHexString(meshNetwork.meshNetKeyList[0].key, ""))

        promise.resolve(meshNetworkInfo)
    }

    private val sdf = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss")
    private var exportDir: File? = null

    @ReactMethod
    fun getMeshNetworkString(promise: Promise) {
        val meshInfo: MeshInfo = TelinkBleApplication.getInstance().getMeshInfo()!!
        val selectedKeys = TelinkBleApplication.getInstance().getMeshInfo()!!.meshNetKeyList
        val jsonStr = MeshStorageService.getInstance().meshToJsonString(meshInfo, selectedKeys)
        if (jsonStr.isNotEmpty()) {
            promise.resolve(jsonStr)
        } else {
            promise.reject("export_failed", "export failed")
        }
    }

    @ReactMethod
    fun importMeshNetworkString(meshJson: String, promise: Promise) {
        val meshInfo: MeshInfo = TelinkBleApplication.getInstance().getMeshInfo()!!
        val newMesh: MeshInfo = try {
            MeshStorageService.getInstance().importExternal(meshJson, meshInfo)
        } catch (e: java.lang.Exception) {
            e.printStackTrace()
            promise.reject("import_failed", "import_failed")
            return
        }
        newMesh.saveOrUpdate(reactApplicationContext)
        MeshService.getInstance().idle(true)
        TelinkBleApplication.getInstance().setupMesh(newMesh)
        MeshService.getInstance().setupMeshNetwork(newMesh.convertToConfiguration())
        promise.resolve(true)
    }

    @ReactMethod
    fun exportMeshNetwork(database: String, promise: Promise) {
        val meshInfo: MeshInfo = TelinkBleApplication.getInstance().getMeshInfo()!!
        exportDir = FileSystem.getSettingPath()
        val selectedKeys = TelinkBleApplication.getInstance().getMeshInfo()!!.meshNetKeyList
        val fileName = """mesh_${sdf.format(Date())}.json"""

        try {
            val file: File = MeshStorageService.getInstance().exportMeshToJson(
                exportDir,
                fileName,
                meshInfo,
                selectedKeys,
                database
            )

            val fileCreated = WritableNativeMap()

            println("filePath " + file.absolutePath);

            fileCreated.putString("fileName", fileName)
            fileCreated.putString("filePath", file.absolutePath)

            promise.resolve(fileCreated)
        } catch (e: Exception) {
            promise.reject("export_fail", "export_fail")
        }

    }

    @ReactMethod
    fun importMeshNetworkAndroid(filePath: String, promise: Promise) {
        try {
            val file = File(filePath)

            if (!file.exists()) {
                println("file not exist")
                return
            }
            val jsonData = FileSystem.readString(file)
            val localMesh: MeshInfo = TelinkBleApplication.getInstance().getMeshInfo()!!
            var newMesh: MeshInfo? = null
            try {
                newMesh = MeshStorageService.getInstance().importExternal(jsonData, localMesh)
            } catch (e: java.lang.Exception) {
                e.printStackTrace()
            }
            if (newMesh == null) {
                println("import failed")
                promise.reject("import_failed", "import_failed")
                return
            }

            newMesh.saveOrUpdate(reactApplicationContext)
            MeshService.getInstance().idle(true)
            TelinkBleApplication.getInstance().setupMesh(newMesh)
            MeshService.getInstance().setupMeshNetwork(newMesh.convertToConfiguration())

            promise.resolve(jsonData)

            println("import success")
        } catch (e: Exception) {
            promise.reject("import_failed", "import_failed")
        }
    }



    @ReactMethod
    fun otaDevice(meshAddress: Int, filePath: String, promise: Promise) {

        val mFirmware: ByteArray

        try {
            val stream: InputStream = FileInputStream(filePath)
            val length = stream.available()
            mFirmware = ByteArray(length)
            stream.read(mFirmware)
            stream.close()
            val connectionFilter =
                ConnectionFilter(ConnectionFilter.TYPE_MESH_ADDRESS, meshAddress)
            val parameters = GattOtaParameters(connectionFilter, mFirmware)
            MeshService.getInstance().startGattOta(parameters)
            promise.resolve("start ota")
        } catch (e: IOException) {
            e.printStackTrace()
            promise.reject("start_ota_failed", "start_ota_failed")
        }
    }

    private fun onOtaDeviceSuccess(event: GattOtaEvent) {
        val desc = event.desc
        val progress = event.progress
        println("ota_success desc $desc")
        println("ota_success progress $progress")

        val otaContent = WritableNativeMap();
        otaContent.putString("description", desc)
        otaContent.putInt("progress", progress)

        sendEventWithName(TelinkBleEvent.EVENT_TYPE_OTA_SUCCESS, otaContent)
    }

    private fun onOtaDeviceProgress(event: GattOtaEvent) {
        val desc = event.desc
        val progress = event.progress
        println("ota_progress desc $desc")
        println("ota_progress progress $progress")

        val otaContent = WritableNativeMap();
        otaContent.putString("description", desc)
        otaContent.putInt("progress", progress)

        sendEventWithName(TelinkBleEvent.EVENT_TYPE_OTA_PROGRESS, otaContent)
    }

    private fun onOtaDeviceFail(event: GattOtaEvent) {
        val desc = event.desc
        val progress = event.progress
        println("ota_fail desc $desc")

        val otaContent = WritableNativeMap();
        otaContent.putString("description", desc)
        otaContent.putInt("progress", progress)

        sendEventWithName(TelinkBleEvent.EVENT_TYPE_OTA_FAIL, otaContent)
    }



    override fun onReceiveNotificationMessageUnknown(notificationMessage: NotificationMessage) {
        val notification = WritableNativeMap()
        notification.putInt("source", notificationMessage.src)
        notification.putInt("destination", notificationMessage.dst)
        notification.putInt("opcode", notificationMessage.opcode)
        notification.putString("params", notificationMessage.params.hexString)
        sendEventWithName(TelinkBleEvent.EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN, notification)
    }

    private fun onTimePublishComplete(success: Boolean, desc: String) {
        if (!isPubSetting) return
        meshInfo.saveOrUpdate(reactApplicationContext)
    }

    override fun onUnprovisionedDeviceScanningFinish() {
        sendEventWithName(TelinkBleEvent.EVENT_SCANNING_TIMEOUT, null)
        autoConnect()
    }

    override fun onModelPublicationStatusMessage(event: Event<String?>?) {
        MeshLogger.d("pub setting status: $isPubSetting")
        if (!isPubSetting) {
            return
        }
        delayHandler.removeCallbacks(timePubSetTimeoutTask)
        val statusNotificationEvent = event as StatusNotificationEvent
        val statusMessage =
            statusNotificationEvent.notificationMessage.statusMessage as ModelPublicationStatusMessage
        if (statusMessage.status.toInt() == ConfigStatus.SUCCESS.code) {
            onTimePublishComplete(true, "time pub set success")
            return;
        }

        onTimePublishComplete(false, "time pub set status err: " + statusMessage.status)
        MeshLogger.log("publication err: " + statusMessage.status)
    }

    override fun performed(event: Event<String?>?) {
        when {
            event!!.type == ProvisioningEvent.EVENT_TYPE_PROVISION_BEGIN -> {
                onProvisionStart(event as ProvisioningEvent)
                val device = event as ProvisioningEvent
                println("scan_device provision begin " + device.provisioningDevice.bluetoothDevice.address)
                println("scan_device provision begin " + device.provisioningDevice.deviceUUID.hexString)
            }
            event.type == ProvisioningEvent.EVENT_TYPE_PROVISION_SUCCESS -> {
                onProvisionSuccess(event as ProvisioningEvent)
                val device = event as ProvisioningEvent
                println("scan_device provision success " + device.provisioningDevice.bluetoothDevice.address)
                println("scan_device provision success " + device.provisioningDevice.deviceUUID.hexString)

            }
            event.type == ScanEvent.EVENT_TYPE_SCAN_TIMEOUT -> {
                onUnprovisionedDeviceScanningFinish()
            }
            event.type == ProvisioningEvent.EVENT_TYPE_PROVISION_FAIL -> {
                onProvisionFail(event as ProvisioningEvent)
                val device = event as ProvisioningEvent
                println("scan_device provision fail " + device.provisioningDevice.bluetoothDevice.address)
                println("scan_device provision fail " + device.provisioningDevice.deviceUUID.hexString)
            }
            event.type == BindingEvent.EVENT_TYPE_BIND_SUCCESS -> {
                onKeyBindSuccess(event as BindingEvent)
                val device = event as BindingEvent
                println("scan_device binding success " + device.bindingDevice.deviceUUID.hexString)
            }
            event.type == BindingEvent.EVENT_TYPE_BIND_FAIL -> {
                onKeyBindFail(event as BindingEvent)
                val device = event as BindingEvent
                println("scan_device binding fail " + device.bindingDevice.deviceUUID.hexString)
            }
            event.type == ScanEvent.EVENT_TYPE_DEVICE_FOUND -> {
                val scanEvent = event as ScanEvent
                if (foundDevice == null) {
                    foundDevice = scanEvent.advertisingDevice;
                    println("scan_device device found " + scanEvent.advertisingDevice.device.address)
                    onDeviceFound(scanEvent.advertisingDevice)
                }

            }
            event.type == ModelPublicationStatusMessage::class.java.name -> {
                onModelPublicationStatusMessage(event)
            }
            event.type == OnOffStatusMessage::class.java.name -> {
                /**
                 * TODO: handle onOff status message
                 */
                println(event.type)
            }
            event.type == LightnessStatusMessage::class.java.name -> {
                /**
                 * TODO: handle lightness status message
                 */
                println(event.type)
            }
            event.type == CtlTemperatureStatusMessage::class.java.name -> {
                /**
                 * TODO: handle temperature status message
                 */
                println(event.type)
            }
            event.type == HslStatusMessage::class.java.name -> {
                /**
                 * TODO: handle HSL status message
                 */
                println(event.type)
            }
            event.type == StatusNotificationEvent.EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN -> {
                /**
                 * TODO: handle status notification unknown message
                 */
                val scanEvent = event as StatusNotificationEvent
                val notification = scanEvent.notificationMessage
                onReceiveNotificationMessageUnknown(notification)
            }
            event.type == GattOtaEvent.EVENT_TYPE_OTA_FAIL -> {
                val scanEvent = event as GattOtaEvent
                onOtaDeviceFail(scanEvent)
                println(event.type)
            }
            event.type == GattOtaEvent.EVENT_TYPE_OTA_PROGRESS -> {
                val scanEvent = event as GattOtaEvent
                onOtaDeviceProgress(scanEvent)
                println(event.type)
            }
            event.type == GattOtaEvent.EVENT_TYPE_OTA_SUCCESS -> {
                val scanEvent = event as GattOtaEvent
                onOtaDeviceSuccess(scanEvent)
                println(event.type)
            }
            else -> {
                println("other " + event.type)
            }
        }
    }
}
