/**
 * Aurora Music 网页预览版应用逻辑
 * 连接数据模型与界面交互
 */

// 当文档加载完成后执行
document.addEventListener('DOMContentLoaded', () => {
    // 初始化应用
    initApp();
});

/**
 * 初始化应用
 */
function initApp() {
    // 加载数据
    loadData();
    
    // 设置标签切换事件
    setupTabSwitching();
    
    // 设置播放控制
    setupPlaybackControls();
    
    // 设置搜索功能
    setupSearch();
    
    // 设置Emby服务器连接功能
    setupEmbyConnection();
}

/**
 * 加载数据到界面
 */
function loadData() {
    // 加载推荐歌曲
    loadRecommendedSongs();
    
    // 加载热门歌单
    loadPopularAlbums();
    
    // 加载音乐分类
    loadMusicCategories();
    
    // 加载用户信息
    loadUserProfile();
    
    // 加载收藏歌曲
    loadFavoriteSongs();
}

/**
 * 加载推荐歌曲
 */
function loadRecommendedSongs() {
    const songListContainer = document.querySelector('#home-section .song-list');
    songListContainer.innerHTML = '';
    
    // 获取前3首歌曲作为推荐
    const recommendedSongs = musicData.songs.slice(0, 3);
    
    recommendedSongs.forEach(song => {
        const songCard = createSongCard(song);
        songListContainer.appendChild(songCard);
    });
}

/**
 * 加载热门歌单
 */
function loadPopularAlbums() {
    const albumGridContainer = document.querySelector('#home-section .album-grid');
    albumGridContainer.innerHTML = '';
    
    // 获取前2个歌单作为热门歌单
    const popularAlbums = musicData.albums.slice(0, 2);
    
    popularAlbums.forEach(album => {
        const albumCard = createAlbumCard(album);
        albumGridContainer.appendChild(albumCard);
    });
}

/**
 * 加载音乐分类
 */
function loadMusicCategories() {
    const categoriesContainer = document.querySelector('#browse-section .album-grid');
    categoriesContainer.innerHTML = '';
    
    musicData.categories.forEach(category => {
        const categoryCard = document.createElement('div');
        categoryCard.className = 'album-card';
        categoryCard.innerHTML = `
            <img src="${category.cover}" alt="${category.name}" class="album-cover">
            <div class="album-info">
                <div class="album-title">${category.name}</div>
            </div>
        `;
        
        categoryCard.addEventListener('click', () => {
            alert(`浏览${category.name}分类的音乐`);
        });
        
        categoriesContainer.appendChild(categoryCard);
    });
}

/**
 * 加载用户信息
 */
function loadUserProfile() {
    const profileSection = document.getElementById('profile-section');
    const userAvatar = profileSection.querySelector('img');
    const userName = profileSection.querySelector('h2');
    const memberType = profileSection.querySelector('p');
    
    userAvatar.src = musicData.user.avatar;
    userName.textContent = musicData.user.username;
    memberType.textContent = musicData.user.memberType;
}

/**
 * 加载收藏歌曲
 */
function loadFavoriteSongs() {
    const favoritesContainer = document.querySelector('#profile-section .song-list');
    favoritesContainer.innerHTML = '';
    
    // 获取用户收藏的歌曲
    const favoriteSongs = musicData.songs.filter(song => 
        musicData.user.favoriteSongs.includes(song.id)
    );
    
    // 只显示前2首收藏歌曲
    favoriteSongs.slice(0, 2).forEach(song => {
        const songCard = createSongCard(song);
        favoritesContainer.appendChild(songCard);
    });
}

/**
 * 创建歌曲卡片元素
 * @param {Object} song - 歌曲数据
 * @returns {HTMLElement} - 歌曲卡片DOM元素
 */
function createSongCard(song) {
    const songCard = document.createElement('div');
    songCard.className = 'song-card';
    songCard.dataset.songId = song.id;
    
    songCard.innerHTML = `
        <img src="${song.cover}" alt="${song.title}" class="song-cover">
        <div class="song-info">
            <div class="song-title">${song.title}</div>
            <div class="song-artist">${song.artist}</div>
        </div>
    `;
    
    // 添加点击事件
    songCard.addEventListener('click', () => {
        playSong(song);
    });
    
    return songCard;
}

/**
 * 创建专辑/歌单卡片元素
 * @param {Object} album - 专辑/歌单数据
 * @returns {HTMLElement} - 专辑卡片DOM元素
 */
