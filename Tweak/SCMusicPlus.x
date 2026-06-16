#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static BOOL SCMCStringContainsAnyToken(NSString *string, NSArray<NSString *> *tokens) {
	if (![string isKindOfClass:[NSString class]] || string.length == 0) {
		return NO;
	}

	NSString *lowercased = string.lowercaseString;
	for (NSString *token in tokens) {
		if ([lowercased containsString:token]) {
			return YES;
		}
	}

	return NO;
}

static BOOL SCMCURLIsConfigURL(NSURL *url) {
	if (![url isKindOfClass:[NSURL class]]) {
		return NO;
	}

	NSString *host = url.host.lowercaseString ?: @"";
	NSString *path = url.path ?: @"";

	if ([host isEqualToString:@"api-mobile.soundcloud.com"] && [path isEqualToString:@"/configuration/ios"]) {
		return YES;
	}

	return NO;
}

static BOOL SCMCRequestIsConfigRequest(NSURLRequest *request) {
	if (![request isKindOfClass:[NSURLRequest class]]) {
		return NO;
	}

	return SCMCURLIsConfigURL(request.URL);
}

static BOOL SCMCJSONObjectLooksLikeConfiguration(id object) {
	if (![object isKindOfClass:[NSDictionary class]]) {
		return NO;
	}

	NSDictionary *dictionary = (NSDictionary *)object;
	if ((dictionary[@"plan"] || dictionary[@"creator_plan"]) && dictionary[@"features"]) {
		return YES;
	}

	if (dictionary[@"high_tier"] || dictionary[@"mid_tier"] || dictionary[@"plan_upsells"]) {
		return YES;
	}

	return NO;
}

static id SCMCMutableJSONObject(id object) {
	if ([object isKindOfClass:[NSDictionary class]]) {
		NSMutableDictionary *mutableDictionary =
			[NSMutableDictionary dictionaryWithCapacity:[(NSDictionary *)object count]];
		[(NSDictionary *)object enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
			mutableDictionary[key] = SCMCMutableJSONObject(value);
		}];
		return mutableDictionary;
	}

	if ([object isKindOfClass:[NSArray class]]) {
		NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:[(NSArray *)object count]];
		for (id value in (NSArray *)object) {
			[mutableArray addObject:SCMCMutableJSONObject(value)];
		}
		return mutableArray;
	}

	return object ?: [NSNull null];
}

static void SCMCSanitizeConfigurationDictionary(NSMutableDictionary *dictionary) {
	static NSArray<NSString *> *blockedContainerTokens;
	static NSArray<NSString *> *disabledBooleanTokens;
	static NSArray<NSString *> *enabledBooleanTokens;
	static NSDictionary<NSString *, NSDictionary *> *featureOverrides;
	static NSDictionary<NSString *, id> *planOverrides;
	static NSDictionary<NSString *, id> *creatorOverrides;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		blockedContainerTokens = @[
			@"ad_banner",
			@"ad_config",
			@"ad_placement",
			@"ad_target",
			@"ads_krux",
			@"audio_ad",
			@"companion_ad",
			@"display_ad",
			@"promoted",
			@"sponsored",
			@"upsell",
			@"upsells",
			@"ads_configuration",
			@"ads_config"
		];
		disabledBooleanTokens = @[
			@"can_show_ad",
			@"display_ad",
			@"enable_ad",
			@"is_promoted",
			@"is_sponsored",
			@"show_ad",
			@"should_show_ad",
		];
		enabledBooleanTokens = @[
			@"no_audio_ads"
		];
		featureOverrides = @{
			@"offline_sync": @{
				@"enabled": @YES,
				@"plans": @[]
			},
			@"no_audio_ads": @{
				@"enabled": @YES,
				@"plans": @[]
			},
			@"hq_audio": @{
				@"enabled": @YES,
				@"plans": @[]
			},
			@"system_playlist_in_library": @{
				@"enabled": @YES
			},
			@"ads_krux": @{
				@"enabled": @NO
			},
			@"new_home": @{
				@"enabled": @NO
			},
			@"spotlight": @{
				@"enabled": @YES
			}
		};
		planOverrides = @{
			@"plan_id": @"go-plus",
			@"plan_name": @"SoundCloud Go+",
			@"plan_upsells": @[],
			@"upsells": @[]
		};
		creatorOverrides = @{
			@"plan_id": @"pro-unlimited",
			@"plan_name": @"Artist Pro"
		};
	});

	for (id key in [dictionary.allKeys copy]) {
		id value = dictionary[key];
		NSString *keyString = [key isKindOfClass:[NSString class]] ? key : [key description];

		if ([value isKindOfClass:[NSMutableDictionary class]]) {
			SCMCSanitizeConfigurationDictionary(value);
		} else if ([value isKindOfClass:[NSMutableArray class]]) {
			for (id item in value) {
				if ([item isKindOfClass:[NSMutableDictionary class]]) {
					SCMCSanitizeConfigurationDictionary(item);
				}
			}
		}

		if (SCMCStringContainsAnyToken(keyString, blockedContainerTokens)) {
			if ([value isKindOfClass:[NSMutableArray class]]) {
				[dictionary setObject:@[] forKey:key];
			} else if ([value isKindOfClass:[NSMutableDictionary class]]) {
				[dictionary setObject:@{} forKey:key];
			} else if ([value isKindOfClass:[NSNumber class]]) {
				[dictionary setObject:@NO forKey:key];
			} else if ([value isKindOfClass:[NSString class]]) {
				[dictionary setObject:@"" forKey:key];
			}
			continue;
		}

		if ([value isKindOfClass:[NSNumber class]]) {
			if (SCMCStringContainsAnyToken(keyString, disabledBooleanTokens)) {
				[dictionary setObject:@NO forKey:key];
			} else if (SCMCStringContainsAnyToken(keyString, enabledBooleanTokens)) {
				[dictionary setObject:@YES forKey:key];
			}
		}

		if ([keyString isEqualToString:@"features"] && [value isKindOfClass:[NSArray class]]) {
			NSMutableArray *features = (NSMutableArray *)value;

			for (id item in features) {
				if (![item isKindOfClass:[NSMutableDictionary class]]) {
					continue;
				}

				NSString *featureName = item[@"name"];
				NSDictionary *featureOverride = featureOverrides[featureName];
				if (featureOverride) {
					[item addEntriesFromDictionary:featureOverride];
				}
			}

			continue;
		}

		if ([keyString isEqualToString:@"plan"] && [value isKindOfClass:[NSMutableDictionary class]]) {
			NSMutableDictionary *plan = (NSMutableDictionary *)value;
			[plan addEntriesFromDictionary:planOverrides];
			continue;
		}

		if ([keyString isEqualToString:@"creator_plan"] && [value isKindOfClass:[NSMutableDictionary class]]) {
			NSMutableDictionary *creatorPlan = (NSMutableDictionary *)value;
			[creatorPlan addEntriesFromDictionary:creatorOverrides];
			continue;
		}
	}
}

