import {NativeModules} from 'react-native';

import ProgressEmitter from './ProgressEmitter';
import PostEmitter from './PostEmitter';

const {ReactNativeAsyncCache} = NativeModules;
const {DocumentDirectory} = ReactNativeAsyncCache;

function executeDeclaredMethod(method, params) {
    if (ReactNativeAsyncCache && ReactNativeAsyncCache[method]) {
        if (params === null || params === undefined) {
            return ReactNativeAsyncCache[method]();
        } else {
            return ReactNativeAsyncCache[method](params);
        }
    } else {
        return Promise.reject(new Error('async-cache module not exists'));
    }
}

const DEFAULT_OPTIONS = {
    statusCodeLeft: 200,
    statusCodeRight: 300,
    targetDir: DocumentDirectory,
    accessibleMethod: 'HEAD',
    timeout: 12000,
    subDir: '',
    id: ''
};

export default {
    trash(options) {
        return executeDeclaredMethod('trash', {
            ...DEFAULT_OPTIONS,
            ...options
        });
    },

    clean() {
        return executeDeclaredMethod('clean');
    },

    remove(options) {
        const params = {
            ...DEFAULT_OPTIONS,
            ...options
        };

        if (!params.url) {
            return Promise.reject(new Error('remove url is required'));
        } else {
            return executeDeclaredMethod('remove', params);
        }
    },

    accessible(options) {
        const params = {
            ...DEFAULT_OPTIONS,
            ...options
        };

        if (!params.url) {
            return Promise.reject(new Error('accessible url is required'));
        } else {
            return executeDeclaredMethod('accessible', params);
        }
    },

    check(options) {
        const params = {
            ...DEFAULT_OPTIONS,
            ...options
        };

        if (!params.url) {
            return Promise.reject(new Error('check url is required'));
        } else {
            return executeDeclaredMethod('check', params);
        }
    },

    download(options, onProgress) {
        const params = {
            ...DEFAULT_OPTIONS,
            ...options
        };

        if (!params.url) {
            return Promise.reject(new Error('download url is required'));
        } else {
            if (ReactNativeAsyncCache && ReactNativeAsyncCache.download) {
                if (typeof onProgress === 'function') {
                    ProgressEmitter.add(params.url, onProgress);
                }
                return new Promise((resolve, reject) => {
                    ReactNativeAsyncCache.download(params).then((res) => {
                        resolve(res);
                    }, (e) => {
                        reject(e);
                    }).finally(() => {
                        ProgressEmitter.remove(params.url, onProgress);
                    });
                });
            } else {
                return Promise.reject(new Error('async-cache module not exists'));
            }
        }
    },

    post(options) {
        const params = {
            ...DEFAULT_OPTIONS,
            ...options
        };
        if (!params.url) {
            return Promise.reject(new Error('post url is required'));
        } else {
            if (ReactNativeAsyncCache && ReactNativeAsyncCache.post) {
                ReactNativeAsyncCache.post(params);
                return Promise.resolve();
            } else {
                return Promise.reject(new Error('async-cache module not exists'));
            }
        }
    },

    select(options, onPosted) {
        const params = {
            ...DEFAULT_OPTIONS,
            ...options
        };
        if (params.url == null) {
            return Promise.reject(new Error('select url is required'));
        } else {
            if (ReactNativeAsyncCache && ReactNativeAsyncCache.select) {
                if (typeof params.url === 'string' && params.url.startsWith('http')) {
                    if (typeof onPosted === 'function') {
                        const url = params.url;
                        const trigger = (event) => {
                            onPosted(event);
                            PostEmitter.remove(url, trigger);
                        };
                        PostEmitter.add(url, trigger);
                    }
                    return ReactNativeAsyncCache.select(params);
                } else {
                    return Promise.resolve({
                        success: false,
                        url: params.url
                    });
                }
            } else {
                return Promise.reject(new Error('async-cache module not exists'));
            }
        }
    }
};
