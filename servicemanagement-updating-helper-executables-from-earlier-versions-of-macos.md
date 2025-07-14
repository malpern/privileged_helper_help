<!--
Downloaded via https://llm.codes by @steipete on July 14, 2025 at 09:14 AM
Source URL: https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos
Total pages processed: 37
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos

- Service Management
- Updating helper executables from earlier versions of macOS

Article

# Updating helper executables from earlier versions of macOS

Simplify your app’s helper executables and support new authorization controls.

## Overview

Launch daemons, launch agents, and startup items are helper executables that macOS starts on behalf of the user that extend the capabilities of apps or provide additional capabilities to users. For example, a `LaunchDaemon` can provide persistent background service for an app, a `LaunchAgent` can provide auxiliary UI capabilities like menu bar extras, and a `LoginItem` can provide the ability to automount remote directories or launch applications when the user logs in.

Prior to macOS 13, part of the application-design process of helper executables included scripts that installed one or more property lists into specific directories based on the type of service, such as the following locations of property lists:

`$HOME/Library/LaunchAgents`

`/Library/LaunchAgents`

`/Library/LaunchDaemons`

In macOS 13 and later, a new structure in the app bundle simplifies the installation of these login items and associated property lists. This new structure allows you to keep helper app resources inside the app’s bundle, which reduces the need for specialized installation scripts or permission to write files into system directories.

### Upgrade existing projects

Upgrading an existing project requires the following general steps — some of which may be optional based on the type of services your app provides:

- Install the helper executable within the app bundle, such as in `Contents/Resources`.

- Install `LaunchAgent` property lists in the app bundle in `Contents/Library/LaunchAgents`.

- Install `LaunchDaemon` property lists in the app bundle in `Contents/Library/LaunchDaemons`.

- In the agents and daemons property lists, replace the `Program` key with the `BundleProgram` key and make the path relative to the bundle, such as `Contents/Resources/mydaemon`.

Apps that don’t use the new bundle structure can determine whether their app’s login items are in a disabled state by checking `statusForLegacyPlist(at:)`, which returns one of the `SMAppService.Status` constants that describes the authorization status. Then your app can alert the user to take an appropriate action depending on the importance of the helper executable.

In apps that target macOS 13 and later, your app needs to only use the property list locations outlined above.

### Connect services to app names in System Settings

Every app that supports a `LoginItem`, `LaunchAgent`, or `LaunchDaemon` has a corresponding switch in the Login Items panel in System Settings. The user can use this switch to allow the corresponding executables to run when they log in, or in the case of a `LaunchDaemon`, when the system starts up.

`LaunchAgents` and `LaunchDaemons` in the app bundle automatically associate with that app in the Login Items panel.

`LaunchAgents` and `LaunchDaemons` that aren’t using the app bundle can adopt the new `AssociatedBundleIdentifiers` key in their `launchd` property list. This optional key indicates which bundles the Login Items panel associates with the helper executable. If an app installs a legacy property list, the property list needs to include the `AssociatedBundleIdentifiers` key with a value of the app’s bundle identifier.

If a legacy `LaunchAgent` or `LaunchDaemon` doesn’t have the `AssociatedBundleIdentifiers` key in its property list, instead of the app name, System Settings displays the organization name in the app’s signing certificate.

If the system can’t attribute a `LaunchAgent` or `LaunchDaemon` to an app and the executable isn’t signed, System Settings displays the executable name from the `Program` or `ProgramArguments` key in the legacy property list.

### Respond to changes in System Settings

In macOS 13 and later, your app can check the authorization state in the System Settings using the `SMAppService` class to get the status of a `LoginItem`, `LaunchAgent`, or `LaunchDaemon`.

The example below demonstrates checking the authorization state of the three kinds of helper executables with the bundle identifier or property lists:

