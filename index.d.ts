import React from 'react';

export class RequestOptions {
    url: string;
    extension?: string;
    id?: string;
    headers?: { [key: string]: string };
    targetDir?: string;
    subDir?: string;
    statusCodeLeft?: number;
    statusCodeRight?: number;
    rewrite?: boolean;
}

export class SelectResponse {
    success: boolean;
    url: string;
    statusCode?: number;
    message?: string;
}

export class CheckResponse {
    exists: boolean;
    path?: string;
    url: string;
}

export class RemoveResponse {
    success: boolean;
    url: string;
    path?: string;
}

export class AccessibleResponse {
    accessible: boolean;
    statusCode: number;
    message: String;
    contentType: String;
    size: number;
    url: string;
}

export class DownloadResponse {
    path: string;
    url: string;
    size: number;
}

export class StoreProvider {
    get(url: string): string;

    set(url: string, local: string): void;

    error(url: string, code: number, message: string): void
}

export class CacheStoreParam {
    Component: React.Component;
    PendingComponent?: null | React.Component;
    mapToRequestOptions?: Function;
    mapToComponentProperties?: Function;
    sourceProperty?: string;
    invokeOnComponentErrorProperty?: string;
    invokeOnComponentLoadProperty?: string;
    sourceMapper?: Function;
    onSourceMapped ?: Function;
    onRequestError?: Function;
}

export class CacheStoreComponentParam {
    Component: React.Component;
    PendingComponent?: null | React.Component;
    mapToRequestOptions?: Function;
    mapToComponentProperties?: Function;
    sourceProperty?: string;
    invokeOnComponentErrorProperty?: string;
    invokeOnComponentLoadProperty?: string;
    store?: StoreProvider;
}

export type ProgressHandler = (progress: number, total: number, current: number, url: string) => void;

export function CacheComponent(CacheStoreParam): React.Component;

export function CacheStoreComponent(CacheStoreComponentParam): React.Component;

export const TemporaryDirectory: string;

export const DocumentDirectory: string;

export function trash(options: RequestOptions): Promise<void>;

export function clean(): Promise<void>;

export function remove(options: RequestOptions): Promise<RemoveResponse>;

export function accessible(options: RequestOptions): Promise<AccessibleResponse>;

export function check(options: RequestOptions): Promise<CheckResponse>;

export function select(options: RequestOptions): Promise<SelectResponse>;

export function post(options: RequestOptions): Promise<void>;

export function download(options: RequestOptions, onProgress: ProgressHandler): Promise<DownloadResponse>;
