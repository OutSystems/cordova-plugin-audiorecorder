package com.outsystems.audiorecorder;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.StateListDrawable;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Handler;
import android.os.Vibrator;
import android.util.AttributeSet;
import android.util.Log;
import android.util.StateSet;
import android.view.View;
import android.widget.ImageButton;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.ViewSwitcher;

import com.outsystems.android.R;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * Created by vitoroliveira on 15/01/16.
 */
public class AudioRecorderView extends RelativeLayout {
    
    private static int AUDIO_SOURCE = MediaRecorder.AudioSource.MIC;
    private static int OUTPUT_FORMAT = MediaRecorder.OutputFormat.AAC_ADTS;
    private static String EXTENSION_FILE = "aac";
    private static int AUDIO_ENCODER = MediaRecorder.AudioEncoder.AAC;
    
    private static int DEFAULT_VIEW_COLORS = Color.WHITE;
    private static int DEFAULT_VIEW_BACKGROUND = Color.BLACK;
    
    // Views
    ViewSwitcher mViewSwitcher;
    TextView textViewCounter;
    
    // Player and Recorder
    private MediaRecorder mRecorder = null;
    private MediaPlayer mPlayer = null;
    
    // Handlers and Listners
    Handler handler;
    AudioRecorderListener mAudioRecorderListener;
    
    // Helpers
    boolean isRecording;
    int recordLimitTime = 0;
    int recordTime=1, minutes;
    int colorView;
    int colorBackground;
    String fileName;
    String filePath;
    
    public AudioRecorderView(Context context) {
        super(context);
    }
    
    public AudioRecorderView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }
    
    public AudioRecorderView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }
    
    public AudioRecorderView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        init();
    }
    
    /**
     * Initialize all views and inflate the xml layout to the view
     */
    private void init() {
        inflate(getContext(), R.layout.view_audio_recorder, this);
        
        (findViewById(R.id.view_audio_recorder)).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                
            }
        });
        
        mViewSwitcher = (ViewSwitcher) findViewById(R.id.viewSwitcher_audio_recorder);
        
        ImageButton startRecord = (ImageButton) findViewById(R.id.img_button_start_record);
        startRecord.setOnClickListener(onClickListenerStartRecord);
        
        ImageButton imageButtonRejectRecord = (ImageButton) findViewById(R.id.img_button_reject_audio);
        imageButtonRejectRecord.setOnClickListener(onClickListenerRejectAudio);
        
        ImageButton playRecordButton = (ImageButton) findViewById(R.id.img_button_play);
        playRecordButton.setOnClickListener(onClickListenerPlayRecord);
        
        ImageButton acceptAudioButton = (ImageButton) findViewById(R.id.img_button_accept_audio);
        acceptAudioButton.setOnClickListener(onClickListenerAcceptAudio);
        
        ImageButton closeView = (ImageButton) findViewById(R.id.img_button_close_view);
        closeView.setOnClickListener(onClickListenerCloseView);
        
        //Get View of TextView Counter
        textViewCounter = (TextView) findViewById(R.id.text_view_counter);
        textViewCounter.setTextColor(Color.WHITE);
        
        // Initialize the Handler to update the text view counter
        handler = new Handler();
    }
    
    /**
     * Initialize the custom configs within the view.
     * @param recordLimitTime - Time needs to be defined on Milliseconds
     * @param audioRecorderListener
     */
    public void setConfigsToView (int recordLimitTime, AudioRecorderListener audioRecorderListener, String colorViews, String colorBackground) {
        //Convert seconds to milliseconds
        this.recordLimitTime= (int) TimeUnit.SECONDS.toMillis(recordLimitTime);
        this.mAudioRecorderListener = audioRecorderListener;
        
        try {
            if (colorViews != null)
                colorView = Color.parseColor(colorViews);
            else if (colorView == 0)
                colorView = DEFAULT_VIEW_COLORS;
            
            if (colorBackground != null)
                this.colorBackground = Color.parseColor(colorBackground);
            else if (this.colorBackground == 0)
                this.colorBackground = DEFAULT_VIEW_BACKGROUND;
        } catch (IllegalArgumentException exp) {
            colorView = DEFAULT_VIEW_COLORS;
            this.colorBackground = DEFAULT_VIEW_BACKGROUND;
        }
        
        updateViewWithNewColors(colorView, this.colorBackground);
    }
    
    /**
     *
     * @param audioRecorderListener
     */
    public void setAudioRecorderListener (AudioRecorderListener audioRecorderListener) {
        this.mAudioRecorderListener = audioRecorderListener;
    }
    
    // Initialization of Runnable to update counter of time record
    Runnable UpdateRecordTime = new Runnable() {
    public void run() {
    if (isRecording) {
    if (recordTime == 60) {
    recordTime = 0;
    minutes++;
}
textViewCounter.setText(String.valueOf("" + (minutes > 9 ? minutes : "0" + minutes) + ":" + (recordTime > 9 ? recordTime : "0" + recordTime)));
recordTime += 1;
// Delay 1s before next call
handler.postDelayed(this, 1000);
}
}
};


