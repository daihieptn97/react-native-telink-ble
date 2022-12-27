# react-native-telink-ble

Telink BLE module for React Native

## Installation

```sh
npm install react-native-telink-ble
```
Add Kotlin support to your project follow this guide: https://developer.android.com/kotlin/add-kotlin


### Add TelinkBleMeshLib to your Gradle settings

Add this to settings.gradle

```
nclude(":TelinkBleMeshLib")
project(":TelinkBleMeshLib").projectDir = new File("../node_modules/react-native-telink-ble/android/TelinkBleMeshLib")
```

Add this to app/build.gradle:

```
dependencies {
  // ...

  implemetation project(":TelinkBleMeshLib")
}
```

Replace your MainApplication.java or MainApplication.kt to extends the TelinkBleApplication class:

```java
import com.react.telink.ble.TelinkBleApplication

class MainApplication : TelinkBleApplication(), ReactApplication {
    // ...
}
```

Replace your MainActivity.java or MainActivity.kt to extends the TelinkBleActivity class:

```
import com.react.telink.ble.TelinkBleActivity

class MainActivity : TelinkBleActivity() {
    // ...
}
```

### Add import statements to your AppDelegate.mm file:

```
#import <react-native-telink-ble/TelinkBle.h>
#import <react-native-telink-ble/TelinkBle+MeshSDK.h>
```

and inside didFinishLaunchingWithOptions method:

```Objective
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // ...
  [self.window makeKeyAndVisible];

  [TelinkBle startMeshSDK]; // <- add this

  return YES;
}
```

### iOS configuration
```
 pod "TelinkSigMeshLib",        :path => "../node_modules/react-native-telink-ble"
  pod "react-native-telink-ble", :path => "../node_modules/react-native-telink-ble"

```

Add the following privacy statements to Info.plist:

```
<key>NSBluetoothPeripheralUsageDescription</key>
<string>App needs Bluetooth permission to scan, connect and control BLE devices</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>App needs Bluetooth permission to scan, connect and control BLE devices</string>
```

## Documentation

Docs available at: [https://docs.thanhtunguet.info/react-native-telink-ble/](https://docs.thanhtunguet.info/react-native-telink-ble/)


```
yarn add react-native-telink-ble
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