func initializer_demo() {
// The identifier must match the CFBundleIdentifier string in Info.plist.

// LoginItem path: $APP.app/Contents/Library/LoginItems/MyMenuExtra.app/Contents/Info.plist
let loginItem = SMAppService.loginItem(identifier: "com.example.mymenuextra")

// LaunchDaemon path: $APP.app/Contents/Library/LaunchDaemons/com.example.daemon.plist
let daemon = SMAppService.daemon(plistName: "com.example.daemon.plist");

// LaunchAgent path: $APP.app/Contents/Library/LaunchAgents/com.example.agent.plist
let agent = SMAppService.agent(plistName: "com.example.agent.plist");

// Retrieving the app reference if the main app itself needs to launch instead of a helper.
let mainApp = SMAppService.mainApp
}

The example below shows an approach to user interaction with the System Settings check box to register and unregister a helper executable:

func handle_checkbox_toggle(_ checked: Bool) {
let service = SMAppService.loginItem(identifier:"com.example.mymenuextra")
if (checked) {
do {
try service.register()
} catch {
os_log("Unable to register \(error)")
}
} else {
service.unregister(completionHandler: { error in
if let error = error {
os_log("Unable to unregister \(error)")
} else {
// Successfully unregistered service.
}
})
}
}

If your app uses launch daemons, it needs to register those first. Launch daemons require authentication by the user because the user is authorizing a system level-process. If the user authorizes the `LaunchDaemon`, the system approves all the other helper executables present in the app bundle, which results in fewer authorization interactions with the user. If your app doesn’t provide a `LauchDaemon`, it needs to register each `LoginItem` or `LaunchAgent`.

If your app depends on its helper executables to operate correctly, it needs to check the authorization state and allow the user to change the app’s authorization. If the user agrees, call `openSystemSettingsLoginItems()` to open the System Settings so they can enable or disable the app’s helper executables.

## See Also

### Essentials

Updating your app package installer to use the new Service Management API

Learn about the Service Management API with a GUI-less agent app.

---

# https://developer.apple.com/documentation/servicemanagement

Framework

# Service Management

Manage startup items, launch agents, and launch daemons from within an app.

## Overview

Use Service Management to install and observe the permission settings of three supplemental helper executables that macOS supports. You can use all three of these to provide additional functionality related to your app, from inside your app’s bundle:

LoginItems

An app that `launchd` starts when the user logs in. A `LoginItem` is an app that continues running until the user logs out or manually quits. Its primary purpose is to enable the system to launch helper executables automatically

LaunchAgents

Processes that run on behalf of the currently logged-in user. `launchd`, a system-level process, manages Agents. Agents can communicate with other processes in the same user session and with system-wide daemons in the system context.

LaunchDaemons

A stand-alone background process that `launchd` manages on behalf of the user and which runs as root and may run before any users have logged on to the system. A daemon doesn’t interact with a user process directly; it can only respond to requests made by user processes in the form of a low-level request, such as a system request, for example XPC, low-level Interprocess Communications system.

## Topics

### Essentials

Updating helper executables from earlier versions of macOS

Simplify your app’s helper executables and support new authorization controls.

Updating your app package installer to use the new Service Management API

Learn about the Service Management API with a GUI-less agent app.

### Management

`class SMAppService`

An object the framework uses to control helper executables that live inside an app’s main bundle.

Submits the executable for the given label as a job to `launchd`.

Deprecated

Constants that describe the ability to authorize helper executables or modify daemon applications.

Property list keys that describe the kinds of applications, daemons, and helper executables the framework manages.

### Enablement

Enables a helper executable in the main app-bundle directory.

### Status

`enum Status`

Constants that describe the registration or authorization status of a helper executable.

### Errors

Errors that the framework returns.

### Variables

`let SMAppServiceErrorDomain: String`

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/statusforlegacyplist(at:)

#app-main)

- Service Management
- SMAppService
- statusForLegacyPlist(at:)

Type Method

# statusForLegacyPlist(at:)

Check the authorization status of an earlier OS version login item.

## Parameters

`url`