//================================================================================
// Listeners to buttons
//================================================================================

private OnClickListener onClickListenerStartRecord = new OnClickListener() {
@Override
public void onClick(final View v) {
//v.setSelected(true);
if (!isRecording) {
vibrate();
setStopImageDrawable(v, R.drawable.stop_button);
mRecorder = new MediaRecorder();
mRecorder.setAudioSource(AUDIO_SOURCE);
mRecorder.setOutputFormat(OUTPUT_FORMAT);

// Generate file name and get the path to save the files
FileManager fileManager = new FileManager(getContext());
fileName = fileManager.createFileName(EXTENSION_FILE);
filePath = fileManager.getFileName(fileName);

mRecorder.setOutputFile(filePath);
mRecorder.setAudioEncoder(AUDIO_ENCODER);
// If on the plugin receive as a parameter the record limit time, should be defined on Media Recorder
if(recordLimitTime > 0)
mRecorder.setMaxDuration(recordLimitTime);

mRecorder.setOnInfoListener(new MediaRecorder.OnInfoListener() {
@Override
public void onInfo(MediaRecorder mr, int what, int extra) {
if (what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED)
stopRecord((ImageButton) v);
}
});

try {
mRecorder.prepare();

mRecorder.start();
isRecording = true;
handler.post(UpdateRecordTime);
} catch (IOException e) {
Log.e(AudioRecorderPlugin.LOG_TAG, "prepare() failed");
sendErrorCallback(AudioRecorderPlugin.ERROR_INTERNAL, "Failed on start record");
}
} else if (isRecording) {
stopRecord((ImageButton) v);
}
}
};

private OnClickListener onClickListenerPlayRecord = new OnClickListener() {

@Override
public void onClick(final View v) {
if(mPlayer == null || !mPlayer.isPlaying()) {
setStopImageDrawable(v, R.drawable.stop_button);
mPlayer = new MediaPlayer();
try {
if (filePath != null && !filePath.isEmpty()) {
mPlayer.setDataSource(filePath);
mPlayer.prepare();
mPlayer.start();

mPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
@Override
public void onCompletion(MediaPlayer mp) {
Log.i(AudioRecorderPlugin.LOG_TAG, "OnCompletion Player");

stopMediaPlayer((ImageButton) v);
}
});
}
} catch (IOException e) {
Log.e(AudioRecorderPlugin.LOG_TAG, "prepare() failed", e);
sendErrorCallback(AudioRecorderPlugin.ERROR_INTERNAL, "Failed on start player");
}
} else {
mPlayer.stop();
stopMediaPlayer((ImageButton) v);
}
}
};

private OnClickListener onClickListenerRejectAudio = new OnClickListener() {

@Override
public void onClick(View v) {
if(mPlayer != null && mPlayer.isPlaying()) {
mPlayer.release();
mPlayer = null;
}

// Delete file when the clip is rejected
if(new FileManager(getContext()).deleteFileByName(fileName))
Log.i(AudioRecorderPlugin.LOG_TAG, "File delete with success");
textViewCounter.setText("00:00");
setStopImageDrawable(findViewById(R.id.img_button_play), R.drawable.play_button);

mViewSwitcher.showPrevious();
}
};

private OnClickListener onClickListenerAcceptAudio = new OnClickListener() {

@Override
public void onClick(View v) {
stopMediaPlayer(null);

sendSuccessCallback(filePath, fileName);
}
};

private OnClickListener onClickListenerCloseView = new OnClickListener() {

@Override
public void onClick(View v) {
// Delete file when close the view
if(new FileManager(getContext()).deleteFileByName(fileName))
Log.i(AudioRecorderPlugin.LOG_TAG, "File delete with success");

stopRecord(null);
stopMediaPlayer(null);
sendErrorCallback(AudioRecorderPlugin.ERROR_CODE_CANCEL, "The audio record was canceled.");
}
};

//================================================================================
// Callback Results
//================================================================================

private void sendErrorCallback (int errorCode, String message) {
if (mAudioRecorderListener != null) {
mAudioRecorderListener.callBackErrorRecordVideo(errorCode, message);
}
}

private void sendSuccessCallback (String filePath, String fileName) {
if (mAudioRecorderListener != null)
mAudioRecorderListener.callBackSuccessRecordVideo(filePath, fileName);
}

/**
 * Method to device vibrate
 */
private void vibrate() {
try {
Vibrator v = (Vibrator) getContext().getSystemService(Context.VIBRATOR_SERVICE);
v.vibrate(200);
} catch (Exception e) {
e.printStackTrace();
}
}

/**
 * Update views after stop recording
 * @param imageButton
 */
