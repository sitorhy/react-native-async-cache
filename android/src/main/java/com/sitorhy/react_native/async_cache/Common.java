package com.sitorhy.react_native.async_cache;

import android.content.Context;
import android.util.Base64;

import androidx.annotation.Nullable;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.Charset;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

public class Common {
    private final static String MODULE_DIR_NAME = "RNAsyncCache";

    private final static String USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36";

    public static AccessibleResult checkUrlAccessible(String method, String url, @Nullable HashMap<String, String> headers, int statusCodeLeft, int statusCodeRight, int timeout) throws IOException {
        URL sourceUrl = new URL(url);
        HttpURLConnection conn = (HttpURLConnection) sourceUrl.openConnection();
        conn.setRequestProperty("User-Agent", USER_AGENT);
        conn.setRequestProperty("Accept-Encoding", "identity");
        if (headers != null) {
            Set<String> keys = headers.keySet();
            Iterator<String> iterator = keys.iterator();
            while (iterator.hasNext()) {
                String key = iterator.next();
                String value = headers.get(key);
                if (value != null && !value.isEmpty()) {
                    conn.setRequestProperty(key, value);
                }
            }
        }
        conn.setRequestMethod(method);
        conn.setConnectTimeout(timeout);
        conn.setReadTimeout(timeout);
        int code = conn.getResponseCode();
        String message = conn.getResponseMessage();
        String contentType = conn.getContentType();
        conn.disconnect();
        AccessibleResult accessibleResult = new AccessibleResult(code, message, contentType, statusCodeLeft <= code && code <= statusCodeRight);
        accessibleResult.setSize(conn.getContentLength());
        return accessibleResult;
    }

    public static File getTempDirectory(Context context) {
        File cache = context.getExternalCacheDir();
        File tmp = new File(cache.getAbsolutePath() + File.separator + MODULE_DIR_NAME);
        if (!tmp.exists()) {
            tmp.mkdirs();
        }
        return tmp;
    }

    public static File getTargetDirectory(Context context) {
        File doc = context.getExternalFilesDir(MODULE_DIR_NAME);
        if (!doc.exists()) {
            doc.mkdirs();
        }
        return doc;
    }

    public static String generateTargetFileName(String taskId, String extension) {
        if (extension != null && !extension.isEmpty()) {
            String str = extension;
            int iQue = str.lastIndexOf("?");
            if (iQue >= 0) {
                str = str.substring(0, iQue);
            }
            int iSep = str.lastIndexOf("/");
            if (iSep >= 0) {
                str = str.substring(iSep + 1);
            }
            int iDot = str.lastIndexOf(".");
            if (iDot >= 0) {
                String ext = str.substring(iDot);
                return taskId + ext;
            }
        }
        return taskId;
    }

    public static File generateTargetDirectory(String targetDir, String subDir) {
        String path = targetDir + ((subDir != null && !subDir.isEmpty()) ? File.separator + subDir : "");
        File dir = new File(path);
        if (!dir.exists()) {
            dir.mkdirs();
        }
        return dir;
    }

    public static File generateTargetFile(String targetDir, String subDir, String taskId, String extension) {
        String path = targetDir + ((subDir != null && !subDir.isEmpty()) ? File.separator + subDir : "");
        File dir = new File(path);
        if (!dir.exists()) {
            dir.mkdirs();
        }
        return new File(path + File.separator + generateTargetFileName(taskId, extension));
    }

    public static void writeDataToFile(File file, byte[] data) throws IOException {
        FileOutputStream fileOutputStream = new FileOutputStream(file);
        fileOutputStream.write(data);
        fileOutputStream.close();
    }

    public static void download(DownloadFeedback feedback, Context context, String url, Map<String, String> headers, final File target, int timeout) throws IOException {
        if (url == null || url.isEmpty()) {
            throw new IllegalArgumentException("url is not allow empty");
        }

        final File temp = new File(getTempDirectory(context).getAbsolutePath() + File.separator + UUID.randomUUID().toString() + ".tmp");
        if (temp.exists()) {
            temp.delete();
        }
        URL resUrl = new URL(url);
        HttpURLConnection conn = (HttpURLConnection) resUrl.openConnection();
        conn.setConnectTimeout(timeout);
        conn.setRequestProperty("User-Agent", USER_AGENT);
        conn.setRequestProperty("Accept-Encoding", "identity");
        if (headers != null) {
            Set<String> keys = headers.keySet();
            Iterator<String> iterator = keys.iterator();
            while (iterator.hasNext()) {
                String key = iterator.next();
                String value = headers.get(key);
                if (value != null && !value.isEmpty()) {
                    conn.setRequestProperty(key, value);
                }
            }
        }
        InputStream inputStream = conn.getInputStream();
        BufferedInputStream bis = new BufferedInputStream(inputStream);
        FileOutputStream fos = new FileOutputStream(temp);
        int read;
        int current = 0;
        int contentLength = conn.getContentLength();
        byte[] buffer;
        if (contentLength >= 10485760) {
            buffer = new byte[1024 * 1024];
        } else {
            buffer = new byte[4096];
        }
        try {
            while ((read = bis.read(buffer, 0, buffer.length)) != -1) {
                fos.write(buffer, 0, read);
                if (feedback != null) {
                    current += read;
                    feedback.onProgress(current, contentLength);
                }
            }
            if (target.exists()) {
                if (target.delete())
                    temp.renameTo(target);
            } else
                temp.renameTo(target);
            if (feedback != null) {
                DownloadReport report = new DownloadReport();
                report.setPath(target.getAbsolutePath());
                report.setSize(target.length());
                feedback.onComplete(report);
            }
        } catch (IOException e) {
            if (feedback != null)
                feedback.onException(e);
        } finally {
            fos.close();
            bis.close();
            inputStream.close();
        }
    }

    public static String selectTaskId(String id, String url, String sign) throws NoSuchAlgorithmException {
        if (id != null && !id.isEmpty()) {
            return id;
        }
        MessageDigest md5 = MessageDigest.getInstance("MD5");
        byte[] md5Bytes = md5.digest(sign == null || sign.isEmpty() ? url.getBytes() : (url + sign).getBytes());
        StringBuilder stringBuffer = new StringBuilder();
        for (int i = 0; i < md5Bytes.length; i++) {
            int val = ((int) md5Bytes[i]) & 0xff;
            if (val < 16)
                stringBuffer.append("0");
            stringBuffer.append(Integer.toHexString(val));
        }
        return stringBuffer.toString();
    }

    static public byte[] decodeBase64String(String str, Charset charset) throws Exception {
        byte[] decode = Base64.decode(str.getBytes(charset), Base64.DEFAULT);
        return decode;
    }

    static public byte[] decodeBase64URLString(String str, Charset charset) throws Exception {
        byte[] decode = Base64.decode(str.getBytes(charset), Base64.URL_SAFE);
        return decode;
    }
}
