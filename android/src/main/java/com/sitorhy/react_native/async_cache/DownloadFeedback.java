package com.sitorhy.react_native.async_cache;

public interface DownloadFeedback {

    void onProgress(int current, int total);

    void onComplete(DownloadReport report);

    void onException(Exception e);

}
