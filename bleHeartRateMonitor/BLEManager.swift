//
//  BLEManager.swift
//  BLEManager
//
//  Created by Toshiki Nagahama on 2021/08/06.
//

import Foundation
import CoreBluetooth

struct Peripheral: Identifiable {
    let id: Int
    let name: String
    let rssi: Int
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isSwitchedOn = false
    @Published var peripherals = [Peripheral]()
    var myCentral: CBCentralManager!
    @Published public var myPeripheral: CBPeripheral!
    @Published public var writeCharacteristic: CBCharacteristic? = nil
    @Published var value: [Double] = [0.0] //ir

    override init(){
        super.init()
        
        myCentral = CBCentralManager(delegate: self, queue: nil)
        myCentral.delegate = self
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var peripheralName: String!
       
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            peripheralName = name
        }
        else {
            return
        }
       
        let newPeripheral = Peripheral(id: peripherals.count, name: peripheralName, rssi: RSSI.intValue)
        print(newPeripheral)
        peripherals.append(newPeripheral)
        if(peripheralName == "HeartRate_M5StickC"){
            myCentral.stopScan()
            myPeripheral = peripheral
            myCentral.connect(myPeripheral, options: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("接続成功")
        myPeripheral.delegate = self
        myPeripheral.discoverServices(nil)
     }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("接続失敗")
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("サービス発見！")
        let service: CBService = myPeripheral.services![0]
        //print(service)
        myPeripheral.discoverCharacteristics(nil, for: service)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("キャラクタリスティック発見!")
        print(service.characteristics ?? "")
        let byteArray: [UInt8] = [0x33, 0x33, 0x33, 0x33]
        let data = Data(_: byteArray)

        //ペリフェラルの保持しているキャラクタリスティクスから特定のものを探す
        for i in service.characteristics!{
            if i.uuid.uuidString == "BEB5483E-36E1-4688-B7F5-EA07361B26A8"{
                self.writeCharacteristic = i
                peripheral.setNotifyValue(true, for: i)
                peripheral.writeValue(data , for: i, type: .withResponse)
                print("write!")
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let notify: CBUUID = CBUUID(string: "BEB5483E-36E1-4688-B7F5-EA07361B26A8")
        if characteristic.uuid.uuidString == notify.uuidString {
            let message = String(bytes: characteristic.value!, encoding: String.Encoding.ascii)
            let arr:[String] = message!.components(separatedBy: ",")
            value = [atof(arr[0])]
            //print(value)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            isSwitchedOn = true
        }else{
            isSwitchedOn = false
        }
    }
    
    func startScanning() {
         print("startScanning")
        myCentral.scanForPeripherals(withServices: nil, options: nil)
     }
    
    func stopScanning() {
        print("stopScanning")
        myCentral.stopScan()
    }
}