The URL of the helper executable’s property list.

## Return Value

One of the `SMAppService.Status` constants that indicate the current authorization status.

## Mentioned in

Updating helper executables from earlier versions of macOS

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum

- Service Management
- SMAppService
- SMAppService.Status

Enumeration

# SMAppService.Status

Constants that describe the registration or authorization status of a helper executable.

enum Status

## Mentioned in

Updating helper executables from earlier versions of macOS

## Topics

### Constants

`case notRegistered`

The service hasn’t registered with the Service Management framework, or the service attempted to reregister after it was already registered.

`case enabled`

The service has been successfully registered and is eligible to run.

`case requiresApproval`

The service has been successfully registered, but the user needs to take action in System Preferences.

`case notFound`

An error occurred and the framework couldn’t find this service.

### Initializers

`init?(rawValue: Int)`

## Relationships

### Conforms To

- `BitwiseCopyable`
- `Equatable`
- `Hashable`
- `RawRepresentable`
- `Sendable`
- `SendableMetatype`

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/opensystemsettingsloginitems()

#app-main)

- Service Management
- SMAppService
- openSystemSettingsLoginItems()

Type Method

# openSystemSettingsLoginItems()

Opens System Settings to the Login Items control panel.

class func openSystemSettingsLoginItems()

## Mentioned in

Updating helper executables from earlier versions of macOS

---

# https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api

- Service Management
- Updating your app package installer to use the new Service Management API

Sample Code

# Updating your app package installer to use the new Service Management API

Learn about the Service Management API with a GUI-less agent app.

Download

Xcode 15.0+

## Overview

This sample project contains three targets:

- `SampleLaunchAgent`, which builds a sample `LaunchAgent` helper executable.

- `SMAppServiceSampleCode`, which builds a GUI-less app that contains the sample launch agent binary property list and an executable to register the agent at install time.

- `SMAppServiceSamplePackage`, which builds the `SMAppServiceSample.pkg` installer you use to install the `SampleLaunchAgent` helper executable.

In addition to demonstrating the new package structure, this sample demonstrates the APIs for registering helper executables. To register a launch agent, the sample creates an agent object, `SMAppService.agent(plistName:)` and then calls `register()`.

let service = SMAppService.agent(plistName: "com.xpc.example.agent.plist")

do {
try service.register()
print("Successfully registered \(service)")
} catch {
print("Unable to register \(error)")
exit(1)
}

To unregister a launch agent, the sample creates an agent object, `SMAppService.agent(plistName:)` and then calls `unregister()`.

do {
try service.unregister()
print("Successfully unregistered \(service)")
} catch {
print("Unable to unregister \(error)")
exit(1)
}

To determine the authorization state of a launch agent, the sample creates an agent object, `SMAppService.agent(plistName:)` and then calls `status()` to determine the helper executable’s authorization state.

print("\(service) has status \(service.status)")

### Configure the sample code project

To set the Team ID for the sample app and package targets, follow these steps:

1. Open `SMAppServiceSampleCode.xcodeproj` in Xcode.

2. Select the `SMAppServiceSampleCode` target from the project editor.

3. Click Signing & Capabilities.

4. Choose your team from the Team pop-up menu.

5. Select the `SMAppServiceSamplePackage` from the project editor and repeat step 4.

### Build the sample app service

1. Open Terminal and change to the directory into which you downloaded the `UpdatingYourAppPackageInstallerToUseTheNewServiceManagementAPI` source code.

2. Run the command `xcodebuild -target SMAppServiceSamplePackage`.

Xcode builds the `SMAppServiceSamplePackage` installer package, and the process concludes with Xcode printing `** BUILD SUCCEEDED **` to the terminal.

### Install the login item and launch agent

1. In Terminal, navigate to the `build/Release` directory using the command `cd build/Release`.

2. Open the build directory in Finder with the command `open .`.

