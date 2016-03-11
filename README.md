# AudioRecorder Plugin

Leverage your hybrid applications with audio recording functionalities.

This plugin defines a global ( `navigator.device.audiorecorder` ) object which you can use to access the public API.


## Plugin

Although `audiorecorder` is globally acessible, it isn't usable until `deviceready` event is called.

As with all the cordova plugins, you can listen to `deviceready` event as follows: 

```javascript
document.addEventListener("deviceready", onDeviceReady, false);
function onDeviceReady() {
    // ...
}
```

## Supported Platforms

 - iOS
 - Android 


## Installation
- Run the following command:

```shell
    cordova plugin add https://github.com/OutSystems/cordova-plugin-audiorecorder.git
``` 
---

## API Reference

### AudioRecorder (`navigator.device.audiorecorder`)

 - [`.recordAudio(successCallback, errorCallback, durationLimit, viewColor, backgroundColor)`](#recordAudio)
 - [`.deleteAudioFile(successCallback, errorCallback, filepath)`](#deleteAudioFile)
 
---

<a name="recordAudio"></a>
#### `navigator.device.audiorecorder.recordAudio(successCallback, errorCallback, durationLimit, viewColor, backgroundColor)`

Calling this method opens the native GUI for the recorder.

| Param             | Type      | Description |
| ---               | ---       | --- |
| successCallback   | [`Function`](#successCallback)  | Callback function called when successfully recorded an audio file. |
| errorCallback     | [`Function`](#errorCallback)    | Callback function called when an error occurs |
| durationLimit     | Integer    | Duration, in seconds, of the recording. Recording stop when reaching the duration limit. |
| viewColor         | String    | An hexadecimal color, in the format `"#FFFFFF"`. Sets the tint color of the action buttons and timer label |
| backgroundColor   | String    | An hexadecimal color, in the format `"#FFFFFF"`. Sets the color of the background opaque area. |



<a name="deleteAudioFile"></a>
#### `navigator.device.audiorecorder.deleteAudioFile(successCallback, errorCallback, filepath)`

Deletes an audio file given its filepath

| Param             | Type      | Description   |
| ---               | ---       | ---           |
| successCallback   | Function  | Callback function called when the file is successfully deleted |
| errorCallback     | Function  | Callback function called when an error occurs while deleting the file |
| filepath          | String    | File path to the desired file. Usually the filepath returned by the successCallback from [`recordAudio`](#recordAudio) |

*Note*: On iOS, since we are saving the recordings into the temporary directory, all files will be deleted when the application is restarted. 

<a name="successCallback"></a>
#### Success Callback

Signature: 

```javascript
function(data){
    // ...
};
```

where `data` parameter is a JSON object:

```javascript
{
    "full_path":"",
    "file_name":""
}
```

<a name="errorCallback"></a>
#### Error Callback

Signature: 

```javascript
function(err){
    // ...
};
```

where `err` parameter is a JSON object:

```javascript
{
    "error_code":"",
    "error_message":""
}
```

Possible `error_code` values:

 - `OS_USER_CANCELLED` - Integer Value 1. User cancelled the recording session.
 - `OS_INTERNAL_ERROR` - Integer Value 2. An internal (native) error occurred.
 - `OS_INVALID_ARGS` - Integer Value 3. Invalid arguments were given.
 - `OS_PERMISSION_DENIED` - Integer Value 50.  _(iOS only.)_

---

#### How it looks

- Main screen
![myimage-alt-tag](http://i.imgur.com/QhLiRDl.png =100x100)

- Recording screen
![myimage-alt-tag](http://i.imgur.com/EnMi0XD.png =100x100)

- Stop recording screen
![myimage-alt-tag](http://i.imgur.com/kzT2mug.png =100x100)

- Play recording screen
![myimage-alt-tag](http://i.imgur.com/s10ijTb.png =100x100)


---

#### Contributors
- OutSystems - Mobility Experts
    - João Gonçalves, <joao.goncalves@outsystems.com>
    - Rúben Gonçalves, <ruben.goncalves@outsystems.com>
    - Vitor Oliveira, <vitor.oliveira@outsystems.com>
    - Danilo Costa, <danilo.costa@outsystems.com>

#### Document author
- João Gonçalves, <joao.goncalves@outsystems.com>

###Copyright OutSystems, 2016

---

LICENSE
=======


[The MIT License (MIT)](http://www.opensource.org/licenses/mit-license.html)

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
