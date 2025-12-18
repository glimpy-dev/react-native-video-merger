
import { NativeModules } from 'react-native';

const { RNVideoEditor } = NativeModules;

export interface VideoMergeConfig {
    videoFiles: string[];
    outputPath?: string;
    quality?: 'low' | 'medium' | 'high';
    onError: (error: string) => void;
    onSuccess: (msg: string, file: string) => void;
}

const VideoEditor = {
    merge: (config: VideoMergeConfig) => {
        const {
            videoFiles,
            outputPath = null,
            quality = 'high',
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

        RNVideoEditor.merge(videoFiles, outputPath, quality, onError, onSuccess);
    },
};

export default VideoEditor;
