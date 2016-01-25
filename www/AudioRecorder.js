
/**
	Mobility Experts
	João Gonçalves - 14/01/2016
*/

var exec = require("cordova/exec");

exports.recordAudio = function(successCallback, errorCallback, durationLimit, viewColor, backgroundColor){
    exec(successCallback, errorCallback, "AudioRecorderPlugin", "recordAudio", [durationLimit, viewColor, backgroundColor]);    
};

exports.deleteAudioFile = function (successCallback, errorCallback, filepath) {
    exec(successCallback, errorCallback, "AudioRecorderPlugin", "deleteAudioFile", [filepath]);
};