function createAlbumCard(album) {
    const albumCard = document.createElement('div');
    albumCard.className = 'album-card';
    albumCard.dataset.albumId = album.id;
    
    albumCard.innerHTML = `
        <img src="${album.cover}" alt="${album.title}" class="album-cover">
        <div class="album-info">
            <div class="album-title">${album.title}</div>
            <div class="album-artist">${album.artist}</div>
        </div>
    `;
    
    // 添加点击事件
    albumCard.addEventListener('click', () => {
        alert(`打开${album.title}${album.type === 'playlist' ? '歌单' : '专辑'}`);
    });
    
    return albumCard;
}

/**
 * 设置标签切换
 */
function setupTabSwitching() {
    document.querySelectorAll('.tab-item').forEach(tab => {
        tab.addEventListener('click', () => {
            // 移除所有活动状态
            document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.content-section').forEach(section => section.classList.remove('active'));
            
            // 添加当前活动状态
            tab.classList.add('active');
            const tabId = tab.getAttribute('data-tab');
            document.getElementById(`${tabId}-section`).classList.add('active');
        });
    });
}

/**
 * 设置播放控制
 */
function setupPlaybackControls() {
    const playButton = document.querySelector('.play-button');
    const prevButton = document.querySelector('.control-button:first-child');
    const nextButton = document.querySelector('.control-button:last-child');
    
    // 播放/暂停按钮
    playButton.addEventListener('click', () => {
        togglePlayback();
    });
    
    // 上一首按钮
    prevButton.addEventListener('click', () => {
        alert('播放上一首');
    });
    
    // 下一首按钮
    nextButton.addEventListener('click', () => {
        alert('播放下一首');
    });
}

/**
 * 设置搜索功能
 */
function setupSearch() {
    const searchInput = document.querySelector('.search-input');
    const searchButton = document.querySelector('.search-button');
    
    // 搜索按钮点击事件
    searchButton.addEventListener('click', () => {
        performSearch(searchInput.value);
    });
    
    // 回车键搜索
    searchInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            performSearch(searchInput.value);
        }
    });
}

/**
 * 执行搜索
 * @param {string} query - 搜索关键词
 */
function performSearch(query) {
    query = query.trim();
    if (!query) return;
    
    // 模拟搜索结果
    alert(`搜索: ${query}`);
    
    // 实际应用中这里会调用搜索API并显示结果
    const searchResults = musicData.songs.filter(song => 
        song.title.includes(query) || song.artist.includes(query)
    );
    
    // 显示搜索结果数量
    console.log(`找到 ${searchResults.length} 个结果`);
}

/**
 * 播放歌曲
 * @param {Object} song - 要播放的歌曲
 */
function playSong(song) {
    // 更新播放器信息
    document.querySelector('.mini-title').textContent = song.title;
    document.querySelector('.mini-artist').textContent = song.artist;
    document.querySelector('.mini-cover').src = song.cover;
    
    // 切换播放按钮为暂停
    const playButton = document.querySelector('.play-button');
    playButton.textContent = '⏸';
    
    // 模拟播放状态
    console.log(`正在播放: ${song.title} - ${song.artist}`);
    alert(`正在播放: ${song.title} - ${song.artist}`);
}

/**
 * 切换播放状态
 */
function togglePlayback() {
    const playButton = document.querySelector('.play-button');
    
    if (playButton.textContent === '▶') {
        playButton.textContent = '⏸';
        alert('开始播放');
    } else {
        playButton.textContent = '▶';
        alert('暂停播放');
    }
}

/**
 * 设置Emby服务器连接功能
 */
function setupEmbyConnection() {
    const connectButton = document.getElementById('connect-button');
    const disconnectButton = document.getElementById('disconnect-button');
    const serverUrlInput = document.getElementById('server-url');
    const usernameInput = document.getElementById('emby-username');
    const passwordInput = document.getElementById('emby-password');
    const connectionStatus = document.getElementById('connection-status');
    const serverInfo = document.getElementById('server-info');
    const embyContent = document.getElementById('emby-content');
    
    // 连接按钮点击事件
    connectButton.addEventListener('click', async () => {
        const serverUrl = serverUrlInput.value.trim();
        const username = usernameInput.value.trim();
        const password = passwordInput.value.trim();
        
        if (!serverUrl) {
            alert('请输入服务器地址');
            return;
        }
        
        try {
            // 显示连接中状态
            connectButton.textContent = '连接中...';
            connectButton.disabled = true;
            
            // 连接到服务器
            const serverInfoData = await embyService.connectToServer(serverUrl);
            
            // 如果提供了用户名和密码，则尝试登录
            if (username && password) {
                await embyService.login(username, password);
            }
            
            // 更新UI显示连接状态
            serverInfo.innerHTML = `
                <div style="font-weight: 600; margin-bottom: 5px;">${serverInfoData.ServerName}</div>
                <div style="font-size: 14px; color: #666;">版本: ${serverInfoData.Version}</div>
                <div style="font-size: 14px; color: #666; margin-bottom: 10px;">状态: ${embyService.isConnected ? '已连接' : '已连接(未登录)'}</div>
            `;
            
            connectionStatus.style.display = 'block';
            
            // 如果已登录，加载音乐库
            if (embyService.isConnected) {
                embyContent.style.display = 'block';
                loadEmbyMusicLibraries();
                loadEmbyRecentMusic();
            }
            
            // 重置连接按钮
            connectButton.textContent = '连接';
            connectButton.disabled = false;
            
        } catch (error) {
            alert(`连接失败: ${error.message}`);
            console.error('连接失败:', error);
            
            // 重置连接按钮
            connectButton.textContent = '连接';
            connectButton.disabled = false;
        }
    });
    
    // 断开连接按钮点击事件
    disconnectButton.addEventListener('click', () => {
        embyService.disconnect();
        connectionStatus.style.display = 'none';
        embyContent.style.display = 'none';
        serverUrlInput.value = '';
        usernameInput.value = '';
        passwordInput.value = '';
    });
}

