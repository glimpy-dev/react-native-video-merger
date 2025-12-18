
import { NativeModules } from 'react-native';

const { RNVideoEditor } = NativeModules;

export interface VideoMergeError {
    message: string;
    code?: number;
    type?: string;
    stack?: string;
    cause?: string;
}

export interface VideoMergeConfig {
    videoFiles: string[];
    outputPath?: string;
    quality?: 'low' | 'medium' | 'high';
    onError: (error: VideoMergeError | string) => void;
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
