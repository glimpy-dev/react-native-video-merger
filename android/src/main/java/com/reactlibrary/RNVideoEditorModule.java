
package com.reactlibrary;

import android.content.Context;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.media3.common.MediaItem;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.transformer.Composition;
import androidx.media3.transformer.EditedMediaItem;
import androidx.media3.transformer.EditedMediaItemSequence;
import androidx.media3.transformer.ExportException;
import androidx.media3.transformer.ExportResult;
import androidx.media3.transformer.Transformer;
import androidx.media3.transformer.VideoEncoderSettings;
import androidx.media3.transformer.DefaultEncoderFactory;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.google.common.collect.ImmutableList;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

@UnstableApi
public class RNVideoEditorModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private static final String TAG = "RNVideoEditor";

  public RNVideoEditorModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @ReactMethod
  public void merge(ReadableArray videoFiles, @Nullable String outputPath, String quality, Callback errorCallback, Callback successCallback) {
    if (videoFiles == null || videoFiles.size() == 0) {
      errorCallback.invoke("No video files provided");
      return;
    }

    try {
      // Create EditedMediaItems from video file paths
      List<EditedMediaItem> editedMediaItems = new ArrayList<>();

      for (int i = 0; i < videoFiles.size(); i++) {
        String videoPath = videoFiles.getString(i).replaceFirst("file://", "");
        File file = new File(videoPath);
        
        if (!file.exists()) {
            errorCallback.invoke("File does not exist: " + videoPath);
            return;
        }

        Uri videoUri = Uri.fromFile(file);

        MediaItem mediaItem = MediaItem.fromUri(videoUri);
        EditedMediaItem editedMediaItem = new EditedMediaItem.Builder(mediaItem).build();
        editedMediaItems.add(editedMediaItem);
      }

      // Create a sequence that concatenates all videos
      EditedMediaItemSequence videoSequence = new EditedMediaItemSequence(
          ImmutableList.copyOf(editedMediaItems)
      );

      // Create composition with the video sequence
      Composition composition = new Composition.Builder(
          ImmutableList.of(videoSequence)
      ).build();

      // Use provided output path or generate default one
      String finalOutputPath;
      if (outputPath != null && !outputPath.isEmpty()) {
        finalOutputPath = "file://" + outputPath.replaceFirst("file://", "");
      } else {
        long timestamp = System.currentTimeMillis() / 1000;
        finalOutputPath = reactContext.getApplicationContext().getCacheDir().getAbsolutePath()
            + "/output_" + timestamp + ".mp4";
      }

      // Configure VideoEncoderSettings based on quality
      Transformer.Builder transformerBuilder = new Transformer.Builder(reactContext);
      
      if (quality != null) {
          int bitrate = -1;
          if (quality.equals("low")) {
              bitrate = 1_000_000; // 1 Mbps
          } else if (quality.equals("medium")) {
              bitrate = 2_500_000; // 2.5 Mbps
          }
          
          if (bitrate != -1) {
              VideoEncoderSettings videoEncoderSettings = new VideoEncoderSettings.Builder()
                  .setBitrate(bitrate)
                  .build();
                  
              DefaultEncoderFactory encoderFactory = new DefaultEncoderFactory.Builder(reactContext)
                  .setRequestedVideoEncoderSettings(videoEncoderSettings)
                  .build();
                  
              transformerBuilder.setEncoderFactory(encoderFactory);
          }
      }

      // Create and configure Transformer
      Transformer transformer = transformerBuilder
          .addListener(new Transformer.Listener() {
            @Override
            public void onCompleted(Composition composition, ExportResult exportResult) {
              Log.d(TAG, "Video merge completed successfully: " + finalOutputPath);
              new Handler(Looper.getMainLooper()).post(() -> {
                successCallback.invoke("", finalOutputPath);
              });
            }

            @Override
            public void onError(
                Composition composition,
                ExportResult exportResult,
                ExportException exportException
            ) {
              WritableMap errorMap = Arguments.createMap();
              errorMap.putString("message", "Export failed: " + exportException.getMessage());
              errorMap.putInt("code", exportException.errorCode);
              if (exportException.getCause() != null) {
                  errorMap.putString("cause", exportException.getCause().getMessage());
              }
              
              Log.e(TAG, "Video merge failed", exportException);
              new Handler(Looper.getMainLooper()).post(() -> {
                errorCallback.invoke(errorMap);
              });
            }
          })
          .build();

      // Start the transformation
      transformer.start(composition, finalOutputPath);
      
    } catch (Exception e) {
        WritableMap errorMap = Arguments.createMap();
        errorMap.putString("message", "Setup failed: " + e.getMessage());
        errorMap.putString("type", e.getClass().getSimpleName());
        errorMap.putString("stack", Log.getStackTraceString(e));
            
        Log.e(TAG, "Error setting up video merge", e);
        errorCallback.invoke(errorMap);
    }
  }

  @Override
  public String getName() {
    return "RNVideoEditor";
  }
}
q