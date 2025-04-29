/**
 * EmbyService.js
 * 提供与Emby媒体服务器连接的功能
 * 包括服务器发现、认证和媒体获取
 */

class EmbyService {
    constructor() {
        this.baseUrl = null; // Emby服务器基础URL
        this.apiKey = null; // API密钥
        this.userId = null; // 用户ID
        this.isConnected = false; // 连接状态
        this.deviceId = this._generateDeviceId(); // 生成设备ID
        this.serverInfo = null; // 服务器信息
    }

    /**
     * 生成唯一设备ID
     * @returns {string} 设备ID
     */
    _generateDeviceId() {
        return 'AuroraMusic_' + Math.random().toString(36).substring(2, 15);
    }

    /**
     * 连接到Emby服务器
     * @param {string} serverUrl - Emby服务器URL
     * @returns {Promise<Object>} 服务器信息
     */
    async connectToServer(serverUrl) {
        try {
            // 确保URL格式正确
            if (!serverUrl.startsWith('http')) {
                serverUrl = 'http://' + serverUrl;
            }
            
            // 移除URL末尾的斜杠
            if (serverUrl.endsWith('/')) {
                serverUrl = serverUrl.slice(0, -1);
            }
            
            this.baseUrl = serverUrl;
            
            // 获取服务器信息
            const response = await this._simulateFetch(`${this.baseUrl}/System/Info/Public`);
            
            if (response && response.ServerName) {
                this.serverInfo = response;
                console.log(`成功连接到Emby服务器: ${response.ServerName}`);
                return response;
            } else {
                throw new Error('无法获取服务器信息');
            }
        } catch (error) {
            console.error('连接Emby服务器失败:', error);
            throw error;
        }
    }

    /**
     * 用户登录
     * @param {string} username - 用户名
     * @param {string} password - 密码
     * @returns {Promise<Object>} 登录结果
     */
    async login(username, password) {
        try {
            if (!this.baseUrl) {
                throw new Error('请先连接到服务器');
            }
            
            // 模拟登录请求
            const response = await this._simulateFetch(`${this.baseUrl}/Users/AuthenticateByName`, {
                method: 'POST',
                body: JSON.stringify({
                    Username: username,
                    Pw: password
                })
            });
            
            if (response && response.AccessToken) {
                this.apiKey = response.AccessToken;
                this.userId = response.User.Id;
                this.isConnected = true;
                console.log(`用户 ${username} 登录成功`);
                return response;
            } else {
                throw new Error('登录失败');
            }
        } catch (error) {
            console.error('登录失败:', error);
            throw error;
        }
    }

    /**
     * 获取音乐库
     * @returns {Promise<Array>} 音乐库列表
     */
    async getMusicLibraries() {
        try {
            if (!this.isConnected) {
                throw new Error('请先登录');
            }
            
            // 获取音乐库
            const response = await this._simulateFetch(
                `${this.baseUrl}/Library/VirtualFolders`,
                { headers: { 'X-MediaBrowser-Token': this.apiKey } }
            );
            
            // 过滤出音乐库
            const musicLibraries = response.filter(library => 
                library.CollectionType === 'music' || 
                library.LibraryOptions.ContentType === 'Audio'
            );
            
            return musicLibraries;
        } catch (error) {
            console.error('获取音乐库失败:', error);
            throw error;
        }
    }

    /**
     * 获取音乐
     * @param {string} libraryId - 音乐库ID
     * @param {Object} options - 查询选项
     * @returns {Promise<Array>} 音乐列表
     */
    async getMusic(libraryId, options = {}) {
        try {
            if (!this.isConnected) {
                throw new Error('请先登录');
            }
            
            // 默认查询参数
            const params = {
                SortBy: 'SortName',
                SortOrder: 'Ascending',
                IncludeItemTypes: 'Audio',
                Recursive: true,
                Fields: 'PrimaryImageAspectRatio,SortName,BasicSyncInfo',
                ImageTypeLimit: 1,
                EnableImageTypes: 'Primary,Backdrop,Banner,Thumb',
                Limit: 100,
                ...options
            };
            
            // 构建查询字符串
            const queryString = Object.keys(params)
                .map(key => `${key}=${encodeURIComponent(params[key])}`)
                .join('&');
            
            // 获取音乐
            const response = await this._simulateFetch(
                `${this.baseUrl}/Items?ParentId=${libraryId}&${queryString}`,
                { headers: { 'X-MediaBrowser-Token': this.apiKey } }
            );
            
            return response.Items || [];
        } catch (error) {
            console.error('获取音乐失败:', error);
            throw error;
        }
    }

    /**
     * 获取专辑
     * @param {string} libraryId - 音乐库ID
     * @returns {Promise<Array>} 专辑列表
     */
    async getAlbums(libraryId) {
        try {
            return await this.getMusic(libraryId, {
                IncludeItemTypes: 'MusicAlbum',
                Recursive: true
            });
        } catch (error) {
            console.error('获取专辑失败:', error);
            throw error;
        }
    }