3. The Finder window contains all the products that the Xcode build process creates, including a package installer named `SMAppServiceSample`. Double-click the installer icon to run it, and follow the instructions to approve the installation of the `SMAppServiceSampleCode` login item and its supporting `SampleLaunchAgent` helper executable.

### Run the sample launch agent

The installer adds a new login item in System Settings and installs the sample launch agent `SampleLaunchAgent` in the directory `/Library/Application Support/YOURDEVELOPERNAME`. Run the `SampleLaunchAgent` executable from the Terminal by invoking the command line app inside the app bundle with an additional command argument:

`/Library/Application Support/YOURDEVELOPERNAME/SMAppServiceSampleCode.app/Contents/MacOS/SMAppServiceSampleCode COMMAND`

The `SMAppServiceSampleCode` app supports the following commands:

- `register` — Registers the `SampleLaunchAgent`.

- `unregister` — Unregisters the `SampleLaunchAgent`.

- `status` — Checks the authorization status of the `SampleLaunchAgent`.

- `test` — Sends an XPC message to the `SampleLaunchAgent` and displays the reply.

The output from the app resembles the following, for each of the app’s commands:

% /Library/Application Support/YOURDEVELOPERNAME/SMAppServiceSampleCode.app/Contents/MacOS/SMAppServiceSampleCode register
Successfully registered LaunchAgent(com.xpc.example.agent.plist)

% /Library/Application Support/YOURDEVELOPERNAME/SMAppServiceSampleCode.app/Contents/MacOS/SMAppServiceSampleCode status
LaunchAgent(com.xpc.example.agent.plist) has status SMAppServiceStatus(rawValue: 1)

% /Library/Application Support/YOURDEVELOPERNAME/SMAppServiceSampleCode.app/Contents/MacOS/SMAppServiceSampleCode test
Received "Hello World"

% /Library/Application Support/YOURDEVELOPERNAME/SMAppServiceSampleCode.app/Contents/MacOS/SMAppServiceSampleCode unregister
Successfully unregistered LaunchAgent(com.xpc.example.agent.plist)

Running the app before registering the service, or after unregistering the service, results in an error.

% /Library/Application Support/YOURDEVELOPERNAME/SMAppServiceSampleCode.app/Contents/MacOS/SMAppServiceSampleCode test

### Uninstall the login item and launch agent

To uninstall the sample app’s login item from System Settings, as well as the `SampleLaunchAgent`, use the following command:

`sudo rm -rf /Library/Application Support/YOURDEVELOPERNAME`

## See Also

### Essentials

Updating helper executables from earlier versions of macOS

Simplify your app’s helper executables and support new authorization controls.

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/statusforlegacyplist(at:)),

),#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/opensystemsettingsloginitems())

)#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/smappservice

- Service Management
- SMAppService

Class

# SMAppService

An object the framework uses to control helper executables that live inside an app’s main bundle.

class SMAppService

## Overview

In macOS 13 and later, use `SMAppService` to register and control `LoginItems`, `LaunchAgents`, and `LaunchDaemons` as helper executables for your app. When converting code from earlier versions of macOS, use an `SMAppService` object and select one of the following methods depending on the type of service your helper executable provides:

- For `SMAppServices` initialized as `LoginItems`, the `register()` and `unregister()` APIs provide a replacement for `SMLoginItemSetEnabled(_:_:)`.

- For `SMAppServices` initialized as `LaunchAgents`, the `register()` and `unregister()` methods provide a replacement for installing property lists in `~/Library/LaunchAgents` or `/Library/LaunchAgents`.

- For `SMAppServices` initialized as `LaunchDaemons`, the `register()` and `unregister()` methods provide a replacement for installing property lists in `/Library/LaunchDaemons`.

## Topics

### Registering services

`func register() throws`

Registers the service so it can begin launching subject to user approval.

`func unregister() throws`

Unregisters the service so the system no longer launches it.

Unregisters the service so the system no longer launches it and calls a completion handler you provide with the resulting error value.

