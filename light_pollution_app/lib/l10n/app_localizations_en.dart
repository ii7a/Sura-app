// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Light Pollution Detector';

  @override
  String get sura => 'Sura';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUpLink => 'Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get loginLink => 'Login';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinCommunity => 'Join the stargazing community';

  @override
  String get fullName => 'Full Name';

  @override
  String get username => 'Username';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get enterAPassword => 'Enter a password';

  @override
  String get enterName => 'Enter your name';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String get usernameTooShort => 'Username must be at least 3 characters';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get errorNoAccount => 'No account found with this email.';

  @override
  String get errorWrongPassword => 'Incorrect email or password.';

  @override
  String get errorInvalidEmail => 'Please enter a valid email.';

  @override
  String get errorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get errorLoginFailed => 'Login failed. Please try again.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordDesc =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get checkYourEmail => 'Check Your Email';

  @override
  String get resetEmailSentTo => 'We\'ve sent a password reset link to';

  @override
  String get resetEmailInstructions =>
      'Open the email and tap the link to set a new password. Then come back and log in.';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get didntGetEmail => 'Didn\'t get the email? ';

  @override
  String get resend => 'Resend';

  @override
  String get resetPasswordFailed =>
      'Failed to send reset email. Check your email address.';

  @override
  String get errorEmailInUse => 'This email is already registered.';

  @override
  String get errorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get errorSignUpFailed => 'Sign up failed. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navCamera => 'Camera';

  @override
  String get navMap => 'Map';

  @override
  String get navReserve => 'Reserve';

  @override
  String get navChat => 'Chat';

  @override
  String get profile => 'Profile';

  @override
  String get premium => 'Verified';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get noBookmarksYet => 'No bookmarks yet';

  @override
  String get noBookmarksDesc => 'Posts you bookmark will appear here';

  @override
  String get repost => 'Repost';

  @override
  String get undoRepost => 'Undo Repost';

  @override
  String get quotePost => 'Quote';

  @override
  String get lists => 'Lists';

  @override
  String get communities => 'Communities';

  @override
  String get myReservations => 'My Trips';

  @override
  String get settingsPrivacy => 'Settings and privacy';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get failedToLoadPosts => 'Failed to load posts.';

  @override
  String get noPostsYet => 'No posts yet. Be the first to share!';

  @override
  String get cancel => 'Cancel';

  @override
  String get post => 'Post';

  @override
  String get whatsHappening => 'What\'s happening?';

  @override
  String get everyoneCanReply => 'Everyone can reply';

  @override
  String get deletePost => 'Delete post';

  @override
  String failedToPost(String error) {
    return 'Failed to post: $error';
  }

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get addComment => 'Add a comment...';

  @override
  String get posts => 'Posts';

  @override
  String get repliesTab => 'Replies';

  @override
  String get photos => 'Photos';

  @override
  String get likesTab => 'Likes';

  @override
  String get noPostsYetSimple => 'No posts yet';

  @override
  String get noRepliesYet => 'No replies yet';

  @override
  String get noPhotosYet => 'No photos yet';

  @override
  String get noLikesYet => 'No likes yet';

  @override
  String get loadingText => 'Loading...';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get save => 'Save';

  @override
  String get nameLabel => 'Name';

  @override
  String get bioLabel => 'Bio';

  @override
  String get locationLabel => 'Location';

  @override
  String get websiteLabel => 'Website';

  @override
  String get addWebsite => 'Add your website';

  @override
  String get birthDate => 'Birth date';

  @override
  String get addBirthDate => 'Add your birth date';

  @override
  String get switchToProfessional => 'Switch to Professional';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get pollutionDetection => 'Pollution Detection';

  @override
  String get takeOrUploadPhoto =>
      'Take or upload a photo of the night sky\nto detect light pollution level';

  @override
  String get photoButton => 'PHOTO';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get analysisFailed => 'Analysis Failed';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get reExamine => 'Re-examine';

  @override
  String get shareAsPost => 'Share as Post';

  @override
  String get modelClassification => 'Model Classification';

  @override
  String get highPollution => 'High Light Pollution';

  @override
  String get lowPollution => 'Low Light Pollution';

  @override
  String get moderatePollution => 'Moderate Light Pollution';

  @override
  String get confidence => 'Confidence';

  @override
  String get skyQualityLabel => 'Sky Quality:';

  @override
  String get details => 'Details';

  @override
  String bortleValue(int value) {
    return 'Bortle $value';
  }

  @override
  String get aiModelScore => 'AI Model Score';

  @override
  String get pixelAnalysisScore => 'Pixel Analysis Score';

  @override
  String get meanBrightness => 'Mean Brightness';

  @override
  String get brightPixels => 'Bright Pixels';

  @override
  String get darkPixels => 'Dark Pixels';

  @override
  String get blueRatio => 'Blue Ratio';

  @override
  String get orangeRatio => 'Orange Ratio';

  @override
  String get brightnessDistribution => 'Brightness Distribution';

  @override
  String get dark => 'Dark';

  @override
  String get bright => 'Bright';

  @override
  String get explore => 'Explore';

  @override
  String get toggleLegend => 'Toggle legend';

  @override
  String get lightPollutionOverlay => 'Light Pollution Overlay';

  @override
  String get opacity => 'Opacity';

  @override
  String get yearLabel => 'Year: ';

  @override
  String get bortleScale => 'Bortle Scale';

  @override
  String get searchLocation => 'Search location...';

  @override
  String get tapLocation => 'Tap a location on the map';

  @override
  String get orSearchCity => 'or search for a city above';

  @override
  String get someDataFailed =>
      'Some data couldn\'t be loaded. Showing available info.';

  @override
  String get stargazingScore => 'Stargazing Score';

  @override
  String get outOf100 => 'out of 100';

  @override
  String get excellent => 'Excellent';

  @override
  String get good => 'Good';

  @override
  String get fair => 'Fair';

  @override
  String get poor => 'Poor';

  @override
  String get veryPoor => 'Very Poor';

  @override
  String get clouds => 'Clouds';

  @override
  String get moon => 'Moon';

  @override
  String get bortle => 'Bortle';

  @override
  String get skyPhotoAnalyzer => 'Sky Photo Analyzer';

  @override
  String get uploadSkyPhoto => 'Upload a sky photo';

  @override
  String get tapToSelect => 'Tap to select from gallery';

  @override
  String get skyQuality => 'Sky Quality';

  @override
  String get avgBrightness => 'Avg Brightness';

  @override
  String get warmGlow => 'Warm Glow';

  @override
  String get skyColor => 'Sky Color: ';

  @override
  String get analyzeAnotherPhoto => 'Analyze another photo';

  @override
  String get lightPollutionBortle => 'Light Pollution (Bortle Scale)';

  @override
  String classLabel(int value, String name) {
    return 'Class $value — $name';
  }

  @override
  String get currentWeather => 'Current Weather';

  @override
  String get cloudCover => 'Cloud Cover';

  @override
  String get humidity => 'Humidity';

  @override
  String get wind => 'Wind';

  @override
  String get cloudCover24h => 'Cloud Cover (24h)';

  @override
  String get sunTwilight => 'Sun & Twilight';

  @override
  String dayDuration(String duration) {
    return 'Day: $duration';
  }

  @override
  String nightDuration(String duration) {
    return 'Night: $duration';
  }

  @override
  String get sunrise => 'Sunrise';

  @override
  String get solarNoon => 'Solar Noon';

  @override
  String get sunset => 'Sunset';

  @override
  String get civilTwilightEnd => 'Civil Twilight End';

  @override
  String get nauticalTwilightEnd => 'Nautical Twilight End';

  @override
  String get astroTwilightEnd => 'Astro. Twilight End';

  @override
  String get moonPhase => 'Moon Phase';

  @override
  String illuminated(int percent) {
    return '$percent% illuminated';
  }

  @override
  String get impact => 'Impact';

  @override
  String get ageLabel => 'Age';

  @override
  String daysValue(String value) {
    return '$value days';
  }

  @override
  String get visiblePlanets => 'Visible Planets';

  @override
  String get visible => 'Visible';

  @override
  String get hidden => 'Hidden';

  @override
  String get mapLegendRadiance => 'Map Legend — Radiance';

  @override
  String get low => 'Low';

  @override
  String get high => 'High';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String underDevelopment(String title) {
    return '$title is under development';
  }

  @override
  String get bortleClass1Name => 'Excellent Dark Sky';

  @override
  String get bortleClass1Desc =>
      'The Milky Way casts shadows. Zodiacal light, gegenschein visible.';

  @override
  String get bortleClass2Name => 'Typical Dark Sky';

  @override
  String get bortleClass2Desc =>
      'Milky Way highly structured. Zodiacal light bright.';

  @override
  String get bortleClass3Name => 'Rural Sky';

  @override
  String get bortleClass3Desc =>
      'Milky Way still appears complex. Some light pollution on horizon.';

  @override
  String get bortleClass4Name => 'Rural/Suburban Transition';

  @override
  String get bortleClass4Desc =>
      'Milky Way visible but lacks detail. Light domes visible.';

  @override
  String get bortleClass5Name => 'Suburban Sky';

  @override
  String get bortleClass5Desc =>
      'Milky Way weak or invisible near horizon. Light domes prominent.';

  @override
  String get bortleClass6Name => 'Bright Suburban Sky';

  @override
  String get bortleClass6Desc =>
      'Milky Way only visible near zenith. Sky glow across entire horizon.';

  @override
  String get bortleClass7Name => 'Suburban/Urban Transition';

  @override
  String get bortleClass7Desc =>
      'Milky Way invisible. Sky has vague grayish-white hue.';

  @override
  String get bortleClass8Name => 'City Sky';

  @override
  String get bortleClass8Desc =>
      'Sky glows white or orange. Only bright constellations visible.';

  @override
  String get bortleClass9Name => 'Inner City Sky';

  @override
  String get bortleClass9Desc =>
      'Only Moon, planets, and a few bright stars visible.';

  @override
  String get pristineDarkSky => 'Pristine Dark Sky';

  @override
  String get darkSky => 'Dark Sky';

  @override
  String get ruralSky => 'Rural Sky';

  @override
  String get suburbanSky => 'Suburban Sky';

  @override
  String get brightSuburban => 'Bright Suburban';

  @override
  String get urbanSky => 'Urban Sky';

  @override
  String get innerCitySky => 'Inner City Sky';

  @override
  String get cloudyOvercast => 'Cloudy / Overcast';

  @override
  String get impactMinimal => 'Minimal';

  @override
  String get impactLow => 'Low';

  @override
  String get impactModerate => 'Moderate';

  @override
  String get impactHigh => 'High';

  @override
  String get impactSevere => 'Severe';

  @override
  String get impactDescExcellent => 'Excellent for stargazing';

  @override
  String get impactDescGood => 'Good conditions';

  @override
  String get impactDescSome => 'Some sky brightness';

  @override
  String get impactDescFaint => 'Faint objects washed out';

  @override
  String get impactDescBright => 'Bright moonlight limits visibility';

  @override
  String get veryBright => 'Very bright';

  @override
  String get brightLabel => 'Bright';

  @override
  String get moderate => 'Moderate';

  @override
  String get dim => 'Dim';

  @override
  String get faint => 'Faint';

  @override
  String get reserveTitle => 'Reserve a Trip';

  @override
  String get filterAll => 'All';

  @override
  String get filterUpcoming => 'Upcoming';

  @override
  String get filterPopular => 'Popular';

  @override
  String get guidedBy => 'Guided by';

  @override
  String get rating => 'Rating';

  @override
  String get bortleClassLabel => 'Bortle Class';

  @override
  String get groupSize => 'Group Size';

  @override
  String get spotsLeftLabel => 'Spots Left';

  @override
  String durationHours(int count) {
    return '$count hours';
  }

  @override
  String get bookNow => 'Book Now';

  @override
  String get aboutTrip => 'About this trip';

  @override
  String get whatsIncluded => 'What\'s included';

  @override
  String get perPerson => 'per person';

  @override
  String get noTripsAvailable => 'No trips available';

  @override
  String get tripBooked => 'Booked';

  @override
  String get tripBookedMsg => 'Trip booked successfully!';

  @override
  String get youAreTheHost => 'You are the host';

  @override
  String get createTrip => 'Create Trip';

  @override
  String get tripTitle => 'Trip Title';

  @override
  String get tripTitleHint => 'e.g. Milky Way Photography Night';

  @override
  String get tripLocationHint => 'e.g. AlUla, Saudi Arabia';

  @override
  String get tripDate => 'Date';

  @override
  String get selectDate => 'Select a date';

  @override
  String get duration => 'Duration';

  @override
  String get hours => 'hrs';

  @override
  String get price => 'Price';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get addItemHint => 'Add an item...';

  @override
  String get tripCreated => 'Trip posted successfully!';

  @override
  String get darkSkySite => 'Dark Sky Site';

  @override
  String get reserveTrip => 'Reserve';

  @override
  String get certifiedDarkSky => 'Certified Dark Sky';

  @override
  String bortleClassInfo(int value, String certification) {
    return 'Bortle $value — $certification';
  }

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get premiumTitle => 'Sura Verified';

  @override
  String get premiumSubtitle =>
      'For trusted contributors to the Sura community';

  @override
  String get premiumFeatureTrips => 'Create & Post Trips';

  @override
  String get premiumFeatureTripsDesc =>
      'Create stargazing trips and share them with the community';

  @override
  String get premiumFeatureBadge => 'Verified Badge';

  @override
  String get premiumFeatureBadgeDesc =>
      'Stand out with the blue verified badge on your profile';

  @override
  String get premiumFeaturePriority => 'Priority Booking';

  @override
  String get premiumFeaturePriorityDesc =>
      'Get early access to popular stargazing trips';

  @override
  String get premiumFeatureAnalysis => 'Advanced Analysis';

  @override
  String get premiumFeatureAnalysisDesc =>
      'Unlock detailed AI sky quality reports';

  @override
  String get premiumMemberSince => 'Verified Member';

  @override
  String get premiumYourBenefits => 'Your Benefits';

  @override
  String get premiumContactSupport =>
      'Verification is granted by the Sura team to trusted contributors. Contact support to learn more about how your account may be reviewed.';

  @override
  String get myTripsTitle => 'My Trips';

  @override
  String get noBookedTrips => 'No booked trips yet';

  @override
  String get noBookedTripsDesc => 'Trips you book will appear here';

  @override
  String get pickFromMap => 'Pick from map';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get changeCoverImage => 'Change cover image';

  @override
  String get uploadingImage => 'Uploading image...';

  @override
  String get verdictExcellent =>
      'Excellent for stargazing! Milky Way should be visible.';

  @override
  String get verdictGood =>
      'Good for stargazing. Many stars and constellations visible.';

  @override
  String get verdictDecent =>
      'Decent for stargazing. Bright stars and planets visible.';

  @override
  String get verdictPoor =>
      'Poor for stargazing. Only the brightest stars visible.';

  @override
  String get verdictVeryPoor =>
      'Very poor for stargazing. Only a few stars visible.';

  @override
  String get verdictNotSuitable =>
      'Not suitable for stargazing. Too much light pollution.';

  @override
  String get verdictCloudy =>
      'Not suitable for stargazing. Sky is cloudy or overcast.';

  @override
  String get privateAccount => 'Private Account';

  @override
  String get privateAccountDesc => 'Only approved followers can see your posts';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsDesc => 'Likes, comments, follows, messages';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get directMessages => 'Direct Messages';

  @override
  String get whoCanSeeYourLikes => 'Who Can See Your Likes';

  @override
  String get locationInformation => 'Location Information';

  @override
  String get locationInfoDesc => 'Include location in posts';

  @override
  String get everyone => 'Everyone';

  @override
  String get followersOnly => 'Followers only';

  @override
  String get noOne => 'No one';

  @override
  String get onlyMe => 'Only me';

  @override
  String get dmSettingsTitle => 'Direct Messages';

  @override
  String get dmSettingsDesc => 'Choose who can send you direct messages';

  @override
  String get likesVisibilityTitle => 'Who Can See Your Likes';

  @override
  String get likesVisibilityDesc => 'Choose who can see the posts you liked';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get account => 'Account';

  @override
  String get changePassword => 'Change Password';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get dataStorage => 'Data & Storage';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheDesc => 'Free up storage space';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get update => 'Update';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String failedUpdate(String error) {
    return 'Failed: $error';
  }

  @override
  String get notSet => 'Not set';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get termsLastUpdated => 'Last updated: April 2026';

  @override
  String get termsSection1Title => '1. Acceptance of Terms';

  @override
  String get termsSection1Body =>
      'By accessing or using SuraApp (\"the App\"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.';

  @override
  String get termsSection2Title => '2. Description of Service';

  @override
  String get termsSection2Body =>
      'SuraApp is a community platform for stargazers and astronomy enthusiasts. The App provides light pollution detection, sky quality analysis, community posts, trip reservations, and direct messaging features.';

  @override
  String get termsSection3Title => '3. User Accounts';

  @override
  String get termsSection3Body =>
      'You must create an account to use the App. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must provide accurate and complete information when creating your account.';

  @override
  String get termsSection4Title => '4. User Content';

  @override
  String get termsSection4Body =>
      'You retain ownership of content you post on the App. By posting content, you grant SuraApp a non-exclusive, worldwide license to use, display, and distribute your content within the App. You agree not to post content that is illegal, harmful, threatening, abusive, or violates the rights of others.';

  @override
  String get termsSection5Title => '5. Privacy';

  @override
  String get termsSection5Body =>
      'Your use of the App is also governed by our Privacy Policy. By using the App, you consent to the collection and use of your information as described in the Privacy Policy.';

  @override
  String get termsSection6Title => '6. Prohibited Conduct';

  @override
  String get termsSection6Body =>
      'You agree not to: impersonate others, harass or bully other users, post spam or misleading content, attempt to gain unauthorized access to other accounts, use the App for any illegal purpose, or interfere with the proper functioning of the App.';

  @override
  String get termsSection7Title => '7. Termination';

  @override
  String get termsSection7Body =>
      'We reserve the right to suspend or terminate your account at any time for violation of these terms or for any other reason at our discretion. You may delete your account at any time through the App settings.';

  @override
  String get termsSection8Title => '8. Changes to Terms';

  @override
  String get termsSection8Body =>
      'We may update these Terms of Service from time to time. We will notify you of any material changes through the App. Your continued use of the App after such changes constitutes acceptance of the new terms.';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyLastUpdated => 'Last updated: April 2026';

  @override
  String get privacySection1Title => '1. Information We Collect';

  @override
  String get privacySection1Body =>
      'We collect information you provide directly: name, email address, username, profile photo, and content you post. We also collect usage data including device information, location data (with your permission), and app interaction data.';

  @override
  String get privacySection2Title => '2. How We Use Your Information';

  @override
  String get privacySection2Body =>
      'We use your information to: provide and improve the App, personalize your experience, send notifications you have opted into, analyze usage patterns, ensure safety and security, and communicate with you about the App.';

  @override
  String get privacySection3Title => '3. Information Sharing';

  @override
  String get privacySection3Body =>
      'We do not sell your personal information. We may share your information with: other users (as part of the social features), service providers who help us operate the App, and law enforcement when required by law.';

  @override
  String get privacySection4Title => '4. Data Security';

  @override
  String get privacySection4Body =>
      'We implement industry-standard security measures to protect your data, including encryption in transit and at rest. However, no method of transmission over the internet is 100% secure.';

  @override
  String get privacySection5Title => '5. Your Rights';

  @override
  String get privacySection5Body =>
      'You have the right to: access your personal data, correct inaccurate data, delete your account and associated data, opt out of notifications, and control your privacy settings including account visibility and who can message you.';

  @override
  String get privacySection6Title => '6. Location Data';

  @override
  String get privacySection6Body =>
      'We collect location data only when you enable the Location Information setting. This data is used to tag posts with location and provide stargazing site recommendations. You can disable location sharing at any time in Settings.';

  @override
  String get privacySection7Title => '7. Contact Us';

  @override
  String get privacySection7Body =>
      'If you have questions about this Privacy Policy or your data, please contact us at privacy@suraapp.com.';

  @override
  String get darkSkyPark => 'Dark Sky Park';

  @override
  String get darkSkyReserve => 'Dark Sky Reserve';

  @override
  String get darkSkySanctuary => 'Dark Sky Sanctuary';

  @override
  String get darkSkyCommunity => 'Dark Sky Community';

  @override
  String get darkSkyUrban => 'Urban Night Sky Place';

  @override
  String get designatedYear => 'Year';

  @override
  String get coordinates => 'Coords';

  @override
  String get bestFor => 'Best For';

  @override
  String get exploreLocation => 'Explore Location';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get notificationLiked => 'liked your post';

  @override
  String get notificationReposted => 'reposted your post';

  @override
  String get notificationQuoted => 'quoted your post';

  @override
  String get notificationCommented => 'commented on your post';

  @override
  String get notificationFollowed => 'started following you';

  @override
  String get adminSendNotification => 'Send notification';

  @override
  String get adminOnly => 'Admins only';

  @override
  String get adminEventType => 'Event type';

  @override
  String get adminTitle => 'Title';

  @override
  String get adminDescription => 'Description';

  @override
  String get adminEventDate => 'Event date & time';

  @override
  String get adminCityOptional => 'City (optional)';

  @override
  String get adminCityHelper => 'Leave empty to send to everyone';

  @override
  String get adminSendBroadcast => 'Send to everyone';

  @override
  String adminNotifSentCount(int count) {
    return 'Sent to $count users';
  }

  @override
  String get requiredField => 'This field is required';

  @override
  String get cosmicEclipse => 'Solar eclipse';

  @override
  String get cosmicLunarEclipse => 'Lunar eclipse';

  @override
  String get cosmicMeteorShower => 'Meteor shower';

  @override
  String get cosmicPlanetConjunction => 'Planet conjunction';

  @override
  String get cosmicSupermoon => 'Supermoon';

  @override
  String get cosmicComet => 'Comet';

  @override
  String get cosmicIssPass => 'ISS pass';

  @override
  String get cosmicOther => 'Other sky event';

  @override
  String get adminUpcomingEvents => 'Upcoming cosmic events';

  @override
  String get adminNoUpcomingEvents => 'No upcoming events right now';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get notificationSettingsDesc => 'Choose types and city';

  @override
  String get notifSettingsEnableAll => 'Enable notifications';

  @override
  String get notifSettingsEnableAllHelp =>
      'Turning this off silences everything';

  @override
  String get notifSettingsCitySection => 'City';

  @override
  String get notifSettingsCity => 'My city';

  @override
  String get notifSettingsInteractionSection => 'Interaction notifications';

  @override
  String get notifSettingsCosmicSection => 'Cosmic events';

  @override
  String get notifTypeLike => 'Likes';

  @override
  String get notifTypeRepost => 'Reposts';

  @override
  String get notifTypeQuote => 'Quotes';

  @override
  String get notifTypeComment => 'Comments';

  @override
  String get notifTypeFollow => 'Follows';

  @override
  String get cityAll => 'All cities';

  @override
  String get cityRiyadh => 'Riyadh';

  @override
  String get cityJeddah => 'Jeddah';

  @override
  String get cityMakkah => 'Makkah';

  @override
  String get cityMadinah => 'Madinah';

  @override
  String get cityDammam => 'Dammam';

  @override
  String get cityAbha => 'Abha';

  @override
  String get cityTabuk => 'Tabuk';

  @override
  String get cityTaif => 'Taif';

  @override
  String get cityKhobar => 'Khobar';

  @override
  String get cityNajran => 'Najran';

  @override
  String get cityHail => 'Hail';

  @override
  String get cityJazan => 'Jazan';

  @override
  String get refreshingFeed => 'Refreshing feed…';
}
