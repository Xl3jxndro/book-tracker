// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonBack => 'Back';

  @override
  String get commonAccept => 'OK';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Automatic';

  @override
  String get languageSystemSubtitle => 'Your phone\'s language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String detailsShareText(
    String title,
    String author,
    int readPages,
    int totalPages,
    String appName,
  ) {
    return '📖 *I\'m reading:* $title\n✍️ *Author:* $author\n📊 *Progress:* $readPages/$totalPages pages\n\n✨ Shared from $appName';
  }

  @override
  String get detailsTimeNow => 'Just now';

  @override
  String detailsTimeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get detailsTimeToday => 'Today';

  @override
  String get detailsTimeYesterday => 'Yesterday';

  @override
  String get detailsShare => 'Share';

  @override
  String get detailsMoreOptions => 'More options';

  @override
  String get detailsEditBook => 'Edit book';

  @override
  String get detailsNotesEmptyTitle => 'No notes yet';

  @override
  String get detailsNotesEmptyDescription =>
      'Save your quotes and thoughts here.';

  @override
  String get detailsNewNote => 'New note';

  @override
  String get detailsFavoritesEmptyHint =>
      'Tap the ☆ on a note to save it to your favorite quotes.';

  @override
  String get detailsShareAsImage => 'Share as image';

  @override
  String get detailsRemoveFavorite => 'Remove from favorites';

  @override
  String get detailsAddFavorite => 'Add to favorites';

  @override
  String get detailsCopy => 'Copy';

  @override
  String get detailsCopied => 'Copied';

  @override
  String detailsNotePage(int page) {
    return 'Page $page';
  }

  @override
  String get detailsReadingSession => 'Reading session';

  @override
  String get detailsNotesAndQuotes => 'Notes & quotes';

  @override
  String get detailsAdd => 'Add';

  @override
  String get detailsFilterRecent => 'Recent';

  @override
  String get detailsFilterPage => 'Page';

  @override
  String get detailsFilterLength => 'Length';

  @override
  String get detailsFilterFavorites => '★ Favorites';

  @override
  String get detailsYourProgress => 'Your progress';

  @override
  String detailsPagesOfTotal(int read, int total) {
    return '$read of $total pages';
  }

  @override
  String get detailsReread => 'Reread';

  @override
  String get detailsUpdate => 'Update';

  @override
  String get detailsStartAddDate => 'Start: add date';

  @override
  String detailsStartedOn(String date) {
    return 'Started $date';
  }

  @override
  String get detailsFinishAddDate => 'Finish: add date';

  @override
  String detailsFinishedOn(String date) {
    return 'Finished $date';
  }

  @override
  String detailsFinishedOnDays(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Finished $date · $_temp0';
  }

  @override
  String get detailsWhenStarted => 'When did you start it?';

  @override
  String get detailsWhenFinished => 'When did you finish it?';

  @override
  String detailsDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String detailsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String detailsPacePerMinute(String pace) {
    return '$pace pages/min';
  }

  @override
  String detailsPacePerHour(int pages) {
    return '$pages pages/h';
  }

  @override
  String get detailsPace => 'Pace';

  @override
  String get detailsTimeLeft => 'Time left';

  @override
  String get detailsTimeRead => 'Time read';

  @override
  String get detailsDailyGoal => 'Daily goal';

  @override
  String detailsDailyGoalProgress(int minutes, int goal) {
    return '$minutes of $goal min today';
  }

  @override
  String get detailsChangeDailyGoal => 'Change daily goal';

  @override
  String get detailsReadingCompleted => 'Book finished!';

  @override
  String detailsRatingStars(int stars) {
    return '$stars of 5';
  }

  @override
  String get detailsWriteReview => 'Write review';

  @override
  String get detailsEditReview => 'Edit review';

  @override
  String get detailsFavoriteRemoved => 'Removed from favorites';

  @override
  String get detailsFavoriteAdded => 'Added to favorites ★';

  @override
  String get detailsNoteDeleted => 'Note deleted';

  @override
  String get detailsUndoAction => 'UNDO';

  @override
  String get detailsEnterPageNumber => 'Enter a page number';

  @override
  String detailsPageCannotExceed(int total) {
    return 'Can\'t be more than $total';
  }

  @override
  String get detailsUpdateProgressTitle => 'Update Progress';

  @override
  String get detailsWhatPage => 'What page are you on?';

  @override
  String get detailsDeleteBookTitle => 'Delete book?';

  @override
  String get detailsDeleteBookMessage => 'All your notes will be lost.';

  @override
  String get detailsDailyGoalTitle => 'Daily Goal';

  @override
  String get detailsRereadTitle => 'Read it again?';

  @override
  String get detailsRereadConfirm => 'Let\'s go!';

  @override
  String get detailsTutorialProgressTitle => '📈​ Your Progress';

  @override
  String get detailsTutorialProgressDesc => 'See how many pages you\'ve read.';

  @override
  String get detailsTutorialGoalTitle => '🏆​ Daily Goal';

  @override
  String get detailsTutorialGoalDesc => 'Set your daily reading minutes.';

  @override
  String get detailsTutorialTimerTitle => '📖​ Reading Session';

  @override
  String get detailsTutorialTimerDesc => 'Start the timer to track your time.';

  @override
  String get detailsTutorialNotesTitle => '​📜​ ​Add Notes';

  @override
  String get detailsTutorialNotesDesc => 'Save your favorite quotes here.';

  @override
  String timerGoalReachedSnack(int minutes) {
    return '🎯 $minutes-min goal reached! Keep going if you like, or finish your session.';
  }

  @override
  String get timerEnterPage => 'Enter a page';

  @override
  String timerAlreadyOnPage(int page) {
    return 'You\'re already on page $page';
  }

  @override
  String timerBookHasPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The book has $count pages',
      one: 'The book has 1 page',
    );
    return '$_temp0';
  }

  @override
  String get timerUntilWhichPage => 'Up to which page?';

  @override
  String get timerReachPage => 'Reach page';

  @override
  String get timerDone => 'Done';

  @override
  String get timerSessionPaused => 'SESSION PAUSED';

  @override
  String get timerReadingTime => 'READING TIME';

  @override
  String get timerPause => 'PAUSE';

  @override
  String get timerResume => 'RESUME';

  @override
  String get timerStart => 'START';

  @override
  String get timerFinishReading => 'Finish session';

  @override
  String timerDurationMinSec(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String timerDurationSec(int seconds) {
    return '$seconds sec';
  }

  @override
  String get timerSessionFinished => 'Session finished!';

  @override
  String get timerWhatPageStopped => 'What page did you stop on?';

  @override
  String get timerCannotExceedTotal => 'Can\'t exceed the total';

  @override
  String get timerDiscard => 'DISCARD';

  @override
  String get timerGoalSheetTitle => '🎯 Goal for this session';

  @override
  String get timerGoalSheetSubtitle =>
      'I\'ll let you know when you reach your time goal, even with the screen off.';

  @override
  String get timerGoalTime => 'Time';

  @override
  String get timerGoalFree => 'None';

  @override
  String timerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get timerGoalPages => 'Pages';

  @override
  String timerUntilPageN(int page) {
    return 'Up to page $page';
  }

  @override
  String get timerUntilPageAsk => 'Up to page…';

  @override
  String get timerGoalFreeLabel => 'Goal: none';

  @override
  String timerGoalReached(int minutes) {
    return '$minutes-min goal reached!';
  }

  @override
  String timerGoalProgress(int elapsed, int total) {
    return 'Goal: $elapsed / $total min';
  }

  @override
  String timerGoalTimeLabel(int minutes) {
    return 'Goal: $minutes min';
  }

  @override
  String timerGoalPageLabel(int page) {
    return 'Goal: up to page $page';
  }

  @override
  String timerGoalMet(int minutes) {
    return '🎯 $minutes-min goal reached';
  }

  @override
  String timerGoalMissed(int minutes, int missing) {
    return 'Goal: $minutes min · $missing min short';
  }

  @override
  String timerPageGoalMet(int page) {
    return '🎯 You made it to page $page!';
  }

  @override
  String timerPageGoalMissed(int page, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left pages to go',
      one: '1 page to go',
    );
    return 'Goal: page $page · $_temp0';
  }

  @override
  String sessionGoalLabelTime(int minutes) {
    return '$minutes min';
  }

  @override
  String sessionGoalLabelPage(int page) {
    return 'up to page $page';
  }

  @override
  String sessionGoalTimeProgress(int elapsed, int total) {
    return '$elapsed / $total min';
  }

  @override
  String get noteCameraError =>
      'Couldn\'t open the camera. Check the permission in your phone settings.';

  @override
  String get noteSaveError => 'Couldn\'t save the note. Please try again.';

  @override
  String get noteNewTitle => 'New Note';

  @override
  String get noteEditTitle => 'Edit note';

  @override
  String get noteListening => 'Listening...';

  @override
  String get noteSubtitle => 'Type, dictate or scan';

  @override
  String get noteScanTooltip => 'Scan text with the camera';

  @override
  String get noteContentHint => 'Start speaking or typing...';

  @override
  String get notePageLabel => 'Book page';

  @override
  String get noteSave => 'Save note';

  @override
  String get noteSaveChanges => 'Save changes';

  @override
  String get scanSourceTitle => 'Scan a quote';

  @override
  String get scanSourcePrivacy =>
      'Text is recognized on your phone: the photo isn\'t sent anywhere.';

  @override
  String get scanSourceCamera => 'Take a photo of the page';

  @override
  String get scanSourceGallery => 'Choose from gallery';

  @override
  String get scanTitle => 'Highlight the quote';

  @override
  String get scanSelectNone => 'None';

  @override
  String get scanSelectAll => 'All';

  @override
  String get scanModelDownloadingTitle => 'Getting the text reader ready';

  @override
  String get scanModelDownloadingText =>
      'Google Play is downloading it (about 4 MB). Connect to the internet and try again in a few minutes.';

  @override
  String get scanErrorTitle => 'Couldn\'t read the photo';

  @override
  String get scanErrorText => 'Try again with another photo.';

  @override
  String get scanReading => 'Reading the page…';

  @override
  String get scanNoTextTitle => 'No text found';

  @override
  String get scanNoTextText =>
      'Try with more light, the page straight and the text in focus.';

  @override
  String get scanZoomIn => 'Zoom in';

  @override
  String get scanZoomOut => 'Zoom out';

  @override
  String get scanZoomFit => 'Show the whole page';

  @override
  String get scanHint =>
      'Slide a finger over the text to highlight it. Use two fingers to zoom in.';

  @override
  String get scanClear => 'Clear';

  @override
  String get scanUseQuote => 'Use quote';

  @override
  String reviewSummaryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String reviewSummaryMinutes(int minutes) {
    return '$minutes min of reading';
  }

  @override
  String reviewSummaryHours(int hours) {
    return '$hours h of reading';
  }

  @override
  String reviewSummaryHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min of reading';
  }

  @override
  String reviewSummaryPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get reviewRating1 => 'Didn\'t like it';

  @override
  String get reviewRating2 => 'It was OK';

  @override
  String get reviewRating3 => 'Good';

  @override
  String get reviewRating4 => 'Really good';

  @override
  String get reviewRating5 => 'Loved it!';

  @override
  String get reviewSaved => 'Review saved to your notes ✍️';

  @override
  String get reviewDeleted => 'Review deleted';

  @override
  String get reviewRatingSaved => 'Rating saved ⭐';

  @override
  String reviewFinishedTitle(String title) {
    return 'You finished $title!';
  }

  @override
  String reviewYourReviewTitle(String title) {
    return 'Your review of $title';
  }

  @override
  String reviewTitle(String title) {
    return 'Review of $title';
  }

  @override
  String get reviewAbandonedSubtitle => 'You didn\'t finish it';

  @override
  String get reviewHowRate => 'How would you rate it?';

  @override
  String reviewStarsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get reviewHintAbandoned => 'Why did you stop? (optional)';

  @override
  String get reviewHint => 'What did you think? One line is enough (optional)';

  @override
  String get reviewNotNow => 'Not now';

  @override
  String get quotesGeneratingCard => 'Creating card...';

  @override
  String quotesShareText(String title) {
    return '📖 $title\n✨ Shared from Book Tracker';
  }

  @override
  String get quotesImageError =>
      'Couldn\'t create the image. Please try again.';

  @override
  String quotesCardPage(int page) {
    return 'Page $page';
  }

  @override
  String get quotesCardFooter => 'Read on Book Tracker';

  @override
  String get quotesTitle => 'My quotes';

  @override
  String quotesLoadError(String error) {
    return 'Couldn\'t load quotes: $error';
  }

  @override
  String get quotesEmptyTitle => 'No quotes yet';

  @override
  String get quotesEmptyDescription =>
      'Save lines and thoughts from the \"Notes & quotes\" section of each book. They\'ll all show up here.';

  @override
  String get quotesSearchHint => 'Search quotes, titles or authors';

  @override
  String get quotesClearSearch => 'Clear search';

  @override
  String quotesFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String quotesFilterFavorites(int count) {
    return 'Favorites ($count)';
  }

  @override
  String get quotesNoFavorites =>
      'No favorites yet.\nTap the ☆ on a quote to save it here.';

  @override
  String get quotesNoMatches => 'No quotes match your search.';

  @override
  String quotesPageShort(int page) {
    return 'p. $page';
  }

  @override
  String get quotesRemoveFavorite => 'Remove from favorites';

  @override
  String get quotesMarkFavorite => 'Mark as favorite';

  @override
  String get quotesShareAsImage => 'Share as image';

  @override
  String get quotesCopy => 'Copy';

  @override
  String get quotesCopied => 'Quote copied';

  @override
  String get statusPending => 'To read';

  @override
  String get statusReading => 'Reading';

  @override
  String get statusFinished => 'Finished';

  @override
  String get statusAbandoned => 'Abandoned';

  @override
  String homeLoadError(String error) {
    return 'Error: $error';
  }

  @override
  String get homeTitle => 'My library';

  @override
  String get homeEmptyTitle => 'Your library is empty';

  @override
  String get homeEmptyDescription =>
      'Looks like a great time to start a new adventure.';

  @override
  String get homeAddFirstBook => 'Add my first book';

  @override
  String get homeNoMatchesTitle => 'No matches';

  @override
  String get homeNoMatchesDescription =>
      'We couldn\'t find anything that matches your filters.';

  @override
  String get homeShowAllBooks => 'See all books';

  @override
  String get homeSearchHint => 'Title or author…';

  @override
  String get homeCloseSearch => 'Close search';

  @override
  String get homeSearch => 'Search';

  @override
  String get homeMyQuotes => 'My quotes';

  @override
  String get homeSort => 'Sort';

  @override
  String get homeSortTitle => 'Sort books';

  @override
  String get homeSortRecentlyAdded => 'Recently added';

  @override
  String get homeSortMostProgress => 'Most progress';

  @override
  String get homeSortLongest => 'Longest books';

  @override
  String get homeSortAlphabetical => 'Alphabetical';

  @override
  String get homeSortShortRecent => 'Recent';

  @override
  String get homeSortShortLongest => 'Longest';

  @override
  String get homeSortShortAlphabetical => 'A–Z';

  @override
  String get homeFilterAll => 'All';

  @override
  String get homeFilterPending => 'To read';

  @override
  String get homeFilterFinished => 'Finished';

  @override
  String get homeFilterAbandoned => 'Abandoned';

  @override
  String homeBookCountSorted(int count, String sort) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books · $sort',
      one: '1 book · $sort',
    );
    return '$_temp0';
  }

  @override
  String get homeListView => 'List view';

  @override
  String get homeGridView => 'Grid view';

  @override
  String get homeDeleteBookTitle => 'Delete book?';

  @override
  String homeDeleteBookMessage(String title) {
    return 'This will permanently delete \"$title\".';
  }

  @override
  String get homeQuickStart => 'Start reading';

  @override
  String get homeQuickFinish => 'Finished';

  @override
  String get homeQuickResume => 'Resume';

  @override
  String homeQuickStartedSnack(String title) {
    return 'Started \"$title\"';
  }

  @override
  String homeQuickFinishedSnack(String title) {
    return 'Finished \"$title\"';
  }

  @override
  String homeQuickResumedSnack(String title) {
    return 'Resumed \"$title\"';
  }

  @override
  String get homeTutorialSearchTitle => '🔍 Find your books';

  @override
  String get homeTutorialSearchDescription =>
      'Quickly search for any title or author in your collection.';

  @override
  String get homeTutorialQuotesTitle => '❝ My quotes';

  @override
  String get homeTutorialQuotesDescription =>
      'All the quotes and notes from your books in one place: search them, mark favorites and share them.';

  @override
  String get homeTutorialSortTitle => '↕️ Organize your library';

  @override
  String get homeTutorialSortDescription =>
      'Sort your books by progress, length or date added.';

  @override
  String get homeTutorialAddTitle => '📚 New adventure';

  @override
  String get homeTutorialAddDescription =>
      'Tap here to add a new book and start reading.';

  @override
  String get homeContinueInSession => 'SESSION IN PROGRESS';

  @override
  String get homeContinueStart => 'START READING';

  @override
  String get homeContinueReading => 'CONTINUE READING';

  @override
  String homeContinueProgress(int percent, int read, int total) {
    return '$percent% · $read of $total pages';
  }

  @override
  String homeContinuePages(int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get homeContinueViewSession => 'View session';

  @override
  String get navBooks => 'Books';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get navTutorialStatsTitle => '📊​ Track your progress';

  @override
  String get navTutorialStatsDescription =>
      'See detailed stats about your reading.';

  @override
  String get navTutorialSettingsTitle => '⚙️​ Settings';

  @override
  String get navTutorialSettingsDescription =>
      'Customize the theme and manage your data.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingImportGoodreads => 'Import from Goodreads';

  @override
  String get onboardingExploreFirst => 'Explore first';

  @override
  String get onboardingPage1Title => 'Your library, in one tap';

  @override
  String get onboardingPage1Subtitle => 'Add books without all the typing.';

  @override
  String get onboardingPage1Point1 => 'Scan the barcode (ISBN) or type it in';

  @override
  String get onboardingPage1Point2 =>
      'Search by title to get the cover and page count';

  @override
  String get onboardingPage1Point3 =>
      'Coming from Goodreads? Import your whole library';

  @override
  String get onboardingPage2Title => 'Read with focus';

  @override
  String get onboardingPage2Subtitle => 'Time your sessions and set a goal.';

  @override
  String get onboardingPage2Point1 =>
      'Reading timer that saves your page when you finish';

  @override
  String get onboardingPage2Point2 =>
      'Session goal: I\'ll let you know when you hit it, even if your phone is locked';

  @override
  String get onboardingPage2Point3 =>
      'Home screen widget to pause without opening the app';

  @override
  String get onboardingPage3Title => 'Keep what moves you';

  @override
  String get onboardingPage3Subtitle => 'Your favorite quotes, always at hand.';

  @override
  String get onboardingPage3Point1 =>
      'Notes and quotes with their page, even dictated by voice';

  @override
  String get onboardingPage3Point2 =>
      'My quotes: search them all and share them as images';

  @override
  String get onboardingPage3Point3 =>
      'Rate and review each book when you finish it';

  @override
  String get onboardingPage4Title => 'Make it a habit';

  @override
  String get onboardingPage4Subtitle => 'Small steps, every day.';

  @override
  String get onboardingPage4Point1 =>
      'Daily streak, with a heads-up when it\'s at risk';

  @override
  String get onboardingPage4Point2 =>
      'Yearly challenge: how many books you want to read this year';

  @override
  String get onboardingPage4Point3 => 'Your reading year on a card to share';

  @override
  String get isbnNotAnIsbn =>
      'That code isn\'t an ISBN. Look for the one that starts with 978 or 979.';

  @override
  String get isbnScanPrompt => 'Point at the barcode on the back cover';

  @override
  String get isbnTypeIsbn => 'Type the ISBN';

  @override
  String get isbnWhereIsIt => 'Where is the ISBN?';

  @override
  String get isbnTorchOn => 'Turn on flashlight';

  @override
  String get isbnTorchOff => 'Turn off flashlight';

  @override
  String get isbnCameraPermission =>
      'To scan, we need permission to use the camera.';

  @override
  String get isbnCameraError =>
      'Couldn\'t open the camera. You can search for the book by typing its title.';

  @override
  String get isbnOpenSettings => 'Open settings';

  @override
  String get isbnHelpTitle => 'Where do I find the ISBN?';

  @override
  String get isbnHelpIntro =>
      'It\'s the number that identifies each edition of a book.';

  @override
  String get isbnHelpBackCoverTitle => 'On the back cover';

  @override
  String get isbnHelpBackCoverText =>
      'Above or below the barcode, after \"ISBN\". You can scan the barcode directly.';

  @override
  String get isbnHelpCreditsTitle => 'On the copyright page';

  @override
  String get isbnHelpCreditsText =>
      'One of the first pages of the book (where the publisher and copyright notice appear).';

  @override
  String get isbnHelpDigitsTitle => '13 or 10 digits';

  @override
  String get isbnHelpDigitsText =>
      'Since 2007 it has 13 digits and starts with 978 or 979. Older books use 10 digits, and the last one can be an X. You can type it with or without hyphens.';

  @override
  String get isbnPartPrefix => 'Prefix';

  @override
  String get isbnPartCountry => 'Country or language';

  @override
  String get isbnPartPublisher => 'Publisher';

  @override
  String get isbnPartBook => 'Book';

  @override
  String get isbnPartCheck => 'Check digit';

  @override
  String isbnLengthError(int count) {
    return 'Must have 10 or 13 digits (you have $count)';
  }

  @override
  String get isbnChecksumError =>
      'Check the numbers: the last digit doesn\'t match';

  @override
  String get isbnManualTitle => 'Enter the ISBN';

  @override
  String get isbnManualHelper =>
      '13 digits (starts with 978 or 979), or 10 digits for older books.';

  @override
  String get isbnManualWhere => 'Where do I find it?';

  @override
  String get isbnManualSearch => 'Search';

  @override
  String get addBookTooltip => 'Add book';

  @override
  String addBookIsbnNotFound(String isbn) {
    return 'We couldn\'t find ISBN $isbn. Enter the details manually.';
  }

  @override
  String addBookIsbnFound(String isbn) {
    return 'Found by ISBN $isbn';
  }

  @override
  String get addBookIsbnSearchFailed =>
      'Couldn\'t look up the ISBN. Enter the details manually.';

  @override
  String get addBookTitleRequired => 'Title is required';

  @override
  String get addBookAuthorRequired => 'Author is required';

  @override
  String addBookMaxChars(int max) {
    return 'Maximum $max characters';
  }

  @override
  String get addBookPagesRequired => 'Enter the page count';

  @override
  String get addBookInvalidNumber => 'Invalid number';

  @override
  String addBookAlreadyRead(int pages) {
    return 'You\'ve already read $pages';
  }

  @override
  String get addBookChangeCover => 'Change cover';

  @override
  String get addBookCamera => 'Camera';

  @override
  String get addBookGallery => 'Gallery';

  @override
  String get addBookSaveError => 'Couldn\'t save the book. Please try again.';

  @override
  String get addBookScanBarcode => 'Scan barcode';

  @override
  String get addBookTitleLabel => 'Book title';

  @override
  String get addBookAuthorLabel => 'Author';

  @override
  String get addBookDetails => 'Book details';

  @override
  String get addBookCategoryLabel => 'Category';

  @override
  String get addBookPagesLabel => 'Pages';

  @override
  String get addBookReadingStatus => 'Reading status';

  @override
  String get addBookAddToCollection => 'Add to Collection';

  @override
  String get addBookUpdateLibrary => 'Update Library';

  @override
  String get addBookStatusRead => 'Read';

  @override
  String get addBookStatusDnf => 'DNF';

  @override
  String get searchHint => 'Search for a book (title, author or ISBN)';

  @override
  String get searchFailed =>
      'Couldn\'t search. You can enter the details manually.';

  @override
  String searchIsbnNotFound(String isbn) {
    return 'We couldn\'t find ISBN $isbn. Check the number or enter the details manually.';
  }

  @override
  String get searchNotFound =>
      'We couldn\'t find it. Enter the details manually.';

  @override
  String searchIsbnResult(String isbn) {
    return 'Result for ISBN $isbn';
  }

  @override
  String searchPageCount(int count) {
    return '$count pp.';
  }

  @override
  String bookCardStatusReading(int percent) {
    return 'Reading · $percent%';
  }

  @override
  String bookCardStatusAbandoned(int read, int total) {
    return 'Abandoned · $read/$total pp.';
  }

  @override
  String bookCardStatusPending(int total) {
    return 'To read · $total pp.';
  }

  @override
  String get bookCardEdit => 'Edit';

  @override
  String get notifChannelRemindersName => 'Reading reminders';

  @override
  String get notifChannelRemindersDescription =>
      'Daily notifications to encourage reading';

  @override
  String get notifChannelSessionName => 'Session goal';

  @override
  String get notifChannelSessionDescription =>
      'Alert when you reach the time goal of a reading session';

  @override
  String get notifChannelStreakName => 'Streak at risk';

  @override
  String get notifChannelStreakDescription =>
      'Alert when you have a streak going and haven\'t read yet today';

  @override
  String get notifDailyTitle => 'Time to read!';

  @override
  String get notifDailyBody =>
      'Your streak is waiting. Open a book and relax for a moment.';

  @override
  String notifSessionGoalTitle(int minutes) {
    return '🎯 $minutes-min goal reached!';
  }

  @override
  String get notifSessionGoalBody =>
      'Keep reading, or end the session and save your page.';

  @override
  String get notifTestTitle => 'Reading test! 📖';

  @override
  String get notifTestBody =>
      'This is an instant notification to check that everything works.';

  @override
  String get widgetEmptyTitle => 'Add your first book';

  @override
  String get widgetEmptySubtitle => 'Tap to get started';

  @override
  String get widgetSessionReading => 'READING';

  @override
  String get widgetSessionPaused => 'PAUSED';

  @override
  String get widgetPause => 'Pause';

  @override
  String get widgetResume => 'Resume';

  @override
  String get widgetFinish => 'Finish';

  @override
  String get widgetFinishDescription => 'Finish the session';

  @override
  String get widgetCover => 'Cover';

  @override
  String widgetToday(String minutes) {
    return 'Today $minutes min';
  }

  @override
  String widgetTodayGoal(String minutes, String goal) {
    return 'Today $minutes/$goal min';
  }

  @override
  String widgetPagesInfo(int read, int total) {
    return '$read/$total pp.';
  }

  @override
  String get widgetStatusToRead => 'To read';

  @override
  String get widgetStatusReading => 'Reading';

  @override
  String get widgetStatusFinished => 'Finished';

  @override
  String get widgetStatusAbandoned => 'Abandoned';

  @override
  String get backupSvcReadFailed => 'Couldn\'t read the file.';

  @override
  String get backupSvcZipDamaged => 'The .zip file is damaged.';

  @override
  String get backupSvcZipNotBackup => 'This .zip isn\'t a Book Tracker backup.';

  @override
  String get backupSvcNotBackup => 'This file isn\'t a Book Tracker backup.';

  @override
  String get backupSvcUnknownFormat => 'The backup has an unknown format.';

  @override
  String get backupSvcNewerVersion =>
      'This backup is from a newer version of the app. Update it and try again.';

  @override
  String get backupSvcNoBooks =>
      'The backup is incomplete: it contains no books.';

  @override
  String backupSvcDamagedBook(int number) {
    return 'The backup has damaged data (book $number). Nothing was changed.';
  }

  @override
  String get backupSvcCoversFailed =>
      'Couldn\'t copy the covers. Nothing was changed.';

  @override
  String get backupSvcRestoreFailed =>
      'Couldn\'t restore the backup. Your library wasn\'t changed.';

  @override
  String get exportShareSubject => 'My Book Tracker library';

  @override
  String get importFileEmpty => 'The file is empty.';

  @override
  String get importNotGoodreads =>
      'This file doesn\'t look like a Goodreads export. Download it from goodreads.com → My Books → Import and export → Export Library.';

  @override
  String get importUnknownAuthor => 'Unknown';

  @override
  String get bookApiRateLimit =>
      'Too many searches in a row. Try again in a minute.';

  @override
  String get bookApiNetwork =>
      'No connection. You can enter the details by hand.';

  @override
  String get bookApiServer => 'The search service didn\'t respond. Try again.';

  @override
  String get bookApiUnknownAuthor => 'Unknown author';

  @override
  String get purchaseStartFailed => 'Couldn\'t start the purchase.';

  @override
  String get purchaseNotCompleted => 'The purchase wasn\'t completed.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsReminderTimeHelp => 'Reminder time';

  @override
  String get settingsStreakRiskTimeHelp => 'Streak alert time';

  @override
  String get settingsPermissionTitle => 'Don\'t lose the thread!';

  @override
  String get settingsPermissionBody =>
      'We\'ll turn on daily reminders to help you keep your reading streak and reach your goals. Your digital reading nook awaits!';

  @override
  String get settingsNotNow => 'Not now';

  @override
  String get settingsPermissionAccept => 'Sure thing!';

  @override
  String get settingsGotIt => 'Got it';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsThemeTitle => 'App theme';

  @override
  String get settingsThemeFollowSystem => 'Follow system';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light Mode';

  @override
  String get settingsThemeDark => 'Dark Mode';

  @override
  String get settingsColorsTitle => 'Colors';

  @override
  String get settingsColorsWallpaper => 'From wallpaper';

  @override
  String get settingsColorsBrandDescription =>
      'Cream and fir green by day, plum and amber by night.';

  @override
  String get settingsColorsWallpaperDescription =>
      'Material You: the colors of your wallpaper.';

  @override
  String get settingsColorsUnavailable => 'Available on Android 12 or later.';

  @override
  String get settingsSectionPreferences => 'PREFERENCES';

  @override
  String get settingsDailyNotificationsTitle => 'Daily notifications';

  @override
  String settingsDailyReminderAt(String time) {
    return 'Reminder at $time';
  }

  @override
  String get settingsDailyNotificationsOff => 'Off';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsStreakRiskTitle => 'Streak-at-risk alert';

  @override
  String get settingsStreakRiskNoPermission =>
      '⚠️ Notification permission is missing. Tap to turn it on.';

  @override
  String settingsStreakRiskSubtitle(String time) {
    return 'If you\'re on a streak and haven\'t read today, I\'ll remind you at $time';
  }

  @override
  String get settingsStreakRiskNeedsPermission =>
      'Turn on Book Tracker notifications to get the alert.';

  @override
  String get settingsSectionSecurity => 'SECURITY';

  @override
  String get settingsAppLockTitle => 'App lock';

  @override
  String get settingsAppLockOn => 'Asks for your secret word when opening';

  @override
  String get settingsAppLockOff => 'Off: the app opens right away';

  @override
  String get settingsChangePassphraseTitle => 'Change secret word';

  @override
  String get settingsChangePassphraseSubtitle =>
      'Your \"open sesame\" to get in';

  @override
  String get settingsChangePin => 'Change backup PIN';

  @override
  String get settingsSetUpPin => 'Set up backup PIN';

  @override
  String get settingsPinSubtitle =>
      'A 4-digit code in case you forget your word';

  @override
  String get settingsAutoLockTitle => 'Lock when leaving';

  @override
  String get settingsAutoLockNever => 'Never: only when opening the app';

  @override
  String settingsAutoLockAfter(int minutes) {
    return 'After $minutes min away from the app';
  }

  @override
  String get settingsAutoLockDescription =>
      'Asks for your word again if you\'re away from the app for this long. When you unlock, you pick up right where you left off.';

  @override
  String get settingsAutoLockNeverOption => 'Never';

  @override
  String settingsAutoLockAfterOption(int minutes) {
    return 'After $minutes min';
  }

  @override
  String get settingsLockEnabled => '🔒 Lock turned on';

  @override
  String get settingsLockDisabled => 'Lock turned off';

  @override
  String get settingsPassphraseUpdated => '✨ Secret word updated';

  @override
  String get settingsPinSaved => 'Backup PIN saved';

  @override
  String get settingsSectionData => 'DATA';

  @override
  String get settingsExportTitle => 'Back up or export';

  @override
  String get settingsExportSubtitle =>
      'Save a copy of your books, notes and covers';

  @override
  String get settingsExportFullTitle => 'Full backup (.zip)';

  @override
  String get settingsExportFullSubtitle =>
      'Everything, including covers. Use it to restore on another phone.';

  @override
  String get settingsExportJsonTitle => 'Data without covers (JSON)';

  @override
  String get settingsExportJsonSubtitle => 'Books, notes and reading sessions.';

  @override
  String get settingsExportCsvTitle => 'Spreadsheet (CSV)';

  @override
  String get settingsExportCsvSubtitle =>
      'Book list for Excel or Google Sheets.';

  @override
  String get settingsExportEmpty =>
      'Your library is empty: the file has no books.';

  @override
  String get settingsExportError => 'Couldn\'t export. Please try again.';

  @override
  String get settingsRestoreTitle => 'Restore backup';

  @override
  String get settingsRestoreSubtitle => 'From a .zip backup or a .json export';

  @override
  String get settingsGoodreadsSubtitle =>
      'Add your books from your Goodreads .csv file';

  @override
  String get settingsUndoRestoreTitle => 'Undo last restore';

  @override
  String get settingsUndoRestoreSubtitle =>
      'Go back to the library you had before';

  @override
  String get settingsSectionNoAds => 'NO ADS';

  @override
  String get settingsSectionWhatsNew => 'WHAT\'S NEW';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String settingsReleaseNotesSubtitle(String version) {
    return 'What\'s new in version $version and earlier';
  }

  @override
  String get settingsReplayWelcomeTitle => 'See the welcome again';

  @override
  String get settingsReplayWelcomeSubtitle =>
      'Go over what you can do in Book Tracker';

  @override
  String get settingsSectionSupport => 'SUPPORT';

  @override
  String get settingsAdPrivacyTitle => 'Ad privacy options';

  @override
  String get settingsAdPrivacySubtitle =>
      'Change your consent for personalized ads';

  @override
  String get aboutTitle => 'About the App';

  @override
  String get aboutTagline => 'Your digital reading nook';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutDeveloper => 'Developer';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutFooter => '© 2026 - Made with ❤️ for readers';

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String get updateTapToUpdate => 'Tap to update';

  @override
  String get updateDownloadingTitle => 'Downloading update…';

  @override
  String get updateKeepUsing => 'You can keep using the app';

  @override
  String get updateReadyTitle => 'Update ready';

  @override
  String get updateTapToRestart => 'Tap to restart and install it';

  @override
  String get updateCheckingTitle => 'Checking for updates…';

  @override
  String get updateCheckTitle => 'Check for updates';

  @override
  String updateUpToDateSubtitle(String version) {
    return 'Version $version · You\'re up to date';
  }

  @override
  String get updateDownloaded => 'Update downloaded';

  @override
  String get updateRestart => 'Restart';

  @override
  String get updateDownloadingNew => 'Downloading the new version…';

  @override
  String get updateLatest => 'You have the latest version';

  @override
  String get updateCheckFailed =>
      'Couldn\'t check. Updates come from Google Play.';

  @override
  String get updatePromptBody =>
      'Update to get the latest improvements. It downloads while you keep using the app.';

  @override
  String get updateButton => 'Update';

  @override
  String get backupPreparing => 'Preparing the backup…';

  @override
  String get backupShareSubject => 'Book Tracker backup';

  @override
  String get backupCreateError =>
      'Couldn\'t create the backup. Please try again.';

  @override
  String get backupPickTitle => 'Choose your backup';

  @override
  String get backupReading => 'Reading the backup…';

  @override
  String get backupRestoring => 'Restoring your library…';

  @override
  String backupBooksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String backupNotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String backupSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reading sessions',
      one: '1 reading session',
    );
    return '$_temp0';
  }

  @override
  String backupCoversCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count covers',
      one: '1 cover',
      zero: 'No covers',
    );
    return '$_temp0';
  }

  @override
  String backupUndoDone(String books) {
    return 'Previous library recovered: $books.';
  }

  @override
  String backupRestoreDone(String books, String notes) {
    return 'Library restored: $books, $notes.';
  }

  @override
  String get backupRestoreError =>
      'Couldn\'t restore the backup. Your library wasn\'t changed.';

  @override
  String get backupUndoConfirmTitle => 'Undo the last restore?';

  @override
  String get backupRestoreConfirmTitle => 'Restore this backup?';

  @override
  String backupSavedOn(String date) {
    return 'Library saved on $date';
  }

  @override
  String backupFrom(String date) {
    return 'Backup from $date';
  }

  @override
  String backupReplaceWarning(String books) {
    return 'This will replace your current library ($books). We\'ll save a copy first so you can undo it.';
  }

  @override
  String get backupUndoButton => 'UNDO';

  @override
  String get backupRestoreButton => 'RESTORE';

  @override
  String get backupErrorTitle => 'Couldn\'t finish';

  @override
  String get goodreadsImportTitle => 'Import from Goodreads';

  @override
  String get goodreadsPickTitle => 'Choose your Goodreads CSV';

  @override
  String get goodreadsFileTooLarge =>
      'The file is too large to be a Goodreads export.';

  @override
  String get goodreadsReadErrorTitle => 'Couldn\'t read the file';

  @override
  String get goodreadsReadErrorBody =>
      'Make sure you choose the .csv file you downloaded from Goodreads.';

  @override
  String get goodreadsNothingNewTitle => 'Nothing new to import';

  @override
  String goodreadsAllDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count books in the file are already in your library.',
      one: 'The book in the file is already in your library.',
    );
    return '$_temp0';
  }

  @override
  String get goodreadsNoBooks => 'The file has no books.';

  @override
  String get goodreadsImportErrorTitle => 'Couldn\'t import';

  @override
  String get goodreadsImportErrorBody =>
      'No books were added. Please try again.';

  @override
  String goodreadsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books imported from Goodreads 📚',
      one: '1 book imported from Goodreads 📚',
    );
    return '$_temp0';
  }

  @override
  String get goodreadsUndo => 'UNDO';

  @override
  String get goodreadsUndone => 'Import undone';

  @override
  String get goodreadsNoCovers =>
      'No covers found on Open Library. You can add them by editing each book.';

  @override
  String goodreadsCoversFound(int found, int total) {
    return 'Covers found: $found of $total.';
  }

  @override
  String get goodreadsHowToIntro =>
      'First, download your library from Goodreads:';

  @override
  String get goodreadsHowToStep1 =>
      '1. Go to goodreads.com in your browser (the Goodreads app can\'t export).';

  @override
  String get goodreadsHowToStep2 => '2. Go to My Books → Import and export.';

  @override
  String get goodreadsHowToStep3 =>
      '3. Tap \"Export Library\" and download the .csv file when it\'s ready.';

  @override
  String get goodreadsHowToNote =>
      'Your current books won\'t be deleted: only the missing ones are added.';

  @override
  String get goodreadsChooseFile => 'Choose file';

  @override
  String goodreadsCountRead(int count) {
    return '$count read';
  }

  @override
  String goodreadsCountReading(int count) {
    return '$count reading';
  }

  @override
  String goodreadsCountToRead(int count) {
    return '$count to read';
  }

  @override
  String goodreadsCountAbandoned(int count) {
    return '$count abandoned';
  }

  @override
  String goodreadsCountNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews and notes (saved as notes)',
      one: '1 review or note (saved as a note)',
    );
    return '$_temp0';
  }

  @override
  String goodreadsConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count books?',
      one: 'Import 1 book?',
    );
    return '$_temp0';
  }

  @override
  String goodreadsSkippedDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skipping $count that are already in your library.',
      one: 'Skipping 1 that\'s already in your library.',
    );
    return '$_temp0';
  }

  @override
  String goodreadsSkippedInvalid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skipping $count rows without a title.',
      one: 'Skipping 1 row without a title.',
    );
    return '$_temp0';
  }

  @override
  String get goodreadsNoReadingTime =>
      'Goodreads doesn\'t store reading time, so your streak and heatmap won\'t change. Read books with a date count toward that year\'s challenge.';

  @override
  String get goodreadsFetchCovers => 'Find covers';

  @override
  String goodreadsFetchCoversSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books with an ISBN · uses the internet',
      one: '1 book with an ISBN · uses the internet',
    );
    return '$_temp0';
  }

  @override
  String get goodreadsImportButton => 'Import';

  @override
  String get authCreatePassphraseTitle => 'Create your open sesame';

  @override
  String get secretNewPassphraseTitle => 'New secret word';

  @override
  String get secretPinTitle => 'Backup PIN';

  @override
  String get secretConfirmIdentity => 'Confirm it\'s you';

  @override
  String secretPinLengthError(int length) {
    return 'Must be $length digits';
  }

  @override
  String get secretMinLengthError => 'At least 3 characters';

  @override
  String get secretMismatch => 'They don\'t match';

  @override
  String get secretCaseHint =>
      'It\'s not case-sensitive. Pick something you\'ll remember.';

  @override
  String get secretNewPinLabel => 'New PIN';

  @override
  String get secretPassphraseLabel => 'Secret word';

  @override
  String get secretRepeatPin => 'Repeat the PIN';

  @override
  String get secretRepeatPassphrase => 'Repeat the word';

  @override
  String get secretPassphraseOrPin => 'Secret word or PIN';

  @override
  String get secretWrong => 'That\'s not right';

  @override
  String get secretConfirm => 'Confirm';

  @override
  String get removeAdsPurchaseFailed => 'The purchase didn\'t go through.';

  @override
  String get removeAdsPending =>
      'Your payment is pending. Ads will be removed once Google Play confirms it.';

  @override
  String get removeAdsActiveTitle => 'Ad-free';

  @override
  String get removeAdsThanks => 'Thanks for supporting Book Tracker! 💜';

  @override
  String get removeAdsTitle => 'Remove ads';

  @override
  String get removeAdsDescription =>
      'One-time payment, forever. No ads in your library, stats or quotes, plus \"Save streak\" for free. It stays if you reinstall or switch phones with the same Google account.';

  @override
  String get removeAdsUnavailable => 'Not available right now';

  @override
  String get removeAdsBuy => 'Buy';

  @override
  String removeAdsBuyFor(String price) {
    return 'Buy for $price';
  }

  @override
  String get removeAdsRestore => 'Restore';

  @override
  String get loginPassphraseSavedTitle => '✨ Word Saved';

  @override
  String get loginOfferPinBody =>
      'Want a 4-digit PIN as a backup? You can set it up later in Settings.';

  @override
  String get loginSetUpPin => 'Set up PIN';

  @override
  String get loginSkipLockTitle => 'Use without a lock?';

  @override
  String get loginSkipLockBody =>
      'Anyone with access to your phone will be able to open your library. You can turn on the lock anytime in Settings → Security.';

  @override
  String get loginSkipLock => 'Use without a lock';

  @override
  String get loginWrongPassphrase => 'That\'s not the magic word...';

  @override
  String loginTooManyAttemptsWait(String time) {
    return 'Too many attempts. Wait $time to try again.';
  }

  @override
  String loginWait(String time) {
    return 'Wait $time to try again.';
  }

  @override
  String get loginWrongPin => 'That PIN isn\'t right.';

  @override
  String get loginBiometricReason => 'Quick access to your library';

  @override
  String get loginCannotVerifyTitle => 'We can\'t verify it\'s you';

  @override
  String get loginCannotVerifyBody =>
      'To get back in, set up a screen lock (PIN, pattern or fingerprint) in your phone\'s settings and try again. Your books are still safe.';

  @override
  String get loginRecoverReason => 'Verify it\'s you to choose a new word';

  @override
  String get loginChooseNewPassphrase => 'Choose a new word';

  @override
  String get loginSetupTitle =>
      'Create your open sesame to begin the adventure';

  @override
  String get loginPinTitle => 'Enter your backup PIN';

  @override
  String get loginPassphraseTitle => 'Say the magic word to get in';

  @override
  String get loginUsePassphrase => 'Use open sesame';

  @override
  String get loginUsePin => 'Use backup PIN';

  @override
  String get loginForgotPin => 'Forgot your PIN?';

  @override
  String get loginForgotPassphrase => 'Forgot your secret word?';

  @override
  String loginLockoutBanner(String time) {
    return 'Too many attempts. You can try again in $time.\nMeanwhile, you can use your fingerprint or \"Forgot…?\".';
  }

  @override
  String get loginSetupBody =>
      'A secret word protects your library. If you forget it, you can recover it with your phone\'s screen lock.';

  @override
  String get loginCreatePassphrase => 'Create secret word';

  @override
  String get loginPassphraseHint => 'Type the word...';

  @override
  String get loginUseFingerprint => 'Use fingerprint';

  @override
  String get loginReveal => 'Reveal library';

  @override
  String get whatsNewTitle => 'Release notes';

  @override
  String get whatsNewHistorySubtitle =>
      'What\'s changed in each version of Book Tracker.';

  @override
  String get whatsNewHeadline => 'What\'s new in Book Tracker';

  @override
  String get whatsNewStart => 'Get started';

  @override
  String whatsNewLatestLabel(String version) {
    return 'WHAT\'S NEW · $version';
  }

  @override
  String whatsNewVersionLabel(String version) {
    return 'VERSION $version';
  }

  @override
  String get whatsNew142EnglishTitle => 'Book Tracker in English';

  @override
  String get whatsNew142EnglishText =>
      'The app is now available in English and Spanish, with dates and numbers in your language.';

  @override
  String get whatsNew142LanguageTitle => 'Choose your language';

  @override
  String get whatsNew142LanguageText =>
      'In Settings > Appearance > Language: automatic (your phone\'s language), Spanish or English.';

  @override
  String get whatsNew142PluralsTitle => 'Polished wording';

  @override
  String get whatsNew142PluralsText =>
      'Correct singular and plural forms (\"1 page\", \"1 book\") and clearer dates.';

  @override
  String get whatsNew141CameraQuotesTitle => 'Quotes from the camera';

  @override
  String get whatsNew141CameraQuotesText =>
      'Snap a page and underline the sentence you want to keep with your finger. With zoom and a magnifier for extra precision.';

  @override
  String get whatsNew141OnDeviceTitle => 'All on your phone';

  @override
  String get whatsNew141OnDeviceText =>
      'Text is recognized on your device: the photo isn\'t sent anywhere.';

  @override
  String get whatsNew141CalendarTitle => 'Reading calendar';

  @override
  String get whatsNew141CalendarText =>
      'Each day is colored by how much you read. Tap a day to see which books you read.';

  @override
  String get whatsNew141MonthlyChartTitle => 'Clearer monthly chart';

  @override
  String get whatsNew141MonthlyChartText =>
      'Round-number scale and bars that start at zero.';

  @override
  String get whatsNew140RedesignTitle => 'Fresh new design';

  @override
  String get whatsNew140RedesignText =>
      'Cleaner and calmer, with new colors, typography and dark mode.';

  @override
  String get whatsNew140PhoneColorsTitle => 'Your phone\'s colors';

  @override
  String get whatsNew140PhoneColorsText =>
      'In Settings > Colors you can use your wallpaper\'s palette.';

  @override
  String get whatsNew140ContinueReadingTitle => 'Continue reading';

  @override
  String get whatsNew140ContinueReadingText =>
      'Your current book at the top of your library: pick up your session in one tap.';

  @override
  String get whatsNew140ListGridTitle => 'List or grid';

  @override
  String get whatsNew140ListGridText =>
      'Choose how to view your library and filter by status or category.';

  @override
  String get whatsNew140SwipeTitle => 'Swipe to act';

  @override
  String get whatsNew140SwipeText =>
      'Right: start or finish a book, with Undo. Left: delete.';

  @override
  String get whatsNew140BookDetailTitle => 'Book details';

  @override
  String get whatsNew140BookDetailText =>
      'Redesigned, with your pace, what\'s left and your notes as quotes.';

  @override
  String get whatsNew140StatsTilesTitle => 'Stats at a glance';

  @override
  String get whatsNew140StatsTilesText =>
      'Your streak, your best streak and your week at a glance.';

  @override
  String get whatsNew140BackGestureTitle => 'Back gesture';

  @override
  String get whatsNew140BackGestureText =>
      'Swipe to go back and see where you\'re headed; \"back\" returns to Books before exiting.';

  @override
  String get whatsNew140UpdateAlertsTitle => 'Update alerts';

  @override
  String get whatsNew140UpdateAlertsText =>
      'We\'ll let you know when there\'s a new version, and you can install it without leaving the app.';

  @override
  String get whatsNew140ReleaseNotesTitle => 'Release notes';

  @override
  String get whatsNew140ReleaseNotesText =>
      'Check what\'s new anytime in Settings > What\'s new.';

  @override
  String get whatsNew130FasterTitle => 'Faster and lighter';

  @override
  String get whatsNew130FasterText =>
      'The app takes up less space and opens faster.';

  @override
  String get whatsNew130SaferTitle => 'More secure';

  @override
  String get whatsNew130SaferText =>
      'Your secret word is stored with the latest secure storage.';

  @override
  String get whatsNew130PurchasesTitle => 'More reliable purchases';

  @override
  String get whatsNew130PurchasesText =>
      '\"Remove ads\" handles pending purchases and refunds better.';

  @override
  String get whatsNew121RemoveAdsTitle => 'Remove ads';

  @override
  String get whatsNew121RemoveAdsText =>
      'A one-time payment to use the app ad-free, forever.';

  @override
  String get whatsNew120IsbnScannerTitle => 'ISBN scanner';

  @override
  String get whatsNew120IsbnScannerText =>
      'Add a book by scanning its barcode or typing the ISBN.';

  @override
  String get whatsNew120MyQuotesTitle => 'My quotes';

  @override
  String get whatsNew120MyQuotesText =>
      'All your notes in one place: search them, mark favorites and share them.';

  @override
  String get whatsNew120ChallengeTitle => 'Yearly challenge and dates';

  @override
  String get whatsNew120ChallengeText =>
      'Start and finish dates for each book, plus your books-per-year goal.';

  @override
  String get whatsNew120SessionGoalTitle => 'Session goal';

  @override
  String get whatsNew120SessionGoalText =>
      'Pick 15–60 min or a page and I\'ll let you know when you hit it.';

  @override
  String get whatsNew120ReviewsTitle => 'Reviews';

  @override
  String get whatsNew120ReviewsText =>
      'Rate and review a book when you finish it (or whenever you like).';

  @override
  String get whatsNew120StreakRiskTitle => 'Streak at risk';

  @override
  String get whatsNew120StreakRiskText =>
      'An evening reminder if you\'re on a streak and haven\'t read yet.';

  @override
  String get whatsNew120WidgetTitle => 'Revamped widget';

  @override
  String get whatsNew120WidgetText =>
      'With your book\'s cover and one-tap pause.';

  @override
  String get whatsNew120ReadingYearTitle => 'My reading year';

  @override
  String get whatsNew120ReadingYearText =>
      'Share a card with your stats for the year.';

  @override
  String get whatsNew120GoodreadsTitle => 'Goodreads and backups';

  @override
  String get whatsNew120GoodreadsText =>
      'Import your Goodreads library and save a full backup with covers.';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsShareTooltip => 'Share my reading year';

  @override
  String statsShareEmpty(int year) {
    return 'No reading in $year to share yet. Start a book!';
  }

  @override
  String statsError(String error) {
    return 'Error: $error';
  }

  @override
  String get statsToday => 'Today';

  @override
  String statsTodayProgress(int minutes, int goal) {
    return '$minutes of $goal min';
  }

  @override
  String get statsBooksRead => 'Books read';

  @override
  String get statsPages => 'Pages';

  @override
  String get statsTotalTime => 'Total time';

  @override
  String get statsFavoriteGenres => 'Favorite genres';

  @override
  String get statsAchievementsTitle => 'Achievements & challenges';

  @override
  String get statsChartMinutes => 'MINUTES';

  @override
  String get statsChartDayOfMonth => 'DAY OF MONTH';

  @override
  String statsChartBarMinutes(int minutes) {
    return '$minutes m';
  }

  @override
  String get streakCurrent => 'Current streak';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String streakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'Your best streak: $_temp0';
  }

  @override
  String streakRiskTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day',
      one: '1-day',
    );
    return '🔥 Your $_temp0 streak is at risk';
  }

  @override
  String get streakRiskBody =>
      'You haven\'t read today. Read a few minutes before midnight to keep it.';

  @override
  String streakSaveSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '🔥 Streak saved! You\'re at $_temp0. Read today to keep it going.';
  }

  @override
  String get streakSaveAdIncomplete =>
      'You need to watch the whole ad to save your streak.';

  @override
  String get streakSaveAdUnavailable =>
      'No ads available right now. Check your connection and try again.';

  @override
  String streakSaveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day',
      one: '1-day',
    );
    return 'Your $_temp0 streak was broken';
  }

  @override
  String get streakSaveBodyFree =>
      'You didn\'t log any reading yesterday. As an ad-free user, you can restore it for free: yesterday will count toward your streak.';

  @override
  String get streakSaveBodyAd =>
      'You didn\'t log any reading yesterday. Watch a short ad and we\'ll restore it: yesterday will count toward your streak.';

  @override
  String get streakSaveOncePerWeek => 'You can do this once a week.';

  @override
  String get streakSaveLoadingAd => 'Loading ad…';

  @override
  String get streakSaveFreeButton => 'Save my streak';

  @override
  String get streakSaveWatchAdButton => 'Watch ad and save my streak';

  @override
  String get streakSaveNotNow => 'Not now';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarHistoryStartsHere =>
      'Your history starts here: no earlier months with reading yet.';

  @override
  String calendarHistoryStartsIn(String month) {
    return 'Your history starts in $month.';
  }

  @override
  String get calendarCurrentMonth => 'This is the current month.';

  @override
  String calendarDaySavedSemantics(String day) {
    return '$day, streak saved';
  }

  @override
  String calendarDayNoReadingSemantics(String day) {
    return '$day, no reading';
  }

  @override
  String calendarDayReadingSemantics(String day, String duration, int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages pages',
      one: '1 page',
    );
    return '$day, $duration, $_temp0';
  }

  @override
  String get calendarLegendLess => 'Less';

  @override
  String get calendarLegendMore => 'More';

  @override
  String get calendarNoReadingYetThisMonth =>
      'You haven\'t read this month yet. Tap a day to see its details.';

  @override
  String get calendarNoReadingThisMonth => 'No reading this month.';

  @override
  String calendarDaysReadLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days read',
      one: 'day read',
    );
    return '$_temp0';
  }

  @override
  String get calendarTotalLabel => 'in total';

  @override
  String calendarPagesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pages',
      one: 'page',
    );
    return '$_temp0';
  }

  @override
  String calendarPagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String calendarPagesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String calendarBestDay(String date, String amount) {
    return 'Your best day: $date · $amount';
  }

  @override
  String get calendarDaySavedDetail =>
      'You didn\'t read, but you saved your streak that day.';

  @override
  String get calendarDayNoReadingDetail => 'You didn\'t read on this day.';

  @override
  String get calendarDeletedBook => 'Deleted book';

  @override
  String get challengeFinishedBooksTitle => 'Finished books';

  @override
  String get challengeNoDatedBooks => 'No finished books with a date yet.';

  @override
  String challengeYearHeader(String year, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$year · $_temp0';
  }

  @override
  String challengeUndatedBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count finished books have no finish date.',
      one: '1 finished book has no finish date.',
    );
    return '$_temp0 You can add it in each book\'s details so it counts toward that year.';
  }

  @override
  String challengeTitleWithYear(String year) {
    return '$year Reading Challenge';
  }

  @override
  String get challengeSetGoalPrompt => 'Set a book goal for this year.';

  @override
  String challengeFinishedSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return 'You\'ve finished $_temp0 this year. Want to set a goal?';
  }

  @override
  String get challengeCreate => 'Create challenge';

  @override
  String get challengeShowBooks => 'View books';

  @override
  String challengeOfGoal(int goal) {
    return 'of $goal';
  }

  @override
  String challengeShortTitle(String year) {
    return '$year Challenge';
  }

  @override
  String get challengeChangeGoal => 'Change goal';

  @override
  String challengeDoneCount(int finished, int goal) {
    return '$finished of $goal books';
  }

  @override
  String challengeRemaining(int count) {
    return '$count to go to reach your goal';
  }

  @override
  String get challengeShowFinished => 'View finished books';

  @override
  String get challengeDialogQuestion =>
      'How many books do you want to read this year?';

  @override
  String get challengeBooksSuffix => 'books';

  @override
  String challengeGoalRange(int max) {
    return 'Between 1 and $max';
  }

  @override
  String get challengeRemove => 'Remove challenge';

  @override
  String get challengeCompleted => 'Challenge complete!';

  @override
  String challengeExceeded(int extra) {
    return 'Challenge beaten! +$extra';
  }

  @override
  String challengeAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0 ahead';
  }

  @override
  String challengeBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0 behind';
  }

  @override
  String get challengeOnTrack => 'Right on track';

  @override
  String get yearSummaryHeading => 'MY READING YEAR';

  @override
  String yearSummaryBooksFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'books\nfinished',
      one: 'book\nfinished',
    );
    return '$_temp0';
  }

  @override
  String yearSummaryGoalDone(int goal) {
    return '🏆 $goal-book challenge complete!';
  }

  @override
  String yearSummaryGoalProgress(int finished, int goal) {
    return 'Challenge: $finished of $goal books';
  }

  @override
  String get yearSummaryPages => 'pages';

  @override
  String get yearSummaryReadingTime => 'reading';

  @override
  String yearSummaryReadingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reading days',
      one: 'reading day',
    );
    return '$_temp0';
  }

  @override
  String yearSummaryLongestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'day best streak',
      one: 'day streak',
    );
    return '$_temp0';
  }

  @override
  String yearSummaryFavoriteGenre(String genre) {
    return 'Favorite genre: $genre';
  }

  @override
  String get yearSummaryRecentlyFinished => 'Recently finished';

  @override
  String yearSummaryShareText(String year) {
    return 'My $year reading year 📚 #BookTracker';
  }

  @override
  String get yearSummaryShareError =>
      'Couldn\'t create the image. Please try again.';

  @override
  String get yearSummaryShare => 'Share';

  @override
  String get achievementCategoryEarly => 'Early Discipline';

  @override
  String get achievementCategorySerious => 'Serious Commitment';

  @override
  String get achievementCategoryScholar => 'Scholar Level (3+ years)';

  @override
  String get achievementHabitFormedName => 'Habit Formed';

  @override
  String get achievementHabitFormedDesc => '21-day streak';

  @override
  String get achievementSprinterName => 'Sprinter';

  @override
  String get achievementSprinterDesc => '500 pages read';

  @override
  String get achievementVoraciousReaderName => 'Voracious Reader';

  @override
  String get achievementVoraciousReaderDesc => '50 books finished';

  @override
  String get achievementHalfMarathonName => 'Half Marathon';

  @override
  String get achievementHalfMarathonDesc => '250 hours of reading';

  @override
  String get achievementPureConsistencyName => 'Pure Consistency';

  @override
  String get achievementPureConsistencyDesc => '100-day streak';

  @override
  String get achievementGoldenBibliophileName => 'Golden Bibliophile';

  @override
  String get achievementGoldenBibliophileDesc => '100,000 pages read';

  @override
  String get achievementLifeAmongBooksName => 'A Life Among Books';

  @override
  String get achievementLifeAmongBooksDesc => '1,000 hours of reading';

  @override
  String get achievementUnbreakableName => 'Unbreakable';

  @override
  String get achievementUnbreakableDesc => '365-day streak';

  @override
  String get achievementLibraryMasterName => 'Library Master';

  @override
  String get achievementLibraryMasterDesc => '250 books completed';
}
