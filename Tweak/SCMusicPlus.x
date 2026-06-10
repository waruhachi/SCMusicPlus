#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL SCMCTextContainsSponsoredMarker(NSString *text) {
	if (text.length == 0) {
		return NO;
	}

	NSString *lowercased = text.lowercaseString;
	return [lowercased containsString:@"promoted"] ||
		[lowercased containsString:@"sponsored"];
}

static BOOL SCMCViewContainsSponsoredMarker(UIView *view) {
	if (!view) {
		return NO;
	}

	if (SCMCTextContainsSponsoredMarker(NSStringFromClass(view.class))) {
		return YES;
	}

	if (SCMCTextContainsSponsoredMarker(view.accessibilityLabel) ||
		SCMCTextContainsSponsoredMarker(view.accessibilityValue) ||
		SCMCTextContainsSponsoredMarker(view.accessibilityHint)) {
		return YES;
	}

	if ([view isKindOfClass:[UILabel class]]) {
		UILabel *label = (UILabel *)view;
		if (SCMCTextContainsSponsoredMarker(label.text) ||
			SCMCTextContainsSponsoredMarker(label.attributedText.string)) {
			return YES;
		}
	}

	for (UIView *subview in view.subviews) {
		if (SCMCViewContainsSponsoredMarker(subview)) {
			return YES;
		}
	}

	return NO;
}

static void SCMCSetViewCollapsed(UIView *view) {
	view.hidden = YES;
	view.alpha = 0.0;
	view.clipsToBounds = YES;
	view.frame = CGRectZero;
}

static BOOL SCMCShouldCollapseView(UIView *view) {
	if (!view) {
		return NO;
	}

	NSString *className = NSStringFromClass(view.class);
	if ([className isEqualToString:@"_TtC7SwiftUIP33_5DAB09131F46EF4FA69B417F7F09D60321PortalGroupMarkerView"]) {
		return YES;
	}

	if ([className isEqualToString:@"SwiftUI.ListCollectionViewCell"]) {
		return SCMCViewContainsSponsoredMarker(view);
	}

	return NO;
}

static CGSize (*SCMCOrigPortalMarkerIntrinsicContentSize)(id, SEL);
static CGSize (*SCMCOrigPortalMarkerSizeThatFits)(id, SEL, CGSize);
static CGSize (*SCMCOrigPortalMarkerSystemLayoutSizeFittingSize)(id, SEL, CGSize);
static CGSize (*SCMCOrigPortalMarkerSystemLayoutSizeFittingSizeWithPriorities)(
	id,
	SEL,
	CGSize,
	UILayoutPriority,
	UILayoutPriority);
static void (*SCMCOrigPortalMarkerLayoutSubviews)(id, SEL);
static void (*SCMCOrigListCellLayoutSubviews)(id, SEL);
static id (*SCMCOrigListCellPreferredLayoutAttributesFittingAttributes)(
	id,
	SEL,
	id);

static CGSize SCMCPortalMarkerIntrinsicContentSize(id self, SEL _cmd) {
	return CGSizeZero;
}

static CGSize SCMCPortalMarkerSizeThatFits(id self, SEL _cmd, CGSize size) {
	return CGSizeZero;
}

static CGSize SCMCPortalMarkerSystemLayoutSizeFittingSize(id self, SEL _cmd, CGSize size) {
	return CGSizeZero;
}

static CGSize SCMCPortalMarkerSystemLayoutSizeFittingSizeWithPriorities(
	id self,
	SEL _cmd,
	CGSize size,
	UILayoutPriority horizontalFittingPriority,
	UILayoutPriority verticalFittingPriority) {
	return CGSizeZero;
}

static void SCMCPortalMarkerLayoutSubviews(id self, SEL _cmd) {
	SCMCOrigPortalMarkerLayoutSubviews(self, _cmd);
	SCMCSetViewCollapsed((UIView *)self);
}

static void SCMCListCellLayoutSubviews(id self, SEL _cmd) {
	SCMCOrigListCellLayoutSubviews(self, _cmd);

	UIView *view = (UIView *)self;
	if (SCMCShouldCollapseView(view)) {
		SCMCSetViewCollapsed(view);
	}
}

