package com.outsystems.audiorecorder;

import android.content.Context;
import android.util.Log;

import java.io.File;

/**
 * Created by vitoroliveira on 15/01/16.
 */
public class FileManager {

    private final static String FOLDER_NAME_SAVE_AUDIO = "AudioRecords";

    private Context mContext;

    public FileManager(Context context) {
        mContext = context;
    }

    /**
     * Return the path and file name where the audio will be saved
     *
     * @param fileName
     * @return path of the file
     */
    public String getFileName(String fileName) {
        File audioPath = getFileDirectory();
        File audioFile = new File(audioPath, fileName);

        return audioFile.getAbsolutePath();
    }

    /**
     * Method to delete file by name of the file. This method only will delete file on directory pre-configured.
     *
     * @param fileName
     * @return the result of the operation. True if delete was executed with success or False otherwise
     */
    public boolean deleteFileByName(String fileName) {
        if (fileName == null || fileName.isEmpty())
            return false;

        File fileDirectory = getFileDirectory();

        File audioFile = new File(fileDirectory, fileName);

        return audioFile.delete();
    }

    /**
     * Delete file when passed the full path to file
     *
     * @param pathToFile
     * @return
     */
    public boolean deleteFileByPath(String pathToFile) {
        if (pathToFile == null || pathToFile.isEmpty())
            return false;

        File audioFile = new File(pathToFile);

        return audioFile.delete();
    }

    /**
     * Method called to clean the directory used to save all audio records
     */
    public void deleteAllFileOnDirectory() {
        File fileDirectory = getFileDirectory();
        if (fileDirectory.isDirectory()) {
            for (File child : fileDirectory.listFiles())
                child.delete();
        }
    }

    /**
     * Method to get the Path where file will be Saved.
     *
     * @return the file directory
     */
    private File getFileDirectory() {
        //File tempFile = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
        File tempFile = new File(mContext.getFilesDir().getAbsolutePath());

        File audioPath = new File(tempFile, FOLDER_NAME_SAVE_AUDIO);

        if (audioPath.mkdir())
            Log.e("Audio Recorder", "Path Created");

        return audioPath;
    }

    /**
     * Method to create a file name with
     *
     * @return name of the file
     */
    public String createFileName(String extentsion) {
        File audioPath = getFileDirectory();
        int count = audioPath.listFiles().length;

        count++;

        if (extentsion.contains("."))
            extentsion = extentsion.replace(".", "");

        String fileName = "temp_" + count + "." + extentsion;

        return fileName;
    }
}
