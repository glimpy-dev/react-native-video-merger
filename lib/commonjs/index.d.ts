export interface VideoMergeConfig {
    videoFiles: string[];
    outputPath?: string;
    quality?: 'low' | 'medium' | 'high';
    onError: (error: string) => void;
    onSuccess: (msg: string, file: string) => void;
}
declare const VideoEditor: {
    merge: (config: VideoMergeConfig) => void;
};
export default VideoEditor;
