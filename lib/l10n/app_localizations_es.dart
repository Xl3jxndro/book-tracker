// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonUndo => 'Deshacer';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonAccept => 'Aceptar';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Automático';

  @override
  String get languageSystemSubtitle => 'El idioma de tu teléfono';

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
    return '📖 *Estoy leyendo:* $title\n✍️ *Autor:* $author\n📊 *Progreso:* $readPages/$totalPages pág.\n\n✨ Compartido desde $appName';
  }

  @override
  String get detailsTimeNow => 'Ahora';

  @override
  String detailsTimeMinutesAgo(int minutes) {
    return 'Hace ${minutes}m';
  }

  @override
  String get detailsTimeToday => 'Hoy';

  @override
  String get detailsTimeYesterday => 'Ayer';

  @override
  String get detailsShare => 'Compartir';

  @override
  String get detailsMoreOptions => 'Más opciones';

  @override
  String get detailsEditBook => 'Editar libro';

  @override
  String get detailsNotesEmptyTitle => 'Sin notas aún';

  @override
  String get detailsNotesEmptyDescription =>
      'Guarda aquí tus citas y pensamientos.';

  @override
  String get detailsNewNote => 'Nueva nota';

  @override
  String get detailsFavoritesEmptyHint =>
      'Toca la ☆ de una nota para guardarla en tus citas favoritas.';

  @override
  String get detailsShareAsImage => 'Compartir como imagen';

  @override
  String get detailsRemoveFavorite => 'Quitar de favoritas';

  @override
  String get detailsAddFavorite => 'Guardar en favoritas';

  @override
  String get detailsCopy => 'Copiar';

  @override
  String get detailsCopied => 'Copiado';

  @override
  String detailsNotePage(int page) {
    return 'Página $page';
  }

  @override
  String get detailsReadingSession => 'Sesión de lectura';

  @override
  String get detailsNotesAndQuotes => 'Notas y citas';

  @override
  String get detailsAdd => 'Añadir';

  @override
  String get detailsFilterRecent => 'Recientes';

  @override
  String get detailsFilterPage => 'Página';

  @override
  String get detailsFilterLength => 'Longitud';

  @override
  String get detailsFilterFavorites => '★ Favoritas';

  @override
  String get detailsYourProgress => 'Tu progreso';

  @override
  String detailsPagesOfTotal(int read, int total) {
    return '$read de $total páginas';
  }

  @override
  String get detailsReread => 'Releer';

  @override
  String get detailsUpdate => 'Actualizar';

  @override
  String get detailsStartAddDate => 'Inicio: añadir fecha';

  @override
  String detailsStartedOn(String date) {
    return 'Empezado el $date';
  }

  @override
  String get detailsFinishAddDate => 'Fin: añadir fecha';

  @override
  String detailsFinishedOn(String date) {
    return 'Terminado el $date';
  }

  @override
  String detailsFinishedOnDays(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Terminado el $date · $_temp0';
  }

  @override
  String get detailsWhenStarted => '¿Cuándo lo empezaste?';

  @override
  String get detailsWhenFinished => '¿Cuándo lo terminaste?';

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
    return '$pace pág/min';
  }

  @override
  String detailsPacePerHour(int pages) {
    return '$pages pág/h';
  }

  @override
  String get detailsPace => 'Ritmo';

  @override
  String get detailsTimeLeft => 'Faltan';

  @override
  String get detailsTimeRead => 'Leído';

  @override
  String get detailsDailyGoal => 'Meta diaria';

  @override
  String detailsDailyGoalProgress(int minutes, int goal) {
    return '$minutes de $goal min hoy';
  }

  @override
  String get detailsChangeDailyGoal => 'Cambiar meta diaria';

  @override
  String get detailsReadingCompleted => '¡Lectura completada!';

  @override
  String detailsRatingStars(int stars) {
    return '$stars de 5';
  }

  @override
  String get detailsWriteReview => 'Escribir reseña';

  @override
  String get detailsEditReview => 'Editar reseña';

  @override
  String get detailsFavoriteRemoved => 'Quitada de favoritas';

  @override
  String get detailsFavoriteAdded => 'Guardada en favoritas ★';

  @override
  String get detailsNoteDeleted => 'Nota eliminada';

  @override
  String get detailsUndoAction => 'DESHACER';

  @override
  String get detailsEnterPageNumber => 'Escribe un número de página';

  @override
  String detailsPageCannotExceed(int total) {
    return 'No puede superar $total';
  }

  @override
  String get detailsUpdateProgressTitle => 'Actualizar Progreso';

  @override
  String get detailsWhatPage => '¿En qué página vas?';

  @override
  String get detailsDeleteBookTitle => '¿Eliminar libro?';

  @override
  String get detailsDeleteBookMessage => 'Se perderán todas tus notas.';

  @override
  String get detailsDailyGoalTitle => 'Meta Diaria';

  @override
  String get detailsRereadTitle => '¿Nueva lectura?';

  @override
  String get detailsRereadConfirm => '¡Vamos!';

  @override
  String get detailsTutorialProgressTitle => '📈​ Tu Progreso';

  @override
  String get detailsTutorialProgressDesc =>
      'Visualiza cuántas páginas llevas leídas.';

  @override
  String get detailsTutorialGoalTitle => '🏆​ Meta Diaria';

  @override
  String get detailsTutorialGoalDesc =>
      'Configura tus minutos de lectura diarios.';

  @override
  String get detailsTutorialTimerTitle => '📖​ Sesión de Lectura';

  @override
  String get detailsTutorialTimerDesc =>
      'Inicia el cronómetro para medir tu tiempo.';

  @override
  String get detailsTutorialNotesTitle => '​📜​ ​Añadir Notas';

  @override
  String get detailsTutorialNotesDesc => 'Guarda tus citas favoritas aquí.';

  @override
  String timerGoalReachedSnack(int minutes) {
    return '🎯 ¡Meta de $minutes min cumplida! Sigue si quieres o finaliza la lectura.';
  }

  @override
  String get timerEnterPage => 'Escribe una página';

  @override
  String timerAlreadyOnPage(int page) {
    return 'Ya vas en la pág. $page';
  }

  @override
  String timerBookHasPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'El libro tiene $count páginas',
      one: 'El libro tiene 1 página',
    );
    return '$_temp0';
  }

  @override
  String get timerUntilWhichPage => '¿Hasta qué página?';

  @override
  String get timerReachPage => 'Llegar a la página';

  @override
  String get timerDone => 'Listo';

  @override
  String get timerSessionPaused => 'SESIÓN PAUSADA';

  @override
  String get timerReadingTime => 'TIEMPO DE LECTURA';

  @override
  String get timerPause => 'PAUSAR';

  @override
  String get timerResume => 'REANUDAR';

  @override
  String get timerStart => 'COMENZAR';

  @override
  String get timerFinishReading => 'Finalizar lectura';

  @override
  String timerDurationMinSec(int minutes, int seconds) {
    return '$minutes min $seconds seg';
  }

  @override
  String timerDurationSec(int seconds) {
    return '$seconds seg';
  }

  @override
  String get timerSessionFinished => '¡Sesión terminada!';

  @override
  String get timerWhatPageStopped => '¿En qué página quedaste?';

  @override
  String get timerCannotExceedTotal => 'No puede exceder el total';

  @override
  String get timerDiscard => 'DESCARTAR';

  @override
  String get timerGoalSheetTitle => '🎯 Meta de esta sesión';

  @override
  String get timerGoalSheetSubtitle =>
      'Te aviso al cumplir la meta de tiempo, aunque tengas la pantalla apagada.';

  @override
  String get timerGoalTime => 'Tiempo';

  @override
  String get timerGoalFree => 'Libre';

  @override
  String timerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get timerGoalPages => 'Páginas';

  @override
  String timerUntilPageN(int page) {
    return 'Hasta la pág. $page';
  }

  @override
  String get timerUntilPageAsk => 'Hasta la página…';

  @override
  String get timerGoalFreeLabel => 'Meta: libre';

  @override
  String timerGoalReached(int minutes) {
    return '¡Meta de $minutes min cumplida!';
  }

  @override
  String timerGoalProgress(int elapsed, int total) {
    return 'Meta: $elapsed / $total min';
  }

  @override
  String timerGoalTimeLabel(int minutes) {
    return 'Meta: $minutes min';
  }

  @override
  String timerGoalPageLabel(int page) {
    return 'Meta: hasta la pág. $page';
  }

  @override
  String timerGoalMet(int minutes) {
    return '🎯 Meta de $minutes min cumplida';
  }

  @override
  String timerGoalMissed(int minutes, int missing) {
    return 'Meta: $minutes min · te faltaron $missing min';
  }

  @override
  String timerPageGoalMet(int page) {
    return '🎯 ¡Llegaste a la pág. $page!';
  }

  @override
  String timerPageGoalMissed(int page, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'te faltan $left páginas',
      one: 'te falta 1 página',
    );
    return 'Meta: pág. $page · $_temp0';
  }

  @override
  String sessionGoalLabelTime(int minutes) {
    return '$minutes min';
  }

  @override
  String sessionGoalLabelPage(int page) {
    return 'hasta la pág. $page';
  }

  @override
  String sessionGoalTimeProgress(int elapsed, int total) {
    return '$elapsed / $total min';
  }

  @override
  String get noteCameraError =>
      'No se pudo abrir la cámara. Revisa el permiso en los ajustes del teléfono.';

  @override
  String get noteSaveError => 'No se pudo guardar la nota. Inténtalo de nuevo.';

  @override
  String get noteNewTitle => 'Nueva Anotación';

  @override
  String get noteEditTitle => 'Editar anotación';

  @override
  String get noteListening => 'Escuchando voz...';

  @override
  String get noteSubtitle => 'Escribe, dicta o escanea';

  @override
  String get noteScanTooltip => 'Escanear texto con la cámara';

  @override
  String get noteContentHint => 'Comienza a hablar o escribir...';

  @override
  String get notePageLabel => 'Página del libro';

  @override
  String get noteSave => 'Guardar nota';

  @override
  String get noteSaveChanges => 'Guardar cambios';

  @override
  String get scanSourceTitle => 'Escanear una cita';

  @override
  String get scanSourcePrivacy =>
      'El texto se reconoce en tu teléfono: la foto no se envía a ningún sitio.';

  @override
  String get scanSourceCamera => 'Tomar foto de la página';

  @override
  String get scanSourceGallery => 'Elegir de la galería';

  @override
  String get scanTitle => 'Subraya la cita';

  @override
  String get scanSelectNone => 'Ninguna';

  @override
  String get scanSelectAll => 'Todo';

  @override
  String get scanModelDownloadingTitle => 'Preparando el lector de texto';

  @override
  String get scanModelDownloadingText =>
      'Google Play lo está descargando (unos 4 MB). Conéctate a internet e inténtalo en unos minutos.';

  @override
  String get scanErrorTitle => 'No se pudo leer la foto';

  @override
  String get scanErrorText => 'Inténtalo de nuevo con otra foto.';

  @override
  String get scanReading => 'Leyendo la página…';

  @override
  String get scanNoTextTitle => 'No encontré texto';

  @override
  String get scanNoTextText =>
      'Prueba con más luz, la página recta y el texto enfocado.';

  @override
  String get scanZoomIn => 'Acercar';

  @override
  String get scanZoomOut => 'Alejar';

  @override
  String get scanZoomFit => 'Ver la página entera';

  @override
  String get scanHint =>
      'Desliza un dedo sobre el texto para subrayarlo. Con dos dedos, acerca la foto.';

  @override
  String get scanClear => 'Borrar';

  @override
  String get scanUseQuote => 'Usar cita';

  @override
  String reviewSummaryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en $count días',
      one: 'en 1 día',
    );
    return '$_temp0';
  }

  @override
  String reviewSummaryMinutes(int minutes) {
    return '$minutes min de lectura';
  }

  @override
  String reviewSummaryHours(int hours) {
    return '$hours h de lectura';
  }

  @override
  String reviewSummaryHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min de lectura';
  }

  @override
  String reviewSummaryPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0';
  }

  @override
  String get reviewRating1 => 'No me gustó';

  @override
  String get reviewRating2 => 'Regular';

  @override
  String get reviewRating3 => 'Bueno';

  @override
  String get reviewRating4 => 'Muy bueno';

  @override
  String get reviewRating5 => '¡Me encantó!';

  @override
  String get reviewSaved => 'Reseña guardada en tus notas ✍️';

  @override
  String get reviewDeleted => 'Reseña eliminada';

  @override
  String get reviewRatingSaved => 'Calificación guardada ⭐';

  @override
  String reviewFinishedTitle(String title) {
    return '¡Terminaste $title!';
  }

  @override
  String reviewYourReviewTitle(String title) {
    return 'Tu reseña de $title';
  }

  @override
  String reviewTitle(String title) {
    return 'Reseña de $title';
  }

  @override
  String get reviewAbandonedSubtitle => 'Lo dejaste sin terminar';

  @override
  String get reviewHowRate => '¿Cómo lo calificas?';

  @override
  String reviewStarsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '1 estrella',
    );
    return '$_temp0';
  }

  @override
  String get reviewHintAbandoned => '¿Por qué lo dejaste? (opcional)';

  @override
  String get reviewHint => '¿Qué te pareció? Una frase basta (opcional)';

  @override
  String get reviewNotNow => 'Ahora no';

  @override
  String get quotesGeneratingCard => 'Generando tarjeta...';

  @override
  String quotesShareText(String title) {
    return '📖 $title\n✨ Compartido desde Book Tracker';
  }

  @override
  String get quotesImageError =>
      'No se pudo crear la imagen. Inténtalo de nuevo.';

  @override
  String quotesCardPage(int page) {
    return 'Página $page';
  }

  @override
  String get quotesCardFooter => 'Leído en Book Tracker';

  @override
  String get quotesTitle => 'Mis citas';

  @override
  String quotesLoadError(String error) {
    return 'No se pudieron cargar las citas: $error';
  }

  @override
  String get quotesEmptyTitle => 'Aún no tienes citas';

  @override
  String get quotesEmptyDescription =>
      'Guarda frases y pensamientos desde la sección \"Notas y Citas\" de cada libro. Aparecerán todas aquí.';

  @override
  String get quotesSearchHint => 'Buscar en citas, títulos o autores';

  @override
  String get quotesClearSearch => 'Borrar búsqueda';

  @override
  String quotesFilterAll(int count) {
    return 'Todas ($count)';
  }

  @override
  String quotesFilterFavorites(int count) {
    return 'Favoritas ($count)';
  }

  @override
  String get quotesNoFavorites =>
      'Aún no tienes favoritas.\nToca la ☆ de una cita para guardarla aquí.';

  @override
  String get quotesNoMatches => 'Ninguna cita coincide con la búsqueda.';

  @override
  String quotesPageShort(int page) {
    return 'pág. $page';
  }

  @override
  String get quotesRemoveFavorite => 'Quitar de favoritas';

  @override
  String get quotesMarkFavorite => 'Marcar como favorita';

  @override
  String get quotesShareAsImage => 'Compartir como imagen';

  @override
  String get quotesCopy => 'Copiar';

  @override
  String get quotesCopied => 'Cita copiada';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusReading => 'Leyendo';

  @override
  String get statusFinished => 'Terminado';

  @override
  String get statusAbandoned => 'Abandonado';

  @override
  String homeLoadError(String error) {
    return 'Error: $error';
  }

  @override
  String get homeTitle => 'Mi biblioteca';

  @override
  String get homeEmptyTitle => 'Tu biblioteca está vacía';

  @override
  String get homeEmptyDescription =>
      'Parece un buen momento para empezar una nueva aventura.';

  @override
  String get homeAddFirstBook => 'Añadir mi primer libro';

  @override
  String get homeNoMatchesTitle => 'Sin coincidencias';

  @override
  String get homeNoMatchesDescription =>
      'No encontramos nada que coincida con tus filtros.';

  @override
  String get homeShowAllBooks => 'Ver todos los libros';

  @override
  String get homeSearchHint => 'Título o autor…';

  @override
  String get homeCloseSearch => 'Cerrar búsqueda';

  @override
  String get homeSearch => 'Buscar';

  @override
  String get homeMyQuotes => 'Mis citas';

  @override
  String get homeSort => 'Ordenar';

  @override
  String get homeSortTitle => 'Ordenar libros';

  @override
  String get homeSortRecentlyAdded => 'Añadido recientemente';

  @override
  String get homeSortMostProgress => 'Mayor progreso';

  @override
  String get homeSortLongest => 'Libros más largos';

  @override
  String get homeSortAlphabetical => 'Orden alfabético';

  @override
  String get homeSortShortRecent => 'Recientes';

  @override
  String get homeSortShortLongest => 'Más largos';

  @override
  String get homeSortShortAlphabetical => 'A–Z';

  @override
  String get homeFilterAll => 'Todos';

  @override
  String get homeFilterPending => 'Pendientes';

  @override
  String get homeFilterFinished => 'Terminados';

  @override
  String get homeFilterAbandoned => 'Abandonados';

  @override
  String homeBookCountSorted(int count, String sort) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros · $sort',
      one: '1 libro · $sort',
    );
    return '$_temp0';
  }

  @override
  String get homeListView => 'Vista de lista';

  @override
  String get homeGridView => 'Vista de cuadrícula';

  @override
  String get homeDeleteBookTitle => '¿Eliminar libro?';

  @override
  String homeDeleteBookMessage(String title) {
    return 'Esta acción borrará \"$title\" permanentemente.';
  }

  @override
  String get homeQuickStart => 'Empezar a leer';

  @override
  String get homeQuickFinish => 'Terminado';

  @override
  String get homeQuickResume => 'Retomar';

  @override
  String homeQuickStartedSnack(String title) {
    return 'Empezaste \"$title\"';
  }

  @override
  String homeQuickFinishedSnack(String title) {
    return 'Terminaste \"$title\"';
  }

  @override
  String homeQuickResumedSnack(String title) {
    return 'Retomaste \"$title\"';
  }

  @override
  String get homeTutorialSearchTitle => '🔍 Encuentra tus libros';

  @override
  String get homeTutorialSearchDescription =>
      'Busca rápidamente cualquier título o autor en tu colección.';

  @override
  String get homeTutorialQuotesTitle => '❝ Mis citas';

  @override
  String get homeTutorialQuotesDescription =>
      'Todas las frases y notas de tus libros en un solo lugar: búscalas, marca favoritas y compártelas.';

  @override
  String get homeTutorialSortTitle => '↕️ Organiza tu biblioteca';

  @override
  String get homeTutorialSortDescription =>
      'Ordena tus libros por progreso, tamaño o fecha de añadido.';

  @override
  String get homeTutorialAddTitle => '📚 Nueva aventura';

  @override
  String get homeTutorialAddDescription =>
      'Toca aquí para registrar un nuevo libro y empezar a leer.';

  @override
  String get homeContinueInSession => 'SESIÓN EN CURSO';

  @override
  String get homeContinueStart => 'EMPEZAR A LEER';

  @override
  String get homeContinueReading => 'CONTINUAR LEYENDO';

  @override
  String homeContinueProgress(int percent, int read, int total) {
    return '$percent% · $read de $total páginas';
  }

  @override
  String homeContinuePages(int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages páginas',
      one: '1 página',
    );
    return '$_temp0';
  }

  @override
  String get homeContinueViewSession => 'Ver la sesión';

  @override
  String get navBooks => 'Libros';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navTutorialStatsTitle => '📊​ Analiza tu progreso';

  @override
  String get navTutorialStatsDescription =>
      'Mira estadísticas detalladas sobre tus lecturas.';

  @override
  String get navTutorialSettingsTitle => '⚙️​ Configuración';

  @override
  String get navTutorialSettingsDescription =>
      'Personaliza el tema y gestiona tus datos.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingImportGoodreads => 'Importar de Goodreads';

  @override
  String get onboardingExploreFirst => 'Explorar primero';

  @override
  String get onboardingPage1Title => 'Tu biblioteca, en un toque';

  @override
  String get onboardingPage1Subtitle => 'Añade libros sin escribir de más.';

  @override
  String get onboardingPage1Point1 =>
      'Escanea el código de barras (ISBN) o escríbelo a mano';

  @override
  String get onboardingPage1Point2 =>
      'Búscalo por título y trae portada y páginas';

  @override
  String get onboardingPage1Point3 =>
      '¿Vienes de Goodreads? Importa toda tu biblioteca';

  @override
  String get onboardingPage2Title => 'Lee con foco';

  @override
  String get onboardingPage2Subtitle => 'Mide tus sesiones y ponte una meta.';

  @override
  String get onboardingPage2Point1 =>
      'Cronómetro de lectura que guarda tu página al terminar';

  @override
  String get onboardingPage2Point2 =>
      'Meta por sesión: te aviso al cumplirla, aunque bloquees el teléfono';

  @override
  String get onboardingPage2Point3 =>
      'Widget en tu pantalla de inicio para pausar sin abrir la app';

  @override
  String get onboardingPage3Title => 'Guarda lo que te marca';

  @override
  String get onboardingPage3Subtitle => 'Tus frases favoritas, siempre a mano.';

  @override
  String get onboardingPage3Point1 =>
      'Notas y citas con la página, también dictadas por voz';

  @override
  String get onboardingPage3Point2 =>
      'Mis citas: búscalas todas y compártelas como imagen';

  @override
  String get onboardingPage3Point3 =>
      'Califica y escribe tu reseña al terminar cada libro';

  @override
  String get onboardingPage4Title => 'Hazlo hábito';

  @override
  String get onboardingPage4Subtitle => 'Pequeños pasos, todos los días.';

  @override
  String get onboardingPage4Point1 => 'Racha diaria y aviso si está en riesgo';

  @override
  String get onboardingPage4Point2 =>
      'Reto anual: cuántos libros quieres leer este año';

  @override
  String get onboardingPage4Point3 =>
      'Tu año lector en una tarjeta para compartir';

  @override
  String get isbnNotAnIsbn =>
      'Ese código no es un ISBN. Busca el que empieza por 978 o 979.';

  @override
  String get isbnScanPrompt => 'Apunta al código de barras de la contraportada';

  @override
  String get isbnTypeIsbn => 'Escribir el ISBN';

  @override
  String get isbnWhereIsIt => '¿Dónde está el ISBN?';

  @override
  String get isbnTorchOn => 'Encender linterna';

  @override
  String get isbnTorchOff => 'Apagar linterna';

  @override
  String get isbnCameraPermission =>
      'Para escanear necesitamos permiso para usar la cámara.';

  @override
  String get isbnCameraError =>
      'No se pudo abrir la cámara. Puedes buscar el libro escribiendo su título.';

  @override
  String get isbnOpenSettings => 'Abrir ajustes';

  @override
  String get isbnHelpTitle => '¿Dónde encuentro el ISBN?';

  @override
  String get isbnHelpIntro =>
      'Es el número que identifica cada edición de un libro.';

  @override
  String get isbnHelpBackCoverTitle => 'En la contraportada';

  @override
  String get isbnHelpBackCoverText =>
      'Encima o debajo del código de barras, precedido de \"ISBN\". Puedes escanear el código de barras directamente.';

  @override
  String get isbnHelpCreditsTitle => 'En la página de créditos';

  @override
  String get isbnHelpCreditsText =>
      'Una de las primeras páginas del libro (donde aparecen la editorial y los derechos de autor).';

  @override
  String get isbnHelpDigitsTitle => '13 o 10 dígitos';

  @override
  String get isbnHelpDigitsText =>
      'Desde 2007 tiene 13 dígitos y empieza por 978 o 979. Los libros más antiguos usan 10 dígitos, y el último puede ser una X. Puedes escribirlo con o sin guiones.';

  @override
  String get isbnPartPrefix => 'Prefijo';

  @override
  String get isbnPartCountry => 'País o idioma';

  @override
  String get isbnPartPublisher => 'Editorial';

  @override
  String get isbnPartBook => 'Libro';

  @override
  String get isbnPartCheck => 'Control';

  @override
  String isbnLengthError(int count) {
    return 'Debe tener 10 o 13 dígitos (llevas $count)';
  }

  @override
  String get isbnChecksumError =>
      'Revisa los números: el último dígito no coincide';

  @override
  String get isbnManualTitle => 'Escribe el ISBN';

  @override
  String get isbnManualHelper =>
      '13 dígitos (empieza por 978 o 979) o 10 dígitos en libros antiguos.';

  @override
  String get isbnManualWhere => '¿Dónde lo encuentro?';

  @override
  String get isbnManualSearch => 'Buscar';

  @override
  String get addBookTooltip => 'Añadir libro';

  @override
  String addBookIsbnNotFound(String isbn) {
    return 'No encontramos el ISBN $isbn. Escribe los datos a mano.';
  }

  @override
  String addBookIsbnFound(String isbn) {
    return 'Encontrado por ISBN $isbn';
  }

  @override
  String get addBookIsbnSearchFailed =>
      'No se pudo buscar el ISBN. Escribe los datos a mano.';

  @override
  String get addBookTitleRequired => 'El título es obligatorio';

  @override
  String get addBookAuthorRequired => 'El autor es obligatorio';

  @override
  String addBookMaxChars(int max) {
    return 'Máximo $max caracteres';
  }

  @override
  String get addBookPagesRequired => 'Indica las páginas';

  @override
  String get addBookInvalidNumber => 'Número no válido';

  @override
  String addBookAlreadyRead(int pages) {
    return 'Ya leíste $pages';
  }

  @override
  String get addBookChangeCover => 'Cambiar portada';

  @override
  String get addBookCamera => 'Cámara';

  @override
  String get addBookGallery => 'Galería';

  @override
  String get addBookSaveError =>
      'No se pudo guardar el libro. Inténtalo de nuevo.';

  @override
  String get addBookScanBarcode => 'Escanear código de barras';

  @override
  String get addBookTitleLabel => 'Título del libro';

  @override
  String get addBookAuthorLabel => 'Autor';

  @override
  String get addBookDetails => 'Detalles del libro';

  @override
  String get addBookCategoryLabel => 'Categoría';

  @override
  String get addBookPagesLabel => 'Páginas';

  @override
  String get addBookReadingStatus => 'Estado de lectura';

  @override
  String get addBookAddToCollection => 'Añadir a la Colección';

  @override
  String get addBookUpdateLibrary => 'Actualizar Biblioteca';

  @override
  String get addBookStatusRead => 'Leído';

  @override
  String get addBookStatusDnf => 'DNF';

  @override
  String get searchHint => 'Buscar libro (título, autor o ISBN)';

  @override
  String get searchFailed =>
      'No se pudo buscar. Puedes escribir los datos a mano.';

  @override
  String searchIsbnNotFound(String isbn) {
    return 'No encontramos el ISBN $isbn. Revisa el número o escribe los datos a mano.';
  }

  @override
  String get searchNotFound => 'No lo encontramos. Escribe los datos a mano.';

  @override
  String searchIsbnResult(String isbn) {
    return 'Resultado por ISBN $isbn';
  }

  @override
  String searchPageCount(int count) {
    return '$count pág.';
  }

  @override
  String bookCardStatusReading(int percent) {
    return 'Leyendo · $percent%';
  }

  @override
  String bookCardStatusAbandoned(int read, int total) {
    return 'Abandonado · $read/$total p.';
  }

  @override
  String bookCardStatusPending(int total) {
    return 'Pendiente · $total p.';
  }

  @override
  String get bookCardEdit => 'Editar';

  @override
  String get notifChannelRemindersName => 'Recordatorios de Lectura';

  @override
  String get notifChannelRemindersDescription =>
      'Notificaciones diarias para fomentar la lectura';

  @override
  String get notifChannelSessionName => 'Meta de la sesión';

  @override
  String get notifChannelSessionDescription =>
      'Aviso cuando cumples la meta de tiempo de una sesión de lectura';

  @override
  String get notifChannelStreakName => 'Racha en riesgo';

  @override
  String get notifChannelStreakDescription =>
      'Aviso cuando llevas racha y aún no has leído hoy';

  @override
  String get notifDailyTitle => '¡Hora de leer!';

  @override
  String get notifDailyBody =>
      'Tu racha te espera. Abre un libro y relájate un momento.';

  @override
  String notifSessionGoalTitle(int minutes) {
    return '🎯 ¡Meta de $minutes min cumplida!';
  }

  @override
  String get notifSessionGoalBody =>
      'Puedes seguir leyendo o terminar la sesión y guardar tu página.';

  @override
  String get notifTestTitle => '¡Prueba de Lectura! 📖';

  @override
  String get notifTestBody =>
      'Esto es una notificación instantánea para verificar que todo funciona.';

  @override
  String get widgetEmptyTitle => 'Añade tu primer libro';

  @override
  String get widgetEmptySubtitle => 'Toca para empezar';

  @override
  String get widgetSessionReading => 'LEYENDO';

  @override
  String get widgetSessionPaused => 'EN PAUSA';

  @override
  String get widgetPause => 'Pausar';

  @override
  String get widgetResume => 'Reanudar';

  @override
  String get widgetFinish => 'Finalizar';

  @override
  String get widgetFinishDescription => 'Finalizar la sesión';

  @override
  String get widgetCover => 'Portada';

  @override
  String widgetToday(String minutes) {
    return 'Hoy $minutes min';
  }

  @override
  String widgetTodayGoal(String minutes, String goal) {
    return 'Hoy $minutes/$goal min';
  }

  @override
  String widgetPagesInfo(int read, int total) {
    return '$read/$total pág.';
  }

  @override
  String get widgetStatusToRead => 'Por leer';

  @override
  String get widgetStatusReading => 'Leyendo';

  @override
  String get widgetStatusFinished => 'Terminado';

  @override
  String get widgetStatusAbandoned => 'Abandonado';

  @override
  String get backupSvcReadFailed => 'No se pudo leer el archivo.';

  @override
  String get backupSvcZipDamaged => 'El archivo .zip está dañado.';

  @override
  String get backupSvcZipNotBackup =>
      'Este .zip no es un respaldo de Book Tracker.';

  @override
  String get backupSvcNotBackup =>
      'El archivo no es un respaldo de Book Tracker.';

  @override
  String get backupSvcUnknownFormat =>
      'El respaldo tiene un formato desconocido.';

  @override
  String get backupSvcNewerVersion =>
      'Este respaldo es de una versión más nueva de la app. Actualízala y vuelve a intentarlo.';

  @override
  String get backupSvcNoBooks =>
      'El respaldo está incompleto: no contiene libros.';

  @override
  String backupSvcDamagedBook(int number) {
    return 'El respaldo tiene datos dañados (libro $number). No se cambió nada.';
  }

  @override
  String get backupSvcCoversFailed =>
      'No se pudieron copiar las portadas. No se cambió nada.';

  @override
  String get backupSvcRestoreFailed =>
      'No se pudo restaurar el respaldo. Tu biblioteca no cambió.';

  @override
  String get exportShareSubject => 'Mi biblioteca de Book Tracker';

  @override
  String get importFileEmpty => 'El archivo está vacío.';

  @override
  String get importNotGoodreads =>
      'Este archivo no parece una exportación de Goodreads. Descárgala desde goodreads.com → Mis libros → Importar y exportar → Exportar biblioteca.';

  @override
  String get importUnknownAuthor => 'Desconocido';

  @override
  String get bookApiRateLimit =>
      'Demasiadas búsquedas seguidas. Inténtalo en un minuto.';

  @override
  String get bookApiNetwork =>
      'Sin conexión. Puedes escribir los datos a mano.';

  @override
  String get bookApiServer => 'El buscador no respondió. Inténtalo de nuevo.';

  @override
  String get bookApiUnknownAuthor => 'Autor desconocido';

  @override
  String get purchaseStartFailed => 'No se pudo iniciar la compra.';

  @override
  String get purchaseNotCompleted => 'La compra no se completó.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsReminderTimeHelp => 'Hora del recordatorio';

  @override
  String get settingsStreakRiskTimeHelp => 'Hora del aviso de racha';

  @override
  String get settingsPermissionTitle => '¡No pierdas el hilo!';

  @override
  String get settingsPermissionBody =>
      'Activamos recordatorios diarios para ayudarte a mantener tu racha de lectura y alcanzar tus metas. ¡Tu refugio digital te espera!';

  @override
  String get settingsNotNow => 'Ahora no';

  @override
  String get settingsPermissionAccept => '¡Claro que sí!';

  @override
  String get settingsGotIt => 'Entendido';

  @override
  String get settingsSectionAppearance => 'APARIENCIA';

  @override
  String get settingsThemeTitle => 'Tema de la aplicación';

  @override
  String get settingsThemeFollowSystem => 'Seguir sistema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Modo Claro';

  @override
  String get settingsThemeDark => 'Modo Oscuro';

  @override
  String get settingsColorsTitle => 'Colores';

  @override
  String get settingsColorsWallpaper => 'Del fondo de pantalla';

  @override
  String get settingsColorsBrandDescription =>
      'Crema y verde abeto de día, ciruela y ámbar de noche.';

  @override
  String get settingsColorsWallpaperDescription =>
      'Material You: los colores de tu fondo de pantalla.';

  @override
  String get settingsColorsUnavailable =>
      'Disponible en Android 12 o superior.';

  @override
  String get settingsSectionPreferences => 'PREFERENCIAS';

  @override
  String get settingsDailyNotificationsTitle => 'Notificaciones diarias';

  @override
  String settingsDailyReminderAt(String time) {
    return 'Recordatorio a las $time';
  }

  @override
  String get settingsDailyNotificationsOff => 'Desactivadas';

  @override
  String get settingsOff => 'Desactivado';

  @override
  String get settingsStreakRiskTitle => 'Aviso de racha en riesgo';

  @override
  String get settingsStreakRiskNoPermission =>
      '⚠️ Falta el permiso de notificaciones. Toca para activarlo.';

  @override
  String settingsStreakRiskSubtitle(String time) {
    return 'Si llevas racha y hoy no has leído, te aviso a las $time';
  }

  @override
  String get settingsStreakRiskNeedsPermission =>
      'Activa las notificaciones de Book Tracker para recibir el aviso.';

  @override
  String get settingsSectionSecurity => 'SEGURIDAD';

  @override
  String get settingsAppLockTitle => 'Bloqueo de la app';

  @override
  String get settingsAppLockOn => 'Pide tu palabra secreta al abrir';

  @override
  String get settingsAppLockOff => 'Desactivado: la app abre directamente';

  @override
  String get settingsChangePassphraseTitle => 'Cambiar palabra secreta';

  @override
  String get settingsChangePassphraseSubtitle =>
      'Tu \"Santo y Seña\" para entrar';

  @override
  String get settingsChangePin => 'Cambiar PIN de respaldo';

  @override
  String get settingsSetUpPin => 'Configurar PIN de respaldo';

  @override
  String get settingsPinSubtitle =>
      'Un código de 4 dígitos por si no recuerdas la palabra';

  @override
  String get settingsAutoLockTitle => 'Bloquear al salir';

  @override
  String get settingsAutoLockNever => 'Nunca: solo al abrir la app';

  @override
  String settingsAutoLockAfter(int minutes) {
    return 'Tras $minutes min fuera de la app';
  }

  @override
  String get settingsAutoLockDescription =>
      'Vuelve a pedir tu palabra si sales de la app durante este tiempo. Al desbloquear sigues donde estabas.';

  @override
  String get settingsAutoLockNeverOption => 'Nunca';

  @override
  String settingsAutoLockAfterOption(int minutes) {
    return 'Tras $minutes min';
  }

  @override
  String get settingsLockEnabled => '🔒 Bloqueo activado';

  @override
  String get settingsLockDisabled => 'Bloqueo desactivado';

  @override
  String get settingsPassphraseUpdated => '✨ Palabra secreta actualizada';

  @override
  String get settingsPinSaved => 'PIN de respaldo guardado';

  @override
  String get settingsSectionData => 'DATOS';

  @override
  String get settingsExportTitle => 'Respaldar o exportar';

  @override
  String get settingsExportSubtitle =>
      'Guarda una copia de tus libros, notas y portadas';

  @override
  String get settingsExportFullTitle => 'Respaldo completo (.zip)';

  @override
  String get settingsExportFullSubtitle =>
      'Todo, con portadas. Sirve para restaurar en otro teléfono.';

  @override
  String get settingsExportJsonTitle => 'Datos sin portadas (JSON)';

  @override
  String get settingsExportJsonSubtitle =>
      'Libros, notas y sesiones de lectura.';

  @override
  String get settingsExportCsvTitle => 'Hoja de cálculo (CSV)';

  @override
  String get settingsExportCsvSubtitle =>
      'Lista de libros para Excel o Google Sheets.';

  @override
  String get settingsExportEmpty =>
      'Tu biblioteca está vacía: el archivo no tiene libros.';

  @override
  String get settingsExportError => 'No se pudo exportar. Inténtalo de nuevo.';

  @override
  String get settingsRestoreTitle => 'Restaurar respaldo';

  @override
  String get settingsRestoreSubtitle =>
      'Desde un respaldo .zip o una exportación .json';

  @override
  String get settingsGoodreadsSubtitle =>
      'Añade tus libros desde el archivo .csv de Goodreads';

  @override
  String get settingsUndoRestoreTitle => 'Deshacer la última restauración';

  @override
  String get settingsUndoRestoreSubtitle =>
      'Vuelve a la biblioteca que tenías antes';

  @override
  String get settingsSectionNoAds => 'SIN ANUNCIOS';

  @override
  String get settingsSectionWhatsNew => 'NOVEDADES';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String settingsReleaseNotesSubtitle(String version) {
    return 'Lo nuevo en la versión $version y anteriores';
  }

  @override
  String get settingsReplayWelcomeTitle => 'Ver la bienvenida de nuevo';

  @override
  String get settingsReplayWelcomeSubtitle =>
      'Repasa lo que puedes hacer en Book Tracker';

  @override
  String get settingsSectionSupport => 'SOPORTE';

  @override
  String get settingsAdPrivacyTitle => 'Opciones de privacidad de anuncios';

  @override
  String get settingsAdPrivacySubtitle =>
      'Cambia tu consentimiento para anuncios personalizados';

  @override
  String get aboutTitle => 'Acerca de la App';

  @override
  String get aboutTagline => 'Tu refugio de lectura digital';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutDeveloper => 'Desarrollador';

  @override
  String get aboutLicense => 'Licencia';

  @override
  String get aboutFooter => '© 2026 - Hecho con ❤️ para lectores';

  @override
  String get updateAvailableTitle => 'Hay una versión nueva';

  @override
  String get updateTapToUpdate => 'Toca para actualizar';

  @override
  String get updateDownloadingTitle => 'Descargando actualización…';

  @override
  String get updateKeepUsing => 'Puedes seguir usando la app';

  @override
  String get updateReadyTitle => 'Actualización lista';

  @override
  String get updateTapToRestart => 'Toca para reiniciar e instalarla';

  @override
  String get updateCheckingTitle => 'Buscando actualizaciones…';

  @override
  String get updateCheckTitle => 'Buscar actualizaciones';

  @override
  String updateUpToDateSubtitle(String version) {
    return 'Versión $version · Estás al día';
  }

  @override
  String get updateDownloaded => 'Actualización descargada';

  @override
  String get updateRestart => 'Reiniciar';

  @override
  String get updateDownloadingNew => 'Descargando la versión nueva…';

  @override
  String get updateLatest => 'Tienes la última versión';

  @override
  String get updateCheckFailed =>
      'No se pudo comprobar. Las actualizaciones llegan desde Google Play.';

  @override
  String get updatePromptBody =>
      'Actualiza para tener las últimas mejoras. Se descarga mientras sigues usando la app.';

  @override
  String get updateButton => 'Actualizar';

  @override
  String get backupPreparing => 'Preparando el respaldo…';

  @override
  String get backupShareSubject => 'Respaldo de Book Tracker';

  @override
  String get backupCreateError =>
      'No se pudo crear el respaldo. Inténtalo de nuevo.';

  @override
  String get backupPickTitle => 'Elige tu respaldo';

  @override
  String get backupReading => 'Leyendo el respaldo…';

  @override
  String get backupRestoring => 'Restaurando tu biblioteca…';

  @override
  String backupBooksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String backupNotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String backupSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones de lectura',
      one: '1 sesión de lectura',
    );
    return '$_temp0';
  }

  @override
  String backupCoversCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portadas',
      one: '1 portada',
      zero: 'Sin portadas',
    );
    return '$_temp0';
  }

  @override
  String backupUndoDone(String books) {
    return 'Biblioteca anterior recuperada: $books.';
  }

  @override
  String backupRestoreDone(String books, String notes) {
    return 'Biblioteca restaurada: $books, $notes.';
  }

  @override
  String get backupRestoreError =>
      'No se pudo restaurar el respaldo. Tu biblioteca no cambió.';

  @override
  String get backupUndoConfirmTitle => '¿Deshacer la última restauración?';

  @override
  String get backupRestoreConfirmTitle => '¿Restaurar este respaldo?';

  @override
  String backupSavedOn(String date) {
    return 'Biblioteca guardada el $date';
  }

  @override
  String backupFrom(String date) {
    return 'Respaldo del $date';
  }

  @override
  String backupReplaceWarning(String books) {
    return 'Reemplazará tu biblioteca actual ($books). Antes guardaremos una copia para que puedas deshacerlo.';
  }

  @override
  String get backupUndoButton => 'DESHACER';

  @override
  String get backupRestoreButton => 'RESTAURAR';

  @override
  String get backupErrorTitle => 'No se pudo completar';

  @override
  String get goodreadsImportTitle => 'Importar de Goodreads';

  @override
  String get goodreadsPickTitle => 'Elige el CSV de Goodreads';

  @override
  String get goodreadsFileTooLarge =>
      'El archivo es demasiado grande para ser una exportación de Goodreads.';

  @override
  String get goodreadsReadErrorTitle => 'No se pudo leer el archivo';

  @override
  String get goodreadsReadErrorBody =>
      'Asegúrate de elegir el archivo .csv que descargaste de Goodreads.';

  @override
  String get goodreadsNothingNewTitle => 'Nada nuevo que importar';

  @override
  String goodreadsAllDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Los $count libros del archivo ya están en tu biblioteca.',
      one: 'El libro del archivo ya está en tu biblioteca.',
    );
    return '$_temp0';
  }

  @override
  String get goodreadsNoBooks => 'El archivo no tiene libros.';

  @override
  String get goodreadsImportErrorTitle => 'No se pudo importar';

  @override
  String get goodreadsImportErrorBody =>
      'No se añadió ningún libro. Inténtalo de nuevo.';

  @override
  String goodreadsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros importados de Goodreads 📚',
      one: '1 libro importado de Goodreads 📚',
    );
    return '$_temp0';
  }

  @override
  String get goodreadsUndo => 'DESHACER';

  @override
  String get goodreadsUndone => 'Importación deshecha';

  @override
  String get goodreadsNoCovers =>
      'No se encontraron portadas en Open Library. Puedes añadirlas editando cada libro.';

  @override
  String goodreadsCoversFound(int found, int total) {
    return 'Portadas encontradas: $found de $total.';
  }

  @override
  String get goodreadsHowToIntro =>
      'Primero descarga tu biblioteca desde Goodreads:';

  @override
  String get goodreadsHowToStep1 =>
      '1. Entra a goodreads.com en el navegador (la app de Goodreads no permite exportar).';

  @override
  String get goodreadsHowToStep2 =>
      '2. Ve a Mis libros → Importar y exportar (Import and export).';

  @override
  String get goodreadsHowToStep3 =>
      '3. Toca \"Exportar biblioteca\" (Export Library) y descarga el archivo .csv cuando esté listo.';

  @override
  String get goodreadsHowToNote =>
      'Tus libros actuales no se borran: solo se añaden los que faltan.';

  @override
  String get goodreadsChooseFile => 'Elegir archivo';

  @override
  String goodreadsCountRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leídos',
      one: '1 leído',
    );
    return '$_temp0';
  }

  @override
  String goodreadsCountReading(int count) {
    return '$count leyendo';
  }

  @override
  String goodreadsCountToRead(int count) {
    return '$count por leer';
  }

  @override
  String goodreadsCountAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abandonados',
      one: '1 abandonado',
    );
    return '$_temp0';
  }

  @override
  String goodreadsCountNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reseñas y notas (se guardan como notas)',
      one: '1 reseña o nota (se guarda como nota)',
    );
    return '$_temp0';
  }

  @override
  String goodreadsConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Importar $count libros?',
      one: '¿Importar 1 libro?',
    );
    return '$_temp0';
  }

  @override
  String goodreadsSkippedDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se omiten $count que ya están en tu biblioteca.',
      one: 'Se omite 1 que ya está en tu biblioteca.',
    );
    return '$_temp0';
  }

  @override
  String goodreadsSkippedInvalid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se omiten $count filas sin título.',
      one: 'Se omite 1 fila sin título.',
    );
    return '$_temp0';
  }

  @override
  String get goodreadsNoReadingTime =>
      'Goodreads no guarda el tiempo de lectura, así que la racha y el mapa de calor no cambian. Los leídos con fecha cuentan en el reto de su año.';

  @override
  String get goodreadsFetchCovers => 'Buscar portadas';

  @override
  String goodreadsFetchCoversSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros con ISBN · usa internet',
      one: '1 libro con ISBN · usa internet',
    );
    return '$_temp0';
  }

  @override
  String get goodreadsImportButton => 'Importar';

  @override
  String get authCreatePassphraseTitle => 'Crea tu Santo y Seña';

  @override
  String get secretNewPassphraseTitle => 'Nueva palabra secreta';

  @override
  String get secretPinTitle => 'PIN de respaldo';

  @override
  String get secretConfirmIdentity => 'Confirma que eres tú';

  @override
  String secretPinLengthError(int length) {
    return 'Deben ser $length dígitos';
  }

  @override
  String get secretMinLengthError => 'Al menos 3 caracteres';

  @override
  String get secretMismatch => 'No coinciden';

  @override
  String get secretCaseHint =>
      'No distingue mayúsculas. Elige algo que recuerdes.';

  @override
  String get secretNewPinLabel => 'Nuevo PIN';

  @override
  String get secretPassphraseLabel => 'Palabra secreta';

  @override
  String get secretRepeatPin => 'Repite el PIN';

  @override
  String get secretRepeatPassphrase => 'Repite la palabra';

  @override
  String get secretPassphraseOrPin => 'Palabra secreta o PIN';

  @override
  String get secretWrong => 'No es correcta';

  @override
  String get secretConfirm => 'Confirmar';

  @override
  String get removeAdsPurchaseFailed => 'La compra no se completó.';

  @override
  String get removeAdsPending =>
      'Tu pago está pendiente. Los anuncios se quitarán cuando Google Play lo confirme.';

  @override
  String get removeAdsActiveTitle => 'Sin anuncios';

  @override
  String get removeAdsThanks => '¡Gracias por apoyar Book Tracker! 💜';

  @override
  String get removeAdsTitle => 'Quitar anuncios';

  @override
  String get removeAdsDescription =>
      'Pago único, para siempre. Sin anuncios en la biblioteca, estadísticas ni citas, y \"Salvar racha\" gratis. Se mantiene si reinstalas o cambias de teléfono con la misma cuenta de Google.';

  @override
  String get removeAdsUnavailable => 'No disponible por ahora';

  @override
  String get removeAdsBuy => 'Comprar';

  @override
  String removeAdsBuyFor(String price) {
    return 'Comprar por $price';
  }

  @override
  String get removeAdsRestore => 'Restaurar';

  @override
  String get loginPassphraseSavedTitle => '✨ Palabra Guardada';

  @override
  String get loginOfferPinBody =>
      '¿Quieres un PIN de 4 dígitos como respaldo? Podrás configurarlo después en Ajustes.';

  @override
  String get loginSetUpPin => 'Configurar PIN';

  @override
  String get loginSkipLockTitle => '¿Usar sin bloqueo?';

  @override
  String get loginSkipLockBody =>
      'Cualquiera con acceso a tu teléfono podrá abrir tu biblioteca. Puedes activar el bloqueo cuando quieras en Ajustes → Seguridad.';

  @override
  String get loginSkipLock => 'Usar sin bloqueo';

  @override
  String get loginWrongPassphrase => 'Esa no es la palabra mágica...';

  @override
  String loginTooManyAttemptsWait(String time) {
    return 'Demasiados intentos. Espera $time para volver a probar.';
  }

  @override
  String loginWait(String time) {
    return 'Espera $time para volver a probar.';
  }

  @override
  String get loginWrongPin => 'El PIN no es correcto.';

  @override
  String get loginBiometricReason => 'Acceso rápido a tu biblioteca';

  @override
  String get loginCannotVerifyTitle => 'No podemos verificar que eres tú';

  @override
  String get loginCannotVerifyBody =>
      'Para recuperar el acceso, activa un bloqueo de pantalla (PIN, patrón o huella) en los ajustes de tu teléfono y vuelve a intentarlo. Tus libros siguen a salvo.';

  @override
  String get loginRecoverReason =>
      'Verifica que eres tú para elegir una palabra nueva';

  @override
  String get loginChooseNewPassphrase => 'Elige una palabra nueva';

  @override
  String get loginSetupTitle => 'Crea tu Santo y Seña para iniciar la aventura';

  @override
  String get loginPinTitle => 'Introduce tu PIN de respaldo';

  @override
  String get loginPassphraseTitle => 'Di la palabra mágica para entrar';

  @override
  String get loginUsePassphrase => 'Usar Santo y Seña';

  @override
  String get loginUsePin => 'Usar PIN de respaldo';

  @override
  String get loginForgotPin => '¿Olvidaste tu PIN?';

  @override
  String get loginForgotPassphrase => '¿Olvidaste tu palabra secreta?';

  @override
  String loginLockoutBanner(String time) {
    return 'Demasiados intentos. Podrás volver a probar en $time.\nMientras, puedes usar la huella o «¿Olvidaste…?».';
  }

  @override
  String get loginSetupBody =>
      'Una palabra secreta protege tu biblioteca. Si la olvidas, podrás recuperarla con el bloqueo de tu teléfono.';

  @override
  String get loginCreatePassphrase => 'Crear palabra secreta';

  @override
  String get loginPassphraseHint => 'Escribe la palabra...';

  @override
  String get loginUseFingerprint => 'Usar huella';

  @override
  String get loginReveal => 'Revelar biblioteca';

  @override
  String get whatsNewTitle => 'Notas de la versión';

  @override
  String get whatsNewHistorySubtitle =>
      'Lo que ha cambiado en cada versión de Book Tracker.';

  @override
  String get whatsNewHeadline => 'Lo nuevo en Book Tracker';

  @override
  String get whatsNewStart => 'Empezar';

  @override
  String whatsNewLatestLabel(String version) {
    return 'NOVEDADES · $version';
  }

  @override
  String whatsNewVersionLabel(String version) {
    return 'VERSIÓN $version';
  }

  @override
  String get whatsNew141CameraQuotesTitle => 'Citas con la cámara';

  @override
  String get whatsNew141CameraQuotesText =>
      'Fotografía una página y subraya con el dedo la frase que quieres guardar. Con zoom y lupa para más precisión.';

  @override
  String get whatsNew141OnDeviceTitle => 'Todo en tu teléfono';

  @override
  String get whatsNew141OnDeviceText =>
      'El texto se reconoce en tu dispositivo: la foto no se envía a ningún sitio.';

  @override
  String get whatsNew141CalendarTitle => 'Calendario de lectura';

  @override
  String get whatsNew141CalendarText =>
      'Cada día coloreado según cuánto leíste. Toca un día para ver qué libros leíste.';

  @override
  String get whatsNew141MonthlyChartTitle => 'Gráfico mensual más claro';

  @override
  String get whatsNew141MonthlyChartText =>
      'Escala redonda y barras que nacen en el cero.';

  @override
  String get whatsNew140RedesignTitle => 'Diseño renovado';

  @override
  String get whatsNew140RedesignText =>
      'Más limpio y tranquilo, con nuevos colores, tipografía y modo oscuro.';

  @override
  String get whatsNew140PhoneColorsTitle => 'Colores de tu teléfono';

  @override
  String get whatsNew140PhoneColorsText =>
      'En Ajustes > Colores puedes usar la paleta de tu fondo de pantalla.';

  @override
  String get whatsNew140ContinueReadingTitle => 'Continuar leyendo';

  @override
  String get whatsNew140ContinueReadingText =>
      'Tu libro actual arriba de la biblioteca: retoma la sesión en un toque.';

  @override
  String get whatsNew140ListGridTitle => 'Lista o cuadrícula';

  @override
  String get whatsNew140ListGridText =>
      'Elige cómo ver tu biblioteca y filtra por estado o categoría.';

  @override
  String get whatsNew140SwipeTitle => 'Desliza para actuar';

  @override
  String get whatsNew140SwipeText =>
      'A la derecha: empezar o terminar un libro, con Deshacer. A la izquierda: borrar.';

  @override
  String get whatsNew140BookDetailTitle => 'Detalle del libro';

  @override
  String get whatsNew140BookDetailText =>
      'Rediseñado, con tu ritmo, lo que falta y tus notas como citas.';

  @override
  String get whatsNew140StatsTilesTitle => 'Estadísticas en mosaico';

  @override
  String get whatsNew140StatsTilesText =>
      'Racha, tu mejor racha y la semana de un vistazo.';

  @override
  String get whatsNew140BackGestureTitle => 'Gesto atrás';

  @override
  String get whatsNew140BackGestureText =>
      'Desliza para volver y mira a dónde vas; \"atrás\" vuelve a Libros antes de salir.';

  @override
  String get whatsNew140UpdateAlertsTitle => 'Avisos de actualización';

  @override
  String get whatsNew140UpdateAlertsText =>
      'Te avisamos cuando haya una versión nueva y la instalas sin salir de la app.';

  @override
  String get whatsNew140ReleaseNotesTitle => 'Notas de la versión';

  @override
  String get whatsNew140ReleaseNotesText =>
      'Consulta las novedades cuando quieras en Ajustes > Novedades.';

  @override
  String get whatsNew130FasterTitle => 'Más rápida y ligera';

  @override
  String get whatsNew130FasterText => 'La app ocupa menos y abre antes.';

  @override
  String get whatsNew130SaferTitle => 'Más segura';

  @override
  String get whatsNew130SaferText =>
      'Tu palabra secreta se guarda con el almacenamiento seguro más reciente.';

  @override
  String get whatsNew130PurchasesTitle => 'Compras más fiables';

  @override
  String get whatsNew130PurchasesText =>
      '\"Quitar anuncios\" reconoce mejor las compras pendientes y los reembolsos.';

  @override
  String get whatsNew121RemoveAdsTitle => 'Quitar anuncios';

  @override
  String get whatsNew121RemoveAdsText =>
      'Un único pago para usar la app sin anuncios, para siempre.';

  @override
  String get whatsNew120IsbnScannerTitle => 'Escáner de ISBN';

  @override
  String get whatsNew120IsbnScannerText =>
      'Añade un libro escaneando su código de barras o escribiendo el ISBN.';

  @override
  String get whatsNew120MyQuotesTitle => 'Mis citas';

  @override
  String get whatsNew120MyQuotesText =>
      'Todas tus notas en un lugar: búscalas, marca favoritas y compártelas.';

  @override
  String get whatsNew120ChallengeTitle => 'Reto anual y fechas';

  @override
  String get whatsNew120ChallengeText =>
      'Fechas de inicio y fin de cada libro y tu meta de libros del año.';

  @override
  String get whatsNew120SessionGoalTitle => 'Meta por sesión';

  @override
  String get whatsNew120SessionGoalText =>
      'Elige 15–60 min o una página y te aviso al cumplirla.';

  @override
  String get whatsNew120ReviewsTitle => 'Reseñas';

  @override
  String get whatsNew120ReviewsText =>
      'Califica y reseña al terminar un libro (o cuando quieras).';

  @override
  String get whatsNew120StreakRiskTitle => 'Racha en riesgo';

  @override
  String get whatsNew120StreakRiskText =>
      'Un aviso por la noche si aún no has leído y llevas racha.';

  @override
  String get whatsNew120WidgetTitle => 'Widget renovado';

  @override
  String get whatsNew120WidgetText =>
      'Con la portada de tu libro y pausa en un toque.';

  @override
  String get whatsNew120ReadingYearTitle => 'Mi año lector';

  @override
  String get whatsNew120ReadingYearText =>
      'Comparte una tarjeta con tus estadísticas del año.';

  @override
  String get whatsNew120GoodreadsTitle => 'Goodreads y respaldos';

  @override
  String get whatsNew120GoodreadsText =>
      'Importa tu biblioteca de Goodreads y guarda una copia completa con portadas.';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsShareTooltip => 'Compartir mi año lector';

  @override
  String statsShareEmpty(int year) {
    return 'Aún no hay lecturas en $year para compartir. ¡Empieza un libro!';
  }

  @override
  String statsError(String error) {
    return 'Error: $error';
  }

  @override
  String get statsToday => 'Hoy';

  @override
  String statsTodayProgress(int minutes, int goal) {
    return '$minutes de $goal min';
  }

  @override
  String get statsBooksRead => 'Libros leídos';

  @override
  String get statsPages => 'Páginas';

  @override
  String get statsTotalTime => 'Tiempo total';

  @override
  String get statsFavoriteGenres => 'Géneros favoritos';

  @override
  String get statsAchievementsTitle => 'Logros y desafíos';

  @override
  String get statsChartMinutes => 'MINUTOS';

  @override
  String get statsChartDayOfMonth => 'DÍA DEL MES';

  @override
  String statsChartBarMinutes(int minutes) {
    return '$minutes m';
  }

  @override
  String get streakCurrent => 'Racha actual';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String streakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return 'Tu mejor racha: $_temp0';
  }

  @override
  String streakRiskTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '🔥 Tu racha de $_temp0 está en riesgo';
  }

  @override
  String get streakRiskBody =>
      'Aún no has leído hoy. Lee unos minutos antes de medianoche para no perderla.';

  @override
  String streakSaveSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '🔥 ¡Racha salvada! Sigues con $_temp0. Lee hoy para mantenerla.';
  }

  @override
  String get streakSaveAdIncomplete =>
      'Hay que ver el anuncio completo para salvar la racha.';

  @override
  String get streakSaveAdUnavailable =>
      'Ahora no hay anuncios disponibles. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String streakSaveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return 'Tu racha de $_temp0 se rompió';
  }

  @override
  String get streakSaveBodyFree =>
      'Ayer no registraste lectura. Como usuario sin anuncios, puedes recuperarla gratis: ayer contará para tu racha.';

  @override
  String get streakSaveBodyAd =>
      'Ayer no registraste lectura. Mira un anuncio corto y la recuperamos: ayer contará para tu racha.';

  @override
  String get streakSaveOncePerWeek => 'Puedes hacerlo una vez por semana.';

  @override
  String get streakSaveLoadingAd => 'Cargando anuncio…';

  @override
  String get streakSaveFreeButton => 'Salvar mi racha';

  @override
  String get streakSaveWatchAdButton => 'Ver anuncio y salvar mi racha';

  @override
  String get streakSaveNotNow => 'Ahora no';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get calendarPreviousMonth => 'Mes anterior';

  @override
  String get calendarNextMonth => 'Mes siguiente';

  @override
  String get calendarHistoryStartsHere =>
      'Tu historial empieza aquí: aún no hay meses anteriores con lecturas.';

  @override
  String calendarHistoryStartsIn(String month) {
    return 'Tu historial empieza en $month.';
  }

  @override
  String get calendarCurrentMonth => 'Este es el mes actual.';

  @override
  String calendarDaySavedSemantics(String day) {
    return '$day, racha salvada';
  }

  @override
  String calendarDayNoReadingSemantics(String day) {
    return '$day, sin lectura';
  }

  @override
  String calendarDayReadingSemantics(String day, String duration, int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages páginas',
      one: '1 página',
    );
    return '$day, $duration, $_temp0';
  }

  @override
  String get calendarLegendLess => 'Menos';

  @override
  String get calendarLegendMore => 'Más';

  @override
  String get calendarNoReadingYetThisMonth =>
      'Aún no has leído este mes. Toca un día para ver su detalle.';

  @override
  String get calendarNoReadingThisMonth => 'No hay lecturas este mes.';

  @override
  String calendarDaysReadLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días leídos',
      one: 'día leído',
    );
    return '$_temp0';
  }

  @override
  String get calendarTotalLabel => 'en total';

  @override
  String calendarPagesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'páginas',
      one: 'página',
    );
    return '$_temp0';
  }

  @override
  String calendarPagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0';
  }

  @override
  String calendarPagesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count págs.',
      one: '1 pág.',
    );
    return '$_temp0';
  }

  @override
  String calendarBestDay(String date, String amount) {
    return 'Tu mejor día: $date · $amount';
  }

  @override
  String get calendarDaySavedDetail =>
      'No leíste, pero salvaste tu racha este día.';

  @override
  String get calendarDayNoReadingDetail => 'Este día no leíste.';

  @override
  String get calendarDeletedBook => 'Libro eliminado';

  @override
  String get challengeFinishedBooksTitle => 'Libros terminados';

  @override
  String get challengeNoDatedBooks => 'Aún no hay libros terminados con fecha.';

  @override
  String challengeYearHeader(String year, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
      one: '1 libro',
    );
    return '$year · $_temp0';
  }

  @override
  String challengeUndatedBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros terminados no tienen fecha de fin.',
      one: '1 libro terminado no tiene fecha de fin.',
    );
    return '$_temp0 Puedes añadirla en el detalle de cada libro para que cuente en su año.';
  }

  @override
  String challengeTitleWithYear(String year) {
    return 'Reto de lectura $year';
  }

  @override
  String get challengeSetGoalPrompt =>
      'Ponte una meta de libros para este año.';

  @override
  String challengeFinishedSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros terminados',
      one: '1 libro terminado',
    );
    return 'Llevas $_temp0 este año. ¿Te pones una meta?';
  }

  @override
  String get challengeCreate => 'Crear reto';

  @override
  String get challengeShowBooks => 'Ver libros';

  @override
  String challengeOfGoal(int goal) {
    return 'de $goal';
  }

  @override
  String challengeShortTitle(String year) {
    return 'Reto $year';
  }

  @override
  String get challengeChangeGoal => 'Cambiar meta';

  @override
  String challengeDoneCount(int finished, int goal) {
    return '$finished de $goal libros';
  }

  @override
  String challengeRemaining(int count) {
    return '$count por leer para tu meta';
  }

  @override
  String get challengeShowFinished => 'Ver libros terminados';

  @override
  String get challengeDialogQuestion =>
      '¿Cuántos libros quieres leer este año?';

  @override
  String get challengeBooksSuffix => 'libros';

  @override
  String challengeGoalRange(int max) {
    return 'Entre 1 y $max';
  }

  @override
  String get challengeRemove => 'Quitar reto';

  @override
  String get challengeCompleted => '¡Reto cumplido!';

  @override
  String challengeExceeded(int extra) {
    return '¡Reto superado! +$extra';
  }

  @override
  String challengeAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
      one: '1 libro',
    );
    return 'Vas $_temp0 adelantado';
  }

  @override
  String challengeBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
      one: '1 libro',
    );
    return 'Vas $_temp0 atrasado';
  }

  @override
  String get challengeOnTrack => 'Vas al día';

  @override
  String get yearSummaryHeading => 'MI AÑO LECTOR';

  @override
  String yearSummaryBooksFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'libros\nterminados',
      one: 'libro\nterminado',
    );
    return '$_temp0';
  }

  @override
  String yearSummaryGoalDone(int goal) {
    return '🏆 ¡Reto de $goal libros cumplido!';
  }

  @override
  String yearSummaryGoalProgress(int finished, int goal) {
    return 'Reto: $finished de $goal libros';
  }

  @override
  String get yearSummaryPages => 'páginas';

  @override
  String get yearSummaryReadingTime => 'leyendo';

  @override
  String yearSummaryReadingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días con lectura',
      one: 'día con lectura',
    );
    return '$_temp0';
  }

  @override
  String yearSummaryLongestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días de racha máx.',
      one: 'día de racha',
    );
    return '$_temp0';
  }

  @override
  String yearSummaryFavoriteGenre(String genre) {
    return 'Género favorito: $genre';
  }

  @override
  String get yearSummaryRecentlyFinished => 'Últimos terminados';

  @override
  String yearSummaryShareText(String year) {
    return 'Mi año lector $year 📚 #BookTracker';
  }

  @override
  String get yearSummaryShareError =>
      'No se pudo crear la imagen. Inténtalo de nuevo.';

  @override
  String get yearSummaryShare => 'Compartir';

  @override
  String get achievementCategoryEarly => 'Disciplina Temprana';

  @override
  String get achievementCategorySerious => 'Compromiso Serio';

  @override
  String get achievementCategoryScholar => 'Nivel Erudito (3 años+)';

  @override
  String get achievementHabitFormedName => 'Hábito Formado';

  @override
  String get achievementHabitFormedDesc => 'Racha de 21 días';

  @override
  String get achievementSprinterName => 'Velocista';

  @override
  String get achievementSprinterDesc => '500 páginas leídas';

  @override
  String get achievementVoraciousReaderName => 'Lector Voraz';

  @override
  String get achievementVoraciousReaderDesc => '50 libros terminados';

  @override
  String get achievementHalfMarathonName => 'Medio Maratón';

  @override
  String get achievementHalfMarathonDesc => '250 horas de lectura';

  @override
  String get achievementPureConsistencyName => 'Constancia Pura';

  @override
  String get achievementPureConsistencyDesc => 'Racha de 100 días';

  @override
  String get achievementGoldenBibliophileName => 'Bibliófilo de Oro';

  @override
  String get achievementGoldenBibliophileDesc => '100.000 páginas leídas';

  @override
  String get achievementLifeAmongBooksName => 'Vida Entre Libros';

  @override
  String get achievementLifeAmongBooksDesc => '1.000 horas de lectura';

  @override
  String get achievementUnbreakableName => 'Inquebrantable';

  @override
  String get achievementUnbreakableDesc => 'Racha de 365 días';

  @override
  String get achievementLibraryMasterName => 'Maestro de Biblioteca';

  @override
  String get achievementLibraryMasterDesc => '250 libros completados';
}
