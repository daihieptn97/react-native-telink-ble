package com.react.telink.ble.model;

public interface MeshKey {
  /**
   * @return key name
   */
  String getName();

  /**
   * @return key index
   */
  int getIndex();


  /**
   * @return key value
   */
  byte[] getKey();
}
