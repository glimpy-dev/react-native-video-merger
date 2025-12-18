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
declare const VideoEditor: {
    merge: (config: VideoMergeConfig) => void;
};
export default VideoEditor;
