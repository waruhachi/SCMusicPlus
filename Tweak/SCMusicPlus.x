#import <UIKit/UIKit.h>

%hook UpsellManager
- (bool)canNotUpsell {
	return YES;
}

- (bool)shouldUpsell {
	return NO;
}

- (bool)shouldUpsellCreator {
	return NO;
}

- (bool)shouldShowTabBarUpsell {
	return NO;
}

- (bool)shouldUpsellGoLite {
	return NO;
}

- (bool)shouldUpsellForTrack:(id)arg1 {
	return NO;
}

- (bool)shouldUpsellForPlaylist:(id)arg1 {
	return NO;
}
%end

%hook UserFeaturesService
- (bool)isNoAudioAdsEnabled {
	return YES;
}

- (bool)isEnrolledInBetaProgram {
	return YES;
}

- (bool)isHQAudioFeatureEnabled {
	return YES;
}

- (bool)isDevelopmentMenuEnabled {
	return YES;
}

- (bool)isOfflineSyncFeatureEnabled {
	return YES;
}

- (bool)isSpotlightEditingEnabled {
	return YES;
}
%end

%hook AdsRequestPermitter
- (bool)shouldRequestAds {
	return NO;
}
%end

%hook PlayQueueItemTrackEntity
- (bool)isMonetizable {
	return NO;
}

- (id)initWithUrn:(id)arg1
			transcodings:(id)arg2
			   streamURL:(id)arg3
			 waveformURL:(id)arg4
			   artistUrn:(id)arg5
			  stationUrn:(id)arg6
			  artistName:(id)arg7
				   title:(id)arg8
		  playQueueTitle:(id)arg9
	playableDurationInMs:(unsigned long long)arg10
		fullDurationInMs:(unsigned long long)arg11
			 monetizable:(bool)arg12
			   shareable:(bool)arg13
				 blocked:(bool)arg14
				 snipped:(bool)arg15
				syncable:(bool)arg16
			  subMidTier:(bool)arg17
			 subHighTier:(bool)arg18
	   monetizationModel:(id)arg19
				  policy:(id)arg20
			analyticsBag:(id)arg21
			  artworkUrn:(id)arg22
				itemType:(long long)arg23
		imageUrlTemplate:(id)arg24
			 secretToken:(id)arg25
	  playlistStationUrn:(id)arg26
			permalinkURL:(id)arg27
				   genre:(id)arg28 {
	arg12 = NO;
	return %orig;
}

- (id)initWithUrn:(id)arg1
			transcodings:(id)arg2
			   streamURL:(id)arg3
			 waveformURL:(id)arg4
			   artistUrn:(id)arg5
			  stationUrn:(id)arg6
			  artistName:(id)arg7
				   title:(id)arg8
		  playQueueTitle:(id)arg9
	playableDurationInMs:(unsigned long long)arg10
		fullDurationInMs:(unsigned long long)arg11
			 monetizable:(bool)arg12
			   shareable:(bool)arg13
			   isPrivate:(bool)arg14
				 blocked:(bool)arg15
				 snipped:(bool)arg16
				syncable:(bool)arg17
			  subMidTier:(bool)arg18
			 subHighTier:(bool)arg19
	   monetizationModel:(id)arg20
				  policy:(id)arg21
			analyticsBag:(id)arg22
			  artworkUrn:(id)arg23
				itemType:(long long)arg24
		imageUrlTemplate:(id)arg25
			 secretToken:(id)arg26
	  playlistStationUrn:(id)arg27
			permalinkURL:(id)arg28
				   genre:(id)arg29 {
	arg12 = NO;
	return %orig;
}
%end

%hook GoUpsellButtonViewWrapper
- (instancetype)init {
	self = %orig;

	if (self) {
		((UIView *)self).hidden = YES;
	}

	return self;
}
%end

%hook DisplayAdBannerFeatureProvider
- (bool)canShowDisplayAdBanner {
	return NO;
}

- (bool)canShowTrackPageAdBanner {
	return NO;
}

- (void)setCanShowDisplayAdBanner:(bool)arg1 {
	arg1 = NO;
	return %orig;
}
%end

%hook DisplayAdConfigStore
- (NSArray *)sponsoredPlaylists {
	return @[];
}
%end

%hook NewPromotedExperimentProvider
- (bool)isEnabled {
	return NO;
}
%end

%hook AudioAdPlayerEventController
- (id)init {
	return NULL;
}
%end

%hook AdPlayQueueManager
- (bool)isItemMonetizable:(id)arg1 {
	return NO;
}

- (bool)isPlaylistSponsoredFor:(id)arg1 {
	return NO;
}

- (bool)isQueueStartAdEligibleForItem:(id)arg1
						  interaction:(id)arg2
					   taggingContext:(id)arg3 {
	return NO;
}

- (bool)isTrackEligibleToServeAd:(id)arg1 for:(id)arg2 {
	return NO;
}

- (bool)shouldFetchAdsBasedOnDuration:(double)arg1
					 progressDuration:(double)arg2 {
	return NO;
}

- (bool)shouldFetchQueueStartVideoAd {
	return NO;
}

- (bool)shouldShowQueueStartVideoAdForItem:(id)arg1
							   interaction:(id)arg2
							taggingContext:(id)arg3 {
	return NO;
}
%end

%hook PromotedTrackChecker
- (bool)isPromotedTrackFor:(id)arg1 with:(id)arg2 {
	return NO;
}
%end

%hook AudioAdPlayerViewController
- (bool)shouldAddCompanionAd {
	return NO;
}
%end

%ctor {
	%init(
		AdPlayQueueManager = objc_getClass("AdPlayQueueManager"),
		UpsellManager = objc_getClass("SoundCloud.UpsellManager"),
		UserFeaturesService = objc_getClass("SoundCloud.UserFeaturesService"),
		AdsRequestPermitter = objc_getClass("SoundCloud.AdsRequestPermitter"),
		PlayQueueItemTrackEntity =
			objc_getClass("SoundCloud.PlayQueueItemTrackEntity"),
		GoUpsellButtonViewWrapper =
			objc_getClass("Payments.GoUpsellButtonViewWrapper"),
		DisplayAdBannerFeatureProvider =
			objc_getClass("Ads.DisplayAdBannerFeatureProvider"),
		DisplayAdConfigStore = objc_getClass("Ads.DisplayAdConfigStore"),
		NewPromotedExperimentProvider =
			objc_getClass("Ads.NewPromotedExperimentProvider"),
		AudioAdPlayerEventController =
			objc_getClass("SoundCloud.AudioAdPlayerEventController"),
		PromotedTrackChecker =
			objc_getClass("SoundCloud.PromotedTrackChecker"),
		AudioAdPlayerViewController =
			objc_getClass("AudioAdPlayerViewController"));
}