/**
 * 加载Emby音乐库
 */
async function loadEmbyMusicLibraries() {
    try {
        const musicLibrariesContainer = document.getElementById('music-libraries');
        musicLibrariesContainer.innerHTML = '';
        
        // 获取音乐库
        const libraries = await embyService.getMusicLibraries();
        
        if (libraries.length === 0) {
            musicLibrariesContainer.innerHTML = '<div style="grid-column: span 2; text-align: center; padding: 20px;">未找到音乐库</div>';
            return;
        }
        
        // 显示音乐库
        libraries.forEach(library => {
            const libraryCard = document.createElement('div');
            libraryCard.className = 'album-card';
            libraryCard.innerHTML = `
                <div style="height: 150px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); color: white; font-size: 36px;">
                    🎵
                </div>
                <div class="album-info">
                    <div class="album-title">${library.Name}</div>
                    <div class="album-artist">音乐库</div>
                </div>
            `;
            
            // 添加点击事件
            libraryCard.addEventListener('click', () => {
                alert(`打开音乐库: ${library.Name}`);
                // 实际应用中这里会导航到音乐库内容页面
            });
            
            musicLibrariesContainer.appendChild(libraryCard);
        });
        
    } catch (error) {
        console.error('加载音乐库失败:', error);
    }
}

/**
 * 加载Emby最近添加的音乐
 */
async function loadEmbyRecentMusic() {
    try {
        const recentMusicContainer = document.getElementById('recent-music');
        recentMusicContainer.innerHTML = '';
        
        // 获取音乐库
        const libraries = await embyService.getMusicLibraries();
        
        if (libraries.length === 0) {
            recentMusicContainer.innerHTML = '<div style="text-align: center; padding: 20px;">未找到音乐</div>';
            return;
        }
        
        // 获取第一个音乐库的音乐
        const songs = await embyService.getMusic(libraries[0].ItemId, {
            SortBy: 'DateCreated,SortName',
            SortOrder: 'Descending',
            Limit: 5
        });
        
        if (songs.length === 0) {
            recentMusicContainer.innerHTML = '<div style="text-align: center; padding: 20px;">未找到音乐</div>';
            return;
        }
        
        // 显示音乐
        songs.forEach(song => {
            const songCard = document.createElement('div');
            songCard.className = 'song-card';
            
            // 获取封面图片URL
            const coverUrl = embyService.getImageUrl(song.Id);
            
            songCard.innerHTML = `
                <img src="${coverUrl}" alt="${song.Name}" class="song-cover">
                <div class="song-info">
                    <div class="song-title">${song.Name}</div>
                    <div class="song-artist">${song.Artists ? song.Artists.join(', ') : '未知艺术家'}</div>
                </div>
            `;
            
            // 添加点击事件
            songCard.addEventListener('click', () => {
                // 获取播放URL
                const playUrl = embyService.getPlaybackUrl(song.Id);
                
                // 更新播放器信息
                document.querySelector('.mini-title').textContent = song.Name;
                document.querySelector('.mini-artist').textContent = song.Artists ? song.Artists.join(', ') : '未知艺术家';
                document.querySelector('.mini-cover').src = coverUrl;
                
                // 切换播放按钮为暂停
                const playButton = document.querySelector('.play-button');
                playButton.textContent = '⏸';
                
                console.log(`正在播放Emby音乐: ${song.Name}，URL: ${playUrl}`);
                alert(`正在播放: ${song.Name}`);
            });
            
            recentMusicContainer.appendChild(songCard);
        });
        
    } catch (error) {
        console.error('加载最近音乐失败:', error);
        const recentMusicContainer = document.getElementById('recent-music');
        recentMusicContainer.innerHTML = `<div style="text-align: center; padding: 20px;">加载失败: ${error.message}</div>`;
    }
}