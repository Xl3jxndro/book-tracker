import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get commonUndo;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @commonAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get commonAccept;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get languageSystem;

  /// No description provided for @languageSystemSubtitle.
  ///
  /// In es, this message translates to:
  /// **'El idioma de tu teléfono'**
  String get languageSystemSubtitle;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @detailsShareText.
  ///
  /// In es, this message translates to:
  /// **'📖 *Estoy leyendo:* {title}\n✍️ *Autor:* {author}\n📊 *Progreso:* {readPages}/{totalPages} pág.\n\n✨ Compartido desde {appName}'**
  String detailsShareText(
    String title,
    String author,
    int readPages,
    int totalPages,
    String appName,
  );

  /// No description provided for @detailsTimeNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get detailsTimeNow;

  /// No description provided for @detailsTimeMinutesAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {minutes}m'**
  String detailsTimeMinutesAgo(int minutes);

  /// No description provided for @detailsTimeToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get detailsTimeToday;

  /// No description provided for @detailsTimeYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get detailsTimeYesterday;

  /// No description provided for @detailsShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get detailsShare;

  /// No description provided for @detailsMoreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get detailsMoreOptions;

  /// No description provided for @detailsEditBook.
  ///
  /// In es, this message translates to:
  /// **'Editar libro'**
  String get detailsEditBook;

  /// No description provided for @detailsNotesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin notas aún'**
  String get detailsNotesEmptyTitle;

  /// No description provided for @detailsNotesEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Guarda aquí tus citas y pensamientos.'**
  String get detailsNotesEmptyDescription;

  /// No description provided for @detailsNewNote.
  ///
  /// In es, this message translates to:
  /// **'Nueva nota'**
  String get detailsNewNote;

  /// No description provided for @detailsFavoritesEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Toca la ☆ de una nota para guardarla en tus citas favoritas.'**
  String get detailsFavoritesEmptyHint;

  /// No description provided for @detailsShareAsImage.
  ///
  /// In es, this message translates to:
  /// **'Compartir como imagen'**
  String get detailsShareAsImage;

  /// No description provided for @detailsRemoveFavorite.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritas'**
  String get detailsRemoveFavorite;

  /// No description provided for @detailsAddFavorite.
  ///
  /// In es, this message translates to:
  /// **'Guardar en favoritas'**
  String get detailsAddFavorite;

  /// No description provided for @detailsCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get detailsCopy;

  /// No description provided for @detailsCopied.
  ///
  /// In es, this message translates to:
  /// **'Copiado'**
  String get detailsCopied;

  /// No description provided for @detailsNotePage.
  ///
  /// In es, this message translates to:
  /// **'Página {page}'**
  String detailsNotePage(int page);

  /// No description provided for @detailsReadingSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión de lectura'**
  String get detailsReadingSession;

  /// No description provided for @detailsNotesAndQuotes.
  ///
  /// In es, this message translates to:
  /// **'Notas y citas'**
  String get detailsNotesAndQuotes;

  /// No description provided for @detailsAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get detailsAdd;

  /// No description provided for @detailsFilterRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get detailsFilterRecent;

  /// No description provided for @detailsFilterPage.
  ///
  /// In es, this message translates to:
  /// **'Página'**
  String get detailsFilterPage;

  /// No description provided for @detailsFilterLength.
  ///
  /// In es, this message translates to:
  /// **'Longitud'**
  String get detailsFilterLength;

  /// No description provided for @detailsFilterFavorites.
  ///
  /// In es, this message translates to:
  /// **'★ Favoritas'**
  String get detailsFilterFavorites;

  /// No description provided for @detailsYourProgress.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso'**
  String get detailsYourProgress;

  /// No description provided for @detailsPagesOfTotal.
  ///
  /// In es, this message translates to:
  /// **'{read} de {total} páginas'**
  String detailsPagesOfTotal(int read, int total);

  /// No description provided for @detailsReread.
  ///
  /// In es, this message translates to:
  /// **'Releer'**
  String get detailsReread;

  /// No description provided for @detailsUpdate.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get detailsUpdate;

  /// No description provided for @detailsStartAddDate.
  ///
  /// In es, this message translates to:
  /// **'Inicio: añadir fecha'**
  String get detailsStartAddDate;

  /// No description provided for @detailsStartedOn.
  ///
  /// In es, this message translates to:
  /// **'Empezado el {date}'**
  String detailsStartedOn(String date);

  /// No description provided for @detailsFinishAddDate.
  ///
  /// In es, this message translates to:
  /// **'Fin: añadir fecha'**
  String get detailsFinishAddDate;

  /// No description provided for @detailsFinishedOn.
  ///
  /// In es, this message translates to:
  /// **'Terminado el {date}'**
  String detailsFinishedOn(String date);

  /// No description provided for @detailsFinishedOnDays.
  ///
  /// In es, this message translates to:
  /// **'Terminado el {date} · {days, plural, =1{1 día} other{{days} días}}'**
  String detailsFinishedOnDays(String date, int days);

  /// No description provided for @detailsWhenStarted.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo lo empezaste?'**
  String get detailsWhenStarted;

  /// No description provided for @detailsWhenFinished.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo lo terminaste?'**
  String get detailsWhenFinished;

  /// No description provided for @detailsDurationHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String detailsDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @detailsDurationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String detailsDurationMinutes(int minutes);

  /// No description provided for @detailsPacePerMinute.
  ///
  /// In es, this message translates to:
  /// **'{pace} pág/min'**
  String detailsPacePerMinute(String pace);

  /// No description provided for @detailsPacePerHour.
  ///
  /// In es, this message translates to:
  /// **'{pages} pág/h'**
  String detailsPacePerHour(int pages);

  /// No description provided for @detailsPace.
  ///
  /// In es, this message translates to:
  /// **'Ritmo'**
  String get detailsPace;

  /// No description provided for @detailsTimeLeft.
  ///
  /// In es, this message translates to:
  /// **'Faltan'**
  String get detailsTimeLeft;

  /// No description provided for @detailsTimeRead.
  ///
  /// In es, this message translates to:
  /// **'Leído'**
  String get detailsTimeRead;

  /// No description provided for @detailsDailyGoal.
  ///
  /// In es, this message translates to:
  /// **'Meta diaria'**
  String get detailsDailyGoal;

  /// No description provided for @detailsDailyGoalProgress.
  ///
  /// In es, this message translates to:
  /// **'{minutes} de {goal} min hoy'**
  String detailsDailyGoalProgress(int minutes, int goal);

  /// No description provided for @detailsChangeDailyGoal.
  ///
  /// In es, this message translates to:
  /// **'Cambiar meta diaria'**
  String get detailsChangeDailyGoal;

  /// No description provided for @detailsReadingCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Lectura completada!'**
  String get detailsReadingCompleted;

  /// No description provided for @detailsRatingStars.
  ///
  /// In es, this message translates to:
  /// **'{stars} de 5'**
  String detailsRatingStars(int stars);

  /// No description provided for @detailsWriteReview.
  ///
  /// In es, this message translates to:
  /// **'Escribir reseña'**
  String get detailsWriteReview;

  /// No description provided for @detailsEditReview.
  ///
  /// In es, this message translates to:
  /// **'Editar reseña'**
  String get detailsEditReview;

  /// No description provided for @detailsFavoriteRemoved.
  ///
  /// In es, this message translates to:
  /// **'Quitada de favoritas'**
  String get detailsFavoriteRemoved;

  /// No description provided for @detailsFavoriteAdded.
  ///
  /// In es, this message translates to:
  /// **'Guardada en favoritas ★'**
  String get detailsFavoriteAdded;

  /// No description provided for @detailsNoteDeleted.
  ///
  /// In es, this message translates to:
  /// **'Nota eliminada'**
  String get detailsNoteDeleted;

  /// No description provided for @detailsUndoAction.
  ///
  /// In es, this message translates to:
  /// **'DESHACER'**
  String get detailsUndoAction;

  /// No description provided for @detailsEnterPageNumber.
  ///
  /// In es, this message translates to:
  /// **'Escribe un número de página'**
  String get detailsEnterPageNumber;

  /// No description provided for @detailsPageCannotExceed.
  ///
  /// In es, this message translates to:
  /// **'No puede superar {total}'**
  String detailsPageCannotExceed(int total);

  /// No description provided for @detailsUpdateProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualizar Progreso'**
  String get detailsUpdateProgressTitle;

  /// No description provided for @detailsWhatPage.
  ///
  /// In es, this message translates to:
  /// **'¿En qué página vas?'**
  String get detailsWhatPage;

  /// No description provided for @detailsDeleteBookTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar libro?'**
  String get detailsDeleteBookTitle;

  /// No description provided for @detailsDeleteBookMessage.
  ///
  /// In es, this message translates to:
  /// **'Se perderán todas tus notas.'**
  String get detailsDeleteBookMessage;

  /// No description provided for @detailsDailyGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Meta Diaria'**
  String get detailsDailyGoalTitle;

  /// No description provided for @detailsRereadTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Nueva lectura?'**
  String get detailsRereadTitle;

  /// No description provided for @detailsRereadConfirm.
  ///
  /// In es, this message translates to:
  /// **'¡Vamos!'**
  String get detailsRereadConfirm;

  /// No description provided for @detailsTutorialProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'📈​ Tu Progreso'**
  String get detailsTutorialProgressTitle;

  /// No description provided for @detailsTutorialProgressDesc.
  ///
  /// In es, this message translates to:
  /// **'Visualiza cuántas páginas llevas leídas.'**
  String get detailsTutorialProgressDesc;

  /// No description provided for @detailsTutorialGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'🏆​ Meta Diaria'**
  String get detailsTutorialGoalTitle;

  /// No description provided for @detailsTutorialGoalDesc.
  ///
  /// In es, this message translates to:
  /// **'Configura tus minutos de lectura diarios.'**
  String get detailsTutorialGoalDesc;

  /// No description provided for @detailsTutorialTimerTitle.
  ///
  /// In es, this message translates to:
  /// **'📖​ Sesión de Lectura'**
  String get detailsTutorialTimerTitle;

  /// No description provided for @detailsTutorialTimerDesc.
  ///
  /// In es, this message translates to:
  /// **'Inicia el cronómetro para medir tu tiempo.'**
  String get detailsTutorialTimerDesc;

  /// No description provided for @detailsTutorialNotesTitle.
  ///
  /// In es, this message translates to:
  /// **'​📜​ ​Añadir Notas'**
  String get detailsTutorialNotesTitle;

  /// No description provided for @detailsTutorialNotesDesc.
  ///
  /// In es, this message translates to:
  /// **'Guarda tus citas favoritas aquí.'**
  String get detailsTutorialNotesDesc;

  /// No description provided for @timerGoalReachedSnack.
  ///
  /// In es, this message translates to:
  /// **'🎯 ¡Meta de {minutes} min cumplida! Sigue si quieres o finaliza la lectura.'**
  String timerGoalReachedSnack(int minutes);

  /// No description provided for @timerEnterPage.
  ///
  /// In es, this message translates to:
  /// **'Escribe una página'**
  String get timerEnterPage;

  /// No description provided for @timerAlreadyOnPage.
  ///
  /// In es, this message translates to:
  /// **'Ya vas en la pág. {page}'**
  String timerAlreadyOnPage(int page);

  /// No description provided for @timerBookHasPages.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{El libro tiene 1 página} other{El libro tiene {count} páginas}}'**
  String timerBookHasPages(int count);

  /// No description provided for @timerUntilWhichPage.
  ///
  /// In es, this message translates to:
  /// **'¿Hasta qué página?'**
  String get timerUntilWhichPage;

  /// No description provided for @timerReachPage.
  ///
  /// In es, this message translates to:
  /// **'Llegar a la página'**
  String get timerReachPage;

  /// No description provided for @timerDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get timerDone;

  /// No description provided for @timerSessionPaused.
  ///
  /// In es, this message translates to:
  /// **'SESIÓN PAUSADA'**
  String get timerSessionPaused;

  /// No description provided for @timerReadingTime.
  ///
  /// In es, this message translates to:
  /// **'TIEMPO DE LECTURA'**
  String get timerReadingTime;

  /// No description provided for @timerPause.
  ///
  /// In es, this message translates to:
  /// **'PAUSAR'**
  String get timerPause;

  /// No description provided for @timerResume.
  ///
  /// In es, this message translates to:
  /// **'REANUDAR'**
  String get timerResume;

  /// No description provided for @timerStart.
  ///
  /// In es, this message translates to:
  /// **'COMENZAR'**
  String get timerStart;

  /// No description provided for @timerFinishReading.
  ///
  /// In es, this message translates to:
  /// **'Finalizar lectura'**
  String get timerFinishReading;

  /// No description provided for @timerDurationMinSec.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min {seconds} seg'**
  String timerDurationMinSec(int minutes, int seconds);

  /// No description provided for @timerDurationSec.
  ///
  /// In es, this message translates to:
  /// **'{seconds} seg'**
  String timerDurationSec(int seconds);

  /// No description provided for @timerSessionFinished.
  ///
  /// In es, this message translates to:
  /// **'¡Sesión terminada!'**
  String get timerSessionFinished;

  /// No description provided for @timerWhatPageStopped.
  ///
  /// In es, this message translates to:
  /// **'¿En qué página quedaste?'**
  String get timerWhatPageStopped;

  /// No description provided for @timerCannotExceedTotal.
  ///
  /// In es, this message translates to:
  /// **'No puede exceder el total'**
  String get timerCannotExceedTotal;

  /// No description provided for @timerDiscard.
  ///
  /// In es, this message translates to:
  /// **'DESCARTAR'**
  String get timerDiscard;

  /// No description provided for @timerGoalSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'🎯 Meta de esta sesión'**
  String get timerGoalSheetTitle;

  /// No description provided for @timerGoalSheetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te aviso al cumplir la meta de tiempo, aunque tengas la pantalla apagada.'**
  String get timerGoalSheetSubtitle;

  /// No description provided for @timerGoalTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get timerGoalTime;

  /// No description provided for @timerGoalFree.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get timerGoalFree;

  /// No description provided for @timerMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String timerMinutes(int minutes);

  /// No description provided for @timerGoalPages.
  ///
  /// In es, this message translates to:
  /// **'Páginas'**
  String get timerGoalPages;

  /// No description provided for @timerUntilPageN.
  ///
  /// In es, this message translates to:
  /// **'Hasta la pág. {page}'**
  String timerUntilPageN(int page);

  /// No description provided for @timerUntilPageAsk.
  ///
  /// In es, this message translates to:
  /// **'Hasta la página…'**
  String get timerUntilPageAsk;

  /// No description provided for @timerGoalFreeLabel.
  ///
  /// In es, this message translates to:
  /// **'Meta: libre'**
  String get timerGoalFreeLabel;

  /// No description provided for @timerGoalReached.
  ///
  /// In es, this message translates to:
  /// **'¡Meta de {minutes} min cumplida!'**
  String timerGoalReached(int minutes);

  /// No description provided for @timerGoalProgress.
  ///
  /// In es, this message translates to:
  /// **'Meta: {elapsed} / {total} min'**
  String timerGoalProgress(int elapsed, int total);

  /// No description provided for @timerGoalTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Meta: {minutes} min'**
  String timerGoalTimeLabel(int minutes);

  /// No description provided for @timerGoalPageLabel.
  ///
  /// In es, this message translates to:
  /// **'Meta: hasta la pág. {page}'**
  String timerGoalPageLabel(int page);

  /// No description provided for @timerGoalMet.
  ///
  /// In es, this message translates to:
  /// **'🎯 Meta de {minutes} min cumplida'**
  String timerGoalMet(int minutes);

  /// No description provided for @timerGoalMissed.
  ///
  /// In es, this message translates to:
  /// **'Meta: {minutes} min · te faltaron {missing} min'**
  String timerGoalMissed(int minutes, int missing);

  /// No description provided for @timerPageGoalMet.
  ///
  /// In es, this message translates to:
  /// **'🎯 ¡Llegaste a la pág. {page}!'**
  String timerPageGoalMet(int page);

  /// No description provided for @timerPageGoalMissed.
  ///
  /// In es, this message translates to:
  /// **'Meta: pág. {page} · {left, plural, =1{te falta 1 página} other{te faltan {left} páginas}}'**
  String timerPageGoalMissed(int page, int left);

  /// No description provided for @sessionGoalLabelTime.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String sessionGoalLabelTime(int minutes);

  /// No description provided for @sessionGoalLabelPage.
  ///
  /// In es, this message translates to:
  /// **'hasta la pág. {page}'**
  String sessionGoalLabelPage(int page);

  /// No description provided for @sessionGoalTimeProgress.
  ///
  /// In es, this message translates to:
  /// **'{elapsed} / {total} min'**
  String sessionGoalTimeProgress(int elapsed, int total);

  /// No description provided for @noteCameraError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la cámara. Revisa el permiso en los ajustes del teléfono.'**
  String get noteCameraError;

  /// No description provided for @noteSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la nota. Inténtalo de nuevo.'**
  String get noteSaveError;

  /// No description provided for @noteNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva Anotación'**
  String get noteNewTitle;

  /// No description provided for @noteEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar anotación'**
  String get noteEditTitle;

  /// No description provided for @noteListening.
  ///
  /// In es, this message translates to:
  /// **'Escuchando voz...'**
  String get noteListening;

  /// No description provided for @noteSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe, dicta o escanea'**
  String get noteSubtitle;

  /// No description provided for @noteScanTooltip.
  ///
  /// In es, this message translates to:
  /// **'Escanear texto con la cámara'**
  String get noteScanTooltip;

  /// No description provided for @noteContentHint.
  ///
  /// In es, this message translates to:
  /// **'Comienza a hablar o escribir...'**
  String get noteContentHint;

  /// No description provided for @notePageLabel.
  ///
  /// In es, this message translates to:
  /// **'Página del libro'**
  String get notePageLabel;

  /// No description provided for @noteSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar nota'**
  String get noteSave;

  /// No description provided for @noteSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get noteSaveChanges;

  /// No description provided for @scanSourceTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanear una cita'**
  String get scanSourceTitle;

  /// No description provided for @scanSourcePrivacy.
  ///
  /// In es, this message translates to:
  /// **'El texto se reconoce en tu teléfono: la foto no se envía a ningún sitio.'**
  String get scanSourcePrivacy;

  /// No description provided for @scanSourceCamera.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto de la página'**
  String get scanSourceCamera;

  /// No description provided for @scanSourceGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get scanSourceGallery;

  /// No description provided for @scanTitle.
  ///
  /// In es, this message translates to:
  /// **'Subraya la cita'**
  String get scanTitle;

  /// No description provided for @scanSelectNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguna'**
  String get scanSelectNone;

  /// No description provided for @scanSelectAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get scanSelectAll;

  /// No description provided for @scanModelDownloadingTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparando el lector de texto'**
  String get scanModelDownloadingTitle;

  /// No description provided for @scanModelDownloadingText.
  ///
  /// In es, this message translates to:
  /// **'Google Play lo está descargando (unos 4 MB). Conéctate a internet e inténtalo en unos minutos.'**
  String get scanModelDownloadingText;

  /// No description provided for @scanErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer la foto'**
  String get scanErrorTitle;

  /// No description provided for @scanErrorText.
  ///
  /// In es, this message translates to:
  /// **'Inténtalo de nuevo con otra foto.'**
  String get scanErrorText;

  /// No description provided for @scanReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo la página…'**
  String get scanReading;

  /// No description provided for @scanNoTextTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontré texto'**
  String get scanNoTextTitle;

  /// No description provided for @scanNoTextText.
  ///
  /// In es, this message translates to:
  /// **'Prueba con más luz, la página recta y el texto enfocado.'**
  String get scanNoTextText;

  /// No description provided for @scanZoomIn.
  ///
  /// In es, this message translates to:
  /// **'Acercar'**
  String get scanZoomIn;

  /// No description provided for @scanZoomOut.
  ///
  /// In es, this message translates to:
  /// **'Alejar'**
  String get scanZoomOut;

  /// No description provided for @scanZoomFit.
  ///
  /// In es, this message translates to:
  /// **'Ver la página entera'**
  String get scanZoomFit;

  /// No description provided for @scanHint.
  ///
  /// In es, this message translates to:
  /// **'Desliza un dedo sobre el texto para subrayarlo. Con dos dedos, acerca la foto.'**
  String get scanHint;

  /// No description provided for @scanClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get scanClear;

  /// No description provided for @scanUseQuote.
  ///
  /// In es, this message translates to:
  /// **'Usar cita'**
  String get scanUseQuote;

  /// No description provided for @reviewSummaryDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{en 1 día} other{en {count} días}}'**
  String reviewSummaryDays(int count);

  /// No description provided for @reviewSummaryMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min de lectura'**
  String reviewSummaryMinutes(int minutes);

  /// No description provided for @reviewSummaryHours.
  ///
  /// In es, this message translates to:
  /// **'{hours} h de lectura'**
  String reviewSummaryHours(int hours);

  /// No description provided for @reviewSummaryHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min de lectura'**
  String reviewSummaryHoursMinutes(int hours, int minutes);

  /// No description provided for @reviewSummaryPages.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 página} other{{count} páginas}}'**
  String reviewSummaryPages(int count);

  /// No description provided for @reviewRating1.
  ///
  /// In es, this message translates to:
  /// **'No me gustó'**
  String get reviewRating1;

  /// No description provided for @reviewRating2.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get reviewRating2;

  /// No description provided for @reviewRating3.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get reviewRating3;

  /// No description provided for @reviewRating4.
  ///
  /// In es, this message translates to:
  /// **'Muy bueno'**
  String get reviewRating4;

  /// No description provided for @reviewRating5.
  ///
  /// In es, this message translates to:
  /// **'¡Me encantó!'**
  String get reviewRating5;

  /// No description provided for @reviewSaved.
  ///
  /// In es, this message translates to:
  /// **'Reseña guardada en tus notas ✍️'**
  String get reviewSaved;

  /// No description provided for @reviewDeleted.
  ///
  /// In es, this message translates to:
  /// **'Reseña eliminada'**
  String get reviewDeleted;

  /// No description provided for @reviewRatingSaved.
  ///
  /// In es, this message translates to:
  /// **'Calificación guardada ⭐'**
  String get reviewRatingSaved;

  /// No description provided for @reviewFinishedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Terminaste {title}!'**
  String reviewFinishedTitle(String title);

  /// No description provided for @reviewYourReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu reseña de {title}'**
  String reviewYourReviewTitle(String title);

  /// No description provided for @reviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Reseña de {title}'**
  String reviewTitle(String title);

  /// No description provided for @reviewAbandonedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo dejaste sin terminar'**
  String get reviewAbandonedSubtitle;

  /// No description provided for @reviewHowRate.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo lo calificas?'**
  String get reviewHowRate;

  /// No description provided for @reviewStarsTooltip.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 estrella} other{{count} estrellas}}'**
  String reviewStarsTooltip(int count);

  /// No description provided for @reviewHintAbandoned.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué lo dejaste? (opcional)'**
  String get reviewHintAbandoned;

  /// No description provided for @reviewHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te pareció? Una frase basta (opcional)'**
  String get reviewHint;

  /// No description provided for @reviewNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get reviewNotNow;

  /// No description provided for @quotesGeneratingCard.
  ///
  /// In es, this message translates to:
  /// **'Generando tarjeta...'**
  String get quotesGeneratingCard;

  /// No description provided for @quotesShareText.
  ///
  /// In es, this message translates to:
  /// **'📖 {title}\n✨ Compartido desde Book Tracker'**
  String quotesShareText(String title);

  /// No description provided for @quotesImageError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear la imagen. Inténtalo de nuevo.'**
  String get quotesImageError;

  /// No description provided for @quotesCardPage.
  ///
  /// In es, this message translates to:
  /// **'Página {page}'**
  String quotesCardPage(int page);

  /// No description provided for @quotesCardFooter.
  ///
  /// In es, this message translates to:
  /// **'Leído en Book Tracker'**
  String get quotesCardFooter;

  /// No description provided for @quotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis citas'**
  String get quotesTitle;

  /// No description provided for @quotesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las citas: {error}'**
  String quotesLoadError(String error);

  /// No description provided for @quotesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes citas'**
  String get quotesEmptyTitle;

  /// No description provided for @quotesEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Guarda frases y pensamientos desde la sección \"Notas y Citas\" de cada libro. Aparecerán todas aquí.'**
  String get quotesEmptyDescription;

  /// No description provided for @quotesSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en citas, títulos o autores'**
  String get quotesSearchHint;

  /// No description provided for @quotesClearSearch.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get quotesClearSearch;

  /// No description provided for @quotesFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas ({count})'**
  String quotesFilterAll(int count);

  /// No description provided for @quotesFilterFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritas ({count})'**
  String quotesFilterFavorites(int count);

  /// No description provided for @quotesNoFavorites.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes favoritas.\nToca la ☆ de una cita para guardarla aquí.'**
  String get quotesNoFavorites;

  /// No description provided for @quotesNoMatches.
  ///
  /// In es, this message translates to:
  /// **'Ninguna cita coincide con la búsqueda.'**
  String get quotesNoMatches;

  /// No description provided for @quotesPageShort.
  ///
  /// In es, this message translates to:
  /// **'pág. {page}'**
  String quotesPageShort(int page);

  /// No description provided for @quotesRemoveFavorite.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritas'**
  String get quotesRemoveFavorite;

  /// No description provided for @quotesMarkFavorite.
  ///
  /// In es, this message translates to:
  /// **'Marcar como favorita'**
  String get quotesMarkFavorite;

  /// No description provided for @quotesShareAsImage.
  ///
  /// In es, this message translates to:
  /// **'Compartir como imagen'**
  String get quotesShareAsImage;

  /// No description provided for @quotesCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get quotesCopy;

  /// No description provided for @quotesCopied.
  ///
  /// In es, this message translates to:
  /// **'Cita copiada'**
  String get quotesCopied;

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get statusPending;

  /// No description provided for @statusReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo'**
  String get statusReading;

  /// No description provided for @statusFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminado'**
  String get statusFinished;

  /// No description provided for @statusAbandoned.
  ///
  /// In es, this message translates to:
  /// **'Abandonado'**
  String get statusAbandoned;

  /// No description provided for @homeLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String homeLoadError(String error);

  /// No description provided for @homeTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi biblioteca'**
  String get homeTitle;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu biblioteca está vacía'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Parece un buen momento para empezar una nueva aventura.'**
  String get homeEmptyDescription;

  /// No description provided for @homeAddFirstBook.
  ///
  /// In es, this message translates to:
  /// **'Añadir mi primer libro'**
  String get homeAddFirstBook;

  /// No description provided for @homeNoMatchesTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin coincidencias'**
  String get homeNoMatchesTitle;

  /// No description provided for @homeNoMatchesDescription.
  ///
  /// In es, this message translates to:
  /// **'No encontramos nada que coincida con tus filtros.'**
  String get homeNoMatchesDescription;

  /// No description provided for @homeShowAllBooks.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los libros'**
  String get homeShowAllBooks;

  /// No description provided for @homeSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Título o autor…'**
  String get homeSearchHint;

  /// No description provided for @homeCloseSearch.
  ///
  /// In es, this message translates to:
  /// **'Cerrar búsqueda'**
  String get homeCloseSearch;

  /// No description provided for @homeSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get homeSearch;

  /// No description provided for @homeMyQuotes.
  ///
  /// In es, this message translates to:
  /// **'Mis citas'**
  String get homeMyQuotes;

  /// No description provided for @homeSort.
  ///
  /// In es, this message translates to:
  /// **'Ordenar'**
  String get homeSort;

  /// No description provided for @homeSortTitle.
  ///
  /// In es, this message translates to:
  /// **'Ordenar libros'**
  String get homeSortTitle;

  /// No description provided for @homeSortRecentlyAdded.
  ///
  /// In es, this message translates to:
  /// **'Añadido recientemente'**
  String get homeSortRecentlyAdded;

  /// No description provided for @homeSortMostProgress.
  ///
  /// In es, this message translates to:
  /// **'Mayor progreso'**
  String get homeSortMostProgress;

  /// No description provided for @homeSortLongest.
  ///
  /// In es, this message translates to:
  /// **'Libros más largos'**
  String get homeSortLongest;

  /// No description provided for @homeSortAlphabetical.
  ///
  /// In es, this message translates to:
  /// **'Orden alfabético'**
  String get homeSortAlphabetical;

  /// No description provided for @homeSortShortRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get homeSortShortRecent;

  /// No description provided for @homeSortShortLongest.
  ///
  /// In es, this message translates to:
  /// **'Más largos'**
  String get homeSortShortLongest;

  /// No description provided for @homeSortShortAlphabetical.
  ///
  /// In es, this message translates to:
  /// **'A–Z'**
  String get homeSortShortAlphabetical;

  /// No description provided for @homeFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get homeFilterAll;

  /// No description provided for @homeFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get homeFilterPending;

  /// No description provided for @homeFilterFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminados'**
  String get homeFilterFinished;

  /// No description provided for @homeFilterAbandoned.
  ///
  /// In es, this message translates to:
  /// **'Abandonados'**
  String get homeFilterAbandoned;

  /// No description provided for @homeBookCountSorted.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 libro · {sort}} other{{count} libros · {sort}}}'**
  String homeBookCountSorted(int count, String sort);

  /// No description provided for @homeListView.
  ///
  /// In es, this message translates to:
  /// **'Vista de lista'**
  String get homeListView;

  /// No description provided for @homeGridView.
  ///
  /// In es, this message translates to:
  /// **'Vista de cuadrícula'**
  String get homeGridView;

  /// No description provided for @homeDeleteBookTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar libro?'**
  String get homeDeleteBookTitle;

  /// No description provided for @homeDeleteBookMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta acción borrará \"{title}\" permanentemente.'**
  String homeDeleteBookMessage(String title);

  /// No description provided for @homeQuickStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar a leer'**
  String get homeQuickStart;

  /// No description provided for @homeQuickFinish.
  ///
  /// In es, this message translates to:
  /// **'Terminado'**
  String get homeQuickFinish;

  /// No description provided for @homeQuickResume.
  ///
  /// In es, this message translates to:
  /// **'Retomar'**
  String get homeQuickResume;

  /// No description provided for @homeQuickStartedSnack.
  ///
  /// In es, this message translates to:
  /// **'Empezaste \"{title}\"'**
  String homeQuickStartedSnack(String title);

  /// No description provided for @homeQuickFinishedSnack.
  ///
  /// In es, this message translates to:
  /// **'Terminaste \"{title}\"'**
  String homeQuickFinishedSnack(String title);

  /// No description provided for @homeQuickResumedSnack.
  ///
  /// In es, this message translates to:
  /// **'Retomaste \"{title}\"'**
  String homeQuickResumedSnack(String title);

  /// No description provided for @homeTutorialSearchTitle.
  ///
  /// In es, this message translates to:
  /// **'🔍 Encuentra tus libros'**
  String get homeTutorialSearchTitle;

  /// No description provided for @homeTutorialSearchDescription.
  ///
  /// In es, this message translates to:
  /// **'Busca rápidamente cualquier título o autor en tu colección.'**
  String get homeTutorialSearchDescription;

  /// No description provided for @homeTutorialQuotesTitle.
  ///
  /// In es, this message translates to:
  /// **'❝ Mis citas'**
  String get homeTutorialQuotesTitle;

  /// No description provided for @homeTutorialQuotesDescription.
  ///
  /// In es, this message translates to:
  /// **'Todas las frases y notas de tus libros en un solo lugar: búscalas, marca favoritas y compártelas.'**
  String get homeTutorialQuotesDescription;

  /// No description provided for @homeTutorialSortTitle.
  ///
  /// In es, this message translates to:
  /// **'↕️ Organiza tu biblioteca'**
  String get homeTutorialSortTitle;

  /// No description provided for @homeTutorialSortDescription.
  ///
  /// In es, this message translates to:
  /// **'Ordena tus libros por progreso, tamaño o fecha de añadido.'**
  String get homeTutorialSortDescription;

  /// No description provided for @homeTutorialAddTitle.
  ///
  /// In es, this message translates to:
  /// **'📚 Nueva aventura'**
  String get homeTutorialAddTitle;

  /// No description provided for @homeTutorialAddDescription.
  ///
  /// In es, this message translates to:
  /// **'Toca aquí para registrar un nuevo libro y empezar a leer.'**
  String get homeTutorialAddDescription;

  /// No description provided for @homeContinueInSession.
  ///
  /// In es, this message translates to:
  /// **'SESIÓN EN CURSO'**
  String get homeContinueInSession;

  /// No description provided for @homeContinueStart.
  ///
  /// In es, this message translates to:
  /// **'EMPEZAR A LEER'**
  String get homeContinueStart;

  /// No description provided for @homeContinueReading.
  ///
  /// In es, this message translates to:
  /// **'CONTINUAR LEYENDO'**
  String get homeContinueReading;

  /// No description provided for @homeContinueProgress.
  ///
  /// In es, this message translates to:
  /// **'{percent}% · {read} de {total} páginas'**
  String homeContinueProgress(int percent, int read, int total);

  /// No description provided for @homeContinuePages.
  ///
  /// In es, this message translates to:
  /// **'{pages, plural, =1{1 página} other{{pages} páginas}}'**
  String homeContinuePages(int pages);

  /// No description provided for @homeContinueViewSession.
  ///
  /// In es, this message translates to:
  /// **'Ver la sesión'**
  String get homeContinueViewSession;

  /// No description provided for @navBooks.
  ///
  /// In es, this message translates to:
  /// **'Libros'**
  String get navBooks;

  /// No description provided for @navStats.
  ///
  /// In es, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @navTutorialStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'📊​ Analiza tu progreso'**
  String get navTutorialStatsTitle;

  /// No description provided for @navTutorialStatsDescription.
  ///
  /// In es, this message translates to:
  /// **'Mira estadísticas detalladas sobre tus lecturas.'**
  String get navTutorialStatsDescription;

  /// No description provided for @navTutorialSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'⚙️​ Configuración'**
  String get navTutorialSettingsTitle;

  /// No description provided for @navTutorialSettingsDescription.
  ///
  /// In es, this message translates to:
  /// **'Personaliza el tema y gestiona tus datos.'**
  String get navTutorialSettingsDescription;

  /// No description provided for @onboardingSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// No description provided for @onboardingImportGoodreads.
  ///
  /// In es, this message translates to:
  /// **'Importar de Goodreads'**
  String get onboardingImportGoodreads;

  /// No description provided for @onboardingExploreFirst.
  ///
  /// In es, this message translates to:
  /// **'Explorar primero'**
  String get onboardingExploreFirst;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In es, this message translates to:
  /// **'Tu biblioteca, en un toque'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade libros sin escribir de más.'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage1Point1.
  ///
  /// In es, this message translates to:
  /// **'Escanea el código de barras (ISBN) o escríbelo a mano'**
  String get onboardingPage1Point1;

  /// No description provided for @onboardingPage1Point2.
  ///
  /// In es, this message translates to:
  /// **'Búscalo por título y trae portada y páginas'**
  String get onboardingPage1Point2;

  /// No description provided for @onboardingPage1Point3.
  ///
  /// In es, this message translates to:
  /// **'¿Vienes de Goodreads? Importa toda tu biblioteca'**
  String get onboardingPage1Point3;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In es, this message translates to:
  /// **'Lee con foco'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Mide tus sesiones y ponte una meta.'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage2Point1.
  ///
  /// In es, this message translates to:
  /// **'Cronómetro de lectura que guarda tu página al terminar'**
  String get onboardingPage2Point1;

  /// No description provided for @onboardingPage2Point2.
  ///
  /// In es, this message translates to:
  /// **'Meta por sesión: te aviso al cumplirla, aunque bloquees el teléfono'**
  String get onboardingPage2Point2;

  /// No description provided for @onboardingPage2Point3.
  ///
  /// In es, this message translates to:
  /// **'Widget en tu pantalla de inicio para pausar sin abrir la app'**
  String get onboardingPage2Point3;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In es, this message translates to:
  /// **'Guarda lo que te marca'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus frases favoritas, siempre a mano.'**
  String get onboardingPage3Subtitle;

  /// No description provided for @onboardingPage3Point1.
  ///
  /// In es, this message translates to:
  /// **'Notas y citas con la página, también dictadas por voz'**
  String get onboardingPage3Point1;

  /// No description provided for @onboardingPage3Point2.
  ///
  /// In es, this message translates to:
  /// **'Mis citas: búscalas todas y compártelas como imagen'**
  String get onboardingPage3Point2;

  /// No description provided for @onboardingPage3Point3.
  ///
  /// In es, this message translates to:
  /// **'Califica y escribe tu reseña al terminar cada libro'**
  String get onboardingPage3Point3;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In es, this message translates to:
  /// **'Hazlo hábito'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Pequeños pasos, todos los días.'**
  String get onboardingPage4Subtitle;

  /// No description provided for @onboardingPage4Point1.
  ///
  /// In es, this message translates to:
  /// **'Racha diaria y aviso si está en riesgo'**
  String get onboardingPage4Point1;

  /// No description provided for @onboardingPage4Point2.
  ///
  /// In es, this message translates to:
  /// **'Reto anual: cuántos libros quieres leer este año'**
  String get onboardingPage4Point2;

  /// No description provided for @onboardingPage4Point3.
  ///
  /// In es, this message translates to:
  /// **'Tu año lector en una tarjeta para compartir'**
  String get onboardingPage4Point3;

  /// No description provided for @isbnNotAnIsbn.
  ///
  /// In es, this message translates to:
  /// **'Ese código no es un ISBN. Busca el que empieza por 978 o 979.'**
  String get isbnNotAnIsbn;

  /// No description provided for @isbnScanPrompt.
  ///
  /// In es, this message translates to:
  /// **'Apunta al código de barras de la contraportada'**
  String get isbnScanPrompt;

  /// No description provided for @isbnTypeIsbn.
  ///
  /// In es, this message translates to:
  /// **'Escribir el ISBN'**
  String get isbnTypeIsbn;

  /// No description provided for @isbnWhereIsIt.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde está el ISBN?'**
  String get isbnWhereIsIt;

  /// No description provided for @isbnTorchOn.
  ///
  /// In es, this message translates to:
  /// **'Encender linterna'**
  String get isbnTorchOn;

  /// No description provided for @isbnTorchOff.
  ///
  /// In es, this message translates to:
  /// **'Apagar linterna'**
  String get isbnTorchOff;

  /// No description provided for @isbnCameraPermission.
  ///
  /// In es, this message translates to:
  /// **'Para escanear necesitamos permiso para usar la cámara.'**
  String get isbnCameraPermission;

  /// No description provided for @isbnCameraError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la cámara. Puedes buscar el libro escribiendo su título.'**
  String get isbnCameraError;

  /// No description provided for @isbnOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get isbnOpenSettings;

  /// No description provided for @isbnHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde encuentro el ISBN?'**
  String get isbnHelpTitle;

  /// No description provided for @isbnHelpIntro.
  ///
  /// In es, this message translates to:
  /// **'Es el número que identifica cada edición de un libro.'**
  String get isbnHelpIntro;

  /// No description provided for @isbnHelpBackCoverTitle.
  ///
  /// In es, this message translates to:
  /// **'En la contraportada'**
  String get isbnHelpBackCoverTitle;

  /// No description provided for @isbnHelpBackCoverText.
  ///
  /// In es, this message translates to:
  /// **'Encima o debajo del código de barras, precedido de \"ISBN\". Puedes escanear el código de barras directamente.'**
  String get isbnHelpBackCoverText;

  /// No description provided for @isbnHelpCreditsTitle.
  ///
  /// In es, this message translates to:
  /// **'En la página de créditos'**
  String get isbnHelpCreditsTitle;

  /// No description provided for @isbnHelpCreditsText.
  ///
  /// In es, this message translates to:
  /// **'Una de las primeras páginas del libro (donde aparecen la editorial y los derechos de autor).'**
  String get isbnHelpCreditsText;

  /// No description provided for @isbnHelpDigitsTitle.
  ///
  /// In es, this message translates to:
  /// **'13 o 10 dígitos'**
  String get isbnHelpDigitsTitle;

  /// No description provided for @isbnHelpDigitsText.
  ///
  /// In es, this message translates to:
  /// **'Desde 2007 tiene 13 dígitos y empieza por 978 o 979. Los libros más antiguos usan 10 dígitos, y el último puede ser una X. Puedes escribirlo con o sin guiones.'**
  String get isbnHelpDigitsText;

  /// No description provided for @isbnPartPrefix.
  ///
  /// In es, this message translates to:
  /// **'Prefijo'**
  String get isbnPartPrefix;

  /// No description provided for @isbnPartCountry.
  ///
  /// In es, this message translates to:
  /// **'País o idioma'**
  String get isbnPartCountry;

  /// No description provided for @isbnPartPublisher.
  ///
  /// In es, this message translates to:
  /// **'Editorial'**
  String get isbnPartPublisher;

  /// No description provided for @isbnPartBook.
  ///
  /// In es, this message translates to:
  /// **'Libro'**
  String get isbnPartBook;

  /// No description provided for @isbnPartCheck.
  ///
  /// In es, this message translates to:
  /// **'Control'**
  String get isbnPartCheck;

  /// No description provided for @isbnLengthError.
  ///
  /// In es, this message translates to:
  /// **'Debe tener 10 o 13 dígitos (llevas {count})'**
  String isbnLengthError(int count);

  /// No description provided for @isbnChecksumError.
  ///
  /// In es, this message translates to:
  /// **'Revisa los números: el último dígito no coincide'**
  String get isbnChecksumError;

  /// No description provided for @isbnManualTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el ISBN'**
  String get isbnManualTitle;

  /// No description provided for @isbnManualHelper.
  ///
  /// In es, this message translates to:
  /// **'13 dígitos (empieza por 978 o 979) o 10 dígitos en libros antiguos.'**
  String get isbnManualHelper;

  /// No description provided for @isbnManualWhere.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde lo encuentro?'**
  String get isbnManualWhere;

  /// No description provided for @isbnManualSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get isbnManualSearch;

  /// No description provided for @addBookTooltip.
  ///
  /// In es, this message translates to:
  /// **'Añadir libro'**
  String get addBookTooltip;

  /// No description provided for @addBookIsbnNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos el ISBN {isbn}. Escribe los datos a mano.'**
  String addBookIsbnNotFound(String isbn);

  /// No description provided for @addBookIsbnFound.
  ///
  /// In es, this message translates to:
  /// **'Encontrado por ISBN {isbn}'**
  String addBookIsbnFound(String isbn);

  /// No description provided for @addBookIsbnSearchFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo buscar el ISBN. Escribe los datos a mano.'**
  String get addBookIsbnSearchFailed;

  /// No description provided for @addBookTitleRequired.
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio'**
  String get addBookTitleRequired;

  /// No description provided for @addBookAuthorRequired.
  ///
  /// In es, this message translates to:
  /// **'El autor es obligatorio'**
  String get addBookAuthorRequired;

  /// No description provided for @addBookMaxChars.
  ///
  /// In es, this message translates to:
  /// **'Máximo {max} caracteres'**
  String addBookMaxChars(int max);

  /// No description provided for @addBookPagesRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica las páginas'**
  String get addBookPagesRequired;

  /// No description provided for @addBookInvalidNumber.
  ///
  /// In es, this message translates to:
  /// **'Número no válido'**
  String get addBookInvalidNumber;

  /// No description provided for @addBookAlreadyRead.
  ///
  /// In es, this message translates to:
  /// **'Ya leíste {pages}'**
  String addBookAlreadyRead(int pages);

  /// No description provided for @addBookChangeCover.
  ///
  /// In es, this message translates to:
  /// **'Cambiar portada'**
  String get addBookChangeCover;

  /// No description provided for @addBookCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get addBookCamera;

  /// No description provided for @addBookGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get addBookGallery;

  /// No description provided for @addBookSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el libro. Inténtalo de nuevo.'**
  String get addBookSaveError;

  /// No description provided for @addBookScanBarcode.
  ///
  /// In es, this message translates to:
  /// **'Escanear código de barras'**
  String get addBookScanBarcode;

  /// No description provided for @addBookTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título del libro'**
  String get addBookTitleLabel;

  /// No description provided for @addBookAuthorLabel.
  ///
  /// In es, this message translates to:
  /// **'Autor'**
  String get addBookAuthorLabel;

  /// No description provided for @addBookDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles del libro'**
  String get addBookDetails;

  /// No description provided for @addBookCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get addBookCategoryLabel;

  /// No description provided for @addBookPagesLabel.
  ///
  /// In es, this message translates to:
  /// **'Páginas'**
  String get addBookPagesLabel;

  /// No description provided for @addBookReadingStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado de lectura'**
  String get addBookReadingStatus;

  /// No description provided for @addBookAddToCollection.
  ///
  /// In es, this message translates to:
  /// **'Añadir a la Colección'**
  String get addBookAddToCollection;

  /// No description provided for @addBookUpdateLibrary.
  ///
  /// In es, this message translates to:
  /// **'Actualizar Biblioteca'**
  String get addBookUpdateLibrary;

  /// No description provided for @addBookStatusRead.
  ///
  /// In es, this message translates to:
  /// **'Leído'**
  String get addBookStatusRead;

  /// No description provided for @addBookStatusDnf.
  ///
  /// In es, this message translates to:
  /// **'DNF'**
  String get addBookStatusDnf;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar libro (título, autor o ISBN)'**
  String get searchHint;

  /// No description provided for @searchFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo buscar. Puedes escribir los datos a mano.'**
  String get searchFailed;

  /// No description provided for @searchIsbnNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos el ISBN {isbn}. Revisa el número o escribe los datos a mano.'**
  String searchIsbnNotFound(String isbn);

  /// No description provided for @searchNotFound.
  ///
  /// In es, this message translates to:
  /// **'No lo encontramos. Escribe los datos a mano.'**
  String get searchNotFound;

  /// No description provided for @searchIsbnResult.
  ///
  /// In es, this message translates to:
  /// **'Resultado por ISBN {isbn}'**
  String searchIsbnResult(String isbn);

  /// No description provided for @searchPageCount.
  ///
  /// In es, this message translates to:
  /// **'{count} pág.'**
  String searchPageCount(int count);

  /// No description provided for @bookCardStatusReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo · {percent}%'**
  String bookCardStatusReading(int percent);

  /// No description provided for @bookCardStatusAbandoned.
  ///
  /// In es, this message translates to:
  /// **'Abandonado · {read}/{total} p.'**
  String bookCardStatusAbandoned(int read, int total);

  /// No description provided for @bookCardStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente · {total} p.'**
  String bookCardStatusPending(int total);

  /// No description provided for @bookCardEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get bookCardEdit;

  /// No description provided for @notifChannelRemindersName.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de Lectura'**
  String get notifChannelRemindersName;

  /// No description provided for @notifChannelRemindersDescription.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones diarias para fomentar la lectura'**
  String get notifChannelRemindersDescription;

  /// No description provided for @notifChannelSessionName.
  ///
  /// In es, this message translates to:
  /// **'Meta de la sesión'**
  String get notifChannelSessionName;

  /// No description provided for @notifChannelSessionDescription.
  ///
  /// In es, this message translates to:
  /// **'Aviso cuando cumples la meta de tiempo de una sesión de lectura'**
  String get notifChannelSessionDescription;

  /// No description provided for @notifChannelStreakName.
  ///
  /// In es, this message translates to:
  /// **'Racha en riesgo'**
  String get notifChannelStreakName;

  /// No description provided for @notifChannelStreakDescription.
  ///
  /// In es, this message translates to:
  /// **'Aviso cuando llevas racha y aún no has leído hoy'**
  String get notifChannelStreakDescription;

  /// No description provided for @notifDailyTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Hora de leer!'**
  String get notifDailyTitle;

  /// No description provided for @notifDailyBody.
  ///
  /// In es, this message translates to:
  /// **'Tu racha te espera. Abre un libro y relájate un momento.'**
  String get notifDailyBody;

  /// No description provided for @notifSessionGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'🎯 ¡Meta de {minutes} min cumplida!'**
  String notifSessionGoalTitle(int minutes);

  /// No description provided for @notifSessionGoalBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes seguir leyendo o terminar la sesión y guardar tu página.'**
  String get notifSessionGoalBody;

  /// No description provided for @notifTestTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Prueba de Lectura! 📖'**
  String get notifTestTitle;

  /// No description provided for @notifTestBody.
  ///
  /// In es, this message translates to:
  /// **'Esto es una notificación instantánea para verificar que todo funciona.'**
  String get notifTestBody;

  /// No description provided for @widgetEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Añade tu primer libro'**
  String get widgetEmptyTitle;

  /// No description provided for @widgetEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Toca para empezar'**
  String get widgetEmptySubtitle;

  /// No description provided for @widgetSessionReading.
  ///
  /// In es, this message translates to:
  /// **'LEYENDO'**
  String get widgetSessionReading;

  /// No description provided for @widgetSessionPaused.
  ///
  /// In es, this message translates to:
  /// **'EN PAUSA'**
  String get widgetSessionPaused;

  /// No description provided for @widgetPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get widgetPause;

  /// No description provided for @widgetResume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get widgetResume;

  /// No description provided for @widgetFinish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get widgetFinish;

  /// No description provided for @widgetFinishDescription.
  ///
  /// In es, this message translates to:
  /// **'Finalizar la sesión'**
  String get widgetFinishDescription;

  /// No description provided for @widgetCover.
  ///
  /// In es, this message translates to:
  /// **'Portada'**
  String get widgetCover;

  /// No description provided for @widgetToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy {minutes} min'**
  String widgetToday(String minutes);

  /// No description provided for @widgetTodayGoal.
  ///
  /// In es, this message translates to:
  /// **'Hoy {minutes}/{goal} min'**
  String widgetTodayGoal(String minutes, String goal);

  /// No description provided for @widgetPagesInfo.
  ///
  /// In es, this message translates to:
  /// **'{read}/{total} pág.'**
  String widgetPagesInfo(int read, int total);

  /// No description provided for @widgetStatusToRead.
  ///
  /// In es, this message translates to:
  /// **'Por leer'**
  String get widgetStatusToRead;

  /// No description provided for @widgetStatusReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo'**
  String get widgetStatusReading;

  /// No description provided for @widgetStatusFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminado'**
  String get widgetStatusFinished;

  /// No description provided for @widgetStatusAbandoned.
  ///
  /// In es, this message translates to:
  /// **'Abandonado'**
  String get widgetStatusAbandoned;

  /// No description provided for @backupSvcReadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el archivo.'**
  String get backupSvcReadFailed;

  /// No description provided for @backupSvcZipDamaged.
  ///
  /// In es, this message translates to:
  /// **'El archivo .zip está dañado.'**
  String get backupSvcZipDamaged;

  /// No description provided for @backupSvcZipNotBackup.
  ///
  /// In es, this message translates to:
  /// **'Este .zip no es un respaldo de Book Tracker.'**
  String get backupSvcZipNotBackup;

  /// No description provided for @backupSvcNotBackup.
  ///
  /// In es, this message translates to:
  /// **'El archivo no es un respaldo de Book Tracker.'**
  String get backupSvcNotBackup;

  /// No description provided for @backupSvcUnknownFormat.
  ///
  /// In es, this message translates to:
  /// **'El respaldo tiene un formato desconocido.'**
  String get backupSvcUnknownFormat;

  /// No description provided for @backupSvcNewerVersion.
  ///
  /// In es, this message translates to:
  /// **'Este respaldo es de una versión más nueva de la app. Actualízala y vuelve a intentarlo.'**
  String get backupSvcNewerVersion;

  /// No description provided for @backupSvcNoBooks.
  ///
  /// In es, this message translates to:
  /// **'El respaldo está incompleto: no contiene libros.'**
  String get backupSvcNoBooks;

  /// No description provided for @backupSvcDamagedBook.
  ///
  /// In es, this message translates to:
  /// **'El respaldo tiene datos dañados (libro {number}). No se cambió nada.'**
  String backupSvcDamagedBook(int number);

  /// No description provided for @backupSvcCoversFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron copiar las portadas. No se cambió nada.'**
  String get backupSvcCoversFailed;

  /// No description provided for @backupSvcRestoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo restaurar el respaldo. Tu biblioteca no cambió.'**
  String get backupSvcRestoreFailed;

  /// No description provided for @exportShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Mi biblioteca de Book Tracker'**
  String get exportShareSubject;

  /// No description provided for @importFileEmpty.
  ///
  /// In es, this message translates to:
  /// **'El archivo está vacío.'**
  String get importFileEmpty;

  /// No description provided for @importNotGoodreads.
  ///
  /// In es, this message translates to:
  /// **'Este archivo no parece una exportación de Goodreads. Descárgala desde goodreads.com → Mis libros → Importar y exportar → Exportar biblioteca.'**
  String get importNotGoodreads;

  /// No description provided for @importUnknownAuthor.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get importUnknownAuthor;

  /// No description provided for @bookApiRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Demasiadas búsquedas seguidas. Inténtalo en un minuto.'**
  String get bookApiRateLimit;

  /// No description provided for @bookApiNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Puedes escribir los datos a mano.'**
  String get bookApiNetwork;

  /// No description provided for @bookApiServer.
  ///
  /// In es, this message translates to:
  /// **'El buscador no respondió. Inténtalo de nuevo.'**
  String get bookApiServer;

  /// No description provided for @bookApiUnknownAuthor.
  ///
  /// In es, this message translates to:
  /// **'Autor desconocido'**
  String get bookApiUnknownAuthor;

  /// No description provided for @purchaseStartFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar la compra.'**
  String get purchaseStartFailed;

  /// No description provided for @purchaseNotCompleted.
  ///
  /// In es, this message translates to:
  /// **'La compra no se completó.'**
  String get purchaseNotCompleted;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsReminderTimeHelp.
  ///
  /// In es, this message translates to:
  /// **'Hora del recordatorio'**
  String get settingsReminderTimeHelp;

  /// No description provided for @settingsStreakRiskTimeHelp.
  ///
  /// In es, this message translates to:
  /// **'Hora del aviso de racha'**
  String get settingsStreakRiskTimeHelp;

  /// No description provided for @settingsPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'¡No pierdas el hilo!'**
  String get settingsPermissionTitle;

  /// No description provided for @settingsPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Activamos recordatorios diarios para ayudarte a mantener tu racha de lectura y alcanzar tus metas. ¡Tu refugio digital te espera!'**
  String get settingsPermissionBody;

  /// No description provided for @settingsNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get settingsNotNow;

  /// No description provided for @settingsPermissionAccept.
  ///
  /// In es, this message translates to:
  /// **'¡Claro que sí!'**
  String get settingsPermissionAccept;

  /// No description provided for @settingsGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get settingsGotIt;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'APARIENCIA'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tema de la aplicación'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeFollowSystem.
  ///
  /// In es, this message translates to:
  /// **'Seguir sistema'**
  String get settingsThemeFollowSystem;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Modo Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Modo Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsColorsTitle.
  ///
  /// In es, this message translates to:
  /// **'Colores'**
  String get settingsColorsTitle;

  /// No description provided for @settingsColorsWallpaper.
  ///
  /// In es, this message translates to:
  /// **'Del fondo de pantalla'**
  String get settingsColorsWallpaper;

  /// No description provided for @settingsColorsBrandDescription.
  ///
  /// In es, this message translates to:
  /// **'Crema y verde abeto de día, ciruela y ámbar de noche.'**
  String get settingsColorsBrandDescription;

  /// No description provided for @settingsColorsWallpaperDescription.
  ///
  /// In es, this message translates to:
  /// **'Material You: los colores de tu fondo de pantalla.'**
  String get settingsColorsWallpaperDescription;

  /// No description provided for @settingsColorsUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible en Android 12 o superior.'**
  String get settingsColorsUnavailable;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In es, this message translates to:
  /// **'PREFERENCIAS'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsDailyNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones diarias'**
  String get settingsDailyNotificationsTitle;

  /// No description provided for @settingsDailyReminderAt.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio a las {time}'**
  String settingsDailyReminderAt(String time);

  /// No description provided for @settingsDailyNotificationsOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivadas'**
  String get settingsDailyNotificationsOff;

  /// No description provided for @settingsOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get settingsOff;

  /// No description provided for @settingsStreakRiskTitle.
  ///
  /// In es, this message translates to:
  /// **'Aviso de racha en riesgo'**
  String get settingsStreakRiskTitle;

  /// No description provided for @settingsStreakRiskNoPermission.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Falta el permiso de notificaciones. Toca para activarlo.'**
  String get settingsStreakRiskNoPermission;

  /// No description provided for @settingsStreakRiskSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Si llevas racha y hoy no has leído, te aviso a las {time}'**
  String settingsStreakRiskSubtitle(String time);

  /// No description provided for @settingsStreakRiskNeedsPermission.
  ///
  /// In es, this message translates to:
  /// **'Activa las notificaciones de Book Tracker para recibir el aviso.'**
  String get settingsStreakRiskNeedsPermission;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In es, this message translates to:
  /// **'SEGURIDAD'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsAppLockTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo de la app'**
  String get settingsAppLockTitle;

  /// No description provided for @settingsAppLockOn.
  ///
  /// In es, this message translates to:
  /// **'Pide tu palabra secreta al abrir'**
  String get settingsAppLockOn;

  /// No description provided for @settingsAppLockOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivado: la app abre directamente'**
  String get settingsAppLockOff;

  /// No description provided for @settingsChangePassphraseTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar palabra secreta'**
  String get settingsChangePassphraseTitle;

  /// No description provided for @settingsChangePassphraseSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu \"Santo y Seña\" para entrar'**
  String get settingsChangePassphraseSubtitle;

  /// No description provided for @settingsChangePin.
  ///
  /// In es, this message translates to:
  /// **'Cambiar PIN de respaldo'**
  String get settingsChangePin;

  /// No description provided for @settingsSetUpPin.
  ///
  /// In es, this message translates to:
  /// **'Configurar PIN de respaldo'**
  String get settingsSetUpPin;

  /// No description provided for @settingsPinSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un código de 4 dígitos por si no recuerdas la palabra'**
  String get settingsPinSubtitle;

  /// No description provided for @settingsAutoLockTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloquear al salir'**
  String get settingsAutoLockTitle;

  /// No description provided for @settingsAutoLockNever.
  ///
  /// In es, this message translates to:
  /// **'Nunca: solo al abrir la app'**
  String get settingsAutoLockNever;

  /// No description provided for @settingsAutoLockAfter.
  ///
  /// In es, this message translates to:
  /// **'Tras {minutes} min fuera de la app'**
  String settingsAutoLockAfter(int minutes);

  /// No description provided for @settingsAutoLockDescription.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a pedir tu palabra si sales de la app durante este tiempo. Al desbloquear sigues donde estabas.'**
  String get settingsAutoLockDescription;

  /// No description provided for @settingsAutoLockNeverOption.
  ///
  /// In es, this message translates to:
  /// **'Nunca'**
  String get settingsAutoLockNeverOption;

  /// No description provided for @settingsAutoLockAfterOption.
  ///
  /// In es, this message translates to:
  /// **'Tras {minutes} min'**
  String settingsAutoLockAfterOption(int minutes);

  /// No description provided for @settingsLockEnabled.
  ///
  /// In es, this message translates to:
  /// **'🔒 Bloqueo activado'**
  String get settingsLockEnabled;

  /// No description provided for @settingsLockDisabled.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo desactivado'**
  String get settingsLockDisabled;

  /// No description provided for @settingsPassphraseUpdated.
  ///
  /// In es, this message translates to:
  /// **'✨ Palabra secreta actualizada'**
  String get settingsPassphraseUpdated;

  /// No description provided for @settingsPinSaved.
  ///
  /// In es, this message translates to:
  /// **'PIN de respaldo guardado'**
  String get settingsPinSaved;

  /// No description provided for @settingsSectionData.
  ///
  /// In es, this message translates to:
  /// **'DATOS'**
  String get settingsSectionData;

  /// No description provided for @settingsExportTitle.
  ///
  /// In es, this message translates to:
  /// **'Respaldar o exportar'**
  String get settingsExportTitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda una copia de tus libros, notas y portadas'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsExportFullTitle.
  ///
  /// In es, this message translates to:
  /// **'Respaldo completo (.zip)'**
  String get settingsExportFullTitle;

  /// No description provided for @settingsExportFullSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todo, con portadas. Sirve para restaurar en otro teléfono.'**
  String get settingsExportFullSubtitle;

  /// No description provided for @settingsExportJsonTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos sin portadas (JSON)'**
  String get settingsExportJsonTitle;

  /// No description provided for @settingsExportJsonSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Libros, notas y sesiones de lectura.'**
  String get settingsExportJsonSubtitle;

  /// No description provided for @settingsExportCsvTitle.
  ///
  /// In es, this message translates to:
  /// **'Hoja de cálculo (CSV)'**
  String get settingsExportCsvTitle;

  /// No description provided for @settingsExportCsvSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lista de libros para Excel o Google Sheets.'**
  String get settingsExportCsvSubtitle;

  /// No description provided for @settingsExportEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu biblioteca está vacía: el archivo no tiene libros.'**
  String get settingsExportEmpty;

  /// No description provided for @settingsExportError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo exportar. Inténtalo de nuevo.'**
  String get settingsExportError;

  /// No description provided for @settingsRestoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar respaldo'**
  String get settingsRestoreTitle;

  /// No description provided for @settingsRestoreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Desde un respaldo .zip o una exportación .json'**
  String get settingsRestoreSubtitle;

  /// No description provided for @settingsGoodreadsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade tus libros desde el archivo .csv de Goodreads'**
  String get settingsGoodreadsSubtitle;

  /// No description provided for @settingsUndoRestoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Deshacer la última restauración'**
  String get settingsUndoRestoreTitle;

  /// No description provided for @settingsUndoRestoreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a la biblioteca que tenías antes'**
  String get settingsUndoRestoreSubtitle;

  /// No description provided for @settingsSectionNoAds.
  ///
  /// In es, this message translates to:
  /// **'SIN ANUNCIOS'**
  String get settingsSectionNoAds;

  /// No description provided for @settingsSectionWhatsNew.
  ///
  /// In es, this message translates to:
  /// **'NOVEDADES'**
  String get settingsSectionWhatsNew;

  /// No description provided for @settingsVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsReleaseNotesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo nuevo en la versión {version} y anteriores'**
  String settingsReleaseNotesSubtitle(String version);

  /// No description provided for @settingsReplayWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Ver la bienvenida de nuevo'**
  String get settingsReplayWelcomeTitle;

  /// No description provided for @settingsReplayWelcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Repasa lo que puedes hacer en Book Tracker'**
  String get settingsReplayWelcomeSubtitle;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In es, this message translates to:
  /// **'SOPORTE'**
  String get settingsSectionSupport;

  /// No description provided for @settingsAdPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Opciones de privacidad de anuncios'**
  String get settingsAdPrivacyTitle;

  /// No description provided for @settingsAdPrivacySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cambia tu consentimiento para anuncios personalizados'**
  String get settingsAdPrivacySubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In es, this message translates to:
  /// **'Acerca de la App'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu refugio de lectura digital'**
  String get aboutTagline;

  /// No description provided for @aboutVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get aboutVersion;

  /// No description provided for @aboutDeveloper.
  ///
  /// In es, this message translates to:
  /// **'Desarrollador'**
  String get aboutDeveloper;

  /// No description provided for @aboutLicense.
  ///
  /// In es, this message translates to:
  /// **'Licencia'**
  String get aboutLicense;

  /// No description provided for @aboutFooter.
  ///
  /// In es, this message translates to:
  /// **'© 2026 - Hecho con ❤️ para lectores'**
  String get aboutFooter;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay una versión nueva'**
  String get updateAvailableTitle;

  /// No description provided for @updateTapToUpdate.
  ///
  /// In es, this message translates to:
  /// **'Toca para actualizar'**
  String get updateTapToUpdate;

  /// No description provided for @updateDownloadingTitle.
  ///
  /// In es, this message translates to:
  /// **'Descargando actualización…'**
  String get updateDownloadingTitle;

  /// No description provided for @updateKeepUsing.
  ///
  /// In es, this message translates to:
  /// **'Puedes seguir usando la app'**
  String get updateKeepUsing;

  /// No description provided for @updateReadyTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualización lista'**
  String get updateReadyTitle;

  /// No description provided for @updateTapToRestart.
  ///
  /// In es, this message translates to:
  /// **'Toca para reiniciar e instalarla'**
  String get updateTapToRestart;

  /// No description provided for @updateCheckingTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscando actualizaciones…'**
  String get updateCheckingTitle;

  /// No description provided for @updateCheckTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar actualizaciones'**
  String get updateCheckTitle;

  /// No description provided for @updateUpToDateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Versión {version} · Estás al día'**
  String updateUpToDateSubtitle(String version);

  /// No description provided for @updateDownloaded.
  ///
  /// In es, this message translates to:
  /// **'Actualización descargada'**
  String get updateDownloaded;

  /// No description provided for @updateRestart.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get updateRestart;

  /// No description provided for @updateDownloadingNew.
  ///
  /// In es, this message translates to:
  /// **'Descargando la versión nueva…'**
  String get updateDownloadingNew;

  /// No description provided for @updateLatest.
  ///
  /// In es, this message translates to:
  /// **'Tienes la última versión'**
  String get updateLatest;

  /// No description provided for @updateCheckFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo comprobar. Las actualizaciones llegan desde Google Play.'**
  String get updateCheckFailed;

  /// No description provided for @updatePromptBody.
  ///
  /// In es, this message translates to:
  /// **'Actualiza para tener las últimas mejoras. Se descarga mientras sigues usando la app.'**
  String get updatePromptBody;

  /// No description provided for @updateButton.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get updateButton;

  /// No description provided for @backupPreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando el respaldo…'**
  String get backupPreparing;

  /// No description provided for @backupShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Respaldo de Book Tracker'**
  String get backupShareSubject;

  /// No description provided for @backupCreateError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear el respaldo. Inténtalo de nuevo.'**
  String get backupCreateError;

  /// No description provided for @backupPickTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige tu respaldo'**
  String get backupPickTitle;

  /// No description provided for @backupReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo el respaldo…'**
  String get backupReading;

  /// No description provided for @backupRestoring.
  ///
  /// In es, this message translates to:
  /// **'Restaurando tu biblioteca…'**
  String get backupRestoring;

  /// No description provided for @backupBooksCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 libro} other{{count} libros}}'**
  String backupBooksCount(int count);

  /// No description provided for @backupNotesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 nota} other{{count} notas}}'**
  String backupNotesCount(int count);

  /// No description provided for @backupSessionsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 sesión de lectura} other{{count} sesiones de lectura}}'**
  String backupSessionsCount(int count);

  /// No description provided for @backupCoversCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin portadas} =1{1 portada} other{{count} portadas}}'**
  String backupCoversCount(int count);

  /// No description provided for @backupUndoDone.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca anterior recuperada: {books}.'**
  String backupUndoDone(String books);

  /// No description provided for @backupRestoreDone.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca restaurada: {books}, {notes}.'**
  String backupRestoreDone(String books, String notes);

  /// No description provided for @backupRestoreError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo restaurar el respaldo. Tu biblioteca no cambió.'**
  String get backupRestoreError;

  /// No description provided for @backupUndoConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Deshacer la última restauración?'**
  String get backupUndoConfirmTitle;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Restaurar este respaldo?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupSavedOn.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca guardada el {date}'**
  String backupSavedOn(String date);

  /// No description provided for @backupFrom.
  ///
  /// In es, this message translates to:
  /// **'Respaldo del {date}'**
  String backupFrom(String date);

  /// No description provided for @backupReplaceWarning.
  ///
  /// In es, this message translates to:
  /// **'Reemplazará tu biblioteca actual ({books}). Antes guardaremos una copia para que puedas deshacerlo.'**
  String backupReplaceWarning(String books);

  /// No description provided for @backupUndoButton.
  ///
  /// In es, this message translates to:
  /// **'DESHACER'**
  String get backupUndoButton;

  /// No description provided for @backupRestoreButton.
  ///
  /// In es, this message translates to:
  /// **'RESTAURAR'**
  String get backupRestoreButton;

  /// No description provided for @backupErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar'**
  String get backupErrorTitle;

  /// No description provided for @goodreadsImportTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar de Goodreads'**
  String get goodreadsImportTitle;

  /// No description provided for @goodreadsPickTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige el CSV de Goodreads'**
  String get goodreadsPickTitle;

  /// No description provided for @goodreadsFileTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El archivo es demasiado grande para ser una exportación de Goodreads.'**
  String get goodreadsFileTooLarge;

  /// No description provided for @goodreadsReadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el archivo'**
  String get goodreadsReadErrorTitle;

  /// No description provided for @goodreadsReadErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Asegúrate de elegir el archivo .csv que descargaste de Goodreads.'**
  String get goodreadsReadErrorBody;

  /// No description provided for @goodreadsNothingNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada nuevo que importar'**
  String get goodreadsNothingNewTitle;

  /// No description provided for @goodreadsAllDuplicates.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{El libro del archivo ya está en tu biblioteca.} other{Los {count} libros del archivo ya están en tu biblioteca.}}'**
  String goodreadsAllDuplicates(int count);

  /// No description provided for @goodreadsNoBooks.
  ///
  /// In es, this message translates to:
  /// **'El archivo no tiene libros.'**
  String get goodreadsNoBooks;

  /// No description provided for @goodreadsImportErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo importar'**
  String get goodreadsImportErrorTitle;

  /// No description provided for @goodreadsImportErrorBody.
  ///
  /// In es, this message translates to:
  /// **'No se añadió ningún libro. Inténtalo de nuevo.'**
  String get goodreadsImportErrorBody;

  /// No description provided for @goodreadsImported.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 libro importado de Goodreads 📚} other{{count} libros importados de Goodreads 📚}}'**
  String goodreadsImported(int count);

  /// No description provided for @goodreadsUndo.
  ///
  /// In es, this message translates to:
  /// **'DESHACER'**
  String get goodreadsUndo;

  /// No description provided for @goodreadsUndone.
  ///
  /// In es, this message translates to:
  /// **'Importación deshecha'**
  String get goodreadsUndone;

  /// No description provided for @goodreadsNoCovers.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron portadas en Open Library. Puedes añadirlas editando cada libro.'**
  String get goodreadsNoCovers;

  /// No description provided for @goodreadsCoversFound.
  ///
  /// In es, this message translates to:
  /// **'Portadas encontradas: {found} de {total}.'**
  String goodreadsCoversFound(int found, int total);

  /// No description provided for @goodreadsHowToIntro.
  ///
  /// In es, this message translates to:
  /// **'Primero descarga tu biblioteca desde Goodreads:'**
  String get goodreadsHowToIntro;

  /// No description provided for @goodreadsHowToStep1.
  ///
  /// In es, this message translates to:
  /// **'1. Entra a goodreads.com en el navegador (la app de Goodreads no permite exportar).'**
  String get goodreadsHowToStep1;

  /// No description provided for @goodreadsHowToStep2.
  ///
  /// In es, this message translates to:
  /// **'2. Ve a Mis libros → Importar y exportar (Import and export).'**
  String get goodreadsHowToStep2;

  /// No description provided for @goodreadsHowToStep3.
  ///
  /// In es, this message translates to:
  /// **'3. Toca \"Exportar biblioteca\" (Export Library) y descarga el archivo .csv cuando esté listo.'**
  String get goodreadsHowToStep3;

  /// No description provided for @goodreadsHowToNote.
  ///
  /// In es, this message translates to:
  /// **'Tus libros actuales no se borran: solo se añaden los que faltan.'**
  String get goodreadsHowToNote;

  /// No description provided for @goodreadsChooseFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get goodreadsChooseFile;

  /// No description provided for @goodreadsCountRead.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 leído} other{{count} leídos}}'**
  String goodreadsCountRead(int count);

  /// No description provided for @goodreadsCountReading.
  ///
  /// In es, this message translates to:
  /// **'{count} leyendo'**
  String goodreadsCountReading(int count);

  /// No description provided for @goodreadsCountToRead.
  ///
  /// In es, this message translates to:
  /// **'{count} por leer'**
  String goodreadsCountToRead(int count);

  /// No description provided for @goodreadsCountAbandoned.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 abandonado} other{{count} abandonados}}'**
  String goodreadsCountAbandoned(int count);

  /// No description provided for @goodreadsCountNotes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 reseña o nota (se guarda como nota)} other{{count} reseñas y notas (se guardan como notas)}}'**
  String goodreadsCountNotes(int count);

  /// No description provided for @goodreadsConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{¿Importar 1 libro?} other{¿Importar {count} libros?}}'**
  String goodreadsConfirmTitle(int count);

  /// No description provided for @goodreadsSkippedDuplicates.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se omite 1 que ya está en tu biblioteca.} other{Se omiten {count} que ya están en tu biblioteca.}}'**
  String goodreadsSkippedDuplicates(int count);

  /// No description provided for @goodreadsSkippedInvalid.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se omite 1 fila sin título.} other{Se omiten {count} filas sin título.}}'**
  String goodreadsSkippedInvalid(int count);

  /// No description provided for @goodreadsNoReadingTime.
  ///
  /// In es, this message translates to:
  /// **'Goodreads no guarda el tiempo de lectura, así que la racha y el mapa de calor no cambian. Los leídos con fecha cuentan en el reto de su año.'**
  String get goodreadsNoReadingTime;

  /// No description provided for @goodreadsFetchCovers.
  ///
  /// In es, this message translates to:
  /// **'Buscar portadas'**
  String get goodreadsFetchCovers;

  /// No description provided for @goodreadsFetchCoversSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 libro con ISBN · usa internet} other{{count} libros con ISBN · usa internet}}'**
  String goodreadsFetchCoversSubtitle(int count);

  /// No description provided for @goodreadsImportButton.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get goodreadsImportButton;

  /// No description provided for @authCreatePassphraseTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu Santo y Seña'**
  String get authCreatePassphraseTitle;

  /// No description provided for @secretNewPassphraseTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva palabra secreta'**
  String get secretNewPassphraseTitle;

  /// No description provided for @secretPinTitle.
  ///
  /// In es, this message translates to:
  /// **'PIN de respaldo'**
  String get secretPinTitle;

  /// No description provided for @secretConfirmIdentity.
  ///
  /// In es, this message translates to:
  /// **'Confirma que eres tú'**
  String get secretConfirmIdentity;

  /// No description provided for @secretPinLengthError.
  ///
  /// In es, this message translates to:
  /// **'Deben ser {length} dígitos'**
  String secretPinLengthError(int length);

  /// No description provided for @secretMinLengthError.
  ///
  /// In es, this message translates to:
  /// **'Al menos 3 caracteres'**
  String get secretMinLengthError;

  /// No description provided for @secretMismatch.
  ///
  /// In es, this message translates to:
  /// **'No coinciden'**
  String get secretMismatch;

  /// No description provided for @secretCaseHint.
  ///
  /// In es, this message translates to:
  /// **'No distingue mayúsculas. Elige algo que recuerdes.'**
  String get secretCaseHint;

  /// No description provided for @secretNewPinLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo PIN'**
  String get secretNewPinLabel;

  /// No description provided for @secretPassphraseLabel.
  ///
  /// In es, this message translates to:
  /// **'Palabra secreta'**
  String get secretPassphraseLabel;

  /// No description provided for @secretRepeatPin.
  ///
  /// In es, this message translates to:
  /// **'Repite el PIN'**
  String get secretRepeatPin;

  /// No description provided for @secretRepeatPassphrase.
  ///
  /// In es, this message translates to:
  /// **'Repite la palabra'**
  String get secretRepeatPassphrase;

  /// No description provided for @secretPassphraseOrPin.
  ///
  /// In es, this message translates to:
  /// **'Palabra secreta o PIN'**
  String get secretPassphraseOrPin;

  /// No description provided for @secretWrong.
  ///
  /// In es, this message translates to:
  /// **'No es correcta'**
  String get secretWrong;

  /// No description provided for @secretConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get secretConfirm;

  /// No description provided for @removeAdsPurchaseFailed.
  ///
  /// In es, this message translates to:
  /// **'La compra no se completó.'**
  String get removeAdsPurchaseFailed;

  /// No description provided for @removeAdsPending.
  ///
  /// In es, this message translates to:
  /// **'Tu pago está pendiente. Los anuncios se quitarán cuando Google Play lo confirme.'**
  String get removeAdsPending;

  /// No description provided for @removeAdsActiveTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin anuncios'**
  String get removeAdsActiveTitle;

  /// No description provided for @removeAdsThanks.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por apoyar Book Tracker! 💜'**
  String get removeAdsThanks;

  /// No description provided for @removeAdsTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar anuncios'**
  String get removeAdsTitle;

  /// No description provided for @removeAdsDescription.
  ///
  /// In es, this message translates to:
  /// **'Pago único, para siempre. Sin anuncios en la biblioteca, estadísticas ni citas, y \"Salvar racha\" gratis. Se mantiene si reinstalas o cambias de teléfono con la misma cuenta de Google.'**
  String get removeAdsDescription;

  /// No description provided for @removeAdsUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible por ahora'**
  String get removeAdsUnavailable;

  /// No description provided for @removeAdsBuy.
  ///
  /// In es, this message translates to:
  /// **'Comprar'**
  String get removeAdsBuy;

  /// No description provided for @removeAdsBuyFor.
  ///
  /// In es, this message translates to:
  /// **'Comprar por {price}'**
  String removeAdsBuyFor(String price);

  /// No description provided for @removeAdsRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get removeAdsRestore;

  /// No description provided for @loginPassphraseSavedTitle.
  ///
  /// In es, this message translates to:
  /// **'✨ Palabra Guardada'**
  String get loginPassphraseSavedTitle;

  /// No description provided for @loginOfferPinBody.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres un PIN de 4 dígitos como respaldo? Podrás configurarlo después en Ajustes.'**
  String get loginOfferPinBody;

  /// No description provided for @loginSetUpPin.
  ///
  /// In es, this message translates to:
  /// **'Configurar PIN'**
  String get loginSetUpPin;

  /// No description provided for @loginSkipLockTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Usar sin bloqueo?'**
  String get loginSkipLockTitle;

  /// No description provided for @loginSkipLockBody.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera con acceso a tu teléfono podrá abrir tu biblioteca. Puedes activar el bloqueo cuando quieras en Ajustes → Seguridad.'**
  String get loginSkipLockBody;

  /// No description provided for @loginSkipLock.
  ///
  /// In es, this message translates to:
  /// **'Usar sin bloqueo'**
  String get loginSkipLock;

  /// No description provided for @loginWrongPassphrase.
  ///
  /// In es, this message translates to:
  /// **'Esa no es la palabra mágica...'**
  String get loginWrongPassphrase;

  /// No description provided for @loginTooManyAttemptsWait.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera {time} para volver a probar.'**
  String loginTooManyAttemptsWait(String time);

  /// No description provided for @loginWait.
  ///
  /// In es, this message translates to:
  /// **'Espera {time} para volver a probar.'**
  String loginWait(String time);

  /// No description provided for @loginWrongPin.
  ///
  /// In es, this message translates to:
  /// **'El PIN no es correcto.'**
  String get loginWrongPin;

  /// No description provided for @loginBiometricReason.
  ///
  /// In es, this message translates to:
  /// **'Acceso rápido a tu biblioteca'**
  String get loginBiometricReason;

  /// No description provided for @loginCannotVerifyTitle.
  ///
  /// In es, this message translates to:
  /// **'No podemos verificar que eres tú'**
  String get loginCannotVerifyTitle;

  /// No description provided for @loginCannotVerifyBody.
  ///
  /// In es, this message translates to:
  /// **'Para recuperar el acceso, activa un bloqueo de pantalla (PIN, patrón o huella) en los ajustes de tu teléfono y vuelve a intentarlo. Tus libros siguen a salvo.'**
  String get loginCannotVerifyBody;

  /// No description provided for @loginRecoverReason.
  ///
  /// In es, this message translates to:
  /// **'Verifica que eres tú para elegir una palabra nueva'**
  String get loginRecoverReason;

  /// No description provided for @loginChooseNewPassphrase.
  ///
  /// In es, this message translates to:
  /// **'Elige una palabra nueva'**
  String get loginChooseNewPassphrase;

  /// No description provided for @loginSetupTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu Santo y Seña para iniciar la aventura'**
  String get loginSetupTitle;

  /// No description provided for @loginPinTitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu PIN de respaldo'**
  String get loginPinTitle;

  /// No description provided for @loginPassphraseTitle.
  ///
  /// In es, this message translates to:
  /// **'Di la palabra mágica para entrar'**
  String get loginPassphraseTitle;

  /// No description provided for @loginUsePassphrase.
  ///
  /// In es, this message translates to:
  /// **'Usar Santo y Seña'**
  String get loginUsePassphrase;

  /// No description provided for @loginUsePin.
  ///
  /// In es, this message translates to:
  /// **'Usar PIN de respaldo'**
  String get loginUsePin;

  /// No description provided for @loginForgotPin.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu PIN?'**
  String get loginForgotPin;

  /// No description provided for @loginForgotPassphrase.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu palabra secreta?'**
  String get loginForgotPassphrase;

  /// No description provided for @loginLockoutBanner.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Podrás volver a probar en {time}.\nMientras, puedes usar la huella o «¿Olvidaste…?».'**
  String loginLockoutBanner(String time);

  /// No description provided for @loginSetupBody.
  ///
  /// In es, this message translates to:
  /// **'Una palabra secreta protege tu biblioteca. Si la olvidas, podrás recuperarla con el bloqueo de tu teléfono.'**
  String get loginSetupBody;

  /// No description provided for @loginCreatePassphrase.
  ///
  /// In es, this message translates to:
  /// **'Crear palabra secreta'**
  String get loginCreatePassphrase;

  /// No description provided for @loginPassphraseHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe la palabra...'**
  String get loginPassphraseHint;

  /// No description provided for @loginUseFingerprint.
  ///
  /// In es, this message translates to:
  /// **'Usar huella'**
  String get loginUseFingerprint;

  /// No description provided for @loginReveal.
  ///
  /// In es, this message translates to:
  /// **'Revelar biblioteca'**
  String get loginReveal;

  /// No description provided for @whatsNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Notas de la versión'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewHistorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que ha cambiado en cada versión de Book Tracker.'**
  String get whatsNewHistorySubtitle;

  /// No description provided for @whatsNewHeadline.
  ///
  /// In es, this message translates to:
  /// **'Lo nuevo en Book Tracker'**
  String get whatsNewHeadline;

  /// No description provided for @whatsNewStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get whatsNewStart;

  /// No description provided for @whatsNewLatestLabel.
  ///
  /// In es, this message translates to:
  /// **'NOVEDADES · {version}'**
  String whatsNewLatestLabel(String version);

  /// No description provided for @whatsNewVersionLabel.
  ///
  /// In es, this message translates to:
  /// **'VERSIÓN {version}'**
  String whatsNewVersionLabel(String version);

  /// No description provided for @whatsNew142EnglishTitle.
  ///
  /// In es, this message translates to:
  /// **'Book Tracker en inglés'**
  String get whatsNew142EnglishTitle;

  /// No description provided for @whatsNew142EnglishText.
  ///
  /// In es, this message translates to:
  /// **'La app está disponible en español e inglés, con fechas y números en tu idioma.'**
  String get whatsNew142EnglishText;

  /// No description provided for @whatsNew142LanguageTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige el idioma'**
  String get whatsNew142LanguageTitle;

  /// No description provided for @whatsNew142LanguageText.
  ///
  /// In es, this message translates to:
  /// **'En Ajustes > Apariencia > Idioma: automático (el de tu teléfono), español o inglés.'**
  String get whatsNew142LanguageText;

  /// No description provided for @whatsNew142PluralsTitle.
  ///
  /// In es, this message translates to:
  /// **'Textos más cuidados'**
  String get whatsNew142PluralsTitle;

  /// No description provided for @whatsNew142PluralsText.
  ///
  /// In es, this message translates to:
  /// **'Plurales correctos (\"1 página\", \"1 libro\") y fechas más claras.'**
  String get whatsNew142PluralsText;

  /// No description provided for @whatsNew141CameraQuotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Citas con la cámara'**
  String get whatsNew141CameraQuotesTitle;

  /// No description provided for @whatsNew141CameraQuotesText.
  ///
  /// In es, this message translates to:
  /// **'Fotografía una página y subraya con el dedo la frase que quieres guardar. Con zoom y lupa para más precisión.'**
  String get whatsNew141CameraQuotesText;

  /// No description provided for @whatsNew141OnDeviceTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo en tu teléfono'**
  String get whatsNew141OnDeviceTitle;

  /// No description provided for @whatsNew141OnDeviceText.
  ///
  /// In es, this message translates to:
  /// **'El texto se reconoce en tu dispositivo: la foto no se envía a ningún sitio.'**
  String get whatsNew141OnDeviceText;

  /// No description provided for @whatsNew141CalendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario de lectura'**
  String get whatsNew141CalendarTitle;

  /// No description provided for @whatsNew141CalendarText.
  ///
  /// In es, this message translates to:
  /// **'Cada día coloreado según cuánto leíste. Toca un día para ver qué libros leíste.'**
  String get whatsNew141CalendarText;

  /// No description provided for @whatsNew141MonthlyChartTitle.
  ///
  /// In es, this message translates to:
  /// **'Gráfico mensual más claro'**
  String get whatsNew141MonthlyChartTitle;

  /// No description provided for @whatsNew141MonthlyChartText.
  ///
  /// In es, this message translates to:
  /// **'Escala redonda y barras que nacen en el cero.'**
  String get whatsNew141MonthlyChartText;

  /// No description provided for @whatsNew140RedesignTitle.
  ///
  /// In es, this message translates to:
  /// **'Diseño renovado'**
  String get whatsNew140RedesignTitle;

  /// No description provided for @whatsNew140RedesignText.
  ///
  /// In es, this message translates to:
  /// **'Más limpio y tranquilo, con nuevos colores, tipografía y modo oscuro.'**
  String get whatsNew140RedesignText;

  /// No description provided for @whatsNew140PhoneColorsTitle.
  ///
  /// In es, this message translates to:
  /// **'Colores de tu teléfono'**
  String get whatsNew140PhoneColorsTitle;

  /// No description provided for @whatsNew140PhoneColorsText.
  ///
  /// In es, this message translates to:
  /// **'En Ajustes > Colores puedes usar la paleta de tu fondo de pantalla.'**
  String get whatsNew140PhoneColorsText;

  /// No description provided for @whatsNew140ContinueReadingTitle.
  ///
  /// In es, this message translates to:
  /// **'Continuar leyendo'**
  String get whatsNew140ContinueReadingTitle;

  /// No description provided for @whatsNew140ContinueReadingText.
  ///
  /// In es, this message translates to:
  /// **'Tu libro actual arriba de la biblioteca: retoma la sesión en un toque.'**
  String get whatsNew140ContinueReadingText;

  /// No description provided for @whatsNew140ListGridTitle.
  ///
  /// In es, this message translates to:
  /// **'Lista o cuadrícula'**
  String get whatsNew140ListGridTitle;

  /// No description provided for @whatsNew140ListGridText.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo ver tu biblioteca y filtra por estado o categoría.'**
  String get whatsNew140ListGridText;

  /// No description provided for @whatsNew140SwipeTitle.
  ///
  /// In es, this message translates to:
  /// **'Desliza para actuar'**
  String get whatsNew140SwipeTitle;

  /// No description provided for @whatsNew140SwipeText.
  ///
  /// In es, this message translates to:
  /// **'A la derecha: empezar o terminar un libro, con Deshacer. A la izquierda: borrar.'**
  String get whatsNew140SwipeText;

  /// No description provided for @whatsNew140BookDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del libro'**
  String get whatsNew140BookDetailTitle;

  /// No description provided for @whatsNew140BookDetailText.
  ///
  /// In es, this message translates to:
  /// **'Rediseñado, con tu ritmo, lo que falta y tus notas como citas.'**
  String get whatsNew140BookDetailText;

  /// No description provided for @whatsNew140StatsTilesTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas en mosaico'**
  String get whatsNew140StatsTilesTitle;

  /// No description provided for @whatsNew140StatsTilesText.
  ///
  /// In es, this message translates to:
  /// **'Racha, tu mejor racha y la semana de un vistazo.'**
  String get whatsNew140StatsTilesText;

  /// No description provided for @whatsNew140BackGestureTitle.
  ///
  /// In es, this message translates to:
  /// **'Gesto atrás'**
  String get whatsNew140BackGestureTitle;

  /// No description provided for @whatsNew140BackGestureText.
  ///
  /// In es, this message translates to:
  /// **'Desliza para volver y mira a dónde vas; \"atrás\" vuelve a Libros antes de salir.'**
  String get whatsNew140BackGestureText;

  /// No description provided for @whatsNew140UpdateAlertsTitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos de actualización'**
  String get whatsNew140UpdateAlertsTitle;

  /// No description provided for @whatsNew140UpdateAlertsText.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos cuando haya una versión nueva y la instalas sin salir de la app.'**
  String get whatsNew140UpdateAlertsText;

  /// No description provided for @whatsNew140ReleaseNotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Notas de la versión'**
  String get whatsNew140ReleaseNotesTitle;

  /// No description provided for @whatsNew140ReleaseNotesText.
  ///
  /// In es, this message translates to:
  /// **'Consulta las novedades cuando quieras en Ajustes > Novedades.'**
  String get whatsNew140ReleaseNotesText;

  /// No description provided for @whatsNew130FasterTitle.
  ///
  /// In es, this message translates to:
  /// **'Más rápida y ligera'**
  String get whatsNew130FasterTitle;

  /// No description provided for @whatsNew130FasterText.
  ///
  /// In es, this message translates to:
  /// **'La app ocupa menos y abre antes.'**
  String get whatsNew130FasterText;

  /// No description provided for @whatsNew130SaferTitle.
  ///
  /// In es, this message translates to:
  /// **'Más segura'**
  String get whatsNew130SaferTitle;

  /// No description provided for @whatsNew130SaferText.
  ///
  /// In es, this message translates to:
  /// **'Tu palabra secreta se guarda con el almacenamiento seguro más reciente.'**
  String get whatsNew130SaferText;

  /// No description provided for @whatsNew130PurchasesTitle.
  ///
  /// In es, this message translates to:
  /// **'Compras más fiables'**
  String get whatsNew130PurchasesTitle;

  /// No description provided for @whatsNew130PurchasesText.
  ///
  /// In es, this message translates to:
  /// **'\"Quitar anuncios\" reconoce mejor las compras pendientes y los reembolsos.'**
  String get whatsNew130PurchasesText;

  /// No description provided for @whatsNew121RemoveAdsTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar anuncios'**
  String get whatsNew121RemoveAdsTitle;

  /// No description provided for @whatsNew121RemoveAdsText.
  ///
  /// In es, this message translates to:
  /// **'Un único pago para usar la app sin anuncios, para siempre.'**
  String get whatsNew121RemoveAdsText;

  /// No description provided for @whatsNew120IsbnScannerTitle.
  ///
  /// In es, this message translates to:
  /// **'Escáner de ISBN'**
  String get whatsNew120IsbnScannerTitle;

  /// No description provided for @whatsNew120IsbnScannerText.
  ///
  /// In es, this message translates to:
  /// **'Añade un libro escaneando su código de barras o escribiendo el ISBN.'**
  String get whatsNew120IsbnScannerText;

  /// No description provided for @whatsNew120MyQuotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis citas'**
  String get whatsNew120MyQuotesTitle;

  /// No description provided for @whatsNew120MyQuotesText.
  ///
  /// In es, this message translates to:
  /// **'Todas tus notas en un lugar: búscalas, marca favoritas y compártelas.'**
  String get whatsNew120MyQuotesText;

  /// No description provided for @whatsNew120ChallengeTitle.
  ///
  /// In es, this message translates to:
  /// **'Reto anual y fechas'**
  String get whatsNew120ChallengeTitle;

  /// No description provided for @whatsNew120ChallengeText.
  ///
  /// In es, this message translates to:
  /// **'Fechas de inicio y fin de cada libro y tu meta de libros del año.'**
  String get whatsNew120ChallengeText;

  /// No description provided for @whatsNew120SessionGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Meta por sesión'**
  String get whatsNew120SessionGoalTitle;

  /// No description provided for @whatsNew120SessionGoalText.
  ///
  /// In es, this message translates to:
  /// **'Elige 15–60 min o una página y te aviso al cumplirla.'**
  String get whatsNew120SessionGoalText;

  /// No description provided for @whatsNew120ReviewsTitle.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get whatsNew120ReviewsTitle;

  /// No description provided for @whatsNew120ReviewsText.
  ///
  /// In es, this message translates to:
  /// **'Califica y reseña al terminar un libro (o cuando quieras).'**
  String get whatsNew120ReviewsText;

  /// No description provided for @whatsNew120StreakRiskTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha en riesgo'**
  String get whatsNew120StreakRiskTitle;

  /// No description provided for @whatsNew120StreakRiskText.
  ///
  /// In es, this message translates to:
  /// **'Un aviso por la noche si aún no has leído y llevas racha.'**
  String get whatsNew120StreakRiskText;

  /// No description provided for @whatsNew120WidgetTitle.
  ///
  /// In es, this message translates to:
  /// **'Widget renovado'**
  String get whatsNew120WidgetTitle;

  /// No description provided for @whatsNew120WidgetText.
  ///
  /// In es, this message translates to:
  /// **'Con la portada de tu libro y pausa en un toque.'**
  String get whatsNew120WidgetText;

  /// No description provided for @whatsNew120ReadingYearTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi año lector'**
  String get whatsNew120ReadingYearTitle;

  /// No description provided for @whatsNew120ReadingYearText.
  ///
  /// In es, this message translates to:
  /// **'Comparte una tarjeta con tus estadísticas del año.'**
  String get whatsNew120ReadingYearText;

  /// No description provided for @whatsNew120GoodreadsTitle.
  ///
  /// In es, this message translates to:
  /// **'Goodreads y respaldos'**
  String get whatsNew120GoodreadsTitle;

  /// No description provided for @whatsNew120GoodreadsText.
  ///
  /// In es, this message translates to:
  /// **'Importa tu biblioteca de Goodreads y guarda una copia completa con portadas.'**
  String get whatsNew120GoodreadsText;

  /// No description provided for @statsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statsTitle;

  /// No description provided for @statsShareTooltip.
  ///
  /// In es, this message translates to:
  /// **'Compartir mi año lector'**
  String get statsShareTooltip;

  /// No description provided for @statsShareEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay lecturas en {year} para compartir. ¡Empieza un libro!'**
  String statsShareEmpty(int year);

  /// No description provided for @statsError.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String statsError(String error);

  /// No description provided for @statsToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get statsToday;

  /// No description provided for @statsTodayProgress.
  ///
  /// In es, this message translates to:
  /// **'{minutes} de {goal} min'**
  String statsTodayProgress(int minutes, int goal);

  /// No description provided for @statsBooksRead.
  ///
  /// In es, this message translates to:
  /// **'Libros leídos'**
  String get statsBooksRead;

  /// No description provided for @statsPages.
  ///
  /// In es, this message translates to:
  /// **'Páginas'**
  String get statsPages;

  /// No description provided for @statsTotalTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo total'**
  String get statsTotalTime;

  /// No description provided for @statsFavoriteGenres.
  ///
  /// In es, this message translates to:
  /// **'Géneros favoritos'**
  String get statsFavoriteGenres;

  /// No description provided for @statsAchievementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Logros y desafíos'**
  String get statsAchievementsTitle;

  /// No description provided for @statsChartMinutes.
  ///
  /// In es, this message translates to:
  /// **'MINUTOS'**
  String get statsChartMinutes;

  /// No description provided for @statsChartDayOfMonth.
  ///
  /// In es, this message translates to:
  /// **'DÍA DEL MES'**
  String get statsChartDayOfMonth;

  /// No description provided for @statsChartBarMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} m'**
  String statsChartBarMinutes(int minutes);

  /// No description provided for @streakCurrent.
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get streakCurrent;

  /// No description provided for @streakDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String streakDays(int count);

  /// No description provided for @streakBest.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor racha: {count, plural, =1{1 día} other{{count} días}}'**
  String streakBest(int count);

  /// No description provided for @streakRiskTitle.
  ///
  /// In es, this message translates to:
  /// **'🔥 Tu racha de {count, plural, =1{1 día} other{{count} días}} está en riesgo'**
  String streakRiskTitle(int count);

  /// No description provided for @streakRiskBody.
  ///
  /// In es, this message translates to:
  /// **'Aún no has leído hoy. Lee unos minutos antes de medianoche para no perderla.'**
  String get streakRiskBody;

  /// No description provided for @streakSaveSuccess.
  ///
  /// In es, this message translates to:
  /// **'🔥 ¡Racha salvada! Sigues con {count, plural, =1{1 día} other{{count} días}}. Lee hoy para mantenerla.'**
  String streakSaveSuccess(int count);

  /// No description provided for @streakSaveAdIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Hay que ver el anuncio completo para salvar la racha.'**
  String get streakSaveAdIncomplete;

  /// No description provided for @streakSaveAdUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Ahora no hay anuncios disponibles. Revisa tu conexión e inténtalo de nuevo.'**
  String get streakSaveAdUnavailable;

  /// No description provided for @streakSaveTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu racha de {count, plural, =1{1 día} other{{count} días}} se rompió'**
  String streakSaveTitle(int count);

  /// No description provided for @streakSaveBodyFree.
  ///
  /// In es, this message translates to:
  /// **'Ayer no registraste lectura. Como usuario sin anuncios, puedes recuperarla gratis: ayer contará para tu racha.'**
  String get streakSaveBodyFree;

  /// No description provided for @streakSaveBodyAd.
  ///
  /// In es, this message translates to:
  /// **'Ayer no registraste lectura. Mira un anuncio corto y la recuperamos: ayer contará para tu racha.'**
  String get streakSaveBodyAd;

  /// No description provided for @streakSaveOncePerWeek.
  ///
  /// In es, this message translates to:
  /// **'Puedes hacerlo una vez por semana.'**
  String get streakSaveOncePerWeek;

  /// No description provided for @streakSaveLoadingAd.
  ///
  /// In es, this message translates to:
  /// **'Cargando anuncio…'**
  String get streakSaveLoadingAd;

  /// No description provided for @streakSaveFreeButton.
  ///
  /// In es, this message translates to:
  /// **'Salvar mi racha'**
  String get streakSaveFreeButton;

  /// No description provided for @streakSaveWatchAdButton.
  ///
  /// In es, this message translates to:
  /// **'Ver anuncio y salvar mi racha'**
  String get streakSaveWatchAdButton;

  /// No description provided for @streakSaveNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get streakSaveNotNow;

  /// No description provided for @calendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get calendarTitle;

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes siguiente'**
  String get calendarNextMonth;

  /// No description provided for @calendarHistoryStartsHere.
  ///
  /// In es, this message translates to:
  /// **'Tu historial empieza aquí: aún no hay meses anteriores con lecturas.'**
  String get calendarHistoryStartsHere;

  /// No description provided for @calendarHistoryStartsIn.
  ///
  /// In es, this message translates to:
  /// **'Tu historial empieza en {month}.'**
  String calendarHistoryStartsIn(String month);

  /// No description provided for @calendarCurrentMonth.
  ///
  /// In es, this message translates to:
  /// **'Este es el mes actual.'**
  String get calendarCurrentMonth;

  /// No description provided for @calendarDaySavedSemantics.
  ///
  /// In es, this message translates to:
  /// **'{day}, racha salvada'**
  String calendarDaySavedSemantics(String day);

  /// No description provided for @calendarDayNoReadingSemantics.
  ///
  /// In es, this message translates to:
  /// **'{day}, sin lectura'**
  String calendarDayNoReadingSemantics(String day);

  /// No description provided for @calendarDayReadingSemantics.
  ///
  /// In es, this message translates to:
  /// **'{day}, {duration}, {pages, plural, =1{1 página} other{{pages} páginas}}'**
  String calendarDayReadingSemantics(String day, String duration, int pages);

  /// No description provided for @calendarLegendLess.
  ///
  /// In es, this message translates to:
  /// **'Menos'**
  String get calendarLegendLess;

  /// No description provided for @calendarLegendMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get calendarLegendMore;

  /// No description provided for @calendarNoReadingYetThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Aún no has leído este mes. Toca un día para ver su detalle.'**
  String get calendarNoReadingYetThisMonth;

  /// No description provided for @calendarNoReadingThisMonth.
  ///
  /// In es, this message translates to:
  /// **'No hay lecturas este mes.'**
  String get calendarNoReadingThisMonth;

  /// No description provided for @calendarDaysReadLabel.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{día leído} other{días leídos}}'**
  String calendarDaysReadLabel(int count);

  /// No description provided for @calendarTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'en total'**
  String get calendarTotalLabel;

  /// No description provided for @calendarPagesLabel.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{página} other{páginas}}'**
  String calendarPagesLabel(int count);

  /// No description provided for @calendarPagesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 página} other{{count} páginas}}'**
  String calendarPagesCount(int count);

  /// No description provided for @calendarPagesShort.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 pág.} other{{count} págs.}}'**
  String calendarPagesShort(int count);

  /// No description provided for @calendarBestDay.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor día: {date} · {amount}'**
  String calendarBestDay(String date, String amount);

  /// No description provided for @calendarDaySavedDetail.
  ///
  /// In es, this message translates to:
  /// **'No leíste, pero salvaste tu racha este día.'**
  String get calendarDaySavedDetail;

  /// No description provided for @calendarDayNoReadingDetail.
  ///
  /// In es, this message translates to:
  /// **'Este día no leíste.'**
  String get calendarDayNoReadingDetail;

  /// No description provided for @calendarDeletedBook.
  ///
  /// In es, this message translates to:
  /// **'Libro eliminado'**
  String get calendarDeletedBook;

  /// No description provided for @challengeFinishedBooksTitle.
  ///
  /// In es, this message translates to:
  /// **'Libros terminados'**
  String get challengeFinishedBooksTitle;

  /// No description provided for @challengeNoDatedBooks.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay libros terminados con fecha.'**
  String get challengeNoDatedBooks;

  /// No description provided for @challengeYearHeader.
  ///
  /// In es, this message translates to:
  /// **'{year} · {count, plural, =1{1 libro} other{{count} libros}}'**
  String challengeYearHeader(String year, int count);

  /// No description provided for @challengeUndatedBooks.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 libro terminado no tiene fecha de fin.} other{{count} libros terminados no tienen fecha de fin.}} Puedes añadirla en el detalle de cada libro para que cuente en su año.'**
  String challengeUndatedBooks(int count);

  /// No description provided for @challengeTitleWithYear.
  ///
  /// In es, this message translates to:
  /// **'Reto de lectura {year}'**
  String challengeTitleWithYear(String year);

  /// No description provided for @challengeSetGoalPrompt.
  ///
  /// In es, this message translates to:
  /// **'Ponte una meta de libros para este año.'**
  String get challengeSetGoalPrompt;

  /// No description provided for @challengeFinishedSoFar.
  ///
  /// In es, this message translates to:
  /// **'Llevas {count, plural, =1{1 libro terminado} other{{count} libros terminados}} este año. ¿Te pones una meta?'**
  String challengeFinishedSoFar(int count);

  /// No description provided for @challengeCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear reto'**
  String get challengeCreate;

  /// No description provided for @challengeShowBooks.
  ///
  /// In es, this message translates to:
  /// **'Ver libros'**
  String get challengeShowBooks;

  /// No description provided for @challengeOfGoal.
  ///
  /// In es, this message translates to:
  /// **'de {goal}'**
  String challengeOfGoal(int goal);

  /// No description provided for @challengeShortTitle.
  ///
  /// In es, this message translates to:
  /// **'Reto {year}'**
  String challengeShortTitle(String year);

  /// No description provided for @challengeChangeGoal.
  ///
  /// In es, this message translates to:
  /// **'Cambiar meta'**
  String get challengeChangeGoal;

  /// No description provided for @challengeDoneCount.
  ///
  /// In es, this message translates to:
  /// **'{finished} de {goal} libros'**
  String challengeDoneCount(int finished, int goal);

  /// No description provided for @challengeRemaining.
  ///
  /// In es, this message translates to:
  /// **'{count} por leer para tu meta'**
  String challengeRemaining(int count);

  /// No description provided for @challengeShowFinished.
  ///
  /// In es, this message translates to:
  /// **'Ver libros terminados'**
  String get challengeShowFinished;

  /// No description provided for @challengeDialogQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántos libros quieres leer este año?'**
  String get challengeDialogQuestion;

  /// No description provided for @challengeBooksSuffix.
  ///
  /// In es, this message translates to:
  /// **'libros'**
  String get challengeBooksSuffix;

  /// No description provided for @challengeGoalRange.
  ///
  /// In es, this message translates to:
  /// **'Entre 1 y {max}'**
  String challengeGoalRange(int max);

  /// No description provided for @challengeRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar reto'**
  String get challengeRemove;

  /// No description provided for @challengeCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Reto cumplido!'**
  String get challengeCompleted;

  /// No description provided for @challengeExceeded.
  ///
  /// In es, this message translates to:
  /// **'¡Reto superado! +{extra}'**
  String challengeExceeded(int extra);

  /// No description provided for @challengeAhead.
  ///
  /// In es, this message translates to:
  /// **'Vas {count, plural, =1{1 libro} other{{count} libros}} adelantado'**
  String challengeAhead(int count);

  /// No description provided for @challengeBehind.
  ///
  /// In es, this message translates to:
  /// **'Vas {count, plural, =1{1 libro} other{{count} libros}} atrasado'**
  String challengeBehind(int count);

  /// No description provided for @challengeOnTrack.
  ///
  /// In es, this message translates to:
  /// **'Vas al día'**
  String get challengeOnTrack;

  /// No description provided for @yearSummaryHeading.
  ///
  /// In es, this message translates to:
  /// **'MI AÑO LECTOR'**
  String get yearSummaryHeading;

  /// No description provided for @yearSummaryBooksFinished.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{libro\nterminado} other{libros\nterminados}}'**
  String yearSummaryBooksFinished(int count);

  /// No description provided for @yearSummaryGoalDone.
  ///
  /// In es, this message translates to:
  /// **'🏆 ¡Reto de {goal} libros cumplido!'**
  String yearSummaryGoalDone(int goal);

  /// No description provided for @yearSummaryGoalProgress.
  ///
  /// In es, this message translates to:
  /// **'Reto: {finished} de {goal} libros'**
  String yearSummaryGoalProgress(int finished, int goal);

  /// No description provided for @yearSummaryPages.
  ///
  /// In es, this message translates to:
  /// **'páginas'**
  String get yearSummaryPages;

  /// No description provided for @yearSummaryReadingTime.
  ///
  /// In es, this message translates to:
  /// **'leyendo'**
  String get yearSummaryReadingTime;

  /// No description provided for @yearSummaryReadingDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{día con lectura} other{días con lectura}}'**
  String yearSummaryReadingDays(int count);

  /// No description provided for @yearSummaryLongestStreak.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{día de racha} other{días de racha máx.}}'**
  String yearSummaryLongestStreak(int count);

  /// No description provided for @yearSummaryFavoriteGenre.
  ///
  /// In es, this message translates to:
  /// **'Género favorito: {genre}'**
  String yearSummaryFavoriteGenre(String genre);

  /// No description provided for @yearSummaryRecentlyFinished.
  ///
  /// In es, this message translates to:
  /// **'Últimos terminados'**
  String get yearSummaryRecentlyFinished;

  /// No description provided for @yearSummaryShareText.
  ///
  /// In es, this message translates to:
  /// **'Mi año lector {year} 📚 #BookTracker'**
  String yearSummaryShareText(String year);

  /// No description provided for @yearSummaryShareError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear la imagen. Inténtalo de nuevo.'**
  String get yearSummaryShareError;

  /// No description provided for @yearSummaryShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get yearSummaryShare;

  /// No description provided for @achievementCategoryEarly.
  ///
  /// In es, this message translates to:
  /// **'Disciplina Temprana'**
  String get achievementCategoryEarly;

  /// No description provided for @achievementCategorySerious.
  ///
  /// In es, this message translates to:
  /// **'Compromiso Serio'**
  String get achievementCategorySerious;

  /// No description provided for @achievementCategoryScholar.
  ///
  /// In es, this message translates to:
  /// **'Nivel Erudito (3 años+)'**
  String get achievementCategoryScholar;

  /// No description provided for @achievementHabitFormedName.
  ///
  /// In es, this message translates to:
  /// **'Hábito Formado'**
  String get achievementHabitFormedName;

  /// No description provided for @achievementHabitFormedDesc.
  ///
  /// In es, this message translates to:
  /// **'Racha de 21 días'**
  String get achievementHabitFormedDesc;

  /// No description provided for @achievementSprinterName.
  ///
  /// In es, this message translates to:
  /// **'Velocista'**
  String get achievementSprinterName;

  /// No description provided for @achievementSprinterDesc.
  ///
  /// In es, this message translates to:
  /// **'500 páginas leídas'**
  String get achievementSprinterDesc;

  /// No description provided for @achievementVoraciousReaderName.
  ///
  /// In es, this message translates to:
  /// **'Lector Voraz'**
  String get achievementVoraciousReaderName;

  /// No description provided for @achievementVoraciousReaderDesc.
  ///
  /// In es, this message translates to:
  /// **'50 libros terminados'**
  String get achievementVoraciousReaderDesc;

  /// No description provided for @achievementHalfMarathonName.
  ///
  /// In es, this message translates to:
  /// **'Medio Maratón'**
  String get achievementHalfMarathonName;

  /// No description provided for @achievementHalfMarathonDesc.
  ///
  /// In es, this message translates to:
  /// **'250 horas de lectura'**
  String get achievementHalfMarathonDesc;

  /// No description provided for @achievementPureConsistencyName.
  ///
  /// In es, this message translates to:
  /// **'Constancia Pura'**
  String get achievementPureConsistencyName;

  /// No description provided for @achievementPureConsistencyDesc.
  ///
  /// In es, this message translates to:
  /// **'Racha de 100 días'**
  String get achievementPureConsistencyDesc;

  /// No description provided for @achievementGoldenBibliophileName.
  ///
  /// In es, this message translates to:
  /// **'Bibliófilo de Oro'**
  String get achievementGoldenBibliophileName;

  /// No description provided for @achievementGoldenBibliophileDesc.
  ///
  /// In es, this message translates to:
  /// **'100.000 páginas leídas'**
  String get achievementGoldenBibliophileDesc;

  /// No description provided for @achievementLifeAmongBooksName.
  ///
  /// In es, this message translates to:
  /// **'Vida Entre Libros'**
  String get achievementLifeAmongBooksName;

  /// No description provided for @achievementLifeAmongBooksDesc.
  ///
  /// In es, this message translates to:
  /// **'1.000 horas de lectura'**
  String get achievementLifeAmongBooksDesc;

  /// No description provided for @achievementUnbreakableName.
  ///
  /// In es, this message translates to:
  /// **'Inquebrantable'**
  String get achievementUnbreakableName;

  /// No description provided for @achievementUnbreakableDesc.
  ///
  /// In es, this message translates to:
  /// **'Racha de 365 días'**
  String get achievementUnbreakableDesc;

  /// No description provided for @achievementLibraryMasterName.
  ///
  /// In es, this message translates to:
  /// **'Maestro de Biblioteca'**
  String get achievementLibraryMasterName;

  /// No description provided for @achievementLibraryMasterDesc.
  ///
  /// In es, this message translates to:
  /// **'250 libros completados'**
  String get achievementLibraryMasterDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
