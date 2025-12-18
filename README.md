# react-native-video-merger

Merge multiple videos in React Native.

## Installation

```bash
npm install react-native-video-merger
```

## Usage

```typescript
import VideoEditor, { VideoMergeConfig } from 'react-native-video-merger';

const config: VideoMergeConfig = {
  videoFiles: ['file:///path/to/video1.mp4', 'file:///path/to/video2.mp4'],
  outputPath: 'file:///path/to/output.mp4', // Optional. If omitted, a temp file is created.
  onSuccess: (msg: string, file: string) => {
    console.log('Merge success:', file);
  },
  onError: (error: string) => {
    console.error('Merge failed:', error);
  },
};

VideoEditor.merge(config);
```

### Permissions

#### Android

Ensure you have permissions to read the input files. If accessing external storage, you may need:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS

Standard file access permissions apply.

## API

### `merge(config: VideoMergeConfig)`

Merges the provided video files into a single video file.

#### `VideoMergeConfig`

| Property | Type | Description |
|----------|------|-------------|
| `videoFiles` | `string[]` | Array of local file URIs (starting with `file://`). |
| `outputPath` | `string` | (Optional) Output path. |
| `quality` | `string` | (Optional) `low`, `medium`, or `high`. Defaults to `high`. |
| `onSuccess` | `(msg: string, file: string) => void` | Callback on success. `file` is the path to the merged video. |
| `onError` | `(error: string) => void` | Callback on failure. |