### Managing apps

`class var mainApp: SMAppService`

An app service object that corresponds to the main application as a login item.

Initializes an app service object with a launch agent with the property list name you provide.

Initializes an app service object with a launch daemon with the property list name you provide.

Initializes an app service object for a login item corresponding to the bundle with the identifier you provide.

### Interacting with System Settings

`class func openSystemSettingsLoginItems()`

Opens System Settings to the Login Items control panel.

### Getting the state of the service

`var status: SMAppService.Status`

A property that describes registration or authorization state of the service.

`enum Status`

Constants that describe the registration or authorization status of a helper executable.

### Checking authorization for earlier OS version login items

Check the authorization status of an earlier OS version login item.

## Relationships

### Inherits From

- `NSObject`

### Conforms To

- `CVarArg`
- `CustomDebugStringConvertible`
- `CustomStringConvertible`
- `Equatable`
- `Hashable`
- `NSObjectProtocol`

## See Also

### Management

Submits the executable for the given label as a job to `launchd`.

Deprecated

Constants that describe the ability to authorize helper executables or modify daemon applications.

Property list keys that describe the kinds of applications, daemons, and helper executables the framework manages.

---

# https://developer.apple.com/documentation/servicemanagement/smjobbless(_:_:_:_:)

#app-main)

- Service Management
- SMJobBless(\_:\_:\_:\_:) Deprecated

Function

# SMJobBless(\_:\_:\_:\_:)

Submits the executable for the given label as a job to `launchd`.

macOS 10.6–13.0Deprecated

