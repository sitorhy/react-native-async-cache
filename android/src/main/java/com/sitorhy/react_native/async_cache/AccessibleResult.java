package com.sitorhy.react_native.async_cache;

public class AccessibleResult {
    private int responseCode;
    private boolean accessible;
    private String message;
    private String contentType;
    private long size = -1;

    public AccessibleResult(int responseCode, String message, String contentType, boolean accessible) {
        this.responseCode = responseCode;
        this.accessible = accessible;
        this.message = message;
        this.contentType = contentType;
    }


    public long getSize() {
        return size;
    }

    public void setSize(long size) {
        this.size = size;
    }

    public int getResponseCode() {
        return responseCode;
    }

    public String getContentType() {
        return contentType;
    }

    public boolean isAccessible() {
        return accessible;
    }

    public String getMessage() {
        return message;
    }
}
