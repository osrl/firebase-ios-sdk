//
// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// MARK: This file is used to evaluate the experience of using Firebase APIs in Swift.

import Foundation

import AppCheck
import FirebaseCore

final class AppCheckAPITests {
  func usage() {
    let app = FirebaseApp.app()!
    let projectID = app.options.projectID!
    let resourceName = "projects/\(projectID)/\(app.options.googleAppID)"

    // MARK: - AppAttestProvider

    #if TARGET_OS_IOS
      if #available(iOS 14.0, *) {
        // TODO(andrewheard): Add `requestHooks` in API tests.
        if let provider = InternalAppAttestProvider(
          storageID: app.name,
          resourceName: resourceName,
          apiKey: app.options.apiKey,
          keychainAccessGroup: nil,
          requestHooks: nil
        ) {
          provider.getToken { token, error in
            // ...
          }
        }
      }
    #endif // TARGET_OS_IOS

    // MARK: - AppCheck

    guard let app = FirebaseApp.app() else { return }

    // Retrieving an AppCheck instance
    let appCheck = InternalAppCheck(
      instanceName: app.name,
      appCheckProvider: DummyAppCheckProvider(),
      settings: DummyAppCheckSettings(),
      tokenDelegate: DummyAppCheckTokenDelegate(),
      resourceName: resourceName,
      keychainAccessGroup: app.options.appGroupID
    )

    // Get token
    appCheck.token(forcingRefresh: false) { token, error in
      if let _ /* error */ = error {
        // ...
      } else if let _ /* token */ = token {
        // ...
      }
    }

    // Get token (async/await)
    if #available(iOS 13.0, macOS 10.15, macCatalyst 13.0, tvOS 13.0, watchOS 7.0, *) {
      // async/await is only available on iOS 13+
      Task {
        do {
          try await appCheck.token(forcingRefresh: false)
        } catch {
          // ...
        }
      }
    }

    // MARK: - `AppCheckDebugProvider`

    // `AppCheckDebugProvider` initializer
    // TODO(andrewheard): Add `requestHooks` in API tests.
    let debugProvider = InternalAppCheckDebugProvider(
      storageID: app.name,
      resourceName: resourceName,
      apiKey: app.options.apiKey,
      requestHooks: nil
    )
    // Get token
    debugProvider.getToken { token, error in
      if let _ /* error */ = error {
        // ...
      } else if let _ /* token */ = token {
        // ...
      }
    }

    // Get token (async/await)
    if #available(iOS 13.0, macOS 10.15, macCatalyst 13.0, tvOS 13.0, watchOS 7.0, *) {
      // async/await is only available on iOS 13+
      Task {
        do {
          _ = try await debugProvider.getToken()
        } catch {
          // ...
        }
      }
    }

    _ = debugProvider.localDebugToken()
    _ = debugProvider.currentDebugToken()

    // MARK: - AppCheckToken

    let token = InternalAppCheckToken(token: "token", expirationDate: Date.distantFuture)
    _ = token.token
    _ = token.expirationDate

    // MARK: - AppCheckErrors

    appCheck.token(forcingRefresh: false) { _, error in
      if let error = error {
        switch error {
        case InternalAppCheckErrorCode.unknown:
          break
        case InternalAppCheckErrorCode.serverUnreachable:
          break
        case InternalAppCheckErrorCode.invalidConfiguration:
          break
        case InternalAppCheckErrorCode.keychain:
          break
        case InternalAppCheckErrorCode.unsupported:
          break
        default:
          break
        }
      }
      // ...
    }

    // MARK: - AppCheckProvider

    // A protocol implemented by:
    // - `AppAttestDebugProvider`
    // - `AppCheckDebugProvider`
    // - `DeviceCheckProvider`

    // MARK: - DeviceCheckProvider

    // `DeviceCheckProvider` initializer
    #if !os(watchOS)
      if #available(iOS 11.0, macOS 10.15, macCatalyst 13.0, tvOS 11.0, *) {
        // TODO(andrewheard): Add `requestHooks` in API tests.
        let deviceCheckProvider = InternalDeviceCheckProvider(
          storageID: app.name,
          resourceName: resourceName,
          apiKey: app.options.apiKey,
          requestHooks: nil
        )
        // Get token
        deviceCheckProvider.getToken { token, error in
          if let _ /* error */ = error {
            // ...
          } else if let _ /* token */ = token {
            // ...
          }
        }
        // Get token (async/await)
        if #available(iOS 13.0, tvOS 13.0, *) {
          // async/await is only available on iOS 13+
          Task {
            do {
              _ = try await deviceCheckProvider.getToken()
            } catch InternalAppCheckErrorCode.unsupported {
              // ...
            } catch {
              // ...
            }
          }
        }
      }
    #endif // !os(watchOS)
  }
}

class DummyAppCheckProvider: NSObject, InternalAppCheckProvider {
  func getToken(completion handler: @escaping (InternalAppCheckToken?, Error?) -> Void) {
    handler(InternalAppCheckToken(token: "token", expirationDate: .distantFuture), nil)
  }
}

class DummyAppCheckSettings: NSObject, GACAppCheckSettingsProtocol {
  var isTokenAutoRefreshEnabled: Bool = true
}

class DummyAppCheckTokenDelegate: NSObject, GACAppCheckTokenDelegate {
  func tokenDidUpdate(_ token: InternalAppCheckToken, instanceName: String) {}
}