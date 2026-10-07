import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_state.dart';
import '../models/cycle_entry.dart';
import '../models/symptom.dart';
import '../core/utils/helpers.dart';
import 'gemini_service.dart';

// ----------------------------------------------------------------
// DATA MODELS
// ----------------------------------------------------------------

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
        'padType': padRecommendation.padType,
        'padReason': padRecommendation.reason,
        'padAbsorbency': padRecommendation.absorbency,
        'products': padRecommendation.products
            .map((p) => {'name': p.name, 'brand': p.brand, 'type': p.type})
            .toList(),
        'tips': tips,
        'generatedByAi': generatedByAi,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final products = ((json['products'] as List?) ?? [])
        .map((p) => PadProduct(
              name: p['name'] as String? ?? '',
              brand: p['brand'] as String? ?? '',
              type: p['type'] as String? ?? '',
            ))
        .toList();

    return JournalEntry(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      headline: (json['headline'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      padRecommendation: PadRecommendation(
        padType: (json['padType'] as String?) ?? 'Regular Pad',
        reason: (json['padReason'] as String?) ?? '',
        absorbency: (json['padAbsorbency'] as String?) ?? 'Medium',
        products: products,
      ),
      tips: ((json['tips'] as List?) ?? []).map((e) => e.toString()).toList(),
      generatedByAi: (json['generatedByAi'] as bool?) ?? false,
    );
  }
}

class PadRecommendation {
  const PadRecommendation({
    required this.padType,
    required this.reason,
    required this.absorbency,
    required this.products,
  });

  final String padType;
  final String reason;
  final String absorbency;
  final List<PadProduct> products;
}

class PadProduct {
  const PadProduct({
    required this.name,
    required this.brand,
    required this.type,
  });

  final String name;
  final String brand;
  final String type;
}

// ----------------------------------------------------------------
// SERVICE
// ----------------------------------------------------------------

