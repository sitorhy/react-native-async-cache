import React, {useState, useEffect} from 'react';
import {NativeModules} from 'react-native';

const {ReactNativeAsyncCache} = NativeModules;

import AsyncCache from './components/AsyncCache';

export const TemporaryDirectory = ReactNativeAsyncCache.TemporaryDirectory;

export const DocumentDirectory = ReactNativeAsyncCache.DocumentDirectory;

export CacheComponent from './components/CacheComponent';

export CacheStoreComponent from './components/CacheStoreComponent';

export StoreProvider from './components/DefaultStoreProvider';

export default AsyncCache;
