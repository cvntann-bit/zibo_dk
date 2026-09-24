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
  String get coinProBonusLabel => '¡Bono Pro x1,5!';

  @override
  String get coinProPlusBonusLabel => '¡Bono Pro+ x2!';

  @override
  String get historyLimitCardTitle => 'Registros antiguos con Pro';

  @override
  String get historyLimitCardSubtitle =>
      'Mejora a Zibo Pro para ver registros más antiguos';

  @override
  String get historyLimitCardButton => 'Mejorar a Pro';

  @override
  String get streakFreezeOfferTitle => '¡No pierdas tu racha!';

  @override
  String streakFreezeOfferBody(int streak) {
    return '¡Tu racha de $streak días está a punto de romperse! Puedes protegerla con un Streak Freeze.';
  }

  @override
  String streakFreezeOfferFreeButton(int remaining, int quota) {
    return 'Usar gratis ($remaining/$quota restantes)';
  }

  @override
  String streakFreezeOfferCoinButton(int cost) {
    return 'Usar por $cost ZC';
  }

  @override
  String get streakFreezeOfferDeclineButton => 'No, gracias';

  @override
  String streakFreezeRepairedMessage(int streak) {
    return '¡Racha salvada! Llevas $streak días seguidos.';
  }

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
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsThemeModeLight => 'Claro';

  @override
  String get settingsThemeModeDark => 'Oscuro';

  @override
  String get settingsThemeModeSystem => 'Seguir el Sistema';

  @override
  String get settingsSoundEffects => 'Efectos de Sonido';

  @override
  String get settingsProPlusSoundTitle => 'Sonido de Notificación';

  @override
  String get settingsProPlusSoundLockedSubtitle =>
      'Exclusivo de Pro+ — toca para mejorar';

  @override
  String get settingsProPlusSoundDefault => 'Predeterminado';

  @override
  String settingsProPlusSoundOption(int number) {
    return 'Sonido $number';
  }

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
  String get settingsRateUs => 'Califícanos';

  @override
  String get settingsRateUsSubtitle =>
      'Danos una calificación en Play Store y ayuda a Zibo a crecer';

  @override
  String get rateUsSheetTitle => '¿Te gusta Zibo?';

  @override
  String get rateUsSheetSubtitle =>
      '¡Toca las estrellas para calificarnos en Play Store!';

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
  String get moneyAdvancedAnalysisTitle => 'Análisis Avanzado';

  @override
  String get moneyAdvancedAnalysisAvgExpense => 'Gasto Mensual Promedio';

  @override
  String get moneyAdvancedAnalysisAvgSaving => 'Ahorro Mensual Promedio';

  @override
  String get moneyAdvancedAnalysisTopExpense => 'Tu Gasto Principal';

  @override
  String get moneyAdvancedAnalysisEmpty =>
      'Aún no hay suficientes datos para un análisis.';

  @override
  String get lockedChartCta => 'Pásate a Zibo Pro+ Hoy';

  @override
  String get moneyExpenseBreakdownTitle => 'Distribución de Gastos';

  @override
  String get moneyExpenseOtherLabel => 'Otros';

  @override
  String get moneyCurrencyTotalsTitle => 'Por Moneda';

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
  String get moodTrendTitle => 'Tendencia de Ánimo';

  @override
  String get moodTrendGranularityWeek => 'Semanal';

  @override
  String get moodTrendGranularityMonth => 'Mensual';

  @override
  String get moodTrendEmptyState =>
      'Aún no hay suficientes registros de ánimo para una tendencia.';

  @override
  String get moneyTrendGranularityWeekly => 'Semanal';

  @override
  String get moneyTrendGranularityMonthly => 'Mensual';

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
  String get storeAdFreeCardPurchasedLabel => 'Comprado';

  @override
  String get storePackagesSectionTitle => 'Paquetes de Monedas';

  @override
  String storeCoinAmount(int amount) {
    return '$amount ZC';
  }

  @override
  String storeCoinBonus(int amount) {
    return '+$amount de regalo';
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
  String get storeProTabLabel => 'Zibo Pro';

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
  String get adFreePromoPurchaseSuccess => '¡Gracias! Ya no verás anuncios.';

  @override
  String get adFreePromoPurchaseFailed =>
      'No se pudo completar la compra, inténtalo de nuevo.';

  @override
  String get adFreePromoPurchaseFailedDismissButton => 'Vale';

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
  String get moodNoteHint =>
      'Puedes escribir brevemente cómo te sientes hoy (opcional)';

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
  String waterProgressMlShort(int ml) {
    return '$ml ml';
  }

  @override
  String get waterTrendTitle => 'Tendencia de Consumo de Agua';

  @override
  String get waterTrendEmptyState =>
      'Aún no hay suficientes registros de agua para un gráfico de tendencia.';

  @override
  String get waterGoalRateTitle => 'Promedio de Objetivo Cumplido';

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
  String get homeWidgetNewBadge => 'NUEVO';

  @override
  String get homeWaterWidgetTitle => 'Agua';

  @override
  String homeWaterRemainingLabel(int count, String unit) {
    return 'Quedan $count $unit';
  }

  @override
  String get homeWaterCompleteLabel => '¡Meta de hoy completada!';

  @override
  String get homeGoalWidgetTitle => 'Meta';

  @override
  String get homeGoalCompleteLabel => '¡Todo listo hoy!';

  @override
  String get homeGoalEmptyLabel => 'Aún no hay metas';

  @override
  String get homeQuickWidgetEditTooltip => 'Cambiar widget';

  @override
  String get homeQuickWidgetPickerTitle => 'Cambiar Widget';

  @override
  String get homeQuickWidgetDoneTodayLabel => 'Añadido hoy';

  @override
  String get homeQuickWidgetNotDoneTodayLabel => 'Aún no añadido hoy';

  @override
  String get homeMoodWidgetNotSetLabel => 'Aún no seleccionado';

  @override
  String homeFocusWidgetTodayLabel(String duration) {
    return 'Hoy te enfocaste durante $duration';
  }

  @override
  String get homeFocusWidgetNotDoneTodayLabel => 'Hoy aún no te has enfocado';

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
  String get manifestDeleteEntryTooltip => 'Eliminar';

  @override
  String get manifestDeleteConfirmTitle => '¿Eliminar este registro?';

  @override
  String get manifestDeleteConfirmBody =>
      'Este registro se eliminará permanentemente.';

  @override
  String get manifestDeleteConfirmYes => 'Sí';

  @override
  String get manifestDeleteConfirmNo => 'No';

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
      'Tu récord de días seguidos abriendo Zibo';

  @override
  String get longestStreakEncouragement =>
      '¡Abre Zibo hoy también para superar este récord!';

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
  String get founderBadgeEarnedSubtitle =>
      'Eres uno de los primeros 500 usuarios';

  @override
  String get subscriptionBadgeProTooltip => 'Zibo Pro';

  @override
  String get subscriptionBadgeProPlusTooltip => 'Zibo Pro+';

  @override
  String get shareCardProWatermarkSemanticLabel => 'Marca de agua de Zibo Pro';

  @override
  String get founderBadgePromoTitle => 'Gana la Insignia de Miembro Fundador';

  @override
  String founderBadgePromoBody(int remaining) {
    return 'Sé uno de los primeros 500 en vincular una cuenta de Google — ¡quedan $remaining lugares!';
  }

  @override
  String get founderBadgeClaimedMessage =>
      '🏅 ¡Ganaste la insignia de Miembro Fundador!';

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

  @override
  String get badgesTriggerTooltip => 'Insignias';

  @override
  String get badgesGalleryTitle => 'Insignias';

  @override
  String get badgeCategoryConsistency => 'Insignias de Constancia';

  @override
  String get badgeNameFirstStep => 'Primer Paso';

  @override
  String get badgeNameWeekStreak => 'Racha de 1 Semana';

  @override
  String get badgeNameMonthStreak => 'Racha de 1 Mes';

  @override
  String get badgeNameIronWill => 'Voluntad de Hierro';

  @override
  String get badgeNameUnyielding => 'Inquebrantable';

  @override
  String get badgeRequirementFirstStep =>
      'Completa tu primer ciclo de 7 días de un objetivo';

  @override
  String get badgeRequirementWeekStreak => 'Abre la app 7 días seguidos';

  @override
  String get badgeRequirementMonthStreak => 'Abre la app 30 días seguidos';

  @override
  String get badgeRequirementIronWill => 'Abre la app 90 días seguidos';

  @override
  String get badgeRequirementUnyielding => 'Abre la app 180 días seguidos';

  @override
  String get badgeClaimRewardButton => 'Reclamar Recompensa';

  @override
  String get badgeGalleryClaimableLabel => 'Reclamar Recompensa';

  @override
  String badgeRewardClaimedMessage(int amount) {
    return '¡Ganaste +$amount Zibo Coin!';
  }

  @override
  String get badgeCategoryModuleMastery => 'Insignias de Maestría de Módulo';

  @override
  String get badgeNameGratefulHeart => 'Corazón Agradecido';

  @override
  String get badgeNameWaterHero => 'Héroe del Agua';

  @override
  String get badgeNameMoodChronicler => 'Cronista del Ánimo';

  @override
  String get badgeNameSavingsMaster => 'Maestro del Ahorro';

  @override
  String get badgeNameDreamer => 'Soñador';

  @override
  String get badgeNameDreamInterpreter => 'Intérprete de Sueños';

  @override
  String get badgeRequirementGratefulHeart =>
      'Crea un total de 30 registros en el Diario de Gratitud';

  @override
  String get badgeRequirementWaterHero =>
      'Registra tu consumo de agua durante un total de 30 días';

  @override
  String get badgeRequirementMoodChronicler =>
      'Crea un total de 30 registros en el Seguimiento del Ánimo';

  @override
  String get badgeRequirementSavingsMaster =>
      'Crea un total de 20 registros en Dinero y Ahorros';

  @override
  String get badgeRequirementDreamer =>
      'Crea un total de 15 registros en el Diario de Manifestación';

  @override
  String get badgeRequirementDreamInterpreter =>
      'Crea un total de 15 registros en el Diario de Sueños';

  @override
  String get badgeCategoryCollection => 'Insignias de Colección';

  @override
  String get badgeNameCollector => 'Coleccionista';

  @override
  String get badgeNameFashionIcon => 'Ícono de la Moda';

  @override
  String get badgeNameFullWardrobe => 'Armario Completo';

  @override
  String get badgeNameThemeHunter => 'Cazador de Temas';

  @override
  String get badgeRequirementCollector => 'Ten 5 disfraces diferentes';

  @override
  String get badgeRequirementFashionIcon => 'Ten 10 disfraces diferentes';

  @override
  String get badgeRequirementFullWardrobe =>
      'Ten TODOS los disfraces de la tienda';

  @override
  String get badgeRequirementThemeHunter => 'Ten 3 temas diferentes';

  @override
  String get badgeSpecialRewardComingSoon =>
      'Recompensa Especial (Próximamente)';

  @override
  String get badgeSpecialRewardThemeNote => '+ Un Tema Aleatorio de Regalo';

  @override
  String badgeSpecialRewardThemeGrantedMessage(String themeName) {
    return 'Tu recompensa especial: ¡se te regaló el tema $themeName! 🎁';
  }

  @override
  String badgeGiftCostumeMessage(String costumeName) {
    return '¡También ganaste $costumeName! 🎁';
  }

  @override
  String badgeGiftPreviewLabel(String itemName) {
    return 'Regalo: $itemName';
  }

  @override
  String get badgeCategoryLoyalty => 'Insignias de Lealtad';

  @override
  String get badgeNameFirstWeek => 'Primera Semana';

  @override
  String get badgeNameLoyalFriend => 'Amigo Fiel';

  @override
  String get badgeNameAnniversary => 'Aniversario';

  @override
  String get badgeRequirementFirstWeek =>
      'Abre la app un total de 7 días diferentes';

  @override
  String get badgeRequirementLoyalFriend =>
      'Abre la app un total de 100 días diferentes';

  @override
  String get badgeRequirementAnniversary =>
      'Ha pasado 1 año desde que conociste a Zibo';

  @override
  String get badgeCategorySocial => 'Insignias Sociales';

  @override
  String get badgeNameFirstShare => 'Primera Vez que Compartes';

  @override
  String get badgeNameAmbassador => 'Embajador';

  @override
  String get badgeNameCommunityFounder => 'Fundador de la Comunidad';

  @override
  String get badgeRequirementFirstShare =>
      'Comparte una tarjeta de Zibo por primera vez';

  @override
  String get badgeRequirementAmbassador =>
      'Invita con éxito a 1 amigo con Invitar a un Amigo';

  @override
  String get badgeRequirementCommunityFounder =>
      'Invita con éxito a 5 amigos con Invitar a un Amigo';

  @override
  String get badgeCategoryHidden => 'Insignias Ocultas';

  @override
  String get badgeHiddenPlaceholder => '???';

  @override
  String get badgeNameNightOwl => 'Búho Nocturno';

  @override
  String get badgeNameEarlyBird => 'Madrugador';

  @override
  String get badgeNameBalanceMaster => 'Maestro del Equilibrio';

  @override
  String get badgeRequirementNightOwl =>
      'Abre la app 30 veces entre la medianoche y las 5 AM';

  @override
  String get badgeRequirementEarlyBird =>
      'Abre la app 30 veces entre las 6 AM y las 8 AM';

  @override
  String get badgeRequirementBalanceMaster =>
      'Añade un registro a los 7 módulos de la app el mismo día';

  @override
  String levelUpCelebrationTitle(int level) {
    return '¡Alcanzaste el Nivel $level!';
  }

  @override
  String get levelUpCelebrationBody =>
      '¡Lo estás haciendo genial con Zibo, sigue creciendo!';

  @override
  String get levelUpShareButton => 'Compartir';

  @override
  String get levelUpCloseButton => 'Cerrar';

  @override
  String levelUpShareMessage(int level) {
    return '¡Alcancé el Nivel $level en Zibo! 🎉';
  }

  @override
  String get profileLevelRowTitle => 'Tu Nivel';

  @override
  String profileLevelProgressLabel(int current, int needed) {
    return '$current/$needed XP';
  }

  @override
  String get focusTimerTooltip => 'Temporizador de Enfoque';

  @override
  String get focusModuleDescription =>
      'Registra tus sesiones de enfoque y mejora tu productividad.';

  @override
  String get focusTimerScreenTitle => 'Temporizador de Enfoque';

  @override
  String get focusModeFreeLabel => 'Libre';

  @override
  String focusModeMinutesLabel(int minutes) {
    return '$minutes min';
  }

  @override
  String get focusStartButton => 'Iniciar';

  @override
  String get focusPauseButton => 'Pausar';

  @override
  String get focusResumeButton => 'Reanudar';

  @override
  String get focusFinishButton => 'Terminar y Guardar';

  @override
  String get focusResetButton => 'Reiniciar';

  @override
  String focusSessionSavedMessage(int minutes) {
    return '¡Te enfocaste durante $minutes minutos! Buen trabajo.';
  }

  @override
  String get focusSessionTooShortMessage =>
      'Debes enfocarte al menos 1 minuto.';

  @override
  String get focusTotalTimeLabel => 'Tu Tiempo Total de Enfoque';

  @override
  String get profileFocusRowTitle => 'Tiempo de Enfoque';

  @override
  String profileFocusRowSubtitle(String durationText) {
    return 'Te has enfocado $durationText en total';
  }

  @override
  String get instagramFollowCardTitle => 'Síguenos en Instagram';

  @override
  String get instagramFollowCardBody =>
      '¡Sigue @zibo.app y gana 100 ZC, un tema y un disfraz!';

  @override
  String get instagramFollowOpenButton => 'Abrir Instagram';

  @override
  String get instagramFollowClaimButton => 'Ya Sigo';

  @override
  String get instagramFollowRewardGrantedMessage =>
      '¡Tu recompensa fue añadida! 🎉';

  @override
  String get commonOkButton => 'Vale';

  @override
  String get paywallAppBarTitle => 'Zibo Pro';

  @override
  String get paywallBannerTitle => 'Más Cerca de Zibo';

  @override
  String get paywallBannerSubtitle =>
      'Una experiencia sin anuncios, más rápida y personal';

  @override
  String get paywallBillingToggleMonthly => 'Mensual';

  @override
  String get paywallBillingToggleYearly => 'Anual (2 meses gratis)';

  @override
  String get paywallOneTimeTitle => 'Sin Anuncios (Pago Único)';

  @override
  String get paywallOneTimeBenefit => 'Elimina todos los anuncios';

  @override
  String get paywallProTitle => 'Zibo Pro';

  @override
  String get paywallProPlusTitle => 'Zibo Pro+';

  @override
  String get paywallMostPopularBadge => 'Más Popular';

  @override
  String get paywallCurrentPlanBadge => 'Tu Plan Actual';

  @override
  String get paywallAlreadyProPlusBadge => 'Ya Eres Usuario Pro+';

  @override
  String get paywallBuyButton => 'Comprar';

  @override
  String get paywallSubscribeButton => 'Suscribirse';

  @override
  String get paywallUpgradeButton => 'Mejorar a Pro+';

  @override
  String get paywallProPerkNoForcedAds => 'Elimina los anuncios obligatorios';

  @override
  String get paywallProPerkCoinBonus =>
      'Recompensa de monedas de check-in x1,5';

  @override
  String get paywallProPerkStreakFreeze => '1 Streak Freeze gratis al mes';

  @override
  String get paywallProPerkWheelNoAds =>
      'Ruleta de la Suerte sin anuncios + 1 giro extra al día';

  @override
  String get paywallProPerkUnlimitedHistory =>
      'Historial ilimitado en todos los módulos';

  @override
  String get paywallProPerkNotificationTime =>
      'Personaliza la hora de tus notificaciones';

  @override
  String get paywallProPlusPerkAllOfPro => 'Todos los beneficios de Pro';

  @override
  String get paywallProPlusPerkCoinBonus =>
      'Recompensa de monedas de check-in x2';

  @override
  String get paywallProPlusPerkStreakFreeze => '3 Streak Freeze gratis al mes';

  @override
  String get paywallProPlusPerkExclusiveItem =>
      '1 disfraz/tema exclusivo Pro al mes';

  @override
  String get paywallProPlusPerkProfileBadge =>
      'Insignia/marco de perfil exclusivo';

  @override
  String get paywallProPlusPerkWatermark =>
      'Marca de agua Pro+ exclusiva en las tarjetas de compartir';

  @override
  String get paywallProPlusPerkTrendChart => 'Gráfico de tendencias detallado';

  @override
  String get paywallProPlusPerkMoneyAnalysis =>
      'Análisis avanzado de Dinero y Ahorros';

  @override
  String get paywallProPlusPerkNotificationSounds =>
      'Sonidos de notificación exclusivos';

  @override
  String get paywallCloseTooltip => 'Cerrar';

  @override
  String get paywallSocialProofLine =>
      '⭐ 4,8 puntos · miles de Amigos felices usan Zibo Pro';

  @override
  String get paywallCompareTableTitle => '¿Cuál es el ideal para ti?';

  @override
  String get paywallCompareColumnFree => 'Gratis';

  @override
  String get paywallCompareColumnPro => 'Pro';

  @override
  String get paywallCompareColumnProPlus => 'Pro+';

  @override
  String get paywallPurchaseSuccessMessage =>
      '¡Compra exitosa! Bienvenido a Zibo 🎉';

  @override
  String get paywallPurchaseErrorMessage =>
      'No se pudo completar la compra, inténtalo de nuevo.';

  @override
  String get paywallUpgradeSuccessMessage => '¡Mejora a Pro+ exitosa! 🎉';

  @override
  String get paywallUpgradeErrorMessage =>
      'No se pudo completar la mejora, inténtalo de nuevo.';

  @override
  String get paywallPerMonthSuffix => '/mes';

  @override
  String get paywallPerYearSuffix => '/año';

  @override
  String get settingsZiboProRowTitle => 'Zibo Pro';

  @override
  String get settingsZiboProRowSubtitle =>
      'Más funciones, experiencia sin anuncios';
}
