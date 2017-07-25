package com.outsystems.audiorecorder;

import android.Manifest;
import android.content.pm.PackageManager;
import android.util.Log;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.RelativeLayout;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by vitoroliveira on 16/01/16.
 */
public class AudioRecorderPlugin extends CordovaPlugin {

    public static final int ERROR_CODE_CANCEL = 1;
    public static final int ERROR_INTERNAL = 2;
    public static final int ERROR_INVALID_ARGUMENTS = 3;

    public static final String ACTION_RECORD_AUDIO = "recordAudio";
    public static final String ACTION_DELETE_AUDIO = "deleteAudioFile";
    public static final String LOG_TAG = "OS_AUDIO_RECORDER";
    private AudioRecorderView mAudioRecorderView;
    private CallbackContext callbackContext;
    private JSONArray args;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        if (action.equals(ACTION_RECORD_AUDIO)) {
            this.callbackContext = callbackContext;
            this.args = args;
            if (checkPermissions()) {
                recordAudio(callbackContext, args);
            }
        } else if (action.equals(ACTION_DELETE_AUDIO)) {
            deleteAudioFile(callbackContext, args);
        }

        return true;
    }

    private boolean checkPermissions() {
        if (cordova.hasPermission(Manifest.permission.RECORD_AUDIO)) {
            return true;
        } else {
            cordova.requestPermission(this, 1337, Manifest.permission.RECORD_AUDIO);
            return false;
        }
    }

    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        if (requestCode == 1337) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                recordAudio(callbackContext, args);
            }
        }
    }

    /**
     * Record audio
     *
     * @param callbackContext
     * @param args
     * @throws JSONException
     */
    private void recordAudio(final CallbackContext callbackContext, final JSONArray args) throws JSONException {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {

                final int bottom_upResId = cordova.getActivity().getResources().getIdentifier("bottom_up", "anim", cordova.getActivity().getPackageName());

                Animation bottomUp = AnimationUtils.loadAnimation(cordova.getActivity(), bottom_upResId);
                mAudioRecorderView = new AudioRecorderView(cordova.getActivity(), null);

                mAudioRecorderView.startAnimation(bottomUp);
                cordova.getActivity().addContentView(mAudioRecorderView, new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT));

                // Get arguments to use on the view
                int limitation = 0;
                String viewColors = null;
                String backgroundColor = null;
                if (args != null && args.length() > 0) {
                    try {
                        limitation = args.getInt(0);
                    } catch (JSONException e) {
                        // sendErrorCallBack(callbackContext, ERROR_INVALID_ARGUMENTS, "Limitation Time is invalid");
                        Log.e(LOG_TAG, e.toString());
                    }

                    try {
                        viewColors = args.getString(1);
                        backgroundColor = args.getString(2);
                    } catch (JSONException e) {
                        Log.e(LOG_TAG, e.toString());
                    }
                }
                // Set the configs to the view
                mAudioRecorderView.setConfigsToView(limitation, new AudioRecorderListener() {
                    @Override
                    public void callBackSuccessRecordVideo(String fullPath, String fileName) {
                        removeCustomView();
                        JSONObject jsonObject = new JSONObject();
                        try {
                            jsonObject.put("full_path", fullPath);
                            jsonObject.put("file_name", fileName);
                            callbackContext.success(jsonObject.toString());
                        } catch (JSONException e) {
                            Log.e(LOG_TAG, e.toString());
                        }
                    }

                    @Override
                    public void callBackErrorRecordVideo(int errorCode, String errorMessage) {
                        removeCustomView();
                        sendErrorCallBack(callbackContext, errorCode, errorMessage);
                    }
                }, viewColors, backgroundColor);
            }
        });
    }

    /**
     * Delete recorded file from the disk.
     *
     * @param callbackContext
     * @param args
     * @throws JSONException
     */
    private void deleteAudioFile(CallbackContext callbackContext, JSONArray args) throws JSONException {
        if (mAudioRecorderView != null) {
            String fileName = "";
            if (args != null && args.length() > 0) {
                fileName = args.getString(0);
            }

            boolean result = new FileManager(cordova.getActivity()).deleteFileByPath(fileName);

            if (result) {
                Log.d(LOG_TAG, "File Deleted");
                callbackContext.success();
            } else
                sendErrorCallBack(callbackContext, ERROR_INTERNAL, "Error to delete file");

        }
    }

    /**
     * Helper method to report an error to the webview.
     *
     * @param callbackContext
     * @param errorCode
     * @param errorMessage
     */
    private void sendErrorCallBack(CallbackContext callbackContext, int errorCode, String errorMessage) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("error_code", errorCode);
            jsonObject.put("error_message", errorMessage);
            callbackContext.error(jsonObject.toString());
        } catch (JSONException e) {
            Log.e(LOG_TAG, e.toString());
        }
    }

    /**
     * Remove the Audio Recorder View from the screen
     */
    private void removeCustomView() {
        final int animResId = cordova.getActivity()
                .getResources().getIdentifier("bottom_down", "anim", cordova.getActivity().getPackageName());
        Animation slideOutBottom = AnimationUtils.loadAnimation(cordova.getActivity(),
                animResId);
        mAudioRecorderView.startAnimation(slideOutBottom);
        try {
            ((ViewGroup) mAudioRecorderView.getParent()).removeView(mAudioRecorderView);
        } catch (Exception exp) {
            Log.e(LOG_TAG, exp.toString());
        }
    }
}