class AiJournalService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _gemini = GeminiService();

  User? get _currentUser => _supabase.auth.currentUser;

  // ----------------------------------------------------------------
  // PUBLIC API
  // ----------------------------------------------------------------

  /// Get or generate today's journal, using Gemini AI if a key is configured,
  /// falling back to the rule-based engine otherwise.
  Future<JournalEntry> getTodayJournal(AppState state) async {
    final today = Helpers.today;
    final userId = _currentUser?.id;

    // Try Supabase cache first
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

    // Generate fresh journal
    final journal = await _generateJournal(state, today);

    // Persist async
    if (userId != null) {
      unawaited(_save(userId, journal));
    }

    return journal;
  }

  /// Force-refresh today's journal (ignore cache).
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
    final padRec = _recommendPad(state, state.entryFor(date), state.phase);

    if (state.geminiApiKey.isNotEmpty) {
      return _generateWithGemini(state, date, padRec);
    }
    return _generateRuleBased(state, date, padRec);
  }

  // ----------------------------------------------------------------
  // GEMINI AI GENERATION — sends EVERYTHING to the model
  // ----------------------------------------------------------------

  Future<JournalEntry> _generateWithGemini(
    AppState state,
    DateTime date,
    PadRecommendation padRec,
  ) async {
    final prompt = _buildFullContextPrompt(state, date, padRec);

    try {
      final rawText = await _gemini.generate(
        prompt: prompt,
        state: state,
        customSystemPrompt: _journalSystemPrompt(state),
        maxTokens: 1000,
      );

      // Parse structured output from Gemini
      final parsed = _parseGeminiJournalOutput(rawText, padRec, date);

      // Generate AI pad reason using Gemini too
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

  /// Builds a rich, comprehensive prompt that sends ALL user data to Gemini.
  String _buildFullContextPrompt(
    AppState state,
    DateTime date,
    PadRecommendation padRec,
  ) {
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
    buf.writeln('=== USER PROFILE ===');
    buf.writeln('Name: ${user.name}');
    buf.writeln('Age: ${user.age}');
    buf.writeln('Cycle length: ${user.cycleLength} days');
    buf.writeln('Period length: ${user.periodLength} days');
    buf.writeln('Last period started: ${Helpers.dayKey(user.lastPeriodStart)}');
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

    // ---- FULL CYCLE HISTORY (last 30 entries) ----
    if (allEntries.isNotEmpty) {
      buf.writeln('=== RECENT CYCLE HISTORY (last 30 logged days) ===');
      final recent = allEntries.reversed.take(30).toList().reversed.toList();
      for (final e in recent) {
        final parts = <String>[Helpers.dayKey(e.date)];
        parts.add('flow:${e.flow.label}');
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

    // Mood distribution
    final moodEntries = allEntries.where((e) => e.mood != null).toList();
    if (moodEntries.isNotEmpty) {
      final moodCounts = <String, int>{};
      for (final e in moodEntries) {
        moodCounts[e.mood!.label] = (moodCounts[e.mood!.label] ?? 0) + 1;
      }
      final sorted = moodCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      buf.writeln('Most common moods: ${sorted.map((e) => '${e.key}(${e.value}x)').join(', ')}');
    }

    // Symptom frequency
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

    // Flow distribution
    final flowCounts = <String, int>{};
    for (final e in allEntries) {
      if (e.flow != FlowLevel.none) {
        flowCounts[e.flow.label] = (flowCounts[e.flow.label] ?? 0) + 1;
      }
    }
    if (flowCounts.isNotEmpty) {
      buf.writeln('Flow history: ${flowCounts.entries.map((e) => '${e.key}:${e.value} days').join(', ')}');
    }

    // Average sleep
    if (allEntries.isNotEmpty) {
      final avgSleep = allEntries
              .map((e) => e.sleepHours)
              .reduce((a, b) => a + b) /
          allEntries.length;
      buf.writeln('Average sleep: ${avgSleep.toStringAsFixed(1)} hours/night');
    }

    // Heavy flow days
    final heavyDays = allEntries.where((e) => e.flow == FlowLevel.heavy).length;
    if (heavyDays > 0) {
      buf.writeln('Total heavy flow days logged: $heavyDays');
    }

    // Notes history (last 5 with content)
    final notedEntries = allEntries
        .where((e) => e.notes.isNotEmpty)
        .toList()
        .reversed
        .take(5)
        .toList();
    if (notedEntries.isNotEmpty) {
      buf.writeln('');
      buf.writeln('=== RECENT PERSONAL NOTES ===');
      for (final e in notedEntries) {
        buf.writeln('${Helpers.dayKey(e.date)}: "${e.notes}"');
      }
    }

    buf.writeln('');

    // ---- PAD CONTEXT ----
    buf.writeln('=== PAD RECOMMENDATION (already decided) ===');
    buf.writeln('Type: ${padRec.padType}');
    buf.writeln('Absorbency: ${padRec.absorbency}');
    buf.writeln('');

    // ---- INSTRUCTIONS ----
    buf.writeln('=== GENERATE THE FOLLOWING (respond in this exact format) ===');
    buf.writeln('');
    buf.writeln('HEADLINE: [One warm, personal headline for today — max 8 words]');
    buf.writeln('');
    buf.writeln('BODY: [3 paragraphs, written warmly in second person ("You..."). ');
    buf.writeln('Reference her specific data — mention her actual mood, symptoms logged,');
    buf.writeln('sleep hours, phase, and any patterns you notice from her history.');
    buf.writeln('Be like a caring friend who truly knows her. No markdown, no asterisks.]');
    buf.writeln('');
    buf.writeln('TIPS:');
    buf.writeln('- [Tip 1 based on her actual data today]');
    buf.writeln('- [Tip 2 based on her patterns]');
    buf.writeln('- [Tip 3 based on her phase]');
    buf.writeln('- [Tip 4 for her wellbeing]');

    return buf.toString();
  }

  static String _journalSystemPrompt(AppState state) {
    return 'You are Cherry AI, the warm and caring wellness companion inside the '
        'Cheri menstrual health app for ${state.user.name}. '
        'You have access to her complete health data and use it to write '
        'deeply personal, empathetic daily journal entries. '
        'You write like a caring friend who truly knows her patterns and history. '
        'NEVER use markdown formatting (no **, no #, no bullets with *). '
        'NEVER give medical diagnoses. '
        'Always follow the exact structured format requested.';
  }

  /// Parse Gemini's structured output into headline / body / tips.
  Map<String, dynamic> _parseGeminiJournalOutput(
    String raw,
    PadRecommendation padRec,
    DateTime date,
  ) {
    String headline = 'Your Daily Journal 🌸';
    String body = raw;
    final tips = <String>[];

    try {
      // Extract HEADLINE
      final headlineMatch = RegExp(r'HEADLINE:\s*(.+)', caseSensitive: false)
          .firstMatch(raw);
      if (headlineMatch != null) {
        headline = headlineMatch.group(1)?.trim() ?? headline;
      }

      // Extract BODY
      final bodyMatch = RegExp(
        r'BODY:\s*([\s\S]+?)(?=TIPS:|$)',
        caseSensitive: false,
      ).firstMatch(raw);
      if (bodyMatch != null) {
        body = bodyMatch.group(1)?.trim() ?? raw;
      }

      // Extract TIPS
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
        'Log your mood and symptoms in your check-in',
        'Take a 10-minute walk outside if you can',
        'Prioritise 7–8 hours of sleep tonight',
      ]);
    }

    return {'headline': headline, 'body': body, 'tips': tips};
  }

  /// Use Gemini to write a warm, personalised pad recommendation reason.
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
    );

    try {
      final reason = await _gemini.generate(
        prompt: prompt,
        state: state,
        maxTokens: 100,
      );
      return PadRecommendation(
        padType: padRec.padType,
        reason: reason.trim().isNotEmpty ? reason.trim() : padRec.reason,
        absorbency: padRec.absorbency,
        products: padRec.products,
      );
    } catch (e) {
      return padRec;
    }
  }

  // ----------------------------------------------------------------
  // RULE-BASED FALLBACK (no API key)
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

    final tips = _generateTips(entry, phase, allEntries);
    final headline = _generateHeadline(phase, entry, cycleDay);
    final body = _generateBody(state, entry, phase, cycleDay, allEntries);

    return JournalEntry(
      date: date,
      headline: headline,
      body: body,
      padRecommendation: padRec,
      tips: tips,
      generatedByAi: false,
    );
  }

  String _generateHeadline(String phase, CycleEntry? entry, int cycleDay) {
    final mood = entry?.mood;
    final flow = entry?.flow ?? FlowLevel.none;

    if (phase == 'Menstrual Phase') {
      if (flow == FlowLevel.heavy) return 'A Heavy Day — Be Extra Gentle 💕';
      if (flow == FlowLevel.light) return 'Almost There — Light Flow Day 🌸';
      return 'Day $cycleDay of Your Period 🌺';
    }
    if (phase == 'Follicular Phase') {
      if (mood == Mood.happy) return 'Energy Rising — You Are Thriving! ✨';
      return 'A Fresh New Chapter Begins 🌿';
    }
    if (phase == 'Ovulation Phase') return 'Peak Power — Your Brightest Day 🌟';
    if (mood == Mood.anxious || mood == Mood.sad) {
      return 'It Is Okay to Rest — You Are Enough 💜';
    }
    return 'Winding Down With Grace 🍂';
  }

  String _generateBody(
    AppState state,
    CycleEntry? entry,
    String phase,
    int cycleDay,
    List<CycleEntry> allEntries,
  ) {
    final buf = StringBuffer();
    final name = state.user.name;
    final mood = entry?.mood;
    final symptoms = entry?.symptoms ?? {};
    final sleepHours = entry?.sleepHours ?? 7.0;
    final flow = entry?.flow ?? FlowLevel.none;

    buf.write('Hey $name 💕\n\n');

    // Phase opening
    switch (phase) {
      case 'Menstrual Phase':
        buf.write('You are on day $cycleDay of your period. Your body is '
            'shedding its lining — this takes real energy, so please be gentle '
            'with yourself today. ');
        if (flow == FlowLevel.heavy) {
          buf.write('Your flow is heavy today. Stay hydrated, eat iron-rich '
              'foods like spinach or lentils, and keep a heating pad close. ');
        } else if (flow == FlowLevel.light) {
          buf.write('The lighter flow is a good sign your period is winding '
              'down. Gentle stretches can help with any remaining discomfort. ');
        }
        break;
      case 'Follicular Phase':
        buf.write('Your follicular phase is in full swing — day $cycleDay. '
            'Oestrogen is rising and your energy tends to lift naturally. '
            'A great time to start something new or be social. ');
        break;
      case 'Ovulation Phase':
        buf.write('You are ovulating — cycle day $cycleDay. This is often '
            'when you feel most energetic and confident. Lean into it and '
            'stay hydrated. ');
        break;
      default:
        buf.write('You are in your luteal phase, day $cycleDay. Progesterone '
            'is rising and it is normal to feel more tired or moody. '
            'Rest, warm foods and self-compassion are your best friends. ');
    }

    // Symptom analysis with historical context
    if (symptoms.contains('cramps')) {
      final crampsHistory =
          allEntries.where((e) => e.symptoms.contains('cramps')).length;
      buf.write('\n\nYou logged cramps today. '
          'Looking at your history, you have experienced cramps on '
          '$crampsHistory logged days — so your body has a pattern here. '
          'A warm compress, magnesium-rich foods and gentle yoga can help. ');
    }
    if (symptoms.contains('fatigue')) {
      buf.write('\n\nFatigue today — make sure you are getting enough iron '
          'and B12. Even a 20-minute rest can make a real difference. ');
    }
    if (symptoms.contains('headache')) {
      buf.write('\n\nYou noted a headache. Hormonal headaches are common at '
          'this phase. Stay hydrated and rest in a quiet room if you can. ');
    }
    if (symptoms.contains('bloating')) {
      buf.write('\n\nBloating noted. Chamomile tea and a gentle walk can '
          'reduce it. Avoid salty or processed foods for now. ');
    }

    // Mood insight
    if (mood != null) {
      buf.write('\n\n');
      switch (mood) {
        case Mood.happy:
          buf.write('You are feeling happy today — channel that energy into '
              'something creative or meaningful. ');
          break;
        case Mood.calm:
          buf.write('Feeling calm is a gift. Use this energy for journaling '
              'or a gentle walk. ');
          break;
        case Mood.okay:
          buf.write('An "okay" day is still a good day. Small comforts — a '
              'warm drink, a favourite song — can gently lift your spirits. ');
          break;
        case Mood.sad:
          buf.write('It is okay to feel sad. Your feelings are valid. '
              'Reach out to someone you trust, or just allow yourself to rest. '
              'This feeling will pass. 💜 ');
          break;
        case Mood.anxious:
          buf.write('Anxiety can feel overwhelming with hormonal shifts. '
              'Try box breathing — 4 counts in, hold, out, hold — to calm '
              'your nervous system. You are safe. 💙 ');
          break;
      }
    }

    // Sleep insight with historical context
    if (allEntries.isNotEmpty) {
      final avgSleep = allEntries
              .map((e) => e.sleepHours)
              .reduce((a, b) => a + b) /
          allEntries.length;
      if (sleepHours < 6) {
        buf.write('\n\nYou slept ${sleepHours.toStringAsFixed(1)} hours — '
            'below your average of ${avgSleep.toStringAsFixed(1)} hours. '
            'Try to sleep by 10 pm tonight and avoid screens before bed. ');
      } else if (sleepHours >= 8) {
        buf.write('\n\nGreat sleep last night '
            '(${sleepHours.toStringAsFixed(1)} hours — above your average of '
            '${avgSleep.toStringAsFixed(1)} hours)! Quality sleep is one of '
            'the best things you can do for your cycle health. ✨ ');
      }
    }

    buf.write('\n\nThank you for consistently tracking — your journal gets '
        'smarter and more personal with every entry you log. 🌸');

    return buf.toString();
  }

  List<String> _generateTips(
    CycleEntry? entry,
    String phase,
    List<CycleEntry> allEntries,
  ) {
    final tips = <String>[];
    final symptoms = entry?.symptoms ?? {};
    final flow = entry?.flow ?? FlowLevel.none;
    final sleepHours = entry?.sleepHours ?? 7.0;

    if (symptoms.contains('cramps')) {
      tips.add('Apply a warm heating pad to your lower abdomen for 15 minutes');
    }
    if (symptoms.contains('bloating')) {
      tips.add('Drink chamomile tea and take a gentle 10-min walk');
    }
    if (symptoms.contains('headache')) {
      tips.add('Stay hydrated — aim for at least 2 litres of water today');
    }
    if (symptoms.contains('fatigue')) {
      tips.add('Take a 20-minute rest and eat an iron-rich snack');
    }
    if (flow == FlowLevel.heavy) {
      tips.add('Eat iron-rich foods: spinach, lentils, tofu or eggs');
    }
    if (sleepHours < 6) {
      tips.add('Aim for at least 7–8 hours of sleep tonight — sleep heals');
    }

    // Historical pattern tips
    if (allEntries.isNotEmpty) {
      final crampsRate =
          allEntries.where((e) => e.symptoms.contains('cramps')).length /
              allEntries.length;
      if (crampsRate > 0.4 && !symptoms.contains('cramps')) {
        tips.add('You often get cramps — keep a heating pad handy today');
      }
    }

    switch (phase) {
      case 'Follicular Phase':
        tips.add('Great time for exercise — try a workout or yoga class');
        break;
      case 'Ovulation Phase':
        tips.add('Your communication peaks now — great time for important talks');
        break;
      case 'Luteal Phase':
        tips.add('Reduce caffeine and sugar — prioritise warm, nourishing food');
        break;
      case 'Menstrual Phase':
        tips.add('Gentle yoga or stretching eases period discomfort naturally');
        break;
    }

    tips.add('Log your check-in today to keep your insights personalised');
    return tips.take(4).toList();
  }

  // ----------------------------------------------------------------
  // PAD RECOMMENDATION ENGINE (rule-based, always runs)
  // ----------------------------------------------------------------

  PadRecommendation _recommendPad(
    AppState state,
    CycleEntry? entry,
    String phase,
  ) {
    final flow = entry?.flow ?? FlowLevel.none;
    final symptoms = entry?.symptoms ?? {};
    final hasCramps = symptoms.contains('cramps');
    final hasBloating = symptoms.contains('bloating');
    final heavyHistory = _avgHeavyDays(state);

    if (flow == FlowLevel.heavy || heavyHistory >= 2) {
      return PadRecommendation(
        padType: 'Overnight / Heavy Flow Pad',
        absorbency: 'Extra Heavy',
        reason: 'Your flow is heavy${hasCramps ? ' and you have cramps' : ''}. '
            'An extra-absorbent overnight pad gives you comfort and leakage '
            'protection all day.',
        products: const [
          PadProduct(name: 'Whisper Ultra Overnight', brand: 'Whisper (P&G)', type: 'Overnight with wings'),
          PadProduct(name: 'Stayfree Secure XL', brand: 'Stayfree (Kimberly-Clark)', type: 'XL overnight'),
          PadProduct(name: 'Sofy AntiGerm Night', brand: 'Sofy (Unicharm)', type: 'Overnight antibacterial'),
          PadProduct(name: 'Kotex Overnight Ultra Thin', brand: 'Kotex (Kimberly-Clark)', type: 'Ultra-thin overnight'),
        ],
      );
    }

    if (flow == FlowLevel.medium) {
      return PadRecommendation(
        padType: 'Regular Day Pad with Wings',
        absorbency: 'Medium–High',
        reason: 'Your medium flow calls for a reliable day pad with wings'
            '${hasBloating ? ' — wings also help with bloating discomfort' : ''}.',
        products: const [
          PadProduct(name: 'Whisper Ultra Soft Regular', brand: 'Whisper (P&G)', type: 'Thin day pad with wings'),
          PadProduct(name: 'Stayfree Ultra Thin Regular', brand: 'Stayfree (Kimberly-Clark)', type: 'Ultra-thin with wings'),
          PadProduct(name: 'Sofy Body Fit Regular', brand: 'Sofy (Unicharm)', type: 'Body-contour day pad'),
          PadProduct(name: 'Everteen Natural Cotton Regular', brand: 'Everteen', type: 'Organic cotton pad'),
        ],
      );
    }

    if (flow == FlowLevel.light || flow == FlowLevel.spotting) {
      return PadRecommendation(
        padType: 'Panty Liner / Light Pad',
        absorbency: 'Low',
        reason: 'Your flow is ${flow == FlowLevel.spotting ? 'spotting' : 'light'}. '
            'A breathable panty liner keeps you fresh without bulk.',
        products: const [
          PadProduct(name: 'Whisper Bindazz Liner', brand: 'Whisper (P&G)', type: 'Ultra-thin liner'),
          PadProduct(name: 'Stayfree Panty Liners', brand: 'Stayfree (Kimberly-Clark)', type: 'Breathable liner'),
          PadProduct(name: 'Sofy Pantyliner Fresh', brand: 'Sofy (Unicharm)', type: 'Deodorising liner'),
          PadProduct(name: 'Everteen Panty Liner', brand: 'Everteen', type: 'Natural cotton liner'),
        ],
      );
    }

    if (phase == 'Luteal Phase') {
      return PadRecommendation(
        padType: 'Panty Liner (Pre-period)',
        absorbency: 'Very Low',
        reason: 'You are in your luteal phase — your period is approaching. '
            'A light liner keeps you prepared and fresh.',
        products: const [
          PadProduct(name: 'Whisper Bindazz Liner', brand: 'Whisper (P&G)', type: 'Ultra-thin liner'),
          PadProduct(name: 'Stayfree Panty Liners', brand: 'Stayfree (Kimberly-Clark)', type: 'Breathable liner'),
          PadProduct(name: 'Sofy Pantyliner Fresh', brand: 'Sofy (Unicharm)', type: 'Deodorising liner'),
        ],
      );
    }

    return PadRecommendation(
      padType: 'No Pad Needed',
      absorbency: 'None',
      reason: 'You are in your ${phase.replaceAll(' Phase', '')} phase with '
          'no expected flow. Keep a liner handy for peace of mind.',
      products: const [
        PadProduct(name: 'Whisper Bindazz Liner', brand: 'Whisper (P&G)', type: 'Ultra-thin liner (optional)'),
        PadProduct(name: 'Everteen Panty Liner', brand: 'Everteen', type: 'Natural cotton liner (optional)'),
      ],
    );
  }

  int _avgHeavyDays(AppState state) {
    final entries = state.allEntries;
    if (entries.isEmpty) return 0;
    final count = entries.where((e) => e.flow == FlowLevel.heavy).length;
    return (count / (entries.length / 28).clamp(1, 12)).round();
  }
}
