import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/helpers.dart';
import '../models/app_state.dart';
import '../models/cycle_entry.dart';
import '../models/symptom.dart';
import 'ai_chat_service.dart';
import 'gemini_service.dart';

// ----------------------------------------------------------------
// DATA MODELS
// ----------------------------------------------------------------

class PadProduct {
  const PadProduct({
    required this.name,
    required this.brand,
    required this.type,
    this.features = const <String>[],
    this.buyUrl = '',
  });

  final String name;
  final String brand;
  final String type;
  final List<String> features;
  final String buyUrl;

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand': brand,
        'type': type,
        'features': features,
        'buyUrl': buyUrl,
      };

  factory PadProduct.fromJson(Map<String, dynamic> json) => PadProduct(
        name: (json['name'] as String?) ?? '',
        brand: (json['brand'] as String?) ?? '',
        type: (json['type'] as String?) ?? '',
        features: ((json['features'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        buyUrl: (json['buyUrl'] as String?) ?? '',
      );
}

class PadRecommendation {
  const PadRecommendation({
    required this.padType,
    required this.reason,
    required this.absorbency,
    required this.products,
    this.reasonsBreakdown = const <String>[],
  });

  final String padType;
  final String reason;
  final String absorbency;
  final List<PadProduct> products;
  final List<String> reasonsBreakdown;

  Map<String, dynamic> toJson() => {
        'padType': padType,
        'padReason': reason,
        'padAbsorbency': absorbency,
        'reasonsBreakdown': reasonsBreakdown,
        'products': products.map((p) => p.toJson()).toList(),
      };

  factory PadRecommendation.fromJson(Map<String, dynamic> json) {
    final products = ((json['products'] as List?) ?? [])
        .map((p) => PadProduct.fromJson(p as Map<String, dynamic>))
        .toList();
    final breakdown = ((json['reasonsBreakdown'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    return PadRecommendation(
      padType: (json['padType'] as String?) ?? 'Regular Pad',
      reason: (json['padReason'] as String?) ?? '',
      absorbency: (json['padAbsorbency'] as String?) ?? 'Medium',
      products: products,
      reasonsBreakdown: breakdown,
    );
  }
}

class JournalEntry {
  const JournalEntry({
    required this.date,
    required this.headline,
    required this.body,
    required this.padRecommendation,
    required this.tips,
    this.generatedByAi = false,
  });

  final DateTime date;
  final String headline;
  final String body;
  final PadRecommendation padRecommendation;
  final List<String> tips;
  final bool generatedByAi;

  Map<String, dynamic> toJson() => {
        'date': Helpers.dayKey(date),
        'headline': headline,
        'body': body,
        'padRecommendation': padRecommendation.toJson(),
        'tips': tips,
        'generatedByAi': generatedByAi,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    PadRecommendation rec;
    if (json['padRecommendation'] is Map<String, dynamic>) {
      rec = PadRecommendation.fromJson(
          json['padRecommendation'] as Map<String, dynamic>);
    } else {
      final rawProducts = ((json['products'] as List?) ?? [])
          .map((p) => PadProduct(
                name: (p['name'] as String?) ?? '',
                brand: (p['brand'] as String?) ?? '',
                type: (p['type'] as String?) ?? '',
                features: ((p['features'] as List?) ?? [])
                    .map((e) => e.toString())
                    .toList(),
                buyUrl: (p['buyUrl'] as String?) ?? '',
              ))
          .toList();

      rec = PadRecommendation(
        padType: (json['padType'] as String?) ?? 'Regular Pad',
        reason: (json['padReason'] as String?) ?? '',
        absorbency: (json['padAbsorbency'] as String?) ?? 'Medium',
        products: rawProducts,
        reasonsBreakdown: ((json['reasonsBreakdown'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    }

    return JournalEntry(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      headline: (json['headline'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      padRecommendation: rec,
      tips: ((json['tips'] as List?) ?? []).map((e) => e.toString()).toList(),
      generatedByAi: (json['generatedByAi'] as bool?) ?? false,
    );
  }
}

// ----------------------------------------------------------------
// SERVICE
// ----------------------------------------------------------------

class AiJournalService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _gemini = GeminiService();
  final AiChatService _chatService = AiChatService();

  User? get _currentUser => _supabase.auth.currentUser;

  // ----------------------------------------------------------------
  // PUBLIC API
  // ----------------------------------------------------------------

  Future<JournalEntry> getTodayJournal(AppState state) async {
    final today = Helpers.today;
    final userId = _currentUser?.id;

    if (userId != null) {
      try {
        final cached = await _supabase
            .from('ai_journals')
            .select()
            .eq('user_id', userId)
            .eq('date', Helpers.dayKey(today))
            .maybeSingle();

        if (cached != null) {
          return JournalEntry.fromJson(cached as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('AiJournalService cache miss: $e');
      }
    }

    final journal = await _generateJournal(state, today);

    if (userId != null) {
      unawaited(_save(userId, journal));
    }

    return journal;
  }

  Future<JournalEntry> refreshTodayJournal(AppState state) async {
    final today = Helpers.today;
    final journal = await _generateJournal(state, today);
    final userId = _currentUser?.id;
    if (userId != null) {
      unawaited(_save(userId, journal));
    }
    return journal;
  }

  Future<List<JournalEntry>> getPastJournals({int limit = 14}) async {
    final userId = _currentUser?.id;
    if (userId == null) return [];
    try {
      final rows = await _supabase
          .from('ai_journals')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);
      return (rows as List)
          .map((r) => JournalEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('AiJournalService.getPastJournals error: $e');
      return [];
    }
  }

  Future<void> _save(String userId, JournalEntry journal) async {
    try {
      await _supabase.from('ai_journals').upsert({
        'user_id': userId,
        ...journal.toJson(),
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');
    } catch (e) {
      debugPrint('AiJournalService._save error: $e');
    }
  }

  // ----------------------------------------------------------------
  // GENERATION ROUTER
  // ----------------------------------------------------------------

  Future<JournalEntry> _generateJournal(AppState state, DateTime date) async {
    final padRec = recommendPadForState(state, date: date);

    if (state.geminiApiKey.isNotEmpty) {
      return _generateWithGemini(state, date, padRec);
    }
    return _generateRuleBased(state, date, padRec);
  }

  // ----------------------------------------------------------------
  // GEMINI AI GENERATION — Ingests ALL user logs and AI Chat
  // ----------------------------------------------------------------

  Future<JournalEntry> _generateWithGemini(
    AppState state,
    DateTime date,
    PadRecommendation padRec,
  ) async {
    final prompt = await _buildFullContextPrompt(state, date, padRec);

    try {
      final rawText = await _gemini.generate(
        prompt: prompt,
        state: state,
        customSystemPrompt: _journalSystemPrompt(state),
        maxTokens: 1000,
      );

      final parsed = _parseGeminiJournalOutput(rawText, padRec, date);

      final entry = state.entryFor(date);
      final enhancedPadRec = await _enhancePadReasonWithGemini(
        state: state,
        padRec: padRec,
        entry: entry,
      );

      return JournalEntry(
        date: date,
        headline: parsed['headline'] as String,
        body: parsed['body'] as String,
        padRecommendation: enhancedPadRec,
        tips: List<String>.from(parsed['tips'] as List),
        generatedByAi: true,
      );
    } catch (e) {
      debugPrint('Gemini journal generation failed, falling back: $e');
      return _generateRuleBased(state, date, padRec);
    }
  }

  /// Builds a complete context prompt incorporating:
  /// - Full user profile (skin sensitivity, body type, routine, flow tendency)
  /// - Today's check-in (symptoms, rashes, flow, sleep, mood, notes, activity)
  /// - 30-day historical cycle trends
  /// - Recent AI Chat messages with Cherry AI
  Future<String> _buildFullContextPrompt(
    AppState state,
    DateTime date,
    PadRecommendation padRec,
  ) async {
    final user = state.user;
    final phase = state.phase;
    final cycleDay = state.cycleDay;
    final daysUntilPeriod = state.daysUntilNextPeriod;
    final todayEntry = state.entryFor(date);
    final allEntries = state.allEntries;

    final buf = StringBuffer();

    buf.writeln('Generate a personal daily wellness journal for ${user.name}.');
    buf.writeln('');

    // ---- USER PROFILE ----
    buf.writeln('=== USER BASELINE PROFILE ===');
    buf.writeln('Name: ${user.name}');
    buf.writeln('Age: ${user.age}');
    buf.writeln('Cycle length: ${user.cycleLength} days');
    buf.writeln('Period length: ${user.periodLength} days');
    buf.writeln('Last period started: ${Helpers.dayKey(user.lastPeriodStart)}');
    buf.writeln('Skin Sensitivity / Rash History: ${user.skinSensitivity}');
    buf.writeln('Body Type / Hip Fit: ${user.bodyType}');
    buf.writeln('Daily Routine / Movement: ${user.dailyRoutine}');
    buf.writeln('Flow Tendency: ${user.flowTendency}');
    buf.writeln('');

    // ---- TODAY ----
    buf.writeln('=== TODAY (${Helpers.dayKey(date)}) ===');
    buf.writeln('Cycle phase: $phase');
    buf.writeln('Cycle day: $cycleDay of ${user.cycleLength}');
    if (phase == 'Menstrual Phase') {
      buf.writeln('She is currently on her period.');
    } else {
      buf.writeln('Days until next period: $daysUntilPeriod');
    }

    if (todayEntry != null) {
      buf.writeln('Flow today: ${todayEntry.flow.label}');
      buf.writeln('Activity/Routine level today: ${todayEntry.activityLevel}');
      if (todayEntry.mood != null) {
        buf.writeln('Mood today: ${todayEntry.mood!.label} ${todayEntry.mood!.emoji}');
      }
      if (todayEntry.symptoms.isNotEmpty) {
        buf.writeln('Symptoms today: ${todayEntry.symptoms.join(', ')}');
      }
      buf.writeln('Sleep last night: ${todayEntry.sleepHours.toStringAsFixed(1)} hours');
      if (todayEntry.notes.isNotEmpty) {
        buf.writeln('Personal note: "${todayEntry.notes}"');
      }
    } else {
      buf.writeln('No check-in logged for today yet.');
    }
    buf.writeln('');

    // ---- RECENT AI CHAT CONVERSATIONS ----
    try {
      final chatList = await _chatService.loadHistory();
      if (chatList.isNotEmpty) {
        buf.writeln('=== RECENT AI CHAT CONVERSATIONS (Between ${user.name} and Cherry AI) ===');
        final recentChats = chatList.length > 8
            ? chatList.sublist(chatList.length - 8)
            : chatList;
        for (final msg in recentChats) {
          final sender = msg.isUser ? user.name : 'Cherry AI';
          buf.writeln('$sender: "${msg.text}"');
        }
        buf.writeln('Take these recent chat topics into account to make today\'s journal feel connected and attentive.');
        buf.writeln('');
      }
    } catch (e) {
      debugPrint('Could not fetch chat history for prompt: $e');
    }

    // ---- FULL CYCLE HISTORY (last 30 entries) ----
    if (allEntries.isNotEmpty) {
      buf.writeln('=== RECENT CYCLE HISTORY (last 30 logged days) ===');
      final recent = allEntries.reversed.take(30).toList().reversed.toList();
      for (final e in recent) {
        final parts = <String>[Helpers.dayKey(e.date)];
        parts.add('flow:${e.flow.label}');
        parts.add('act:${e.activityLevel}');
        if (e.mood != null) parts.add('mood:${e.mood!.label}');
        if (e.symptoms.isNotEmpty) {
          parts.add('symptoms:[${e.symptoms.join(',')}]');
        }
        parts.add('sleep:${e.sleepHours.toStringAsFixed(1)}h');
        buf.writeln(parts.join(' | '));
      }
      buf.writeln('');
    }

    // ---- STATISTICAL PATTERNS ----
    buf.writeln('=== HER HEALTH PATTERNS ===');
    final symptomMap = <String, int>{};
    for (final e in allEntries) {
      for (final s in e.symptoms) {
        symptomMap[s] = (symptomMap[s] ?? 0) + 1;
      }
    }
    if (symptomMap.isNotEmpty) {
      final sorted = symptomMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      buf.writeln('Most frequent symptoms: ${sorted.take(5).map((e) => '${e.key}(${e.value}x)').join(', ')}');
    }

    buf.writeln('');

    // ---- PAD CONTEXT ----
    buf.writeln('=== RECOMMENDED PAD FOR TODAY ===');
    buf.writeln('Type: ${padRec.padType}');
    buf.writeln('Absorbency: ${padRec.absorbency}');
    buf.writeln('Reason: ${padRec.reason}');
    buf.writeln('');

    // ---- INSTRUCTIONS ----
    buf.writeln('=== GENERATE THE FOLLOWING (respond in this exact format) ===');
    buf.writeln('');
    buf.writeln('HEADLINE: [One warm, personal headline for today — max 8 words]');
    buf.writeln('');
    buf.writeln('BODY: [3 paragraphs, written warmly in second person ("You..."). ');
    buf.writeln('Reference her specific data — mention her actual mood, symptoms logged,');
    buf.writeln('sleep hours, phase, daily routine (${todayEntry?.activityLevel ?? user.dailyRoutine}),');
    buf.writeln('any rashes or skin sensitivity, and recent questions from AI chat if applicable.');
    buf.writeln('Briefly explain why her pad recommendation (${padRec.padType}) keeps her confident today.');
    buf.writeln('Write like a caring friend who truly knows her. No markdown asterisks.]');
    buf.writeln('');
    buf.writeln('TIPS:');
    buf.writeln('- [Tip 1 based on her actual symptoms & skin/rash comfort]');
    buf.writeln('- [Tip 2 based on her daily routine & activity level]');
    buf.writeln('- [Tip 3 based on her cycle phase]');
    buf.writeln('- [Tip 4 for relaxation and wellbeing]');

    return buf.toString();
  }

  static String _journalSystemPrompt(AppState state) {
    return 'You are Cherry AI, the warm, empathetic wellness companion inside the '
        'Cheri menstrual health app for ${state.user.name}. '
        'You have full visibility into her cycle data, skin sensitivity (such as rashes), '
        'body type, daily routine, symptoms, and previous AI chat conversations. '
        'You write deeply caring, supportive daily journals and explain pad recommendations '
        'in a kind, gentle manner. '
        'NEVER use markdown formatting like ** or ##. '
        'NEVER give clinical diagnoses. Follow the exact requested format.';
  }

  Map<String, dynamic> _parseGeminiJournalOutput(
    String raw,
    PadRecommendation padRec,
    DateTime date,
  ) {
    String headline = 'Your Daily Journal 🌸';
    String body = raw;
    final tips = <String>[];

    try {
      final headlineMatch = RegExp(r'HEADLINE:\s*(.+)', caseSensitive: false)
          .firstMatch(raw);
      if (headlineMatch != null) {
        headline = headlineMatch.group(1)?.trim() ?? headline;
      }

      final bodyMatch = RegExp(
        r'BODY:\s*([\s\S]+?)(?=TIPS:|$)',
        caseSensitive: false,
      ).firstMatch(raw);
      if (bodyMatch != null) {
        body = bodyMatch.group(1)?.trim() ?? raw;
      }

      final tipsMatch = RegExp(r'TIPS:([\s\S]+)$', caseSensitive: false)
          .firstMatch(raw);
      if (tipsMatch != null) {
        final tipsBlock = tipsMatch.group(1) ?? '';
        final lines = tipsBlock
            .split('\n')
            .map((l) => l.replaceAll(RegExp(r'^[\s\-\*\d\.]+'), '').trim())
            .where((l) => l.isNotEmpty)
            .toList();
        tips.addAll(lines.take(4));
      }
    } catch (e) {
      debugPrint('Journal parse error: $e');
    }

    if (tips.isEmpty) {
      tips.addAll([
        'Drink at least 2 litres of water today',
        'Keep skin dry and moisturized to prevent chafing',
        'Take a 10-minute walk outside if you can',
        'Prioritise 7–8 hours of restorative sleep tonight',
      ]);
    }

    return {'headline': headline, 'body': body, 'tips': tips};
  }

  Future<PadRecommendation> _enhancePadReasonWithGemini({
    required AppState state,
    required PadRecommendation padRec,
    required CycleEntry? entry,
  }) async {
    if (state.geminiApiKey.isEmpty) return padRec;

    final prompt = GeminiService.buildPadReasonPrompt(
      padType: padRec.padType,
      phase: state.phase,
      flowLevel: entry?.flow.label ?? 'None',
      symptoms: entry?.symptoms.toList() ?? [],
      userName: state.user.name,
      skinSensitivity: state.user.skinSensitivity,
      dailyRoutine: entry?.activityLevel ?? state.user.dailyRoutine,
      bodyType: state.user.bodyType,
    );

    try {
      final reason = await _gemini.generate(
        prompt: prompt,
        state: state,
        maxTokens: 140,
      );
      if (reason.trim().isNotEmpty) {
        return PadRecommendation(
          padType: padRec.padType,
          reason: reason.trim(),
          absorbency: padRec.absorbency,
          products: padRec.products,
          reasonsBreakdown: padRec.reasonsBreakdown,
        );
      }
      return padRec;
    } catch (e) {
      return padRec;
    }
  }

  // ----------------------------------------------------------------
  // RULE-BASED ENGINE (Offline & Zero-Key Fallback)
  // ----------------------------------------------------------------

  JournalEntry _generateRuleBased(
    AppState state,
    DateTime date,
    PadRecommendation padRec,
  ) {
    final entry = state.entryFor(date);
    final phase = state.phase;
    final cycleDay = state.cycleDay;
    final allEntries = state.allEntries;

    final tips = _generateTips(entry, phase, allEntries, state);
    final headline = _generateHeadline(phase, entry, cycleDay, state);
    final body = _generateBody(state, entry, phase, cycleDay, allEntries, padRec);

    return JournalEntry(
      date: date,
      headline: headline,
      body: body,
      padRecommendation: padRec,
      tips: tips,
      generatedByAi: false,
    );
  }

  String _generateHeadline(
    String phase,
    CycleEntry? entry,
    int cycleDay,
    AppState state,
  ) {
    final symptoms = entry?.symptoms ?? {};
    final flow = entry?.flow ?? FlowLevel.none;

    if (symptoms.contains('rashes') || symptoms.contains('chafing')) {
      return 'Soothing Care for Your Skin Today 🌸';
    }
    if (phase == 'Menstrual Phase') {
      if (cycleDay == 1) return 'Day 1 of Your Period — Rest & Reset 💕';
      if (flow == FlowLevel.heavy) return 'Heavy Flow Day — Comfort First 🌺';
      if (flow == FlowLevel.light) return 'Winding Down — Gentle Ease 🌿';
      return 'Period Day $cycleDay — You Are Doing Great ✨';
    }
    if (phase == 'Follicular Phase') {
      return 'Energy Rising — A Fresh Chapter 🌿';
    }
    if (phase == 'Ovulation Phase') {
      return 'Peak Glow — Your Brightest Phase 🌟';
    }
    return 'Luteal Phase Comfort — Be Gentle 💜';
  }

  String _generateBody(
    AppState state,
    CycleEntry? entry,
    String phase,
    int cycleDay,
    List<CycleEntry> allEntries,
    PadRecommendation padRec,
  ) {
    final buf = StringBuffer();
    final name = state.user.name;
    final mood = entry?.mood;
    final symptoms = entry?.symptoms ?? {};
    final sleepHours = entry?.sleepHours ?? 7.0;
    final flow = entry?.flow ?? FlowLevel.none;
    final activity = entry?.activityLevel ?? state.user.dailyRoutine;

    buf.write('Hey $name 💕\n\n');

    // Phase & Routine paragraph
    if (phase == 'Menstrual Phase') {
      buf.write('You are on day $cycleDay of your cycle with ${flow.label.toLowerCase()} flow. '
          'Your body is actively shedding its uterine lining, which naturally draws upon your metabolic energy. '
          'Given your $activity routine today, honoring your rhythm and avoiding strain will make a huge difference.');
    } else if (phase == 'Follicular Phase') {
      buf.write('You are in your follicular phase (cycle day $cycleDay). '
          'Estrogen is steadily climbing, replenishing your stamina and mental sharpness. '
          'With your $activity routine, this is an inspiring time to move, create, and explore.');
    } else if (phase == 'Ovulation Phase') {
      buf.write('Welcome to your ovulation window, cycle day $cycleDay! '
          'Luteinizing hormone and estrogen reach their peak right now. '
          'You may naturally notice heightened confidence and social energy.');
    } else {
      buf.write('You are in your luteal phase on day $cycleDay. Progesterone is the dominant hormone now, '
          'which prepares your body for the upcoming cycle. Feeling a bit more introspective or slower is '
          'completely natural and healthy.');
    }

    // Symptoms, Skin & Rashes paragraph
    buf.write('\n\n');
    if (symptoms.contains('rashes') || symptoms.contains('chafing') ||
        state.user.skinSensitivity.toLowerCase().contains('rash')) {
      buf.write('We noticed skin sensitivity or rashes in your logs. '
          'Synthetic pad netting and trapped perspiration can quickly aggravate intimate skin. '
          'That is why Cheri suggests your ${padRec.padType} today — its pure breathable core '
          'relieves friction and allows delicate skin to breathe and heal. ');
    }
    if (symptoms.contains('cramps')) {
      buf.write('You also noted cramps today. A warm heating pad on your lower back or tummy, '
          'plus gentle child\'s pose stretches, will soothe pelvic muscle spasms. ');
    }
    if (symptoms.contains('fatigue')) {
      buf.write('Fatigue was logged — prioritize iron-rich snacks (like soaked almonds or figs) '
          'and treat yourself to 20 minutes of undisturbed rest. ');
    }
    if (symptoms.isEmpty && !state.user.skinSensitivity.toLowerCase().contains('rash')) {
      buf.write('You have no major discomfort logged today — a great opportunity to enjoy your day '
          'and nourish your body with wholesome meals and refreshing hydration. ');
    }

    // Sleep & Encouragement paragraph
    buf.write('\n\n');
    if (sleepHours < 7) {
      buf.write('You logged ${sleepHours.toStringAsFixed(1)} hours of sleep last night. '
          'Your body repairs hormonal balance during deep sleep, so try to wind down 30 minutes earlier tonight. ');
    } else {
      buf.write('Great job getting ${sleepHours.toStringAsFixed(1)} hours of restorative sleep! ');
    }
    if (mood != null) {
      buf.write('Honoring your ${mood.label.toLowerCase()} mood today: you are doing beautifully. ');
    }
    buf.write('Cheri\'s AI adapts your pad advice and daily insights with every check-in you log. 🌸');

    return buf.toString();
  }

  List<String> _generateTips(
    CycleEntry? entry,
    String phase,
    List<CycleEntry> allEntries,
    AppState state,
  ) {
    final tips = <String>[];
    final symptoms = entry?.symptoms ?? {};
    final isRash = symptoms.contains('rashes') || symptoms.contains('chafing') ||
        state.user.skinSensitivity.toLowerCase().contains('rash');

    if (isRash) {
      tips.add('Wear loose, 100% breathable cotton undergarments to soothe skin irritation');
    }
    if (symptoms.contains('cramps')) {
      tips.add('Apply a warm heating pad to your pelvic area for 15 minutes');
    }
    if (entry?.flow == FlowLevel.heavy) {
      tips.add('Incorporate iron-rich foods: leafy greens, lentils, or dates');
    }
    if (entry?.activityLevel.contains('Active') == true ||
        state.user.dailyRoutine.contains('Active')) {
      tips.add('Change your pad immediately after workouts to prevent sweat chafing');
    }
    if (tips.length < 4) {
      tips.add('Stay hydrated with at least 2.5 litres of room-temperature water');
    }
    if (tips.length < 4) {
      tips.add('Check your recommended pad type to keep friction and leakage at zero');
    }

    return tips.take(4).toList();
  }

  // ----------------------------------------------------------------
  // PAD RECOMMENDATION ENGINE
  // Dynamic matching based on:
  // - Skin sensitivity (rashes / chafing)
  // - Daily routine (active gym, desk sitting, travel)
  // - Body type (curvy hips, petite, athletic)
  // - Flow level & Cycle phase
  // ----------------------------------------------------------------

  PadRecommendation recommendPadForState(
    AppState state, {
    DateTime? date,
  }) {
    final targetDate = date ?? Helpers.today;
    final entry = state.entryFor(targetDate);
    final user = state.user;
    final phase = state.phase;
    final cycleDay = state.cycleDay;

    final flow = entry?.flow ?? FlowLevel.none;
    final symptoms = entry?.symptoms ?? {};
    final isRashProne = symptoms.contains('rashes') ||
        symptoms.contains('chafing') ||
        user.skinSensitivity.toLowerCase().contains('rash') ||
        user.skinSensitivity.toLowerCase().contains('sensitive');

    final activity = (entry?.activityLevel ?? user.dailyRoutine).toLowerCase();
    final body = user.bodyType.toLowerCase();
    final isActiveRoutine = activity.contains('active') ||
        activity.contains('gym') ||
        activity.contains('sport');
    final isSittingRoutine = activity.contains('desk') || activity.contains('sitting');
    final isCurvy = body.contains('curvy') || body.contains('hip');

    final isPeriodPhase = phase == 'Menstrual Phase' ||
        flow == FlowLevel.heavy ||
        flow == FlowLevel.medium ||
        flow == FlowLevel.light;

    // --------------------------------------------------------------
    // 1. RASH / SENSITIVE SKIN PRIORITY
    // --------------------------------------------------------------
    if (isRashProne && isPeriodPhase) {
      return PadRecommendation(
        padType: '100% Organic Cotton Rash-Free Pad',
        absorbency: flow == FlowLevel.heavy ? 'Heavy Flow (Cotton Core)' : 'Medium–High (Rash-Free)',
        reason: 'Because you have sensitive skin or logged rashes/chafing, Cheri selects '
            '100% pure organic cotton pads without plastic netting or fragrances that trigger friction and dermatitis.',
        reasonsBreakdown: const [
          '🌿 Pure Cotton Top-Sheet: Zero plastic mesh in contact with delicate intimate skin.',
          '🛡️ Anti-Chafing Contoured Wings: Ultra-soft side wings stop inner-thigh friction.',
          '🌬️ High Breathability Core: Allows air circulation, preventing moisture and bacterial heat rash.',
          '🌸 Hypoallergenic & pH-Friendly: Free of chlorine bleach, artificial perfumes, and harsh chemicals.',
        ],
        products: const [
          PadProduct(
            name: 'Carmesi 100% Pure Organic Cotton Rash-Free Pads',
            brand: 'Carmesi',
            type: 'Chemical-free, certified organic cotton top-sheet',
            features: ['Naturally rash-free', 'Corn-starch backsheet', 'Super-soft wings'],
            buyUrl: 'https://www.google.com/search?q=buy+Carmesi+organic+cotton+rash+free+pads',
          ),
          PadProduct(
            name: 'Nua Ultra-Thin Chemical-Free Rash-Free Pads',
            brand: 'Nua',
            type: 'Zero plastic touch, personalized sizes with disposal covers',
            features: ['Toxin-free guarantee', 'Ultra-absorbent core', 'Paper wrapper'],
            buyUrl: 'https://www.google.com/search?q=buy+Nua+rash+free+sanitary+pads',
          ),
          PadProduct(
            name: 'Plush 100% Pure US Cotton Rash-Free Pads',
            brand: 'Plush',
            type: 'Pure natural cotton, zero artificial scents',
            features: ['Feather-light feel', 'No synthetic itching', 'Ultra-thin core'],
            buyUrl: 'https://www.google.com/search?q=buy+Plush+pure+cotton+pads',
          ),
          PadProduct(
            name: 'Sofy AntiBacteria Extra Long Pad',
            brand: 'Sofy (Unicharm)',
            type: '99.9% antibacterial layer for rash and itch defense',
            features: ['Antibacterial green sheet', 'Deep absorbent center', 'Odor lock'],
            buyUrl: 'https://www.google.com/search?q=buy+Sofy+anti+bacteria+pads',
          ),
          PadProduct(
            name: 'Pee Safe 100% Organic Cotton Biodegradable Pads',
            brand: 'Pee Safe',
            type: 'Eco-friendly bamboo & organic cotton rash guard',
            features: ['Biodegradable', 'Zero irritation', 'Leak-proof barrier'],
            buyUrl: 'https://www.google.com/search?q=buy+Pee+Safe+organic+cotton+pads',
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // 2. ACTIVE WORKOUT / GYM / SPORT ROUTINE
    // --------------------------------------------------------------
    if (isActiveRoutine && isPeriodPhase) {
      return PadRecommendation(
        padType: 'Extra Long XXL Wings Active Sport Anti-Leak Pad',
        absorbency: 'High Impact Absorbency',
        reason: 'Designed for your active gym and movement routine. Dual-flex wings stay locked '
            'in position without twisting or side leaks during workouts and sweat.',
        reasonsBreakdown: const [
          '🏃 Dual-Flex Sport Wings: Double adhesive grip prevents shifting during squats, runs, and stretching.',
          '🛡️ Anti-Bunching Center: Resists scrunching and twisting under heavy motion.',
          '🌬️ 360° Air Circulation: Wicks perspiration away from skin to keep you dry and fresh.',
          '📐 Low-Profile Fit: Maximum absorption without bulky undergarment outlines.',
        ],
        products: const [
          PadProduct(
            name: 'Whisper Ultra Clean XXL Wings (317mm)',
            brand: 'Whisper (P&G)',
            type: 'Lock-gel core with 317mm extended length for motion',
            features: ['1000 suction pores', 'Instant lock gel', 'XXL coverage'],
            buyUrl: 'https://www.google.com/search?q=buy+Whisper+ultra+clean+xxl+wings',
          ),
          PadProduct(
            name: 'Stayfree Secure XL Ultra Thin with Wings',
            brand: 'Stayfree',
            type: 'Flexible gel-lock technology with active movement wings',
            features: ['Flexible wings', 'Odour neutralizer', 'Dry-mesh top'],
            buyUrl: 'https://www.google.com/search?q=buy+Stayfree+secure+xl+ultra+thin',
          ),
          PadProduct(
            name: 'Kotex ProHealth Overnight Active XXL Pads',
            brand: 'Kotex',
            type: 'Sports-grade movement security with micro-cushion core',
            features: ['0% leak protection', 'Flex-motion wings', 'Silk soft touch'],
            buyUrl: 'https://www.google.com/search?q=buy+Kotex+prohealth+xxl+pads',
          ),
          PadProduct(
            name: 'Sofy Bodyfit Extra Long Day & Night',
            brand: 'Sofy (Unicharm)',
            type: 'Flexible body-contour fit with deep side barriers',
            features: ['Multi-leak guard', 'Body contouring', 'Soft flex wings'],
            buyUrl: 'https://www.google.com/search?q=buy+Sofy+bodyfit+extra+long',
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // 3. CURVY BODY TYPE / WIDE HIP FIT
    // --------------------------------------------------------------
    if (isCurvy && isPeriodPhase) {
      return PadRecommendation(
        padType: 'Extra Wide Contour Curved Hip-Guard Pad with Wings',
        absorbency: 'Extra Wide Rear Coverage',
        reason: 'Matched to your curvy hip build. Features an expanded rear fan and contoured wings '
            'that wrap smoothly around wide-cut undergarments, eliminating back and side gaps.',
        reasonsBreakdown: const [
          '🍑 Expanded Rear Flare: 1.5x wider back wings prevent gap leakage when seated or sleeping.',
          '🔒 Ergonomic Contour: Flexes naturally with hip and pelvic curves rather than bunching flat.',
          '🕊️ Secure Wide Wings: Stays glued securely without edge peeling.',
        ],
        products: const [
          PadProduct(
            name: 'Whisper Bindazzz Nights Koala Extra Wide Wings (360mm)',
            brand: 'Whisper (P&G)',
            type: 'Wide back koala design with 0% back leak guarantee',
            features: ['Wide rear wing', 'Surge absorption', '360mm length'],
            buyUrl: 'https://www.google.com/search?q=buy+Whisper+bindazzz+nights+koala',
          ),
          PadProduct(
            name: 'Stayfree Advanced All Night Comfort Extra Wide',
            brand: 'Stayfree',
            type: 'Extra wide rear wings with multi-directional leak channels',
            features: ['Wide back flare', 'Soft cottony touch', 'Leak barrier'],
            buyUrl: 'https://www.google.com/search?q=buy+Stayfree+all+night+comfort+extra+wide',
          ),
          PadProduct(
            name: 'Sofy Deep Absorbent Curved Wide Rear Pad',
            brand: 'Sofy (Unicharm)',
            type: 'Curved side barriers and extra wide rear fan',
            features: ['Curved barriers', 'Wide hip contour', 'Double protection'],
            buyUrl: 'https://www.google.com/search?q=buy+Sofy+deep+absorbent+wide+rear',
          ),
          PadProduct(
            name: 'Kotex Overnight Ultra Wide Rear Wings',
            brand: 'Kotex',
            type: 'Extra wide rear coverage with micro-cushion center',
            features: ['Extra wide back', 'Double wing wrap', 'Anti-stain barrier'],
            buyUrl: 'https://www.google.com/search?q=buy+Kotex+overnight+wide+wings',
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // 4. DESK JOB / LONG SITTING ROUTINE
    // --------------------------------------------------------------
    if (isSittingRoutine && isPeriodPhase) {
      return PadRecommendation(
        padType: 'Ultra-Thin Breathable Soft Cotton Day Pad with Wings',
        absorbency: 'Medium–High Breathable',
        reason: 'Sitting for extended hours creates heat, pressure, and moisture buildup. '
            'An ultra-thin breathable cotton core prevents friction without pressure pinch.',
        reasonsBreakdown: const [
          '🪑 Zero Pressure Pinch: Ultra-thin compressed core does not cause sitting discomfort.',
          '💨 500+ Airflow Pores: Releases trapped body heat during prolonged desk hours.',
          '🛡️ Channel Guards: Captures medium flow safely under continuous pressure.',
        ],
        products: const [
          PadProduct(
            name: 'Whisper Ultra Soft Air-Fresh Breathable Day Pads',
            brand: 'Whisper (P&G)',
            type: '500 air-fresh pores with feather-soft breathable top sheet',
            features: ['Air-fresh pores', 'Ultra soft wings', 'Zero stuffiness'],
            buyUrl: 'https://www.google.com/search?q=buy+Whisper+ultra+soft+air+fresh',
          ),
          PadProduct(
            name: 'Nua Ultra-Thin Customized Day Pads',
            brand: 'Nua',
            type: 'Zero bulk, chemical-free and discreetly thin',
            features: ['Ultra-thin core', 'No artificial perfume', 'Individually wrapped'],
            buyUrl: 'https://www.google.com/search?q=buy+Nua+ultra+thin+pads',
          ),
          PadProduct(
            name: 'Stayfree Ultra Thin Cottony Soft Regular',
            brand: 'Stayfree',
            type: 'Cottony soft surface with fast-absorbing gel center',
            features: ['Ultra thin', 'Cottony cover', 'Odor neutralizer'],
            buyUrl: 'https://www.google.com/search?q=buy+Stayfree+ultra+thin+cottony+soft',
          ),
          PadProduct(
            name: 'Everteen 100% Natural Cotton Regular Wings',
            brand: 'Everteen',
            type: 'Naturally soft cotton with breathable anti-bacterial sheet',
            features: ['Pure cotton', 'Breathable bottom layer', 'Zero allergy'],
            buyUrl: 'https://www.google.com/search?q=buy+Everteen+natural+cotton+pads',
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // 5. HEAVY FLOW (Day 1 / Day 2)
    // --------------------------------------------------------------
    if (flow == FlowLevel.heavy || (cycleDay <= 2 && phase == 'Menstrual Phase')) {
      return PadRecommendation(
        padType: 'Overnight / Heavy Flow Anti-Leak Lock Pad',
        absorbency: 'Extra Heavy Lock-Core',
        reason: 'Your flow is heavy. A high-capacity lock core with dual wings and surge channels '
            'keeps you fully protected from sudden leaks all day and night.',
        reasonsBreakdown: const [
          '🌊 Surge Protection: Instant lock gel converts heavy gushes into solid gel within seconds.',
          '📏 310mm–350mm Length: Full front-to-back security whether standing or resting.',
          '🛡️ Raised Hydrophobic Walls: Double side barriers prevent edge overflow.',
        ],
        products: const [
          PadProduct(
            name: 'Whisper Ultra Heavy Flow Overnight (350mm)',
            brand: 'Whisper (P&G)',
            type: 'Instant gel lock core with wide wings and 350mm length',
            features: ['Surge absorbing core', 'XXL wings', '0% leak guarantee'],
            buyUrl: 'https://www.google.com/search?q=buy+Whisper+ultra+heavy+flow+overnight',
          ),
          PadProduct(
            name: 'Stayfree Secure XL Heavy Flow Wings',
            brand: 'Stayfree',
            type: 'Deep absorption channels with extended rear wings',
            features: ['Deep channels', 'XL wings', 'Fast absorbency'],
            buyUrl: 'https://www.google.com/search?q=buy+Stayfree+secure+xl+heavy+flow',
          ),
          PadProduct(
            name: 'Sofy AntiGerm Extra Heavy Overnight Pad',
            brand: 'Sofy (Unicharm)',
            type: 'High capacity antibacterial overnight core',
            features: ['Anti-germ protection', 'High capacity', 'Overnight comfort'],
            buyUrl: 'https://www.google.com/search?q=buy+Sofy+anti+germ+overnight',
          ),
          PadProduct(
            name: 'Kotex Overnight Extra Heavy Cushion Pad',
            brand: 'Kotex',
            type: 'Micro-cushion center with double wings',
            features: ['Double wings', 'Extra heavy capacity', 'Soft touch'],
            buyUrl: 'https://www.google.com/search?q=buy+Kotex+overnight+extra+heavy',
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // 6. LIGHT FLOW / SPOTTING / LUTEAL PRE-PERIOD
    // --------------------------------------------------------------
    if (flow == FlowLevel.light || flow == FlowLevel.spotting || phase == 'Luteal Phase') {
      return PadRecommendation(
        padType: 'Breathable Cotton Panty Liner / Light Day Pad',
        absorbency: 'Low / Daily Freshness',
        reason: 'For light flow or pre-period preparation, an ultra-thin breathable cotton liner '
            'provides complete peace of mind without heat, weight, or bulk.',
        reasonsBreakdown: const [
          '🍃 Invisible Comfort: Under 1mm thin for seamless, lightweight wear.',
          '🌿 Cottony Freshness: Prevents underwear staining and odor buildup.',
          '✨ Breathable Bottom: Allows natural airflow to maintain intimate flora.',
        ],
        products: const [
          PadProduct(
            name: 'Whisper Bindazzz Daily Panty Liners',
            brand: 'Whisper (P&G)',
            type: 'Ultra-thin, breathable everyday liner',
            features: ['Cottony soft', 'Breathable pores', 'Stay-in-place adhesive'],
            buyUrl: 'https://www.google.com/search?q=buy+Whisper+daily+panty+liners',
          ),
          PadProduct(
            name: 'Carefree Breathable Cotton Feel Liners',
            brand: 'Carefree',
            type: 'Dermatologically tested breathable daily liners',
            features: ['Cotton feel', 'Air permeable', 'Hypoallergenic'],
            buyUrl: 'https://www.google.com/search?q=buy+Carefree+breathable+panty+liners',
          ),
          PadProduct(
            name: 'Sofy Pantyliner Daily Fresh',
            brand: 'Sofy (Unicharm)',
            type: 'Clean scent with soft breathable surface',
            features: ['Fresh feeling', 'Curved shape', 'No odor'],
            buyUrl: 'https://www.google.com/search?q=buy+Sofy+pantyliner+fresh',
          ),
          PadProduct(
            name: 'Plush 100% Pure Cotton Panty Liners',
            brand: 'Plush',
            type: 'Pure organic cotton rash-free liners',
            features: ['Pure cotton', 'Zero chemicals', 'Compostable wrapper'],
            buyUrl: 'https://www.google.com/search?q=buy+Plush+pure+cotton+panty+liners',
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // 7. DEFAULT / NON-BLEEDING DAYS (Follicular / Ovulation)
    // --------------------------------------------------------------
    return PadRecommendation(
      padType: 'Hypoallergenic Breathable Daily Panty Liner (Optional)',
      absorbency: 'Discharge Protection / Peace of Mind',
      reason: 'You are in your ${phase.replaceAll(' Phase', '')} phase with no period flow. '
          'A light breathable liner is optional for natural ovulation discharge and all-day freshness.',
      reasonsBreakdown: const [
        '🌸 Natural Discharge Defense: Absorbs healthy cervical mucus during peak ovulation.',
        '🍃 Ultra Breathable: Doesn\'t alter natural vaginal pH or create heat.',
        '✨ Discreet Freshness: Keeps undergarments pristine throughout the day.',
      ],
      products: const [
        PadProduct(
          name: 'Whisper Clean & Fresh Daily Panty Liners',
          brand: 'Whisper (P&G)',
          type: 'Breathable daily liner with cotton feel',
          features: ['Breathable cover', 'Ultra-thin', 'Discreet'],
          buyUrl: 'https://www.google.com/search?q=buy+Whisper+clean+and+fresh+liners',
        ),
        PadProduct(
          name: 'Carefree Breathable Cotton Feel Liners',
          brand: 'Carefree',
          type: 'Daily freshness and hypoallergenic comfort',
          features: ['Hypoallergenic', 'Cottony soft', 'All-day security'],
          buyUrl: 'https://www.google.com/search?q=buy+Carefree+breathable+panty+liners',
        ),
        PadProduct(
          name: 'Everteen 100% Natural Cotton Daily Liners',
          brand: 'Everteen',
          type: 'Natural cotton antimicrobial daily liner',
          features: ['100% cotton', 'Anti-bacterial', 'Feather light'],
          buyUrl: 'https://www.google.com/search?q=buy+Everteen+cotton+daily+liners',
        ),
      ],
    );
  }
}
