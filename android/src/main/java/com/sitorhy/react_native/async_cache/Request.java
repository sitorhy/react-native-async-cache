package com.sitorhy.react_native.async_cache;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;

import java.io.File;
import java.io.IOException;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class Request {
    private int statusCodeLeft = 200;
    private int statusCodeRight = 300;
    private int timeout = 12000;
    private String subDir = "";
    private String targetDir = "";
    private String id = "";
    private String url = "";
    private ReadableMap headers = null;
    private boolean accessible = false;
    private String accessibleMethod = "HEAD";
    private boolean rewrite = false;
    private String extension = null;

    private String __taskId = null;
    private HashMap<String, String> __headersMap;

    Request(ReadableMap request) {
        if (request.hasKey(Constants.STATUS_CODE_LEFT) && request.getType(Constants.STATUS_CODE_LEFT) == ReadableType.Number)
            statusCodeLeft = request.getInt(Constants.STATUS_CODE_LEFT);
        if (request.hasKey(Constants.STATUS_CODE_RIGHT) && request.getType(Constants.STATUS_CODE_RIGHT) == ReadableType.Number)
            statusCodeRight = request.getInt(Constants.STATUS_CODE_RIGHT);
        if (request.hasKey(Constants.TIME_OUT) && request.getType(Constants.TIME_OUT) == ReadableType.Number)
            timeout = request.getInt(Constants.TIME_OUT);
        if (request.hasKey(Constants.SUB_DIR))
            subDir = request.getString(Constants.SUB_DIR);
        if (request.hasKey(Constants.TARGET_DIR))
            targetDir = request.getString(Constants.TARGET_DIR);
        if (request.hasKey(Constants.EXTENSION)) {
            extension = request.getString(Constants.EXTENSION);
            if (extension != null) {
                extension = extension.trim();
                if (extension.length() > 0 && extension.charAt(0) != '.') {
                    extension = '.' + extension;
                }
            }
        }
        if (request.hasKey(Constants.ID))
            id = request.getString(Constants.ID);
        if (request.hasKey(Constants.URL))
            url = request.getString(Constants.URL);
        if (request.hasKey(Constants.HEADERS) && request.getType(Constants.HEADERS) == ReadableType.Map)
            headers = request.getMap(Constants.HEADERS);
        if (request.hasKey(Constants.ACCESSIBLE) && request.getType(Constants.ACCESSIBLE) == ReadableType.Boolean)
            accessible = request.getBoolean(Constants.ACCESSIBLE);
        if (request.hasKey(Constants.ACCESSIBLE_METHOD))
            accessibleMethod = request.getString(Constants.ACCESSIBLE_METHOD);
        if (request.hasKey(Constants.REWRITE) && request.getType(Constants.REWRITE) == ReadableType.Boolean)
            rewrite = request.getBoolean(Constants.REWRITE);
    }

    public HashMap<String, String> getHeadersMap() {
        if (__headersMap != null)
            return __headersMap;
        if (headers != null) {
            __headersMap = new HashMap<>();
            Iterator<Map.Entry<String, Object>> entryIterator = headers.getEntryIterator();
            while (entryIterator.hasNext()) {
                Map.Entry<String, Object> next = entryIterator.next();
                Object v = next.getValue();
                if (v.getClass() == String.class) {
                    __headersMap.put(next.getKey(), v.toString());
                }
            }
        }
        return __headersMap;
    }

    public String selectTaskId() {
        if (id != null && !id.isEmpty()) {
            return id;
        }
        if (__taskId != null && !__taskId.isEmpty())
            return __taskId;
        try {
            __taskId = Common.selectTaskId(id, url);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return __taskId;
    }

    public File generateTargetFile() {
        return Common.generateTargetFile(targetDir, subDir, this.selectTaskId(), this.extension);
    }

    public File generateTargetDirectory() {
        return Common.generateTargetDirectory(targetDir, subDir);
    }

    public boolean validateRequest(Promise promise) {
        if (url == null || url.isEmpty()) {
            if (promise != null) {
                promise.reject(new Exception("url not allow empty"));
            }
            return true;
        }
        if (!url.startsWith("http")) {
            if (promise != null) {
                promise.reject(new Exception("url is not a http link"));
            }
            return true;
        }
        return false;
    }

    public AccessibleResult checkUrlAccessible() throws IOException {
        return Common.checkUrlAccessible(this.accessibleMethod, this.url, this.getHeadersMap(), this.statusCodeLeft, this.statusCodeRight, this.timeout);
    }

    public int getStatusCodeLeft() {
        return statusCodeLeft;
    }

    public int getStatusCodeRight() {
        return statusCodeRight;
    }

    public int getTimeout() {
        return timeout;
    }

    public String getUrl() {
        return url;
    }

    public String getSubDir() {
        return subDir;
    }

    public boolean isAccessible() {
        return accessible;
    }

    public void setAccessible(boolean accessible) {
        this.accessible = accessible;
    }

    public boolean isRewrite() {
        return rewrite;
    }

    public String getAccessibleMethod() {
        return accessibleMethod;
    }

    public String getExtension() {
        return extension;
    }

    public void setExtension(String extension) {
        this.extension = extension;
    }
}