static id SCMCListCellPreferredLayoutAttributesFittingAttributes(id self, SEL _cmd, id layoutAttributes) {
	id attributes = SCMCOrigListCellPreferredLayoutAttributesFittingAttributes(
		self, _cmd, layoutAttributes);

	UIView *view = (UIView *)self;
	if (!SCMCShouldCollapseView(view)) {
		return attributes;
	}

	UICollectionViewLayoutAttributes *collapsedAttributes = [attributes copy];
	collapsedAttributes.hidden = YES;
	collapsedAttributes.alpha = 0.0;
	collapsedAttributes.frame = CGRectZero;
	return collapsedAttributes;
}

static void SCMCInstallSponsoredViewBlockers(void) {
	Class portalMarkerView = objc_getClass(
		"_TtC7SwiftUIP33_5DAB09131F46EF4FA69B417F7F09D60321PortalGroupMarkerView");
	if (portalMarkerView) {
		Method intrinsicContentSizeMethod = class_getInstanceMethod(
			portalMarkerView, @selector(intrinsicContentSize));
		if (intrinsicContentSizeMethod) {
			SCMCOrigPortalMarkerIntrinsicContentSize =
				(CGSize (*)(id, SEL))method_getImplementation(intrinsicContentSizeMethod);
			method_setImplementation(intrinsicContentSizeMethod,
				(IMP)SCMCPortalMarkerIntrinsicContentSize);
		}

		Method sizeThatFitsMethod = class_getInstanceMethod(
			portalMarkerView, @selector(sizeThatFits:));
		if (sizeThatFitsMethod) {
			SCMCOrigPortalMarkerSizeThatFits =
				(CGSize (*)(id, SEL, CGSize))method_getImplementation(sizeThatFitsMethod);
			method_setImplementation(sizeThatFitsMethod, (IMP)SCMCPortalMarkerSizeThatFits);
		}

		Method fittingSizeMethod = class_getInstanceMethod(
			portalMarkerView, @selector(systemLayoutSizeFittingSize:));
		if (fittingSizeMethod) {
			SCMCOrigPortalMarkerSystemLayoutSizeFittingSize =
				(CGSize (*)(id, SEL, CGSize))method_getImplementation(fittingSizeMethod);
			method_setImplementation(fittingSizeMethod,
				(IMP)SCMCPortalMarkerSystemLayoutSizeFittingSize);
		}

		SEL fittingWithPrioritiesSelector = @selector(
			  systemLayoutSizeFittingSize:withHorizontalFittingPriority:
			verticalFittingPriority:);
		Method fittingWithPrioritiesMethod = class_getInstanceMethod(
			portalMarkerView, fittingWithPrioritiesSelector);
		if (fittingWithPrioritiesMethod) {
			SCMCOrigPortalMarkerSystemLayoutSizeFittingSizeWithPriorities =
				(CGSize (*)(id, SEL, CGSize, UILayoutPriority, UILayoutPriority))
					method_getImplementation(fittingWithPrioritiesMethod);
			method_setImplementation(fittingWithPrioritiesMethod,
				(IMP)SCMCPortalMarkerSystemLayoutSizeFittingSizeWithPriorities);
		}

		Method layoutSubviewsMethod = class_getInstanceMethod(
			portalMarkerView, @selector(layoutSubviews));
		if (layoutSubviewsMethod) {
			SCMCOrigPortalMarkerLayoutSubviews =
				(void (*)(id, SEL))method_getImplementation(layoutSubviewsMethod);
			method_setImplementation(layoutSubviewsMethod,
				(IMP)SCMCPortalMarkerLayoutSubviews);
		}
	}

	Class listCollectionViewCell = objc_getClass("SwiftUI.ListCollectionViewCell");
	if (listCollectionViewCell) {
		Method layoutSubviewsMethod = class_getInstanceMethod(
			listCollectionViewCell, @selector(layoutSubviews));
		if (layoutSubviewsMethod) {
			SCMCOrigListCellLayoutSubviews =
				(void (*)(id, SEL))method_getImplementation(layoutSubviewsMethod);
			method_setImplementation(layoutSubviewsMethod, (IMP)SCMCListCellLayoutSubviews);
		}

		Method preferredLayoutAttributesMethod = class_getInstanceMethod(
			listCollectionViewCell,
			@selector(preferredLayoutAttributesFittingAttributes:));
		if (preferredLayoutAttributesMethod) {
			SCMCOrigListCellPreferredLayoutAttributesFittingAttributes =
				(id (*)(id, SEL, id))method_getImplementation(preferredLayoutAttributesMethod);
			method_setImplementation(preferredLayoutAttributesMethod,
				(IMP)SCMCListCellPreferredLayoutAttributesFittingAttributes);
		}
	}
}

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
	SCMCInstallSponsoredViewBlockers();

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
