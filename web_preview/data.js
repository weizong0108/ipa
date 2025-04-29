/**
 * Aurora Music 网页预览版数据模型
 * 模拟应用中的音乐数据，用于展示界面
 */

// 歌曲数据
const songs = [
    {
        id: 1,
        title: "星辰大海",
        artist: "黄霄雲",
        album: "星辰大海",
        cover: "https://via.placeholder.com/300/6a11cb/ffffff?text=星辰大海",
        duration: "03:25",
        isFavorite: true
    },
    {
        id: 2,
        title: "起风了",
        artist: "买辣椒也用券",
        album: "起风了",
        cover: "https://via.placeholder.com/300/2575fc/ffffff?text=起风了",
        duration: "05:11",
        isFavorite: false
    },
    {
        id: 3,
        title: "光年之外",
        artist: "G.E.M.邓紫棋",
        album: "光年之外",
        cover: "https://via.placeholder.com/300/8844ee/ffffff?text=光年之外",
        duration: "04:15",
        isFavorite: true
    },
    {
        id: 4,
        title: "晴天",
        artist: "周杰伦",
        album: "叶惠美",
        cover: "https://via.placeholder.com/300/44aadd/ffffff?text=晴天",
        duration: "04:29",
        isFavorite: false
    },
    {
        id: 5,
        title: "漠河舞厅",
        artist: "柳爽",
        album: "漠河舞厅",
        cover: "https://via.placeholder.com/300/dd5566/ffffff?text=漠河舞厅",
        duration: "03:46",
        isFavorite: false
    },
    {
        id: 6,
        title: "可能",
        artist: "程响",
        album: "可能",
        cover: "https://via.placeholder.com/300/55aa66/ffffff?text=可能",
        duration: "04:08",
        isFavorite: true
    },
    {
        id: 7,
        title: "我曾",
        artist: "隔壁老樊",
        album: "我曾",
        cover: "https://via.placeholder.com/300/aa7744/ffffff?text=我曾",
        duration: "04:54",
        isFavorite: true
    }
];

// 专辑/歌单数据
const albums = [
    {
        id: 1,
        title: "流行热歌",
        artist: "编辑推荐",
        cover: "https://via.placeholder.com/300/6a11cb/ffffff?text=流行热歌",
        songCount: 25,
        type: "playlist"
    },
    {
        id: 2,
        title: "轻音乐集",
        artist: "编辑推荐",
        cover: "https://via.placeholder.com/300/2575fc/ffffff?text=轻音乐集",
        songCount: 18,
        type: "playlist"
    },
    {
        id: 3,
        title: "叶惠美",
        artist: "周杰伦",
        cover: "https://via.placeholder.com/300/44aadd/ffffff?text=叶惠美",
        songCount: 10,
        type: "album",
        releaseYear: 2003
    },
    {
        id: 4,
        title: "新歌速递",
        artist: "编辑推荐",
        cover: "https://via.placeholder.com/300/dd5566/ffffff?text=新歌速递",
        songCount: 15,
        type: "playlist"
    }
];

// 音乐分类
const categories = [
    {
        id: 1,
        name: "流行",
        cover: "https://via.placeholder.com/300/6a11cb/ffffff?text=流行"
    },
    {
        id: 2,
        name: "摇滚",
        cover: "https://via.placeholder.com/300/2575fc/ffffff?text=摇滚"
    },
    {
        id: 3,
        name: "古典",
        cover: "https://via.placeholder.com/300/8844ee/ffffff?text=古典"
    },
    {
        id: 4,
        name: "电子",
        cover: "https://via.placeholder.com/300/44aadd/ffffff?text=电子"
    },
    {
        id: 5,
        name: "民谣",
        cover: "https://via.placeholder.com/300/dd5566/ffffff?text=民谣"
    },
    {
        id: 6,
        name: "嘻哈",
        cover: "https://via.placeholder.com/300/55aa66/ffffff?text=嘻哈"
    }
];

// 用户数据
const user = {
    username: "音乐爱好者",
    avatar: "https://via.placeholder.com/300/6a11cb/ffffff?text=用户",
    memberType: "普通会员",
    favoriteSongs: [1, 3, 6, 7],
    favoriteAlbums: [1, 3],
    recentlyPlayed: [2, 4, 5]
};

// Emby服务器数据
const embyServers = [
    {
        id: 1,
        name: "家庭NAS",
        url: "http://192.168.1.100:8096",
        lastConnected: "2023-05-15"
    },
    {
        id: 2,
        name: "工作室服务器",
        url: "http://10.0.0.50:8096",
        lastConnected: "2023-05-10"
    }
];

// 导出数据模型
const musicData = {
    songs,
    albums,
    categories,
    user,
    embyServers
};