static NSData *SCMCSanitizedConfigurationData(NSData *data) {
	if (![data isKindOfClass:[NSData class]] || data.length == 0) {
		return data;
	}

	NSError *parseError = nil;
	id jsonObject = [NSJSONSerialization JSONObjectWithData:data
													options:0
													  error:&parseError];
	if (parseError || ![jsonObject isKindOfClass:[NSDictionary class]]) {
		return data;
	}

	NSMutableDictionary *mutableObject = SCMCMutableJSONObject(jsonObject);
	if (![mutableObject isKindOfClass:[NSMutableDictionary class]]) {
		return data;
	}

	SCMCSanitizeConfigurationDictionary(mutableObject);

	NSError *serializationError = nil;
	NSData *sanitizedData = [NSJSONSerialization dataWithJSONObject:mutableObject
															options:0
															  error:&serializationError];
	return serializationError || !sanitizedData ? data : sanitizedData;
}

%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
	if ([key isEqualToString:@"USER_FEATURE_hq_audio"]) {
		return 1;
	}

	if ([key isEqualToString:@"USER_FEATURE_no_audio_ads"]) {
		return 1;
	}

	if ([key isEqualToString:@"USER_FEATURE_new_home"]) {
		return 1;
	}

	if ([key isEqualToString:@"USER_FEATURE_offline_sync"]) {
		return 1;
	}

	if ([key isEqualToString:@"USER_FEATURE_spotlight"]) {
		return 1;
	}

	return %orig;
}

- (NSInteger)integerForKey:(NSString *)key {
	if ([key isEqualToString:@"PlanType"]) {
		return 2;
	}

	return %orig;
}

%end

%hook NSJSONSerialization
+ (id)JSONObjectWithData:(NSData *)data
				 options:(NSJSONReadingOptions)opt
				   error:(NSError **)error {
	id jsonObject = %orig;
	if (!SCMCJSONObjectLooksLikeConfiguration(jsonObject)) {
		return jsonObject;
	}

	NSMutableDictionary *mutableObject = SCMCMutableJSONObject(jsonObject);
	if (![mutableObject isKindOfClass:[NSMutableDictionary class]]) {
		return jsonObject;
	}

	SCMCSanitizeConfigurationDictionary(mutableObject);
	return mutableObject;
}
%end

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
							completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
	if (!SCMCRequestIsConfigRequest(request) || !completionHandler) {
		return %orig;
	}

	void (^wrappedCompletion)(NSData *, NSURLResponse *, NSError *) =
		^(NSData *data, NSURLResponse *response, NSError *error) {
			completionHandler(SCMCSanitizedConfigurationData(data), response, error);
		};

	return %orig(request, wrappedCompletion);
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
						completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
	if (!SCMCURLIsConfigURL(url) || !completionHandler) {
		return %orig;
	}

	void (^wrappedCompletion)(NSData *, NSURLResponse *, NSError *) =
		^(NSData *data, NSURLResponse *response, NSError *error) {
			completionHandler(SCMCSanitizedConfigurationData(data), response, error);
		};

	return %orig(url, wrappedCompletion);
}
%end

%hook NSData
+ (NSData *)dataWithContentsOfURL:(NSURL *)url {
	NSData *data = %orig;
	if (SCMCURLIsConfigURL(url)) {
		return SCMCSanitizedConfigurationData(data);
	}
	return data;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url {
	NSData *data = %orig;
	if (SCMCURLIsConfigURL(url)) {
		return SCMCSanitizedConfigurationData(data);
	}
	return data;
}
%end

%hook NSURLConnection
+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request
				 returningResponse:(NSURLResponse **)response
							 error:(NSError **)error {
	NSData *data = %orig;
	return SCMCRequestIsConfigRequest(request) ? SCMCSanitizedConfigurationData(data) : data;
}

+ (void)sendAsynchronousRequest:(NSURLRequest *)request
						  queue:(NSOperationQueue *)queue
			  completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError))handler {
	if (!SCMCRequestIsConfigRequest(request) || !handler) {
		%orig;
		return;
	}

	void (^wrappedHandler)(NSURLResponse *, NSData *, NSError *) =
		^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			handler(response, SCMCSanitizedConfigurationData(data), connectionError);
		};

	%orig(request, queue, wrappedHandler);
}
%end

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
