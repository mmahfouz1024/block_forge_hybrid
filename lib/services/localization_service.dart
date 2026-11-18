class L10n {
  static const Map<String, (String ar, String en)> _strings = {
    'app_title': ('قلعة البلوكات', 'Block Forge'),
    'app_subtitle': ('ألغاز ومغامرة المملكة', 'Kingdom Puzzle'),
    'classic_mode': ('الوضع الكلاسيكي', 'Classic Mode'),
    'classic_desc': ('حقق أعلى سكور بدون توقف', 'Endless high-score challenge'),
    'adventure_mode': ('خريطة المغامرة', 'Adventure Map'),
    'adventure_desc': ('30 مرحلة بأهداف وجوائز', '30 levels with gems & ice'),
    'kingdom_builder': ('تطوير المملكة', 'Kingdom Builder'),
    'kingdom_desc': ('ابني وطور مباني قلعتك', 'Upgrade landmarks for perks'),
    'daily_quests': ('المهام اليومية', 'Daily Quests'),
    'settings': ('الإعدادات', 'Settings'),
    'best_score': ('أفضل سكور', 'Best Score'),
    'gems': ('الجواهر', 'Gems'),
    'stars': ('النجوم', 'Stars'),
    'score': ('النقاط', 'Score'),
    'combo': ('كومبو', 'COMBO'),
    'goal_score': ('الهدف', 'Target'),
    'goal_gems': ('جواهر', 'Gems'),
    'goal_ice': ('جليد', 'Ice'),
    'bomb': ('قنبلة 3×3', '3x3 Bomb'),
    'hammer': ('مطرقة', 'Hammer'),
    'refresh': ('تبديل', 'Refresh'),
    'tap_board_bomb': ('اضغط على الرقعة لتفجير 3×3', 'Tap board to blast 3x3 area'),
    'tap_board_hammer': ('اضغط على مربع محدد لتحطيمه', 'Tap any filled cell to smash it'),
    'cancel': ('إلغاء', 'Cancel'),
    'game_over': ('انتهت المحاولات!', 'No Moves Left!'),
    'revive': ('إنقاذ وتنظيف جزء', 'Revive & Clear Space'),
    'play_again': ('العب مرة أخرى', 'Play Again'),
    'back_home': ('الرئيسية', 'Home'),
    'level_complete': ('تم اجتياز المرحلة!', 'Level Complete!'),
    'next_level': ('المرحلة التالية', 'Next Level'),
    'upgrade': ('ترقية', 'Upgrade'),
    'max_level': ('الحد الأقصى', 'MAX'),
    'level_short': ('مستوى', 'Lv.'),
    'claim': ('استلام', 'Claim'),
    'claimed': ('تم الاستلام', 'Claimed'),
    'sound': ('المؤثرات الصوتية', 'Sound Effects'),
    'haptics': ('الاهتزاز (Haptics)', 'Vibration Haptics'),
    'language': ('اللغة (العربية / English)', 'Language (العربية / English)'),
    'privacy': ('سياسة الخصوصية', 'Privacy Policy'),
    'privacy_body': (
      'تطبيق Block Forge يعمل محلياً على جهازك لحفظ تقدمك وإحصائياتك ولا يجمع أي بيانات شخصية أو حساسة.',
      'Block Forge stores your game progress locally on your device and collects no personal or sensitive data.'
    ),
    'not_enough_gems': ('الجواهر غير كافية!', 'Not enough Gems!'),
    'buy_booster': ('شراء أداة (20 جوهرة)', 'Buy booster (20 Gems)'),
    'drag_hint': ('اسحب القطع إلى الرقعة أو اضغط لاختيارها ثم اضغط المكان', 'Drag pieces to the board, or tap a piece then tap the board'),
    'new_record': ('رقم قياسي جديد!', 'NEW BEST!'),
    'pause': ('إيقاف مؤقت', 'Paused'),
    'resume': ('استكمال', 'Resume'),
  };

  static String tr(String key, bool isArabic) {
    final entry = _strings[key];
    if (entry == null) return key;
    return isArabic ? entry.$1 : entry.$2;
  }
}
