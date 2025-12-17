export interface VideoMergeConfig {
  videoFiles: string[];
  outputPath?: string | null;
  onError: (error: string) => void;
  onSuccess: (result: string) => void;
}

export interface VideoEditor {
  merge: (config: VideoMergeConfig) => void;
}

declare const VideoEditor: VideoEditor;

export default VideoEditor;