func SMJobBless(
_ domain: CFString!,
_ executableLabel: CFString,
_ auth: AuthorizationRef!,

## Parameters

`domain`

The job’s domain. The Service Management framework only supports the `kSMDomainSystemLaunchd` domain.

`executableLabel`

The label of the privileged executable to install. This label must be one of the keys found in the `SMPrivilegedExecutables` dictionary in the application’s `Info.plist`.

`auth`

An authorization reference containing the `kSMRightBlessPrivilegedHelper` right.

`outError`

An output reference to a `CFError` describing the specific error encountered while submitting the executable tool; or, `NULL` if successful. It’s the responsibility of the application to release the error reference. This argument may be `NULL`.

## Return Value

Returns `true` if the job was successfully submitted; otherwise `false`.

## Discussion

`SMJobBless` submits the executable for the given label as a `launchd` job. This function removes the need for a `setuid(_:)` helper invoked through `AuthorizationExecuteWithPrivileges` in order to install a `launchd` property list. If the job is already installed, this methods returns `true`.

In order to use this function, the app must meet the following requirements:

1. Xcode must sign both the calling app and target executable tool.

2. The calling app’s `Info.plist` must include an `SMPrivilegedExecutables` dictionary of strings. Each string is a textual representation of a code signing requirement the system uses to determine whether the app owns the privileged tool once installed (for example, in order for subsequent versions to update the installed version).

Each key of `SMPrivilegedExecutables` is a reverse-DNS label for the helper tool that must be globally unique.

1. The helper tool must have an embedded `Info.plist` containing an `SMAuthorizedClients` array of strings. Each string is a textual representation of a code signing requirement describing a client allowed to add and remove the tool.

2. The helper tool must have an embedded launchd property list. The only required key in this property list is the `Label` key. When the Service Management framework extracts the `launchd` property list and writes it to disk, it sets the key for `ProgramArguments` to an array of 1 element that points to a standard location. You can’t specify your own program arguments, so don’t rely on the system passing custom command line arguments to your tool. Pass any parameters through an inter-process communication (IPC) channel.

3. The helper tool must reside in the Contents/Library/LaunchServices directory inside the application bundle, and its name must be its launchd job label. So if your launchd job label is `com.apple.Mail.helper`, this must be the name of the tool in your application bundle.

## See Also

### Management

`class SMAppService`

An object the framework uses to control helper executables that live inside an app’s main bundle.

Constants that describe the ability to authorize helper executables or modify daemon applications.

Property list keys that describe the kinds of applications, daemons, and helper executables the framework manages.

---

# https://developer.apple.com/documentation/servicemanagement/authorization-constants

Collection

- Service Management
- Authorization Constants

API Collection

# Authorization Constants

Constants that describe the ability to authorize helper executables or modify daemon applications.

## Topics

### Constants

`var kSMRightBlessPrivilegedHelper: String`

The authorization rights key for approving and installing a privileged helper tool.

`var kSMRightModifySystemDaemons: String`

The authorization rights key for modifying system daemons.

## See Also

### Management

`class SMAppService`

An object the framework uses to control helper executables that live inside an app’s main bundle.

Submits the executable for the given label as a job to `launchd`.

Deprecated

Property list keys that describe the kinds of applications, daemons, and helper executables the framework manages.

---

# https://developer.apple.com/documentation/servicemanagement/property-list-keys

Collection

- Service Management
- Property List Keys

API Collection

# Property List Keys

Property list keys that describe the kinds of applications, daemons, and helper executables the framework manages.

## Topics

### Constants

`let kSMDomainSystemLaunchd: CFString!`

The system-level launch domain.

`let kSMDomainUserLaunchd: CFString!`

The user-level launch domain.

## See Also

### Management

`class SMAppService`

An object the framework uses to control helper executables that live inside an app’s main bundle.

Submits the executable for the given label as a job to `launchd`.

Deprecated

Constants that describe the ability to authorize helper executables or modify daemon applications.

---

# https://developer.apple.com/documentation/servicemanagement/smloginitemsetenabled(_:_:)

#app-main)

- Service Management
- SMLoginItemSetEnabled(\_:\_:) Deprecated

Function

# SMLoginItemSetEnabled(\_:\_:)

Enables a helper executable in the main app-bundle directory.

macOS 10.6–13.0Deprecated

func SMLoginItemSetEnabled(
_ identifier: CFString,
_ enabled: Bool

## Parameters

`identifier`

The identifier of the helper executable bundle.

`enabled`

A Boolean value that represents the state of the helper executable. This value is effective only for the currently logged-in user. If `true`, the helper tool executable immediately (and upon subsequent logins) and keeps running. If `false`, the helper executable stops.

## Return Value

Returns `true` if the requested change has taken effect.

## Discussion

The build system places helper executables in the app’s bundle in the `Contents/Library/LoginItems` directory.

---

# https://developer.apple.com/documentation/servicemanagement/service-management-errors

Collection

- Service Management
- Service Management Errors

API Collection

# Service Management Errors

Errors that the framework returns.

## Topics

### Constants

`var kSMErrorAlreadyRegistered: Int`

The application is already registered.

`var kSMErrorAuthorizationFailure: Int`

The authorization requested failed.

`var kSMErrorInternalFailure: Int`

An internal failure has occurred.

`var kSMErrorInvalidPlist: Int`

The app’s property list is invalid.

`var kSMErrorInvalidSignature: Int`

The app’s code signature doesn’t meet the requirements to perform the operation.

`var kSMErrorJobMustBeEnabled: Int`

`var kSMErrorJobNotFound: Int`

The system can’t find the specified job.

`var kSMErrorJobPlistNotFound: Int`

`var kSMErrorLaunchDeniedByUser: Int`

The user denied the app’s launch request.

`var kSMErrorServiceUnavailable: Int`

The service necessary to perform this operation is unavailable or is no longer accepting requests.

`var kSMErrorToolNotValid: Int`

The specified path doesn’t exist or the helper tool at the specified path isn’t valid.

---

# https://developer.apple.com/documentation/servicemanagement/deprecated-symbols

Collection

- Service Management
- Deprecated Symbols

API Collection

# Deprecated Symbols

## Topics

### Deprecated Constants

`let kSMErrorDomainFramework: CFString!`

A Service Management error domain.

Deprecated

`let kSMErrorDomainIPC: CFString!`

A Service Management IPC error domain.

`let kSMErrorDomainLaunchd: CFString!`

A Service Management `launchd` error domain.

### Deprecated Functions

Copies the job description dictionaries for all jobs in the specified domain.

Copies the job description dictionary for the specified job label.

Removes the job with the specified label from the specified domain.

Submits the specified job to the specified domain.

### Deprecated Property List Keys

kSMInfoKeyAuthorizedClients

The authorized clients property list key.

kSMInfoKeyPrivilegedExecutables

The privileged executables property list key.

---

# https://developer.apple.com/documentation/servicemanagement/smappserviceerrordomain

- Service Management
- SMAppServiceErrorDomain

Global Variable

# SMAppServiceErrorDomain

let SMAppServiceErrorDomain: String

---

# https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/smappservice)



---

# https://developer.apple.com/documentation/servicemanagement/smjobbless(_:_:_:_:))



---

# https://developer.apple.com/documentation/servicemanagement/authorization-constants)



---

# https://developer.apple.com/documentation/servicemanagement/property-list-keys)



---

# https://developer.apple.com/documentation/servicemanagement/smloginitemsetenabled(_:_:))

)#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/service-management-errors)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/deprecated-symbols)



---

# https://developer.apple.com/documentation/servicemanagement/smappserviceerrordomain)



---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/notregistered

- Service Management
- SMAppService
- SMAppService.Status
- SMAppService.Status.notRegistered

Case

# SMAppService.Status.notRegistered

The service hasn’t registered with the Service Management framework, or the service attempted to reregister after it was already registered.

case notRegistered

## See Also

### Constants

`case enabled`

The service has been successfully registered and is eligible to run.

`case requiresApproval`

The service has been successfully registered, but the user needs to take action in System Preferences.

`case notFound`

An error occurred and the framework couldn’t find this service.

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/enabled

- Service Management
- SMAppService
- SMAppService.Status
- SMAppService.Status.enabled

Case

# SMAppService.Status.enabled

The service has been successfully registered and is eligible to run.

case enabled

## See Also

### Constants

`case notRegistered`

The service hasn’t registered with the Service Management framework, or the service attempted to reregister after it was already registered.

`case requiresApproval`

The service has been successfully registered, but the user needs to take action in System Preferences.

`case notFound`

An error occurred and the framework couldn’t find this service.

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/requiresapproval

- Service Management
- SMAppService
- SMAppService.Status
- SMAppService.Status.requiresApproval

Case

# SMAppService.Status.requiresApproval

The service has been successfully registered, but the user needs to take action in System Preferences.

case requiresApproval

## Discussion

The Service Management framework successfully registered this service, but the user needs to take action in System Settings before the service is eligible to run. The framework also returns this status if the user revokes consent for the service to run in System Settings.

## See Also

### Constants

`case notRegistered`

The service hasn’t registered with the Service Management framework, or the service attempted to reregister after it was already registered.

`case enabled`

The service has been successfully registered and is eligible to run.

`case notFound`

An error occurred and the framework couldn’t find this service.

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/notfound

- Service Management
- SMAppService
- SMAppService.Status
- SMAppService.Status.notFound

Case

# SMAppService.Status.notFound

An error occurred and the framework couldn’t find this service.

case notFound

## See Also

### Constants

`case notRegistered`

The service hasn’t registered with the Service Management framework, or the service attempted to reregister after it was already registered.

`case enabled`

The service has been successfully registered and is eligible to run.

`case requiresApproval`

The service has been successfully registered, but the user needs to take action in System Preferences.

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/init(rawvalue:)

#app-main)

- Service Management
- SMAppService
- SMAppService.Status
- init(rawValue:)

Initializer

# init(rawValue:)

init?(rawValue: Int)

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/notregistered)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/enabled)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/requiresapproval)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/notfound)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/init(rawvalue:))

)#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

