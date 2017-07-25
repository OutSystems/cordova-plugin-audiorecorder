package com.outsystems.audiorecorder;

/**
 * Created by vitoroliveira on 16/01/16.
 */
public interface AudioRecorderListener {

    public void callBackSuccessRecordVideo(String fullPath, String fileName);

    public void callBackErrorRecordVideo(int errorCode, String errorMessage);

}
