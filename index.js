
import { NativeModules } from 'react-native';

const { RNVideoEditor } = NativeModules;

const VideoEditor = {
  merge: (config) => {
    const {
      videoFiles,
      outputPath = null,
      onError,
      onSuccess
    } = config;

    if (!videoFiles || !Array.isArray(videoFiles) || videoFiles.length === 0) {
      if (onError) {
        onError('No video files provided');
      }
      return;
    }

    if (!onError || !onSuccess) {
      throw new Error('onError and onSuccess callbacks are required');
    }

    return RNVideoEditor.merge(videoFiles, outputPath, onError, onSuccess);
  }
};

export default VideoEditor;
