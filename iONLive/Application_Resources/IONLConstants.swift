
import Foundation
let userLoginIdKey = "userLoginIdKey"
let userAccessTockenKey = "userAccessTockenKey"
let userBucketName = "userBucketName"
let archiveId = "archiveId"
let ArchiveCount =  "archiveMediaCount"
let apiErrorMessageKey = "errorMessage"
let apiErrorCodeKey = "errorCode"
let pullTorefreshKey = "channel_media_detail_id"
let infiniteScrollIdKey = "channel_media_detail_id"
let startedStreaming = "StartedStreaming"
let streamingToken = "StreamingToken"
let initializingStream = "InitializingStream"
let subChannelIdKey = "channel_sub_detail_id"
let apiDeveloperFailureMessage = "developerMsg"

let vowzaIp = "104.197.92.137" //Developer

//let vowzaIp = "104.154.69.174" //production

//let vowzaIp = "104.196.159.90" //IR3

//channel details
let MyChannelIdKey = "channel_detail_id"
let channelNameKey = "channel_name"
let totalMediaKey = "total_no_media_shared"
let ChannelCreatedTimeKey = "last_updated_time_stamp"
let sharedOriginalKey = "orgSelected"
let sharedTemporaryKey = "tempSelected"
let chanelSharedIndicatorKey = "channel_shared_ind"
let latestMediaIdKey = "latest_thumbnail_id"

//media details
let mediaIdKey = "media_detail_id"
let tImageKey = "thumbImage"
let tImageURLKey = "thumbImage_URL"
let fImageURLKey = "fullImage_URL"
let notifTypeKey = "notification_type"
let mediaTypeKey = "gcs_object_type"
let progressKey = "upload_progress"
let channelMediaIdKey = "channel_media_detail_id"
let videoDurationKey = "video_duration"
let mediaCreatedTimeKey = "created_time_stamp"

// channel page
let ch_channelIdkey = "ch_detail_id"
let ch_channelNameKey = "channel_name"
let sharedMediaCount = "total_no_media_shared"
let totalNoShared = "totalNo"
let timeStamp = "created_time_stamp"
let lastUpdatedTimeStamp = "last_updated_time_stamp"
let usernameKey = "user_name"
let profileImageKey = "profile_image_thumbnail"
let liveStreamStatus = "liveChannel"
let isWatched = "isWatched"
let streamTockenKey = "wowza_stream_token"
let mediaImageKey = "mediaImage"
let thumbImageKey = "thumbImage"
let liveChannelKey = "liveChannels"
let subscribedChannelsKey = "subscribedChannels"
let latest_thumbnail_idKey = "latest_thumbnail_id"

// Stream & Other channel keys
let actualImageKey = "actualImage"
let userIdKey = "user_name"
let mediaUrlKey = "mediaUrl"
let stream_mediaIdKey = "mediaId"
let stream_mediaTypeKey = "mediaType"
let timeKey = ""
let stream_thumbImageKey = "thumbImage"
let stream_streamTockenKey = "wowza_stream_token"
let imageKey = "image"
let typeKey = "type"
let imageType = "imageType"
let timestamp = "last_updated_time_stamp"
let channelIdkey = "ch_detail_id"
let stream_channelNameKey = "channel_name"
let notificationKey = "notification"

@objc enum SnapCamSelectionMode : Int {
    
    case LiveStream = 0
    case Photos
    case Video
    case CatchGif
    case Timelapse
    case iPhone
    case TestAPI
    case SnapCam
    
    init() {
        self = .Photos
    }
    
}


