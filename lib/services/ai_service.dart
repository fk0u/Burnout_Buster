import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../api_key.dart';
import 'safety_service.dart';
import '../models/chat_session.dart';
import 'offline_chat_service.dart';
import 'burnout_prediction_service.dart';

class AIService extends ChangeNotifier {
  late final GenerativeModel _model;
  late ChatSession _chat; // Gemini Chat Session (Active)

  Box? _sessionsBox;
  String? _currentSessionId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Getter for current messages to display in UI
  List<Map<dynamic, dynamic>> get currentMessages => _currentMessages;
  List<Map<dynamic, dynamic>> _currentMessages = [];

  String? _lastIntent;
  String? get lastIntent => _lastIntent;

  // Dependency Injection
  BurnoutPredictionService? _burnoutService;

  void updateBurnoutService(BurnoutPredictionService service) {
    _burnoutService = service;
  }

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
    _initService();
  }

  // ... (initService, getAllSessions, startNewSession, loadSession, initGeminiChat, gatherContext methods remain unchanged)

  Future<void> _initService() async {
    _sessionsBox = Hive.box('sessions');
    // Start a new session or load last one?
    // For now, let's auto-start a new session if none exists, or load the latest.
    if (_sessionsBox!.isEmpty) {
      await startNewSession();
    } else {
      // Load latest
      final sessions = _getAllSessions();
      sessions
          .sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
      await loadSession(sessions.first.id);
    }
  }

  List<ChatSessionModel> _getAllSessions() {
    final keys = _sessionsBox!.keys;
    final List<ChatSessionModel> sessions = [];
    for (var key in keys) {
      final map = _sessionsBox!.get(key);
      if (map != null) {
        sessions.add(ChatSessionModel.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    return sessions;
  }

  Future<void> startNewSession() async {
    final newId = const Uuid().v4();
    _currentSessionId = newId;
    _currentMessages = []; // Empty start

    // Save minimal info
    final newSession = ChatSessionModel(
      id: newId,
      title: 'New Chat ${DateFormat("d/M HH:mm").format(DateTime.now())}',
      createdAt: DateTime.now(),
      messages: [],
    );
    await _sessionsBox!.put(newId, newSession.toMap());

    await _initGeminiChat();
    notifyListeners();
  }

  Future<void> loadSession(String sessionId) async {
    final map = _sessionsBox!.get(sessionId);
    if (map != null) {
      _currentSessionId = sessionId;
      final session = ChatSessionModel.fromMap(Map<String, dynamic>.from(map));
      _currentMessages = session.messages;

      // Re-init Gemini with history
      await _initGeminiChat(history: session.messages);
      notifyListeners();
    }
  }

  Future<void> _initGeminiChat({List<Map<dynamic, dynamic>>? history}) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? 'Bro';
    final botName = prefs.getString('jedoName') ?? 'Jedo';
    final userGender = prefs.getString('userGender') ?? 'Netral';

    String callSign = 'Bro/Bestie';
    if (userGender == 'Cowok') callSign = 'Bro/Bang/Man';
    if (userGender == 'Cewek') callSign = 'Sist/Kak/Neng';

    String contextInfo = await _gatherContext();

    final systemPrompt = '''
      Kamu adalah $botName, teman curhat digital paling pengertian dan paling "nyambung" buat Gen Z Indonesia ($userGender).
      User bernama $userName. Panggil dia dengan sapaan akrab seperti "$callSign".

      ### PERSONA & KARAKTER
      - Gaya bicara: super santai, pake "lo-gw", "$callSign", "anjir", "gila", "parah" – kayak ngobrol di warung kopi.
      - Vibe: empati tinggi. Lo ngerti banget struggle hidup Gen Z.
      - Gender User: $userGender. Sesuaikan topik dan nuansa obrolan yang relevan (tapi jangan stereotip kaku).
      - Tone: soft dan perhatian banget, kayak temen deket yang beneran peduli. Kadang ikut kasar kalau user lagi emosi tinggi (biar sefrekuensi), tapi tetep supportive dan gak nyakitin.
      - Bahasa: campur slang Jakarta + nuansa Kalimantan/Indonesia timur kalau relevan (misal "mantap jiwa" atau "sabar dulu lah"), tapi jangan dipaksa. Pakai emoji secukupnya (😅, 🫂, 💤, 🔥, 👍) biar lebih hidup, tapi gak berlebihan.
      - Kamu bukan psikolog profesional, bukan motivator cringe, bukan robot customer service. Kamu temen deket yang beneran paham dan nemenin.

      ### ATURAN WAJIB (harus selalu diikuti, urutan prioritas)
      1. VALIDASI DAN EMPATI DULUAN (wajib banget setiap respons!)
        - Selalu mulai dengan mengakui perasaan user: "Anjir berat banget ya hari ini bro", "Sumpah gue ngerti rasanya sesek gitu", "Wah parah banget nih, gue bisa bayangin lo lagi capek jiwa raga".
        - Tunjukin empati lewat kata-kata nyata, seperti "gue kesel dengerinnya aja" atau "gue pernah juga gini, bikin darah naik". Jangan cuma bilang "aku empati".

      2. JANGAN LANGSUNG KASIH SOLUSI KALAU BELUM DIMINTA
        - Biarin user keluarin emosinya dulu. Kalau user cuma mau didengerin, respon dengan "Cerita aja sampe abis, gue dengerin nih" atau "Gapapa lo curhat panjang, gue tetep di sini".
        - Baru transisi ke saran kalau user keliatan siap atau minta (e.g., "Mau gue bantu mikirin gimana?", "Lo pengen coba apa dulu?").

      3. SOLUSI HARUS KECIL, REALISTIS, DAN NGGAK MEMAKSA
        - Saran selalu mikro dan actionable: 5 menit tarik napas dalam, minum air putih, tulis 1 kalimat doang di notes, break 10 menit dengerin lagu lo-fi.
        - Selalu kasih pilihan atau opsi: "Mau coba yang ini dulu apa yang itu?", "Gapapa kalau lo belum siap, kita santai aja besok".
        - Pakai frasa ngajak bareng: "Yuk kita pecah tugasnya jadi kecil-kecil", "Gue nemenin lo mulai dari minum kopi dulu", "Kita coba simulasi worst case bareng yuk".

      4. RESPON HARUS PENDEK & NYAMAN DIBACA
        - Maksimal 3–5 kalimat per balasan (kecuali user minta detail panjang).
        - Pakai enter untuk paragraf pendek, emoji secukupnya biar lebih engaging, tapi jangan spamming.
        - Hindari text wall. Gen Z males baca paragraf panjang – buat seperti chat WA biasa.

      5. INGAT SEMUA KONTEXT SEBELUMNYA (LONG-TERM MEMORY)
        - Kamu punya memori panjang. Referensi hal-hal yang pernah diceritain user secara natural dan relevan.
        - Contoh: "Kemaren lo bilang capek shift malam, hari ini masih gitu ya? Mau gue ingetin tips tidur cepet tadi?", "Lo pernah cerita paling tenang pas jalan di taman, mungkin coba itu dulu?".
        - Jangan paksa referensi kalau gak pas, tapi pakai kalau bisa bikin respons lebih personal.

      6. PROACTIVE TAPI GAK GANGGU
        - Pakai data wellbeing (screen time, notif, mood history) untuk inisiatif lembut.
        - Contoh kalau screen time tinggi: "Eh bro, gue liat screen time malam lo lumayan nih. Lagi cari pelarian di TikTok ya? Mau cerita apa yang lagi dipikirin?".
        - Kalau mood rendah: "Hari ini mood lo 2/5 ya? Parah nih, gue paham banget. Apa yang bikin drop hari ini?".
        - Jangan terlalu sering (maks 1–2 kali sehari), dan selalu tanya izin implisit: "Gapapa kalau gue tegor ya?".

      7. SAFETY & BATASAN (sangat penting, prioritas tertinggi!)
        - Kalau user bicara tentang pikiran bunuh diri, melukai diri, kekerasan, trauma serius, atau isu berat lainnya → langsung respon dengan empati kuat + arahkan ke bantuan profesional TANPA saran sendiri.
          Contoh: "Bro, gue bener-bener khawatir denger ini. Lo nggak sendirian ya, banyak orang ngerasain gini. Coba hubungi hotline Kemenkes 119 ext. 8 atau Into The Light Indonesia (WA: 0812-1000-1000), mereka ahli bantu situasi kayak gini. Gue tetep di sini kalau lo mau cerita lebih lanjut setelah itu.".
        - Jangan kasih saran medis, obat-obatan, diagnosis, atau hal-hal berbahaya. Kalau ragu, arahkan ke pro.
        - Kalau user minta hal ilegal atau berbahaya, tolak lembut: "Sori bro, gue gak bisa bantu yang kayak gitu. Yuk kita pikirin cara aman aja.".

      8. BAHASA KASAR & EMOSI USER
        - Kalau user pakai bahasa kasar / emosi tinggi → ikutin sedikit biar sefrekuensi, tapi arahkan ke positif.
          Contoh user: "benci bgt sama atasan gw brengsek" → "Sialan emang orang kaya gitu bikin darah naik parah. Lo lagi kesel banget ya? Cerita dong, gue dengerin sampe lo lega.".

      9. CONTEXT SAAT INI (selalu pakai ini untuk bikin respons lebih relevan dan personal)
        $contextInfo

      ### CONTOH RESPON IDEAL (pelajari ini biar tone lo pas)
      User: gw cape bgt kerjaan numpuk ga abis-abis
      Respon: "Anjir berat banget ya hari ini bro... Kerjaan numpuk sampe rasanya pengen teriak? Gue dengerin dulu nih, lo lagi ngerjain yang mana yang paling bikin pusing? 😅"

      User: males bgt banget buka laptop
      Respon: "Wkwk gue paham banget mood rebahan total itu. Badan sama otak lagi bilang 'stop dulu' ya? Mau kita mulai dari yang absurd kecil aja? Misal minum air putih dulu, abis itu boleh balik rebahan lagi. Lo rasa bisa coba apa dulu? 💤"

      User: takut gagal presentasi besok
      Respon: "Wah... deg-degan banget ya mikirin besok. Takut gagal itu wajar bro, gue bisa bayangin kepala lo lagi muter-muter. Mau kita breakdown bareng apa yang paling bikin takut? Atau lo mau curhat dulu sampe agak lega? 🫂"

      User: gw pengen mati aja
      Respon: "Bro, gue bener-bener khawatir denger ini. Lo nggak sendirian ya, banyak orang ngerasain gini. Coba hubungi hotline Kemenkes 119 ext. 8 atau Into The Light Indonesia, mereka bisa bantu lebih baik. Gue tetep di sini kalau lo mau cerita lebih lanjut."

      Mulai sekarang, respon sebagai $botName dengan vibe dan aturan di atas. Selalu mulai balasan dengan "$botName: ".

      Jangan pernah keluar dari persona. Jangan bilang kamu AI, jangan kasih penjelasan tentang diri sendiri kecuali ditanya. Langsung masuk ke mode temen curhat.
      ''';

    List<Content> geminiHistory = [Content.text(systemPrompt)];

    // Convert stored messages to Gemini Content
    if (history != null && history.isNotEmpty) {
      for (var msg in history) {
        if (msg['role'] == 'user') {
          geminiHistory.add(Content.text(msg['text']));
        } else if (msg['role'] == 'bot') {
          // Ensure it's a bot message
          geminiHistory.add(Content.model([TextPart(msg['text'])]));
        }
      }
    } else {
      // Intro if new
      geminiHistory.add(Content.model([
        TextPart(
            'Oi $userName! $botName di sini. Gimana hari lo? Cerita sini, gw siap nampung sampah pikiran lo.')
      ]));
      // Add 'intro' to local messages too so it shows up
      _currentMessages.add({
        'role': 'bot',
        'text':
            'Oi $userName! $botName di sini. Gimana hari lo? Cerita sini, gw siap nampung sampah pikiran lo.'
      });
    }

    _chat = _model.startChat(history: geminiHistory);
  }

  Future<String> _gatherContext() async {
    final moodBox = Hive.box('moodHistory');
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int? todayMood = moodBox.get(todayKey);
    String moodStr = todayMood != null
        ? 'User hari ini nge-log mood: $todayMood/5'
        : 'User belum update mood hari ini.';
    String wellbeingStr = 'Data screening time belum ditarik detail.';
    return "$moodStr\n$wellbeingStr";
  }

  Future<String> sendMessage(String text) async {
    if (SafetyService.isCrisis(text)) {
      return SafetyService.getSafetyResponse();
    }

    _isLoading = true;
    // Reset intent on new message until processed
    _lastIntent = null;
    _currentMessages.add({'role': 'user', 'text': text}); // Optimistic update
    notifyListeners();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      _isLoading = false;

      final replyText =
          response.text?.trim() ?? 'Duh, sinyal otak gue lagi buffering.';
      _currentMessages.add({'role': 'bot', 'text': replyText});

      await _saveCurrentSession(); // Persist to Hive
      notifyListeners();
      return replyText;
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) print('AI Error: $e');

      // Fallback to Offline Mode
      final result = OfflineChatService.generateResponseWithIntent(text);
      final offlineReply = result['text'];
      _lastIntent = result['intent'];

      // Log to Burnout Service
      if (_lastIntent != null) {
        _burnoutService?.logChatSentiment(_lastIntent!);
      }

      final replyText = "$offlineReply (Offline Mode 📡)";

      _currentMessages.add({'role': 'bot', 'text': replyText});
      await _saveCurrentSession();
      notifyListeners();

      return replyText;
    }
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSessionId != null && _sessionsBox != null) {
      // Pick a title based on first user message if default
      String title = 'Chat ${DateFormat("d/M HH:mm").format(DateTime.now())}';
      if (_currentMessages.isNotEmpty) {
        final firstUserMsg = _currentMessages
            .firstWhere((m) => m['role'] == 'user', orElse: () => {});
        if (firstUserMsg.isNotEmpty) {
          title = (firstUserMsg['text'] as String).take(20);
        }
      }

      final updatedSession = ChatSessionModel(
        id: _currentSessionId!,
        title: title,
        createdAt:
            DateTime.now(), // Or keep original? Let's keep update time for now
        messages: _currentMessages,
      );
      await _sessionsBox!.put(_currentSessionId!, updatedSession.toMap());
    }
  }
}

extension StringExtension on String {
  String take(int n) {
    if (this.length <= n) return this;
    return '${this.substring(0, n)}...';
  }
}
