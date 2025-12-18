"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const react_native_1 = require("react-native");
const { RNVideoEditor } = react_native_1.NativeModules;
const VideoEditor = {
    merge: (config) => {
        const { videoFiles, outputPath = null, quality = 'high', onError, onSuccess } = config;
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
exports.default = VideoEditor;
//# sourceMappingURL=index.js.map