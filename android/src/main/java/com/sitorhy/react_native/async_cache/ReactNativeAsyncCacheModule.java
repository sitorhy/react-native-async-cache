package com.sitorhy.react_native.async_cache;

import android.os.AsyncTask;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.GuardedAsyncTask;
import com.facebook.react.bridge.NativeModuleCallExceptionHandler;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class ReactNativeAsyncCacheModule extends ReactContextBaseJavaModule {
    private static double STEP = 0.036;
    private final ReactApplicationContext reactContext;
    private final Set<String> tasks = new CopyOnWriteArraySet<>();
    private final ThreadPoolExecutor threadPoolExecutor = new ThreadPoolExecutor(1, 16, 30, TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>(128));

    public ReactNativeAsyncCacheModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "ReactNativeAsyncCache";
    }

    @Nullable
    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put(Constants.TEMP_DIR, Common.getTempDirectory(reactContext).getAbsolutePath());
        constants.put(Constants.DOC_DIR, Common.getTargetDirectory(reactContext).getAbsolutePath());
        return constants;
    }

    @ReactMethod
    public void post(final ReadableMap options) {
        Request request = new Request(options);
        post(request);
    }

    private void sendEvent(String event, Object params) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(event, params);
    }

    private void sendPostedEvent(String url, String path, int statusCode, String message, long size) {
        WritableMap errResp = Arguments.createMap();
        errResp.putInt(Constants.STATUS_CODE, statusCode);
        errResp.putString(Constants.MESSAGE, message);
        errResp.putString(Constants.PATH, path);
        errResp.putDouble(Constants.SIZE, size);
        errResp.putString(Constants.URL, url);
        this.sendEvent("RNAsyncCachePosted", errResp);
    }

    private void clean(File dir, boolean deleteSelf) {
        if (dir == null || !dir.exists()) {
            return;
        }
        File[] files = dir.listFiles();
        for (File f : files) {
            if (f.isDirectory()) {
                clean(f, true);
            } else {
                f.delete();
            }
        }
        if (deleteSelf)
            dir.delete();
    }

    private void execute(Runnable task, final String taskId) {
        try {
            threadPoolExecutor.execute(task);
        } catch (RejectedExecutionException e) {
            try {
                new GuardedAsyncTask<Runnable, Void>(new NativeModuleCallExceptionHandler() {
                    @Override
                    public void handleException(Exception e) {
                        if (taskId != null) {
                            tasks.remove(taskId);
                        }
                    }
                }) {
                    @Override
                    protected void doInBackgroundGuarded(Runnable... runnables) {
                        runnables[0].run();
                    }
                }.executeOnExecutor(AsyncTask.SERIAL_EXECUTOR, task);
            } catch (Exception e2) {
                if (taskId != null) {
                    tasks.remove(taskId);
                }
            }
        }
    }

    private void download(final Request request, final Promise promise, final boolean reportProgress) {
        final String url = request.getUrl();
        final String taskId = request.selectTaskId();

        Runnable task = new Runnable() {
            @Override
            public void run() {
                tasks.add(taskId);
                final double[] progress = {0};
                try {
                    Common.download(
                            new DownloadFeedback() {
                                @Override
                                public void onProgress(int current, int total) {
                                    if (reportProgress) {
                                        WritableMap result = Arguments.createMap();
                                        result.putString(Constants.URL, url);
                                        result.putInt(Constants.TOTAL, total);
                                        result.putInt(Constants.CURRENT, current);
                                        double nextProgress = total > 0 ? (double) current / (double) total : 0;
                                        if (nextProgress == 1.0 || progress[0] + STEP < nextProgress) {
                                            progress[0] = nextProgress;
                                            sendEvent("RNAsyncCacheProgress", result);
                                        }
                                    }
                                }

                                @Override
                                public void onComplete(DownloadReport report) {
                                    WritableMap result = Arguments.createMap();
                                    result.putString(Constants.PATH, report.getPath());
                                    result.putDouble(Constants.SIZE, report.getSize());
                                    result.putString(Constants.URL, url);
                                    if (promise != null) {
                                        promise.resolve(result);
                                    }
                                    tasks.remove(taskId);
                                    sendPostedEvent(url, report.getPath(), 0, "", report.getSize());
                                }

                                @Override
                                public void onException(Exception e) {
                                    sendPostedEvent(url, "", -1, e.getMessage(), -1);
                                    tasks.remove(taskId);
                                    if (promise != null) {
                                        promise.reject(e);
                                    }
                                }
                            },
                            reactContext,
                            url,
                            request.getHeadersMap(),
                            request.generateTargetFile(),
                            request.getTimeout()
                    );
                } catch (IOException e) {
                    sendPostedEvent(url, "", -1, e.getMessage(), -1);
                    tasks.remove(taskId);
                    if (promise != null) {
                        promise.reject(e);
                    }
                }
            }
        };
        execute(task, taskId);
    }

    private void post(final Request request) {
        if (request.validateRequest(null)) {
            return;
        }
        final String taskId = request.selectTaskId();
        final File target = request.generateTargetFile();
        if (tasks.contains(taskId)) {
            return;
        }
        Runnable task = new Runnable() {
            @Override
            public void run() {
                HashMap<String, String> headers = request.getHeadersMap();
                try {
                    AccessibleResult urlAccessible = request.checkUrlAccessible();
                    if (urlAccessible.isAccessible()) {
                        if (request.isRewrite() || target.isDirectory()) {
                            if (target.exists())
                                target.delete();
                        }
                        download(request, null, false);
                    } else {
                        sendPostedEvent(request.getUrl(), "", urlAccessible.getResponseCode(), urlAccessible.getMessage(), -1);
                    }
                } catch (Exception e) {
                    tasks.remove(taskId);
                }
            }
        };
        execute(task, taskId);
    }

    private void rejectSelect(Promise promise, WritableMap map, String url) {
        map.putString(Constants.URL, url);
        map.putBoolean(Constants.SUCCESS, false);
        promise.resolve(map);
    }

    @ReactMethod
    public void download(final ReadableMap options, Promise promise) {
        final Request request = new Request(options);
        if (request.validateRequest(promise)) {
            return;
        }
        this.download(request, promise, true);
    }

    @ReactMethod
    public void accessible(final ReadableMap options, final Promise promise) {
        final Request request = new Request(options);
        if (request.validateRequest(promise)) {
            return;
        }

        Runnable task = new Runnable() {
            @Override
            public void run() {
                try {
                    AccessibleResult urlAccessible = request.checkUrlAccessible();
                    WritableMap result = Arguments.createMap();
                    result.putString(Constants.CONTENT_TYPE, urlAccessible.getContentType());
                    result.putString(Constants.MESSAGE, urlAccessible.getMessage());
                    result.putInt(Constants.STATUS_CODE, urlAccessible.getResponseCode());
                    result.putBoolean(Constants.ACCESSIBLE, urlAccessible.isAccessible());
                    result.putDouble(Constants.SIZE, urlAccessible.getSize());
                    result.putString(Constants.URL, request.getUrl());
                    promise.resolve(result);
                } catch (IOException e) {
                    WritableMap result = Arguments.createMap();
                    result.putString(Constants.CONTENT_TYPE, null);
                    result.putString(Constants.MESSAGE, e.getLocalizedMessage());
                    result.putInt(Constants.STATUS_CODE, -1);
                    result.putBoolean(Constants.ACCESSIBLE, false);
                    result.putDouble(Constants.SIZE, -1);
                    result.putString(Constants.URL, request.getUrl());
                    promise.resolve(result);
                }
            }
        };
        execute(task, request.selectTaskId());
    }

    @ReactMethod
    public void trash(final ReadableMap options, final Promise promise) {
        final Request request = new Request(options);
        final File dir = request.generateTargetDirectory();

        Runnable task = new Runnable() {
            @Override
            public void run() {
                try {
                    clean(dir, !request.getSubDir().isEmpty());
                } catch (Exception e) {
                    promise.reject(e);
                    return;
                }
                promise.resolve(null);
            }
        };
        execute(task, null);
    }

    @ReactMethod
    public void clean(final Promise promise) {
        Runnable task = new Runnable() {
            @Override
            public void run() {
                File tempDirectory = Common.getTempDirectory(reactContext);
                if (tempDirectory.exists() && tempDirectory.isDirectory()) {
                    try {
                        clean(tempDirectory, false);
                    } catch (Exception e) {
                        promise.reject(e);
                        return;
                    }
                }
                promise.resolve(null);
            }
        };
        execute(task, null);
    }

    @ReactMethod
    public void remove(final ReadableMap options, final Promise promise) {
        final Request request = new Request(options);
        if (request.validateRequest(promise)) {
            return;
        }
        Runnable task = new Runnable() {
            @Override
            public void run() {
                File target = request.generateTargetFile();
                if (target.exists()) {
                    WritableMap result = Arguments.createMap();
                    result.putBoolean(Constants.SUCCESS, target.delete());
                    result.putString(Constants.URL, request.getUrl());
                    result.putString(Constants.PATH, target.getAbsolutePath());
                    promise.resolve(result);
                } else {
                    WritableMap result = Arguments.createMap();
                    result.putBoolean(Constants.SUCCESS, false);
                    result.putString(Constants.URL, request.getUrl());
                    promise.resolve(result);
                }
            }
        };
        execute(task, null);
    }

    @ReactMethod
    public void check(final ReadableMap options, final Promise promise) {
        final Request request = new Request(options);
        if (request.validateRequest(promise)) {
            return;
        }
        Runnable task = new Runnable() {
            @Override
            public void run() {
                File target = request.generateTargetFile();
                if (target.exists() && target.length() > 0 && !target.isDirectory()) {
                    WritableMap result = Arguments.createMap();
                    result.putBoolean(Constants.EXISTS, true);
                    result.putString(Constants.PATH, target.getAbsolutePath());
                    result.putString(Constants.URL, request.getUrl());
                    promise.resolve(result);
                } else {
                    WritableMap result = Arguments.createMap();
                    result.putBoolean(Constants.EXISTS, false);
                    result.putString(Constants.URL, request.getUrl());
                    promise.resolve(result);
                }
            }
        };
        execute(task, null);
    }

    @ReactMethod
    public void select(final ReadableMap options, final Promise promise) {
        final Request request = new Request(options);
        if (request.validateRequest(promise)) {
            return;
        }
        final String url = request.getUrl();
        try {
            threadPoolExecutor.execute(new Runnable() {
                @Override
                public void run() {
                    String taskId = request.selectTaskId();
                    if (tasks.contains(taskId)) {
                        rejectSelect(promise, Arguments.createMap(), url);
                    } else {
                        final File target = request.generateTargetFile();
                        if (!target.exists()) {
                            try {
                                AccessibleResult accessibleResult = request.checkUrlAccessible();
                                if (!accessibleResult.isAccessible()) {
                                    WritableMap errResp = Arguments.createMap();
                                    errResp.putInt(Constants.STATUS_CODE, accessibleResult.getResponseCode());
                                    errResp.putString(Constants.MESSAGE, accessibleResult.getMessage());
                                    rejectSelect(promise, errResp, url);
                                } else {
                                    post(request);
                                    rejectSelect(promise, Arguments.createMap(), url);
                                }
                            } catch (IOException e) {
                                WritableMap errResp = Arguments.createMap();
                                errResp.putInt(Constants.STATUS_CODE, -1);
                                errResp.putString(Constants.MESSAGE, e.getMessage());
                                rejectSelect(promise, errResp, url);
                            }
                        } else {
                            if (!target.isDirectory() && target.length() > 0) {
                                WritableMap map = Arguments.createMap();
                                map.putString(Constants.URL, "file://" + target.getAbsolutePath());
                                map.putBoolean(Constants.SUCCESS, true);
                                promise.resolve(map);
                            } else {
                                if (target.isDirectory())
                                    target.delete();
                                rejectSelect(promise, Arguments.createMap(), url);
                            }
                        }
                    }
                }
            });
        } catch (RejectedExecutionException e) {
            rejectSelect(promise, Arguments.createMap(), url);
        }
    }
}