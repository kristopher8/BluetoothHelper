//
//  PeripheralHelper.swift
//  StopHereManager
//
//  Created by yuszha on 2018/3/2.
//  Copyright © 2018年 yuszha. All rights reserved.
//

import UIKit
import CoreBluetooth

let characteristicUUIDString = "FFF6"

protocol PeripheralHelperDelegate {
    func connectPeripheralSuccess()
}

class PeripheralHelper: NSObject {
    
    static let shared = PeripheralHelper()
    
    var peripheral : CBPeripheral!
    var characteristic : CBCharacteristic!
    var ssid : String!
    var BLEPassword : String!
    var delegate : PeripheralHelperDelegate?
    
    func connectPeripheral(_ ssid: String, password: String) {
        self.characteristic = nil
        self.BLEPassword = nil
        
        self.ssid = ssid
        self.BLEPassword = password
        BlueToothHelper.shared.addDelegate(self)
        BlueToothHelper.shared.discoverPeripherals()
    }
    
    func disConnectPeripheral() {
        if peripheral != nil {
            BlueToothHelper.shared.disConnect(peripheral)
        }
        
        BlueToothHelper.shared.stopDiscoverPeripherals()
        BlueToothHelper.shared.removeDelegate(self)
        self.peripheral = nil
        self.ssid = nil
        self.characteristic = nil
        self.BLEPassword = nil
    }
    
    func write(_ value: Int) -> Bool {
        
        guard let characteristic = self.characteristic, let peripheral = self.peripheral, let passwordStr = BLEPassword else { return false }
        guard checkIsConnect() else {
            return false
        }
  
        var orderStr = ""
        var numberStr = ""
        
        switch value {
        case 1: // "升锁"
            orderStr = "A02"
            numberStr = "00000"
            
        case 0: // "降锁"
            orderStr = "A01"
            numberStr = "00000"
            
        case 2: // "鸣叫"
            orderStr = "A03"
            numberStr = "00010"
            
        case 3: // "停止鸣叫"
            orderStr = "A03"
            numberStr = "00000"
        
        case 4: // "休眠"
            orderStr = "A05"
            numberStr = "00000"
            
        case 5: // "唤醒"
            orderStr = "A02"
            numberStr = "00000"
            
        default:
            break
        }
        
        let order = passwordStr + "M" + orderStr + numberStr
        peripheral.writeValue(BlueToothHelper.shared.dataFromString(order), for: characteristic, type: .withResponse)
        
        return true
//        ShowHUD(success: "指令发送成功")
    }
    
//    func write(_ values:[Int]) {
//        
//       
//    }
    
    func checkIsConnect() -> Bool {
        
        if (peripheral.state == .disconnected) {
            let alertVC = UIAlertController.init(title: "设备已断开", message: "重新连接？", preferredStyle: UIAlertControllerStyle.alert)
            
            alertVC.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (_) in
                BlueToothHelper.shared.connect(self.peripheral)
            }))
            alertVC.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (_) in
                
            }))
            
            (delegate as? UIViewController)?.navigationController?.present(alertVC, animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
    
}
extension PeripheralHelper : BlueToothHelperDelegate {
    
    func discoverPeripheral(_ helper: BlueToothHelper, peripheral: CBPeripheral) {
        guard ssid != nil else {
            return
        }
        if BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] == ssid! {
            self.peripheral = peripheral
            BlueToothHelper.shared.connect(peripheral)
            BlueToothHelper.shared.stopDiscoverPeripherals()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService) {
        
        if peripheral == self.peripheral {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.uuid.uuidString == characteristicUUIDString  && self.characteristic == nil {
                        self.characteristic = characteristic
                        delegate?.connectPeripheralSuccess()
                    }
                }
            }
        }
        
    }
    
    func centralManagerDidConnect(_ peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            self.peripheral.discoverServices(nil)
        }
    }
    
    
    func centralManagerDidDisconnectPeripheral(_ peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            characteristic = nil;
            BlueToothHelper.shared.connect(peripheral)
        }
    }
    
    func centralManagerDidFailToConnect(_ peripheral: CBPeripheral) {
        BlueToothHelper.shared.connect(peripheral)
    }
    
}
