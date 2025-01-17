# Jitouch
![macOS 10.9+](https://img.shields.io/badge/macOS-10.9%2B-blue?logo=Apple)
![Apple Silicon ready](https://img.shields.io/badge/Apple%20Silicon-supported-blue?logo=Apple)
[![License GPL3](https://img.shields.io/github/license/Crazor/jitouch?color=success)](LICENSE)
[![CI](https://github.com/Crazor/Jitouch-project/actions/workflows/build.yml/badge.svg)](https://github.com/Crazor/Jitouch-project/actions/workflows/build.yml)

**Jitouch** is a Mac application that expands the set of multi-touch gestures for MacBook, Magic Mouse, and Magic Trackpad. These thoughtfully designed gestures enable users to perform frequent tasks more easily such as changing tabs in web browsers, closing windows, minimizing windows, changing spaces, and a lot more.

For more details, see https://www.jitouch.com/.

## Hacking

To build or modify Jitouch, please install the necessary prerequisites and then follow the building steps below.

### Prerequisites

1. **Xcode** (necessary)
    - [Install Xcode](https://apps.apple.com/de/app/xcode/id497799835) from the Mac App Store
2. **Homebrew** (recommended):
    - Follow the [official instructions](https://brew.sh/)
    - or run `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
3. **CocoaPods** (necessary)
    - `brew install cocoapods`
    - or follow the [official instructions](https://guides.cocoapods.org/using/getting-started.html#installation)
4. **npm** (required for release builds)
    - `brew install npm`
5. **appdmg** (required for release builds)
    - `npm install -g appdmg`


### Building
1. Clone this repository:
    ```bash
    git clone https://github.com/JitouchApp/Jitouch
    cd Jitouch
    ```
2. Install the dependencies:
    ```bash
    pod install
    ```
3. Either open the project in Xcode:
    ```bash
    open Jitouch.xcworkspace
    ````

| :exclamation: Please note that you must not open `Jitouch.xcodeproj`, otherwise CocoaPods dependencies will not be built correctly. |
|-|



4. Or compile from the shell:
    ```bash
    make build
    ````
5. Install and run:
    ```bash
    open DerivedData/Build/Products/Debug/Jitouch.prefPane
    ```

## Contributing

1. Fork this project, commit your changes and open a pull-request

| :exclamation: You need to sign-off your commits to acknowledge the [Developer Certificate of Origin (DCO)](https://developercertificate.org/). |
|-|

This will be enforced automatically on pull requests. For more information, read about the [DCO App](https://github.com/apps/dco) and the following section.

### Developer Certificate of Origin (DCO)

To sign-off on a commit, [read the DCO](https://developercertificate.org/) and then add the `-s` flag to `git commit`:
```
-s, --signoff
    Add Signed-off-by line by the committer at the end of the commit log
    message. The meaning of a signoff depends on the project, but it typically
    certifies that committer has the rights to submit this work under the same
    license and agrees to a Developer Certificate of Origin (see
    http://developercertificate.org/ for more information).
```

## License
Jitouch is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

Jitouch is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
Jitouch. If not, see <https://www.gnu.org/licenses/>.
```
