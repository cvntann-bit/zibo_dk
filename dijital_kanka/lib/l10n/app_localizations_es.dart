// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Zibo';

  @override
  String get homeAppBarTitle => 'Zibo';

  @override
  String coinBalanceLabel(int count) {
    return '$count Zibo Coin';
  }

  @override
  String get insufficientCoins => 'Zibo Coin insuficientes';

  @override
  String get ziboImagePlaceholder => 'Zibo';

  @override
  String get tapZiboHint => 'Toca a Zibo para una nueva frase';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabGoalTracking => 'Seguimiento de Metas';

  @override
  String get bottomBarGoalsLabel => 'Metas';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String goalProgressLabel(int completed) {
    return '$completed/7 días';
  }

  @override
  String goalDayToday(int day) {
    return 'Día $day, hoy';
  }

  @override
  String goalDayDone(int day) {
    return 'Día $day, completado';
  }

  @override
  String goalDayMissed(int day) {
    return 'Día $day, perdido';
  }

  @override
  String goalDayUpcoming(int day) {
    return 'Día $day, aún no disponible';
  }

  @override
  String get goalCycleCompleted =>
      '¡Genial! Completaste la meta de 7 días y ganaste +50 Zibo Coin.';

  @override
  String goalStreakReset(String goalNames) {
    return 'Se perdió un día en $goalNames, la racha se reinició. Empezamos de nuevo desde hoy.';
  }

  @override
  String get addGoalButton => 'Añadir Nueva Meta';

  @override
  String get addGoalDialogTitle => 'Nueva Meta';

  @override
  String get addGoalDialogHint => 'ej. Leer 30 minutos al día';

  @override
  String get deleteGoalTooltip => 'Eliminar meta';

  @override
  String get completedGoalsButtonTooltip => 'Metas Completadas';

  @override
  String get completedGoalsScreenTitle => 'Metas Completadas';

  @override
  String get completedGoalsEmpty =>
      'Aún no hay metas completadas. ¡Termina tu primer ciclo de 7 días y aparecerá aquí!';

  @override
  String get completedGoalsBadgeLabel => '1 semana completada';

  @override
  String completedGoalsGroupCount(int count) {
    return '$count veces completada';
  }

  @override
  String completedGoalsDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAbout => 'Acerca de la App';

  @override
  String get settingsDarkTheme => 'Tema Oscuro';

  @override
  String get settingsSoundEffects => 'Efectos de Sonido';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionSupport => 'Soporte';

  @override
  String get settingsSectionPushNotifications => 'Notificaciones Push';

  @override
  String get pushNotificationDailyMotivationTitle => 'Motivación Diaria';

  @override
  String get pushNotificationDailyMotivationSubtitle =>
      'Recibe una frase motivadora aleatoria cada mañana entre las 9 y las 11';

  @override
  String get pushNotificationStreakReminderTitle => 'Recordatorio de Racha';

  @override
  String get pushNotificationStreakReminderSubtitle =>
      'Recibe un recordatorio por la noche si estás a punto de perder tu racha';

  @override
  String get pushNotificationDailyRewardTitle =>
      'Recordatorio de Recompensa Diaria';

  @override
  String get pushNotificationDailyRewardSubtitle =>
      'Recibe un recordatorio por la tarde si no reclamaste tu recompensa diaria';

  @override
  String get pushNotificationReEngagementTitle => 'Te Extrañamos';

  @override
  String get pushNotificationReEngagementSubtitle =>
      'Zibo te extraña si no has entrado en 2 días';

  @override
  String get settingsContactUs => 'Contáctanos';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsWebsite => 'Sitio Web';

  @override
  String get settingsPrivacyPolicy => 'Política de Privacidad';

  @override
  String get settingsTermsOfService => 'Términos de Servicio';

  @override
  String get settingsLegalPlaceholderBody =>
      'Este contenido estará disponible aquí próximamente.';

  @override
  String get settingsCouldNotOpenLink =>
      'No se pudo abrir, inténtalo de nuevo.';

  @override
  String get tabMoney => 'Dinero y Ahorros';

  @override
  String get bottomBarMoneyLabel => 'Ahorros';

  @override
  String get moneyModuleDescription => 'Sigue tus gastos, ahorros e ingresos';

  @override
  String get moneyScreenTitle => 'Gastos y Ahorros';

  @override
  String get moneyExpenses => 'Gastos';

  @override
  String get moneySavings => 'Ahorros';

  @override
  String get moneyIncome => 'Ingresos';

  @override
  String get moneyTrendSectionTitle => 'Estado Actual';

  @override
  String get moneyTrendEmpty =>
      'Aún no hay suficientes datos para un gráfico de tendencia. Agrega un gasto o ahorro y aparecerá aquí.';

  @override
  String get moneyTrendExpenseLegend => 'Gasto';

  @override
  String get moneyTrendSavingLegend => 'Ahorro';

  @override
  String get moneyTrendGranularityDaily => 'Diario';

  @override
  String get moneyTrendGranularityWeekly => 'Semanal';

  @override
  String get moneyEmptyCategory => 'Aún no hay registros';

  @override
  String get moneyAddEntryButton => 'Añadir';

  @override
  String get moneyAddEntryTitle => 'Nuevo Registro';

  @override
  String get moneyEditEntryTitle => 'Editar Registro';

  @override
  String get moneyEntryNameHint => 'Nombre';

  @override
  String get moneyEntryAmountHint => 'Cantidad';

  @override
  String get moneyEntryCurrencyLabel => 'Moneda';

  @override
  String get moneyDeleteEntryTooltip => 'Eliminar registro';

  @override
  String get moneyCurrencyTooltip => 'Moneda';

  @override
  String get moneyCurrencyPickerTitle => 'Elegir Moneda';

  @override
  String moneyCategoryTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get storeButtonTooltip => 'Comprar monedas';

  @override
  String get storeTitle => 'Tienda';

  @override
  String get storeAdFreeSectionTitle => 'Zibo sin Anuncios';

  @override
  String get storeAdFreeCardTitle => 'Quitar Anuncios';

  @override
  String get storeAdFreeCardSubtitle =>
      'Desactiva todos los anuncios para siempre';

  @override
  String get storePackagesSectionTitle => 'Paquetes de Monedas';

  @override
  String storeCoinAmount(int amount) {
    return '$amount ZC';
  }

  @override
  String get storeBuyButton => 'Comprar';

  @override
  String get storeFreeSectionTitle => 'Gratis';

  @override
  String get storeWatchAdTitle => 'Ver un Anuncio';

  @override
  String storeWatchAdSubtitle(int amount) {
    return 'Gana $amount Zibo Coin, totalmente gratis';
  }

  @override
  String get storeWatchAdButton => 'Ver';

  @override
  String get dailyAdLimitReachedMessage =>
      'Se acabaron tus oportunidades de hoy, ¡vuelve mañana!';

  @override
  String storeCoinsAdded(int amount) {
    return '¡Se añadieron $amount Zibo Coin a tu saldo!';
  }

  @override
  String get storePurchaseFailedMessage =>
      'No se pudo completar la compra. Inténtalo de nuevo.';

  @override
  String get shareButtonTooltip => 'Compartir esta frase';

  @override
  String get favoriteQuoteAddTooltip => 'Marcar esta frase como favorita';

  @override
  String get favoriteQuoteRemoveTooltip => 'Quitar de favoritos';

  @override
  String get shareSheetTitle => 'Comparte tu Zibo';

  @override
  String get shareBackgroundLabel => 'Fondo';

  @override
  String get shareTextStyleLabel => 'Estilo de Texto';

  @override
  String get shareActionButton => 'Compartir';

  @override
  String get shareErrorMessage =>
      'No se pudo iniciar el compartir, ¿puedes intentarlo de nuevo?';

  @override
  String get storeCoinsTabLabel => 'Comprar Monedas';

  @override
  String get storeCostumesTabLabel => 'Disfraces';

  @override
  String get costumeNameZiboHippi => 'Zibo Hippie';

  @override
  String get costumeNameZiboSporcu => 'Zibo Deportista';

  @override
  String get costumeNameZiboAsker => 'Zibo Soldado';

  @override
  String get costumeNameZiboHoca => 'Zibo Profesor';

  @override
  String get costumeNameZiboPunk => 'Zibo Punk';

  @override
  String get costumeNameZiboRapci => 'Zibo Rapero';

  @override
  String get costumeNameZiboGladyator => 'Zibo Gladiador';

  @override
  String get costumeNameZiboKorsan => 'Zibo Pirata';

  @override
  String get costumeNameZiboZombi => 'Zibo Zombi';

  @override
  String get costumeNameZiboAltin => 'Zibo Dorado';

  @override
  String get costumeNameZiboElmas => 'Zibo Bañado en Diamante';

  @override
  String get costumeNameZiboGentleman => 'Zibo Caballero';

  @override
  String get costumeNameZiboSamurai => 'Zibo Samurái';

  @override
  String get costumeNameZiboCyborg => 'Zibo Cíborg';

  @override
  String get costumeNameZiboAstronot => 'Zibo Astronauta';

  @override
  String get costumeNameZiboKing => 'Zibo Rey';

  @override
  String get costumeOwnedBadge => 'Adquirido';

  @override
  String get costumeEquippedBadge => 'Puesto';

  @override
  String costumePurchasedMessage(String name) {
    return '¡$name comprado!';
  }

  @override
  String costumeLockedSemanticLabel(String name, int price) {
    return '$name, bloqueado, $price Zibo Coin';
  }

  @override
  String costumeEquipSemanticLabel(String name) {
    return 'Ponerse $name';
  }

  @override
  String costumeUnequipSemanticLabel(String name) {
    return 'Quitarse $name';
  }

  @override
  String costumeUnlockViaStreak(int current, int target) {
    return '🎯 Desbloquéalo gratis con una racha de $target días ($current/$target)';
  }

  @override
  String costumeUnlockViaCompletions(int current, int target) {
    return '🎯 Desbloquéalo gratis completando $target metas ($current/$target)';
  }

  @override
  String costumeUnlockViaWater(int current, int target) {
    return '🎯 Desbloquéalo gratis con $target días de seguimiento de agua ($current/$target)';
  }

  @override
  String costumeUnlockedViaGoalMessage(String name) {
    return '🎉 ¡Desbloqueaste $name gratis al cumplir tu meta!';
  }

  @override
  String get storeThemesTabLabel => 'Temas';

  @override
  String get adFreePromoTitle => 'Zibo ADS';

  @override
  String get adFreePromoSubtitle => 'Experiencia Sin Anuncios';

  @override
  String get adFreePromoBenefitNoAds => 'Sin anuncios';

  @override
  String get adFreePromoBenefitUninterrupted => 'Uso ininterrumpido';

  @override
  String get adFreePromoBenefitSupport => 'Apoya a Zibo';

  @override
  String get adFreePromoBuyButton => 'Comprar';

  @override
  String get adFreePromoDismissButton => 'Quizás Después';

  @override
  String get adFreePromoComingSoon =>
      '¡Pronto! La experiencia sin anuncios estará disponible pronto.';

  @override
  String get themeNameSunset => 'Atardecer';

  @override
  String get themeNameOcean => 'Océano';

  @override
  String get themeNameForest => 'Bosque';

  @override
  String get themeNameNightSky => 'Cielo Nocturno';

  @override
  String get themeNameGoldenAge => 'Edad Dorada';

  @override
  String get themeNameWinterSnow => 'Invierno';

  @override
  String get themeNameGalaxyStars => 'Galaxia';

  @override
  String get themeNamePartyConfetti => 'Confeti de Fiesta';

  @override
  String get themeNameHeartsLove => 'Tema de Corazones';

  @override
  String get themeNameMusicNotes => 'Tema de Notas Musicales';

  @override
  String get themeNameTropicalParadise => 'Tema Tropical';

  @override
  String get themeNameCherryBlossom => 'Tema de Flores de Cerezo';

  @override
  String get themeNameLavenderGarden => 'Jardín de Lavanda';

  @override
  String get themeNameCoralReef => 'Arrecife de Coral';

  @override
  String get themeNameCherryOrchard => 'Huerto de Cerezos';

  @override
  String get themeNameMintGreens => 'Verdes de Menta';

  @override
  String get themeNameDesertDunes => 'Dunas del Desierto';

  @override
  String get themeNameMoonlight => 'Luz de Luna';

  @override
  String get themeNameCopperHills => 'Colinas de Cobre';

  @override
  String get themeNameEmeraldValley => 'Valle Esmeralda';

  @override
  String get themeNameAmethystCave => 'Cueva de Amatista';

  @override
  String get themeNameDustyRoseDream => 'Sueño Rosa Empolvado';

  @override
  String get storeThemesStandardSectionTitle => 'Temas Estándar';

  @override
  String get storeThemesPremiumSectionTitle => 'Premium / Animado';

  @override
  String get storeThemesPremiumSectionSubtitle =>
      'Temas especiales con un sutil efecto de movimiento en tu pantalla';

  @override
  String get themeOwnedBadge => 'Adquirido';

  @override
  String get themeActiveBadge => 'Activo';

  @override
  String themePurchasedMessage(String name) {
    return '¡Tema $name comprado!';
  }

  @override
  String themeLockedSemanticLabel(String name, int price) {
    return 'Tema $name, bloqueado, $price Zibo Coin';
  }

  @override
  String themeApplySemanticLabel(String name) {
    return 'Aplicar tema $name';
  }

  @override
  String themeRemoveSemanticLabel(String name) {
    return 'Quitar tema $name';
  }

  @override
  String get wheelTriggerTooltip => 'Rueda de la Suerte';

  @override
  String get wheelTitle => 'Rueda de la Suerte';

  @override
  String get wheelSpinButton => 'Ver Anuncio\ny Girar';

  @override
  String get wheelCloseTooltip => 'Cerrar';

  @override
  String get wheelResultTitle => '¡Felicidades!';

  @override
  String wheelResultMessage(int amount) {
    return '¡Ganaste $amount Zibo Coin!';
  }

  @override
  String get wheelResultButton => '¡Genial!';

  @override
  String get dailyRewardsTriggerTooltip => 'Recompensas Diarias';

  @override
  String get dailyRewardsTitle => 'Recompensas de Inicio de Sesión';

  @override
  String get dailyRewardsCloseTooltip => 'Cerrar';

  @override
  String dailyRewardsDayLabel(int day) {
    return 'Día $day';
  }

  @override
  String dailyRewardsPromptToday(int day, int amount) {
    return 'Toca el Día $day para reclamar la recompensa de hoy: ¡$amount Zibo Coin!';
  }

  @override
  String dailyRewardsAlreadyClaimedToday(int amount) {
    return '¡Ya reclamaste $amount Zibo Coin hoy! Vuelve mañana.';
  }

  @override
  String dailyRewardsClaimedSemanticLabel(int day, int amount) {
    return 'Día $day, $amount Zibo Coin reclamados';
  }

  @override
  String dailyRewardsClaimSemanticLabel(int day, int amount) {
    return 'Reclamar recompensa del Día $day, $amount Zibo Coin';
  }

  @override
  String dailyRewardsLockedSemanticLabel(int day, int amount) {
    return 'Día $day, todavía bloqueado, $amount Zibo Coin';
  }

  @override
  String get notificationsSectionTitle => 'Notificaciones';

  @override
  String get notificationFrequencyOff => 'Desactivado';

  @override
  String get notificationFrequencyOnce => 'Una vez al día';

  @override
  String get notificationFrequencyThrice => '3 veces al día';

  @override
  String get notificationSlotMorning => 'Mañana';

  @override
  String get notificationSlotNoon => 'Mediodía';

  @override
  String get notificationSlotEvening => 'Noche';

  @override
  String get notificationReliabilityTitle => 'Para notificaciones fiables';

  @override
  String get notificationBatteryOptimizationWarning =>
      'La optimización de batería puede retrasar las notificaciones';

  @override
  String get notificationBatteryOptimizationOk =>
      'La optimización de batería está desactivada';

  @override
  String get notificationBatteryOptimizationButton => 'Desactivar';

  @override
  String get notificationAutostartDescription =>
      'Algunos teléfonos (Xiaomi, Huawei, Oppo, Vivo, etc.) requieren permiso de \"inicio automático\" para que lleguen las notificaciones';

  @override
  String get notificationUnusedAppsDescription =>
      'Tu teléfono puede considerar la app como \"no usada\" y detener las notificaciones — puede que también debas desactivar este ajuste';

  @override
  String get notificationUnusedAppsButton => 'Abrir ajustes';

  @override
  String get notificationAutostartButton => 'Abrir ajustes';

  @override
  String get dreamJournalTooltip => 'Diario de Sueños';

  @override
  String get dreamJournalTitle => 'Diario de Sueños';

  @override
  String get dreamAddButton => 'Añadir Nuevo Sueño';

  @override
  String get dreamEmptyState =>
      'Todavía no has escrito ningún sueño. ¿Tuviste alguno hoy?';

  @override
  String get dreamMoodCorrelationNote =>
      'Ese día tu ánimo también estaba bajo 😔';

  @override
  String get dreamTitleHint => 'Título';

  @override
  String get dreamTextHint => 'Cuenta tu sueño...';

  @override
  String get dreamSaveButton => 'Guardar';

  @override
  String get dreamNewEntryTitle => 'Nuevo Sueño';

  @override
  String get dreamEditEntryTitle => 'Editar Sueño';

  @override
  String get dreamDeleteEntryTooltip => 'Eliminar';

  @override
  String get dreamDeleteConfirmTitle => '¿Eliminar este sueño?';

  @override
  String get dreamDeleteConfirmBody =>
      'Este sueño se eliminará permanentemente.';

  @override
  String get dreamDeleteConfirmButton => 'Eliminar';

  @override
  String get gratitudeSettingsTitle => 'Diario de Gratitud';

  @override
  String get gratitudeScreenTitle => 'Diario de Gratitud';

  @override
  String gratitudeFieldLabel(int n) {
    return 'Gratitud $n';
  }

  @override
  String get gratitudeSaveButton => 'Guardar';

  @override
  String get gratitudeTodayDoneTitle => '¡Completado por hoy!';

  @override
  String get gratitudeTodayDoneBody =>
      'Escribiste 3 cosas por las que estás agradecido/a y ganaste 5 Zibo Coin. ¡Vuelve mañana!';

  @override
  String get gratitudeHistoryTitle => 'Registros Anteriores';

  @override
  String get gratitudeHistoryEmpty => 'Aún no hay registros completados.';

  @override
  String get gratitudeCoinRewardMessage => '¡Ganaste 5 Zibo Coin!';

  @override
  String get gratitudeEntryDetailCloseButton => 'Cerrar';

  @override
  String get gratitudeEditTooltip => 'Editar';

  @override
  String get moodSettingsTitle => 'Seguimiento Diario del Ánimo';

  @override
  String get moodScreenTitle => 'Seguimiento Diario del Ánimo';

  @override
  String get moodWeekSummaryTitle => 'Últimos 7 Días';

  @override
  String get moodHistoryTitle => 'Historial';

  @override
  String get moodHistoryEmpty => 'Aún no hay registros.';

  @override
  String get moodLabelVeryUnhappy => 'Muy mal';

  @override
  String get moodLabelUnhappy => 'Mal';

  @override
  String get moodLabelNeutral => 'Neutral';

  @override
  String get moodLabelHappy => 'Bien';

  @override
  String get moodLabelVeryHappy => 'Muy bien';

  @override
  String get modulesMenuZButtonTooltip => 'Abrir módulos extra';

  @override
  String get modulesMenuTitle => 'Módulos Extra';

  @override
  String get dreamModuleDescription => 'Anota tus sueños, revisa tu historial';

  @override
  String get gratitudeModuleDescription =>
      'Escribe 3 cosas por las que estás agradecido/a cada día y gana Zibo Coin';

  @override
  String get moodModuleDescription => 'Marca tu ánimo de hoy con un emoji';

  @override
  String get waterSettingsTitle => 'Seguimiento de Agua';

  @override
  String get waterModuleDescription =>
      'Sigue tu meta diaria de agua, vaso a vaso';

  @override
  String get waterScreenTitle => 'Seguimiento de Agua';

  @override
  String waterProgressLabel(int count, int goal, String unit) {
    return '$count/$goal $unit';
  }

  @override
  String waterProgressMl(int consumedMl, int goalMl) {
    return '$consumedMl ml / $goalMl ml';
  }

  @override
  String waterGlassFilledLabel(int index, String unit) {
    return '$unit $index, lleno';
  }

  @override
  String waterGlassEmptyLabel(int index, String unit) {
    return '$unit $index, vacío';
  }

  @override
  String get waterGoalCompletedMessage =>
      '¡Completaste tu meta de agua de hoy! ¡+5 Zibo Coin ganados!';

  @override
  String get waterTodayCompleteBody =>
      'Hoy cumpliste tu meta de agua, ¡así se hace!';

  @override
  String get waterGoalSettingsTitle => 'Meta Diaria de Agua';

  @override
  String get waterGoalDialogTitle => 'Meta Diaria de Agua';

  @override
  String waterGoalDialogUnitCount(int count, String unit) {
    return '$count $unit';
  }

  @override
  String get waterUnitGlass => 'vaso';

  @override
  String get waterUnitBottle => 'botella';

  @override
  String get waterUnitSectionLabel => 'Unidad';

  @override
  String waterMlPerUnitLabel(String unit) {
    return '1 $unit = ¿cuántos ml?';
  }

  @override
  String get waterHistoryTitle => 'Historial';

  @override
  String get waterHistoryEmpty => 'Aún no hay historial.';

  @override
  String waterHistoryCompletedEntry(String date) {
    return 'Meta completada el $date';
  }

  @override
  String waterHistoryPartialEntry(String date, int count, int goal) {
    return '$date: $count/$goal';
  }

  @override
  String get manifestSettingsTitle => 'Diario de Manifestación';

  @override
  String get manifestModuleDescription =>
      'Crea tu tablero de visión diario con una foto e intención';

  @override
  String get manifestScreenTitle => 'Diario de Manifestación';

  @override
  String get manifestPhotoPickerHint => 'Elige una foto';

  @override
  String get manifestPhotoSemanticLabel => 'Foto subida';

  @override
  String get manifestIntentionHint => '¿Qué quieres manifestar hoy?';

  @override
  String get manifestSaveButton => 'Guardar';

  @override
  String get manifestSavedMessage => 'Se guardó el registro de hoy.';

  @override
  String get manifestCoinRewardMessage => '¡Ganaste 5 Zibo Coin!';

  @override
  String get manifestHistoryTitle => 'Registros Anteriores';

  @override
  String get manifestHistoryEmpty =>
      'Aún no hay registros. ¡Añade tu primera visión hoy!';

  @override
  String get manifestDetailCloseButton => 'Cerrar';

  @override
  String get profileScreenTitle => 'Perfil';

  @override
  String get profileModuleDescription =>
      'Mira tu foto, nombre y estadísticas de hábitos';

  @override
  String get profilePhotoSemanticLabel => 'Foto de perfil, toca para cambiar';

  @override
  String get profileNameHint => 'Escribe tu nombre';

  @override
  String get profileStatsSectionTitle => 'Mis Estadísticas';

  @override
  String get profileStatMoneyTitle => 'Gestión del Dinero';

  @override
  String get profileStatGratitudeManifestTitle => 'Gratitud y Manifestación';

  @override
  String get profileStatConsistencyTitle => 'Constancia';

  @override
  String get profileStatSelfCareTitle => 'Autocuidado y Salud';

  @override
  String get profileStatMoneyEmpty =>
      'Aún no hay datos — ¡empieza a usar Dinero y Ahorros!';

  @override
  String get profileStatGratitudeManifestEmpty =>
      'Aún no hay datos — ¡empieza a usar el Diario de Gratitud o el Diario de Manifestación!';

  @override
  String get profileStatConsistencyEmpty =>
      'Aún no hay datos — ¡empieza a usar Seguimiento de Metas!';

  @override
  String get profileStatSelfCareEmpty =>
      'Aún no hay datos — ¡empieza a usar Seguimiento de Agua!';

  @override
  String get profileBondSectionTitle => 'Tu Vínculo con Zibo';

  @override
  String get bondLevelScreenTitle => 'Nivel de Vínculo con Zibo';

  @override
  String profileBondLevelRowSubtitle(int days) {
    return 'Llevas $days días siendo amigo de Zibo';
  }

  @override
  String profileBondNextLevelHint(int days, String tier) {
    return 'En $days días serás $tier';
  }

  @override
  String get profileBondMaxLevelHint =>
      '¡Ya alcanzaste el nivel máximo, felicidades!';

  @override
  String get bondLevelNewBuddy => 'Nuevo Amigo';

  @override
  String get bondLevelGettingClose => 'Amigo Cercano';

  @override
  String get bondLevelOldFriend => 'Viejo Amigo';

  @override
  String get bondLevelSoulBuddy => 'Amigo del Alma';

  @override
  String get bondLevelLifetimeBuddy => 'Amigo de por Vida';

  @override
  String get longestStreakScreenTitle => 'Récord de Racha Más Larga';

  @override
  String profileStreakRowSubtitle(int days) {
    return 'Tu racha más larga: $days días';
  }

  @override
  String get longestStreakScreenSubtitle =>
      'Tu racha ininterrumpida más larga en Seguimiento de Metas';

  @override
  String get longestStreakEncouragement =>
      '¡Marca una meta hoy para superar este récord!';

  @override
  String get profileCostumeClosetRowTitle => 'Armario de Disfraces';

  @override
  String get profileCostumeClosetEmpty =>
      'Aún no tienes ningún disfraz — ¡elige uno en la Tienda!';

  @override
  String get coinSummaryScreenTitle => 'Resumen de Zibo Coin';

  @override
  String get coinSummaryTotalEarnedLabel => 'Total Ganado';

  @override
  String get coinSummaryTotalSpentLabel => 'Total Gastado';

  @override
  String coinSummaryAmount(int amount) {
    return '$amount ZC';
  }

  @override
  String profileCoinSummaryRowSubtitle(int earned, int spent) {
    return 'Ganado $earned ZC · Gastado $spent ZC';
  }

  @override
  String get addressTermScreenTitle => 'Preferencia de Trato';

  @override
  String get addressTermScreenDescription =>
      '¿Cómo debería llamarte Zibo? Lo que escribas reemplaza \"amigo\" donde aparezca en tus frases.';

  @override
  String get addressTermFieldHint =>
      '¿Cómo debería llamarte Zibo? Ej.: Amigo, Jefe, Campeón...';

  @override
  String profileAddressTermRowSubtitle(String term) {
    return 'Zibo te llama \"$term\"';
  }

  @override
  String get favoriteQuotesScreenTitle => 'Frases Favoritas';

  @override
  String get favoriteQuotesEmpty =>
      'Aún no tienes frases favoritas — ¡toca el ícono de corazón en la Pantalla Principal para guardar las que te gusten!';

  @override
  String get customMessagesButtonTooltip => 'Agrega tu propio mensaje';

  @override
  String get customMessagesScreenTitle => 'Mis Mensajes Personalizados';

  @override
  String get customMessagesSubtitle =>
      'Agrega tus propias frases para que Zibo te las diga de vez en cuando — se mezclan con las frases estándar y aparecen al azar.';

  @override
  String get customMessagesEmpty =>
      'Aún no has agregado ningún mensaje personalizado.';

  @override
  String get customMessagesAddButton => 'Agregar Nuevo Mensaje';

  @override
  String get customMessagesFieldHint => 'Que Zibo diga...';

  @override
  String get customMessagesSaveButton => 'Guardar';

  @override
  String get customMessagesCancelButton => 'Cancelar';

  @override
  String get customMessagesDeleteTooltip => 'Eliminar';

  @override
  String profileFavoriteQuotesRowSubtitle(int count) {
    return '$count frases favoritas';
  }

  @override
  String get profileShareCardRowTitle => 'Compartir Tarjeta de Perfil';

  @override
  String get profileShareCardRowSubtitle =>
      'Comparte tu nivel de vínculo y estadísticas en una tarjeta';

  @override
  String get monthlyStatsRowTitle => 'Estadísticas de Meses Anteriores';

  @override
  String monthlyStatsRowSubtitle(int count) {
    return '$count meses archivados';
  }

  @override
  String get monthlyStatsScreenTitle => 'Estadísticas de Meses Anteriores';

  @override
  String get monthlyStatsEmpty =>
      'Aún no hay meses archivados. Aparecerán aquí al final del primer mes.';

  @override
  String get profileShareCardTitle => '🐣 Mi Vínculo con Zibo';

  @override
  String get onboardingLanguageStepTitle => '¿Qué idioma prefieres?';

  @override
  String get onboardingLanguageStepSubtitle =>
      'El resto de la app se abrirá en el idioma que elijas — puedes cambiarlo después desde Ajustes.';

  @override
  String get onboardingNameStepTitle => '¿Cómo te llamamos?';

  @override
  String get onboardingNameStepSubtitle =>
      'Zibo usará este nombre contigo — puedes cambiarlo después desde Perfil.';

  @override
  String get onboardingContinueButton => 'Continuar';

  @override
  String get onboardingNextButton => 'Siguiente';

  @override
  String get onboardingSkipButton => 'Omitir';

  @override
  String get onboardingStartButton => '¡Empecemos!';

  @override
  String get onboardingGoalsDescription =>
      'Divide tus grandes sueños en pequeños pasos.';

  @override
  String get onboardingWaterDescription =>
      'Aprende a cumplir hasta la promesa más pequeña a tu cuerpo.';

  @override
  String get onboardingGratitudeDescription =>
      'Mira tu día recordando lo que ya tienes.';

  @override
  String get onboardingMoodDescription => 'No ignores tus emociones, síguelas.';

  @override
  String get onboardingDreamJournalDescription =>
      'Descubre lo que tu subconsciente te está diciendo.';

  @override
  String get onboardingManifestDescription =>
      'Pon frente a tus ojos la vida que sueñas.';

  @override
  String get onboardingStoreDescription =>
      'Dale color a tu esfuerzo, viste a Zibo a tu manera.';

  @override
  String get onboardingProfileDescription =>
      'Ve tu vínculo con Zibo y tu progreso de un vistazo.';

  @override
  String get onboardingClosingTitle => '¡Tu Viaje con Zibo Comienza!';

  @override
  String onboardingClosingMessage(String name) {
    return '¡Ya estás listo, $name! Haremos grandes cambios con pequeños pasos — sigue tus metas, cuídate, siempre estoy contigo. ¡Empecemos, amigo!';
  }

  @override
  String get googleLinkRowTitleUnlinked => 'Vincular con Google';

  @override
  String get googleLinkRowTitleLinked => 'Tu cuenta de Google';

  @override
  String get googleLinkRowSubtitle => 'Mantén seguras tus compras y datos';

  @override
  String get googleLinkSuccessMessage => '¡Vinculado con tu cuenta de Google!';

  @override
  String get googleLinkFailedMessage =>
      'Hubo un problema al vincular tu cuenta, inténtalo de nuevo.';

  @override
  String get googleAlreadyLinkedDialogTitle =>
      'Esta cuenta está vinculada a otro dispositivo';

  @override
  String get googleAlreadyLinkedDialogBody =>
      'Esta cuenta de Google ya está asociada con datos en otro dispositivo. Si cambias a esa cuenta, tu progreso actual en este dispositivo se perderá.';

  @override
  String get googleSignInInsteadButton => 'Iniciar sesión con Google';

  @override
  String get googleSignInSuccessMessage =>
      '¡Sesión iniciada con Google, tus datos se han restaurado!';

  @override
  String get googleSignInFailedMessage =>
      'Hubo un problema al iniciar sesión, inténtalo de nuevo.';

  @override
  String get googleLinkPromoTitle => 'Mantén Seguras Tus Compras';

  @override
  String get googleLinkPromoBody =>
      'Vincula tu cuenta de Google para que tus Zibo Coins y tu progreso no se pierdan si cambias de dispositivo.';

  @override
  String get googleLinkPromoSkipButton => 'Omitir por Ahora';

  @override
  String get googleSignOutButton => 'Cerrar Sesión';

  @override
  String get googleSwitchAccountButton => 'Cambiar de Cuenta';

  @override
  String get googleSignOutConfirmTitle => 'Cerrar Sesión';

  @override
  String get googleSignOutConfirmBody =>
      '¿Seguro que quieres cerrar sesión? Los datos vinculados a esta cuenta no se perderán — se restaurarán la próxima vez que inicies sesión con la misma cuenta de Google.';

  @override
  String get googleSignOutFailedMessage =>
      'Hubo un problema al cerrar sesión, inténtalo de nuevo.';

  @override
  String get referralScreenTitle => 'Invita a un Amigo';

  @override
  String get referralRowTitle => 'Invita a un Amigo';

  @override
  String get referralRowSubtitle => 'Invita a alguien, los dos ganan Zibo Coin';

  @override
  String get referralCodeLabel => 'Tu Código de Invitación';

  @override
  String get referralCopyButton => 'Copiar';

  @override
  String get referralCodeCopiedMessage => '¡Código de invitación copiado!';

  @override
  String get referralShareButton => 'Compartir';

  @override
  String referralShareMessage(String code, int amount) {
    return '¡Estoy probando Zibo, únete! Mi código de invitación: $code — ingrésalo en Perfil > Invita a un Amigo y ambos ganaremos $amount Zibo Coin! 🎉';
  }

  @override
  String get referralRedeemFieldLabel => '¿Tienes un código de invitación?';

  @override
  String get referralRedeemButton => 'Usar Código';

  @override
  String get referralRedeemSuccessMessage =>
      '¡Tu código fue enviado! Tus monedas se añadirán pronto.';

  @override
  String get referralRedeemSelfCodeError =>
      'No puedes usar tu propio código de invitación.';

  @override
  String get referralRedeemInvalidCodeError =>
      'Ingresa un código de invitación válido.';

  @override
  String get referralAlreadyRedeemedStatus =>
      '¡Ya usaste un código de invitación, gracias!';

  @override
  String get referralUnavailableMessage =>
      'Las invitaciones no están disponibles ahora, inténtalo más tarde.';

  @override
  String get founderBadgeTooltip => 'Miembro Fundador';

  @override
  String get widgetTitleGoals => 'Seguimiento de Metas';

  @override
  String get widgetTitleWater => 'Seguimiento de Agua';

  @override
  String get widgetTitleGratitude => 'Diario de Gratitud';

  @override
  String get widgetTitleMood => 'Seguimiento del Ánimo';

  @override
  String get widgetTitleManifest => 'Diario de Manifestación';

  @override
  String get widgetTitleDream => 'Diario de Sueños';

  @override
  String get widgetTitleMoney => 'Dinero y Ahorros';

  @override
  String get widgetTitleDailyRewards => 'Recompensas Diarias';

  @override
  String get widgetTitleMotivation => 'Una Palabra de Zibo';

  @override
  String get widgetTitleProfileStats => 'Mis Estadísticas';

  @override
  String get widgetGoalsEmptyHint => 'Aún no hay metas';

  @override
  String get widgetGoalsActiveHint => 'metas marcadas hoy';

  @override
  String widgetWaterHint(String unit) {
    return '$unit · hoy';
  }

  @override
  String get widgetGratitudeDoneHint => 'Completado hoy';

  @override
  String get widgetGratitudeEmptyHint => 'Aún no escrito';

  @override
  String get widgetMoodSetHint => 'Tu ánimo de hoy';

  @override
  String get widgetMoodEmptyHint => 'Aún no elegido';

  @override
  String get widgetManifestActiveHint => 'entradas añadidas hoy';

  @override
  String get widgetManifestEmptyHint => 'Aún no hay entradas';

  @override
  String get widgetDreamActiveHint => 'sueños registrados en total';

  @override
  String get widgetDreamEmptyHint => 'Aún no hay sueños';

  @override
  String get widgetMoneyHint => 'neto este mes';

  @override
  String get widgetDailyRewardsClaimedHint => 'Reclamado hoy ✓';

  @override
  String get widgetDailyRewardsAvailableHint => 'Disponible hoy 🎁';

  @override
  String widgetDailyRewardsPrimary(int day) {
    return 'Día $day/7';
  }

  @override
  String get widgetsScreenTitle => 'Widgets de Pantalla de Inicio';

  @override
  String get widgetsScreenIntro =>
      'Sigue los módulos de Zibo directamente desde tu pantalla de inicio. Toca el botón junto a un módulo para añadirlo.';

  @override
  String get widgetsScreenAddButton => 'Añadir';

  @override
  String get widgetsScreenAddedSuccessMessage =>
      '¡Widget añadido! Revisa tu pantalla de inicio.';

  @override
  String get widgetsScreenAddFailedMessage =>
      'No se pudo añadir el widget — puede que tu dispositivo no sea compatible. También puedes mantener presionada tu pantalla de inicio y buscar Zibo en la lista de widgets.';

  @override
  String get widgetsScreenAddSheetTitle =>
      'Cómo Añadirlo a tu Pantalla de Inicio';

  @override
  String get widgetsScreenAddStep1 =>
      'Mantén presionada un área vacía de tu pantalla de inicio.';

  @override
  String get widgetsScreenAddStep2 =>
      'Toca \"Widgets\" en el menú que aparece.';

  @override
  String get widgetsScreenAddStep3 =>
      'Busca Zibo en la lista y arrastra el widget que quieras a tu pantalla de inicio.';

  @override
  String get widgetsScreenAddSheetGotIt => 'Entendido';

  @override
  String get settingsWidgetsRowSubtitle =>
      'Sigue el estado de los módulos desde tu pantalla de inicio';
}