private void stopRecord (ImageButton imageButton) {
//imageButton.setImageResource(R.drawable.ic_play_arrow_audio);
if(imageButton != null)
setStopImageDrawable(imageButton, R.drawable.record_button);

if(mRecorder != null) {
mRecorder.stop();
mRecorder.release();
mRecorder = null;

isRecording = false;
recordTime = 1;
minutes = 0;
mViewSwitcher.showNext();
}
}

/**
 * Method to stop the media player and change the status of play button
 * @param imageButton
 */
private void stopMediaPlayer (ImageButton imageButton) {
if(mPlayer != null) {
mPlayer.release();
mPlayer = null;

if(imageButton != null)
setStopImageDrawable(imageButton, R.drawable.play_button);
}
}

/**
 *
 * @param viewColors - Color in Hex format. Ex: #FFFFFF
 * @param backgroundColor - Color in Hex. Ex: #FFFFFF
 */
public void setButtonColors(int viewColors, int backgroundColor) {
this.colorView = viewColors;
this.colorBackground = backgroundColor;
updateViewWithNewColors(viewColors, backgroundColor);
}

private void updateViewWithNewColors (int viewColor, int backgroundColor) {
//        PorterDuff.Mode mMode = PorterDuff.Mode.SRC_IN;
//
//        Drawable dr = getResources().getDrawable(R.drawable.ic_mic_audio);
//        dr.setColorFilter(viewColor, mMode);
//        ((ImageButton) findViewById(R.id.img_button_start_record)).setImageDrawable(createSelectorIconApplications(dr));
//
//        dr = getResources().getDrawable(R.drawable.ic_close_audio);
//        dr.setColorFilter(viewColor, mMode);
//        ((ImageButton) findViewById(R.id.img_button_reject_audio)).setImageDrawable(createSelectorIconApplications(dr));
//
//        dr = getResources().getDrawable(R.drawable.ic_play_arrow_audio);
//        dr.setColorFilter(viewColor, mMode);
//        ((ImageButton) findViewById(R.id.img_button_play)).setImageDrawable(createSelectorIconApplications(dr));
//
//        dr = getResources().getDrawable(R.drawable.ic_done_audio);
//        dr.setColorFilter(viewColor, mMode);
//        ((ImageButton) findViewById(R.id.img_button_accept_audio)).setImageDrawable(createSelectorIconApplications(dr));
//
//        textViewCounter.setTextColor(viewColor);
//
//        Drawable drClose = getResources().getDrawable(R.drawable.ic_close_audio);
//        drClose.setColorFilter(viewColor, mMode);
//        ((ImageButton) findViewById(R.id.img_button_close_view)).setImageDrawable(createSelectorIconApplications(drClose));
//
//        mViewSwitcher.setBackgroundColor(backgroundColor);
//
//        //This was done because to change the transperency view.
//        /*String strColor = String.format("#%06X", 0xFFFFFF & backgroundColor);
//        View view = findViewById(R.id.view_audio_recorder);
//        //view.setAlpha(0.65f);
//        view.setBackgroundColor(Color.parseColor("#A6".concat(strColor.replace("#", ""))));*/
//       // findViewById(R.id.view_audio_recorder).setAlpha(0.65f);

}

/**
 *
 * @param v
 * @param res
 */
private void setStopImageDrawable(View v, int res) {
//   PorterDuff.Mode mMode = PorterDuff.Mode.MULTIPLY;
// Drawable dr = getResources().getDrawable(res);
// dr.setColorFilter(color, mMode);
((ImageButton) v).setImageDrawable((getResources().getDrawable(res)));
}

/**
 * Creates the selector icon applications.
 *
 * @return the drawable
 */
private Drawable createSelectorIconApplications(Drawable iconPressed) {
StateListDrawable drawable = new StateListDrawable();

BitmapDrawable bitmapDrawable = getDisableButton(iconPressed);

drawable.addState(new int[] { -android.R.attr.state_pressed }, iconPressed);
drawable.addState(new int[]{-android.R.attr.state_enabled}, iconPressed);
drawable.addState(StateSet.WILD_CARD, bitmapDrawable);

return drawable;
}


/**
 * Gets the disable button.
 *
 * @param icon the icon
 * @return the disable button
 */
private BitmapDrawable getDisableButton(Drawable icon) {
Bitmap enabledBitmap = ((BitmapDrawable) icon).getBitmap();

// Setting alpha directly just didn't work, so we draw a new bitmap!
Bitmap disabledBitmap = Bitmap.createBitmap(icon.getIntrinsicWidth(), icon.getIntrinsicHeight(),
android.graphics.Bitmap.Config.ARGB_8888);
Canvas canvas = new Canvas(disabledBitmap);

Paint paint = new Paint();
paint.setAlpha(200);
canvas.drawBitmap(enabledBitmap, 0, 0, paint);

BitmapDrawable disabled = new BitmapDrawable(getResources(), disabledBitmap);

return disabled;
}
}