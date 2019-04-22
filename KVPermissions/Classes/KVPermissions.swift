/**
 Copyright (c) 2019 Vu Van Khac (VTI.D1) <khac.vuvan@vti.com.vn>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import AVFoundation
import Contacts
import CoreMotion
import EventKit
import Foundation
import MediaPlayer
import UIKit
import Photos
import UserNotifications
import Speech

public enum KVLocationType {
    case whenInUse
    case always
}

public enum KVPermissionType {
    case calendar
    case camera
    case contacts
    case location(type: KVLocationType)
    case mediaLibrary
    case microphone
    case motion
    case notification
    case photoLibrary
    case reminder
    case speech
    
    public var isRequested: Bool {
        if !isAllowed, !isDenied {
            return false
        }
        
        return true
    }
    
    public var isAllowed: Bool {
        switch self {
        case .calendar:
            return EKEventStore.authorizationStatus(for: EKEntityType.event) == .authorized
            
        case .camera:
            return AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized
            
        case .contacts:
            if #available(iOS 9.0, *) {
                return CNContactStore.authorizationStatus(for: .contacts) == .authorized
            } else {
                return false
            }
            
        case .location(let type):
            let status = CLLocationManager.authorizationStatus()
            if status == .authorizedAlways {
                return true
            } else {
                switch type {
                case .whenInUse:
                    return status == .authorizedWhenInUse
                case .always:
                    return false
                }
            }
            
        case .mediaLibrary:
            if #available(iOS 9.3, *) {
                return MPMediaLibrary.authorizationStatus() == .authorized
            } else {
                return false
            }
            
        case .microphone:
            return AVAudioSession.sharedInstance().recordPermission == .granted
            
        case .motion:
            if #available(iOS 11.0, *) {
                return CMMotionActivityManager.authorizationStatus() == .authorized
            } else {
                return false
            }
            
        case .notification:
            if #available(iOS 10.0, *) {
                guard let remoteNotificationsAuthorizationStatus = fetchRemoteNotificationsAuthorizationStatus() else { return false }
                return remoteNotificationsAuthorizationStatus == .authorized
            } else {
                if let notificationType = UIApplication.shared.currentUserNotificationSettings?.types, notificationType.isEmpty {
                    return false
                } else {
                    return true
                }
            }
            
        case .photoLibrary:
            return PHPhotoLibrary.authorizationStatus() == .authorized
            
        case .reminder:
            return EKEventStore.authorizationStatus(for: .reminder) == .authorized
            
        case .speech:
            if #available(iOS 10.0, *) {
                return SFSpeechRecognizer.authorizationStatus() == .authorized
            } else {
                return false
            }
        }
    }
    
    public var isDenied: Bool {
        switch self {
        case .calendar:
            return EKEventStore.authorizationStatus(for: EKEntityType.event) == .denied
            
        case .camera:
            return AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .denied
            
        case .contacts:
            if #available(iOS 9.0, *) {
                return CNContactStore.authorizationStatus(for: .contacts) == .denied
            } else {
                return false
            }
            
        case .location(_):
            return CLLocationManager.authorizationStatus() == .denied
            
        case .mediaLibrary:
            if #available(iOS 9.3, *) {
                return MPMediaLibrary.authorizationStatus() == .denied
            } else {
                return false
            }
            
        case .microphone:
            return AVAudioSession.sharedInstance().recordPermission == .denied
            
        case .motion:
            if #available(iOS 11.0, *) {
                return CMMotionActivityManager.authorizationStatus() == .denied
            } else {
                return false
            }
            
        case .notification:
            if #available(iOS 10.0, *) {
                guard let remoteNotificationsAuthorizationStatus = fetchRemoteNotificationsAuthorizationStatus() else { return false }
                return remoteNotificationsAuthorizationStatus == .denied
            } else {
                if let notificationType = UIApplication.shared.currentUserNotificationSettings?.types, notificationType.isEmpty {
                    return true
                } else {
                    return false
                }
            }
            
        case .photoLibrary:
            return PHPhotoLibrary.authorizationStatus() == .denied
            
        case .reminder:
            return EKEventStore.authorizationStatus(for: .reminder) == .denied
            
        case .speech:
            if #available(iOS 10.0, *) {
                return SFSpeechRecognizer.authorizationStatus() == .denied
            } else {
                return false
            }
        }
    }
    
    public func request() {
        if isRequested {
            return
        }
        
        switch self {
        case .calendar:
            let eventStore = EKEventStore()
            eventStore.requestAccess(to: .event) { (granted, error) in }
            
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { (finished) in }
            
        case .contacts:
            if #available(iOS 9.0, *) {
                let store = CNContactStore()
                store.requestAccess(for: .contacts) { (granted, error) in }
            }
            
        case .location(let type):
            switch type {
            case .whenInUse:
                let status = CLLocationManager.authorizationStatus()
                if status == .notDetermined || status == .authorizedAlways {
                    KVStored.shared.locationManager.requestWhenInUseAuthorization()
                }
                
            case .always:
                let status = CLLocationManager.authorizationStatus()
                if status == .notDetermined || status == .authorizedWhenInUse {
                    KVStored.shared.locationManager.requestAlwaysAuthorization()
                }
            }
            
        case .mediaLibrary:
            if #available(iOS 9.3, *) {
                MPMediaLibrary.requestAuthorization { (finished) in }
            }
            
        case .microphone:
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in }
            
        case .motion:
            let today = Date()
            let manager = CMMotionActivityManager()
            manager.queryActivityStarting(from: today, to: today, to: .main) { (activities, error) in
                manager.stopActivityUpdates()
            }
            
        case .notification:
            if #available(iOS 10.0, *) {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in }
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
                UIApplication.shared.registerForRemoteNotifications()
            }
            
        case .photoLibrary:
            PHPhotoLibrary.requestAuthorization { (finished) in }
            
        case .reminder:
            let eventStore = EKEventStore()
            eventStore.requestAccess(to: .reminder) { (granted, error) in }
            
        case .speech:
            if #available(iOS 10.0, *) {
                SFSpeechRecognizer.requestAuthorization { (status) in }
            }
        }
    }
    
    @available(iOS 10.0, *)
    private func fetchRemoteNotificationsAuthorizationStatus() -> UNAuthorizationStatus? {
        var notificationSettings: UNNotificationSettings?
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.global().async {
            UNUserNotificationCenter.current().getNotificationSettings { setttings in
                notificationSettings = setttings
                semaphore.signal()
            }
        }
        
        semaphore.wait()
        return notificationSettings?.authorizationStatus
    }
}

public struct KVPermission {
    public static let calendar: KVPermissionType = .calendar
    public static let camera: KVPermissionType = .camera
    public static let contacts: KVPermissionType = .contacts
    public static let locationWhenInUse: KVPermissionType = .location(type: .whenInUse)
    public static let locationAlways: KVPermissionType = .location(type: .always)
    public static let mediaLibrary: KVPermissionType = .mediaLibrary
    public static let microphone: KVPermissionType = .microphone
    public static let motion: KVPermissionType = .motion
    public static let notification: KVPermissionType = .notification
    public static let photoLibrary: KVPermissionType = .photoLibrary
    public static let reminder: KVPermissionType = .reminder
    public static let speech: KVPermissionType = .speech
}

class KVStored: NSObject {
    static let shared = KVStored()
    
    lazy var locationManager = CLLocationManager()
}
