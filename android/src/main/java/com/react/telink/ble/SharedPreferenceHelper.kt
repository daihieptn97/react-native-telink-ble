/********************************************************************************************************
 * @file SharedPreferenceHelper.java
 *
 * @brief for TLSR chips
 *
 * @author telink
 * @date Sep. 30, 2010
 *
 * @par Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 * All rights reserved.
 *
 * The information contained herein is confidential and proprietary property of Telink
 * Semiconductor (Shanghai) Co., Ltd. and is available under the terms
 * of Commercial License Agreement between Telink Semiconductor (Shanghai)
 * Co., Ltd. and the licensee in separate contract or the terms described here-in.
 * This heading MUST NOT be removed from this file.
 *
 * Licensees are granted free, non-transferable use of the information in this
 * file under Mutual Non-Disclosure Agreement. NO WARRANTY of ANY KIND is provided.
 */
package com.react.telink.ble

import android.content.Context
import com.telink.ble.mesh.core.MeshUtils
import com.telink.ble.mesh.util.Arrays

/**
 * Created by kee on 2017/8/30.
 */
object SharedPreferenceHelper {
  private const val DEFAULT_NAME = "telink_shared"
  private const val KEY_FIRST_LOAD = "com.telink.bluetooth.light.KEY_FIRST_LOAD"
  private const val KEY_LOCATION_IGNORE = "com.telink.bluetooth.light.KEY_LOCATION_IGNORE"
  private const val KEY_LOG_ENABLE = "com.telink.bluetooth.light.KEY_LOG_ENABLE"

  /**
   * scan device by private mode
   */
  private const val KEY_PRIVATE_MODE = "com.telink.bluetooth.light.KEY_PRIVATE_MODE"
  private const val KEY_LOCAL_UUID = "com.telink.bluetooth.light.KEY_LOCAL_UUID"
  private const val KEY_REMOTE_PROVISION = "com.telink.bluetooth.light.KEY_REMOTE_PROVISION"
  private const val KEY_FAST_PROVISION = "com.telink.bluetooth.light.KEY_FAST_PROVISION"
  private const val KEY_NO_OOB = "com.telink.bluetooth.light.KEY_NO_OOB"
  private const val KEY_DLE_ENABLE = "com.telink.bluetooth.light.KEY_DLE_ENABLE"
  private const val KEY_AUTO_PV = "com.telink.bluetooth.light.KEY_AUTO_PV"

  fun isFirstLoad(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_FIRST_LOAD, true)
  }

  fun setFirst(context: Context, isFirst: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_FIRST_LOAD, isFirst).apply()
  }

  fun isLocationIgnore(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_LOCATION_IGNORE, false)
  }

  fun setLocationIgnore(context: Context, ignore: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_LOCATION_IGNORE, ignore).apply()
  }

  fun isLogEnable(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_LOG_ENABLE, false)
  }

  fun setLogEnable(context: Context, enable: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_LOG_ENABLE, enable).apply()
  }

  fun isPrivateMode(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_PRIVATE_MODE, false)
  }

  fun setPrivateMode(context: Context, enable: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_PRIVATE_MODE, enable).apply()
  }

  fun getLocalUUID(context: Context): String {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    var uuid = sharedPreferences.getString(KEY_LOCAL_UUID, null)
    if (uuid == null) {
      uuid = Arrays.bytesToHexString(MeshUtils.generateRandom(16), "").toUpperCase()
      sharedPreferences.edit().putString(KEY_LOCAL_UUID, uuid).apply()
    }
    return uuid
  }

  fun isRemoteProvisionEnable(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_REMOTE_PROVISION, false)
  }

  fun setRemoteProvisionEnable(context: Context, enable: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_REMOTE_PROVISION, enable).apply()
  }

  fun isFastProvisionEnable(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_FAST_PROVISION, false)
  }

  fun setFastProvisionEnable(context: Context, enable: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_FAST_PROVISION, enable).apply()
  }

  fun isNoOOBEnable(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_NO_OOB, true)
  }

  fun setNoOOBEnable(context: Context, enable: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_NO_OOB, enable).apply()
  }

  fun isDleEnable(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_DLE_ENABLE, false)
  }

  fun setDleEnable(context: Context, enable: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_DLE_ENABLE, enable).apply()
  }

  fun isAutoPvEnable(context: Context): Boolean {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    return sharedPreferences.getBoolean(KEY_AUTO_PV, false)
  }

  fun setAutoPvEnable(context: Context, enable: Boolean) {
    val sharedPreferences = context.getSharedPreferences(DEFAULT_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putBoolean(KEY_AUTO_PV, enable).apply()
  }
}
