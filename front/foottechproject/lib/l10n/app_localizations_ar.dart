// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'فوت تك';

  @override
  String get onboardingSubtitle => 'مدرب، مساعد أو لاعب — ناديك في جيبك.';

  @override
  String get onboardingCoachBtn => 'أنا مدرب أو مساعد';

  @override
  String get onboardingPlayerBtn => 'أنا لاعب (دخول عبر الرسائل القصيرة)';

  @override
  String get onboardingCreateCoach => 'نادٍ جديد؟ إنشاء حساب مدرب';

  @override
  String get loginTitle => 'دخول المدرب / المساعد';

  @override
  String get loginEmail => 'البريد الإلكتروني';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صحيح';

  @override
  String get required => 'مطلوب';

  @override
  String get firstTimeAssistant => 'أول دخول للمساعد؟';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get unableToLogin => 'تعذر الاتصال';

  @override
  String get registerTitle => 'إنشاء حساب مدرب';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'اللقب';

  @override
  String get phone => 'الهاتف';

  @override
  String get invalidNumber => 'رقم غير صحيح';

  @override
  String get min8Chars => '8 أحرف على الأقل';

  @override
  String get createAccount => 'إنشاء حسابي';

  @override
  String get unableToRegister => 'تعذر التسجيل';

  @override
  String get activateTitle => 'تفعيل المساعد';

  @override
  String get activateIntro =>
      'قام مدربك بإضافتك كمساعد. تم إرسال رمز عبر الرسائل القصيرة إلى الرقم المقدم — أدخله أدناه مع كلمة مرور من اختيارك لتفعيل حسابك.';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get codeReceivedSms => 'الرمز المستلم عبر الرسائل القصيرة';

  @override
  String get invalidCode => 'رمز غير صحيح';

  @override
  String get newPassword => 'كلمة مرور جديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get activateButton => 'تفعيل حسابي';

  @override
  String get codeExpired =>
      'الرمز منتهي أو لم يُستلم؟ اطلب من مدربك إعادة إضافتك إلى الفريق لاستلام رمز جديد.';

  @override
  String get accountActivatedLogin =>
      'تم تفعيل الحساب — يمكنك الآن تسجيل الدخول';

  @override
  String get aiTrendTitle => 'اتجاه الأداء بالذكاء الاصطناعي';

  @override
  String get aiTrendProgressing => 'في تحسن';

  @override
  String get aiTrendStable => 'مستقر';

  @override
  String get aiTrendDeclining => 'يحتاج إلى متابعة';

  @override
  String get aiTrendUnavailable =>
      'يلزم توفر ثلاثة تقييمات على الأقل لحساب الاتجاه.';

  @override
  String aiTrendBasedOn(Object count) {
    return 'استنادًا إلى $count تقييمات حديثة';
  }

  @override
  String get playerLoginTitle => 'دخول اللاعب';

  @override
  String codeSentToPhone(Object phone) {
    return 'تم إرسال رمز إلى $phone. أدخله أدناه.';
  }

  @override
  String get enterCoachPhone => 'أدخل رقم الهاتف الذي أعطيته لمدربك.';

  @override
  String get validate => 'تحقق';

  @override
  String get receiveCode => 'استلام الرمز';

  @override
  String get changeNumber => 'تغيير الرقم';

  @override
  String get otpTitle => 'التحقق من الحساب';

  @override
  String otpCodeSentEmail(Object email) {
    return 'تم إرسال رمز إلى $email. أدخله أدناه لتفعيل حسابك.';
  }

  @override
  String otpWillSendEmail(Object email) {
    return 'سيتم إرسال رمز تحقق عبر الرسائل القصيرة إلى الرقم المرتبط بـ $email لتفعيل حسابك.';
  }

  @override
  String get verifyAndActivate => 'تحقق وفعّل';

  @override
  String get receiveNewCode => 'استلام رمز جديد';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navTeam => 'الفريق';

  @override
  String get navTrainings => 'التدريبات';

  @override
  String get navMatches => 'المباريات';

  @override
  String get navCalendar => 'التقويم';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get biometricLocked => 'فوت تك مقفلة';

  @override
  String get unlock => 'فتح';

  @override
  String get biometricReason => 'افتح تطبيق فوت تك';

  @override
  String get errorGeneric => 'حدث خطأ';

  @override
  String get errorNetwork => 'تعذر الوصول إلى الخادم';

  @override
  String get sessionNotFound => 'الجلسة غير موجودة.';

  @override
  String get nextTraining => 'التدريب القادم';

  @override
  String get nextMatch => 'المباراة القادمة';

  @override
  String get players => 'اللاعبون';

  @override
  String get proposals => 'الاقتراحات';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get seasonSummary => 'ملخص الموسم';

  @override
  String get starter => 'أساسي';

  @override
  String get substitute => 'بديل';

  @override
  String get notSelected => 'غير مختار';

  @override
  String get noData => 'لا توجد بيانات حالياً';

  @override
  String get player => 'اللاعب';

  @override
  String get position => 'المركز';

  @override
  String get played => 'مباريات';

  @override
  String get rating => 'التقييم';

  @override
  String get goals => 'الأهداف';

  @override
  String get assists => 'التمريرات';

  @override
  String get goalsConceded => 'الأهداف المقبولة';

  @override
  String get noTeamLinked => 'لا يوجد فريق مرتبط بحسابك حالياً.';

  @override
  String get createFirstTeam => 'أنشئ فريقك الأول';

  @override
  String get canAddPlayersAssistants => 'يمكنك بعد ذلك إضافة لاعبيك ومساعديك.';

  @override
  String get teamName => 'اسم الفريق';

  @override
  String category(Object example) {
    return 'الفئة ($example)';
  }

  @override
  String get create => 'إنشاء';

  @override
  String get addPlayer => 'إضافة لاعب';

  @override
  String get addAssistant => 'إضافة مساعد';

  @override
  String get noPlayersYet => 'لا يوجد لاعبون بعد';

  @override
  String get noAssistantsYet => 'لا يوجد مساعدون بعد';

  @override
  String awaitingActivation(Object phone) {
    return '$phone - بانتظار التفعيل';
  }

  @override
  String get staff => 'الطاقم';

  @override
  String get add => 'إضافة';

  @override
  String get newPlayer => 'لاعب جديد';

  @override
  String get phoneSmsActivation => 'الهاتف (تفعيل عبر الرسائل القصيرة)';

  @override
  String get primaryPosition => 'المركز الأساسي';

  @override
  String get strongFoot => 'القدم القوية';

  @override
  String get right => 'يمين';

  @override
  String get left => 'يسار';

  @override
  String get ambidextrous => 'بكلتا القدمين';

  @override
  String get jerseyNumber => 'رقم القميص';

  @override
  String get createPlayer => 'إنشاء اللاعب';

  @override
  String get tabIdentity => 'الهوية';

  @override
  String get tabFamily => 'العائلة';

  @override
  String get tabSchool => 'المدرسة';

  @override
  String get tabInjuries => 'الإصابات';

  @override
  String get height => 'الطول';

  @override
  String get weight => 'الوزن';

  @override
  String get foot => 'القدم';

  @override
  String get evolutionBySeason => 'التطور حسب الموسم';

  @override
  String get noDataRecorded => 'لا توجد بيانات مسجلة';

  @override
  String get parentsGuardian => 'الوالدان / الوصي';

  @override
  String get father => 'الأب';

  @override
  String get mother => 'الأم';

  @override
  String get guardian => 'الوصي';

  @override
  String get noContactRecorded => 'لا توجد جهة اتصال مسجلة';

  @override
  String get addressCommute => 'العنوان والتنقل';

  @override
  String get notProvided => 'غير محدد';

  @override
  String kmFromClub(Object distance) {
    return '$distance كم من النادي';
  }

  @override
  String get school => 'المؤسسة';

  @override
  String get classLevel => 'الصف';

  @override
  String get level => 'المستوى';

  @override
  String get noInjuries => 'لا توجد إصابات مسجلة';

  @override
  String get injury => 'إصابة';

  @override
  String days(Object days) {
    return '· $days يوم';
  }

  @override
  String get noTrainingPlanned => 'لا يوجد تدريب مخطط';

  @override
  String get technicalSheet => 'الورقة الفنية';

  @override
  String get attendance => 'الحضور';

  @override
  String get objectives => 'الأهداف';

  @override
  String get edit => 'تعديل';

  @override
  String get situations => 'المواقف';

  @override
  String get noSituationAdded => 'لا يوجد موقف مضاف';

  @override
  String work(Object value) {
    return 'العمل: $value';
  }

  @override
  String recovery(Object value) {
    return 'الاستشفاء: $value';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get newSituation => 'موقف جديد';

  @override
  String get title => 'العنوان';

  @override
  String get workDuration => 'مدة العمل (مثال: 2*4)';

  @override
  String get recoveryDuration => 'مدة الاستشفاء';

  @override
  String get diagramSaved => 'تم حفظ المخطط';

  @override
  String get tacticalDiagram => 'المخطط التكتيكي';

  @override
  String get newTraining => 'تدريب جديد';

  @override
  String get date => 'التاريخ';

  @override
  String get startTime => 'وقت البدء';

  @override
  String get endTime => 'وقت الانتهاء';

  @override
  String get location => 'المكان';

  @override
  String get noMatches => 'لا توجد مباريات';

  @override
  String homeAwayVs(Object homeAway, Object opponent) {
    return '$homeAway ضد $opponent';
  }

  @override
  String get home => 'على أرضه';

  @override
  String get away => 'خارج أرضه';

  @override
  String get lineup => 'التشكيلة';

  @override
  String get ai => 'الذكاء الاصطناعي';

  @override
  String get live => 'مباشر';

  @override
  String get starters => 'الأساسيون';

  @override
  String get substitutes => 'البدلاء';

  @override
  String get lineupNotSet => 'التشكيلة غير محددة';

  @override
  String get start => 'ابدأ';

  @override
  String get addEvent => '+ حدث';

  @override
  String get finish => 'إنهاء';

  @override
  String get noEvents => 'لا توجد أحداث';

  @override
  String get eventGoal => 'هدف';

  @override
  String get eventAssist => 'تمريرة حاسمة';

  @override
  String get yellowCard => 'بطاقة صفراء';

  @override
  String get redCard => 'بطاقة حمراء';

  @override
  String get eventSubOn => 'دخول اللعب';

  @override
  String get eventSubOff => 'خروج';

  @override
  String get eventInjury => 'إصابة';

  @override
  String get type => 'النوع';

  @override
  String get minute => 'الدقيقة';

  @override
  String get generateAiRecommendations => 'توليد توصيات الذكاء الاصطناعي';

  @override
  String get noRecommendation => 'لم يتم توليد أي توصية';

  @override
  String playerId(Object id) {
    return 'اللاعب #$id';
  }

  @override
  String get opponent => 'الخصم';

  @override
  String get time => 'الوقت';

  @override
  String get homeGame => 'على أرضه';

  @override
  String get newMatch => 'مباراة جديدة';

  @override
  String get refresh => 'تحديث';

  @override
  String get noEventsDay => 'لا توجد أحداث هذا اليوم.';

  @override
  String get noEventsDayTap => 'لا توجد أحداث هذا اليوم. اضغط + لإضافة واحدة.';

  @override
  String get description => 'الوصف';

  @override
  String get delete => 'حذف';

  @override
  String get readOnly => 'للقراءة فقط';

  @override
  String get eventAdded => 'تمت إضافة الحدث';

  @override
  String get eventModified => 'تم تعديل الحدث';

  @override
  String get deleteTitle => 'حذف';

  @override
  String deleteConfirm(Object title) {
    return 'حذف \"$title\"؟';
  }

  @override
  String get eventDeleted => 'تم حذف الحدث';

  @override
  String get newEvent => 'حدث جديد';

  @override
  String get titleRequired => 'العنوان *';

  @override
  String get allDay => 'طوال اليوم';

  @override
  String get color => 'اللون: ';

  @override
  String get titleRequiredMsg => 'العنوان مطلوب';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get coachRole => 'مدرب';

  @override
  String get assistantRole => 'مساعد';

  @override
  String get playerRole => 'لاعب';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get exerciseProposals => 'اقتراحات التمارين';

  @override
  String get noPendingProposal => 'لا يوجد اقتراح معلق';

  @override
  String get pending => 'معلق';

  @override
  String get proposeExercise => 'اقتراح تمرين';

  @override
  String get submit => 'إرسال';

  @override
  String presentCount(Object present, Object total) {
    return '$present/$total حاضر';
  }

  @override
  String vsOpponent(Object opponent) {
    return 'ضد $opponent';
  }

  @override
  String get minutesPlayed => 'د';

  @override
  String heightValue(Object cm) {
    return '$cm سم';
  }

  @override
  String weightValue(Object kg) {
    return '$kg كغ';
  }

  @override
  String get match => 'مباراة';

  @override
  String aiScorePercent(Object value) {
    return 'النسبة: $value%';
  }

  @override
  String situationNumber(Object value) {
    return 'موقف $value';
  }

  @override
  String get navSeasons => 'المواسم';

  @override
  String get newSeason => 'موسم جديد';

  @override
  String get seasonName => 'اسم الموسم';

  @override
  String get startDate => 'البداية';

  @override
  String get endDate => 'النهاية';

  @override
  String get current => 'الموسم الحالي';

  @override
  String get createSeason => 'إنشاء الموسم';

  @override
  String get noSeasons => 'لا توجد مواسم';

  @override
  String get seasonDetails => 'تفاصيل الموسم';

  @override
  String fromTo(Object end, Object start) {
    return 'من $start إلى $end';
  }

  @override
  String get deleteSeason => 'حذف الموسم';
}