    /**
     * 获取艺术家
     * @param {string} libraryId - 音乐库ID
     * @returns {Promise<Array>} 艺术家列表
     */
    async getArtists(libraryId) {
        try {
            return await this.getMusic(libraryId, {
                IncludeItemTypes: 'MusicArtist',
                Recursive: true
            });
        } catch (error) {
            console.error('获取艺术家失败:', error);
            throw error;
        }
    }

    /**
     * 获取歌曲播放URL
     * @param {string} itemId - 歌曲ID
     * @returns {string} 播放URL
     */
    getPlaybackUrl(itemId) {
        if (!this.isConnected || !this.baseUrl || !this.apiKey) {
            throw new Error('请先登录');
        }
        
        return `${this.baseUrl}/Audio/${itemId}/stream?api_key=${this.apiKey}&DeviceId=${this.deviceId}`;
    }

    /**
     * 获取图片URL
     * @param {string} itemId - 项目ID
     * @param {string} imageType - 图片类型 (Primary, Backdrop, etc.)
     * @returns {string} 图片URL
     */
    getImageUrl(itemId, imageType = 'Primary') {
        if (!this.baseUrl) {
            return 'https://via.placeholder.com/300/6a11cb/ffffff?text=无图片';
        }
        
        return `${this.baseUrl}/Items/${itemId}/Images/${imageType}`;
    }

    /**
     * 搜索
     * @param {string} query - 搜索关键词
     * @returns {Promise<Object>} 搜索结果
     */
    async search(query) {
        try {
            if (!this.isConnected) {
                throw new Error('请先登录');
            }
            
            const response = await this._simulateFetch(
                `${this.baseUrl}/Search/Hints?SearchTerm=${encodeURIComponent(query)}`,
                { headers: { 'X-MediaBrowser-Token': this.apiKey } }
            );
            
            return response;
        } catch (error) {
            console.error('搜索失败:', error);
            throw error;
        }
    }

    /**
     * 模拟网络请求
     * 注意：这是一个模拟函数，实际应用中应使用真实的fetch请求
     * @param {string} url - 请求URL
     * @param {Object} options - 请求选项
     * @returns {Promise<Object>} 响应数据
     */
    async _simulateFetch(url, options = {}) {
        console.log(`模拟请求: ${url}`, options);
        
        // 延迟模拟网络请求
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // 根据URL返回模拟数据
        if (url.includes('/System/Info/Public')) {
            return {
                ServerName: 'Emby 家庭媒体服务器',
                Version: '4.7.0',
                Id: 'emby123456',
                OperatingSystem: 'Linux'
            };
        }
        
        if (url.includes('/Users/AuthenticateByName')) {
            return {
                User: {
                    Name: 'user',
                    Id: 'user123'
                },
                AccessToken: 'mock-token-123456',
                ServerId: 'emby123456'
            };
        }
        
        if (url.includes('/Library/VirtualFolders')) {
            return [
                {
                    Name: '音乐库',
                    CollectionType: 'music',
                    ItemId: 'music123',
                    LibraryOptions: {
                        ContentType: 'Audio'
                    }
                },
                {
                    Name: '电影库',
                    CollectionType: 'movies',
                    ItemId: 'movies123',
                    LibraryOptions: {
                        ContentType: 'Video'
                    }
                }
            ];
        }
        
        if (url.includes('/Items') && url.includes('IncludeItemTypes=MusicAlbum')) {
            return {
                Items: [
                    {
                        Name: '叶惠美',
                        Id: 'album1',
                        Type: 'MusicAlbum',
                        Artists: ['周杰伦']
                    },
                    {
                        Name: '魔杰座',
                        Id: 'album2',
                        Type: 'MusicAlbum',
                        Artists: ['周杰伦']
                    }
                ],
                TotalRecordCount: 2
            };
        }
        
        if (url.includes('/Items') && url.includes('IncludeItemTypes=Audio')) {
            return {
                Items: [
                    {
                        Name: '晴天',
                        Id: 'song1',
                        Type: 'Audio',
                        Artists: ['周杰伦'],
                        Album: '叶惠美'
                    },
                    {
                        Name: '稻香',
                        Id: 'song2',
                        Type: 'Audio',
                        Artists: ['周杰伦'],
                        Album: '魔杰座'
                    }
                ],
                TotalRecordCount: 2
            };
        }
        
        if (url.includes('/Search/Hints')) {
            return {
                SearchHints: [
                    {
                        Name: '晴天',
                        Id: 'song1',
                        Type: 'Audio',
                        Artists: ['周杰伦'],
                        Album: '叶惠美'
                    }
                ],
                TotalRecordCount: 1
            };
        }
        
        // 默认返回空数组
        return [];
    }

    /**
     * 断开连接
     */
    disconnect() {
        this.baseUrl = null;
        this.apiKey = null;
        this.userId = null;
        this.isConnected = false;
        this.serverInfo = null;
        console.log('已断开与Emby服务器的连接');
    }
}

// 创建单例实例
const embyService = new EmbyService();