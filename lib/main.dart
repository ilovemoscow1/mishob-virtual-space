import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VirtualSpaceApp());
}

// ─── 3 API Formats ───────────────────────────────────────────────
// openai    → ChatGPT jaisa format (sabse common)
// anthropic → Claude ka alag format
// gemini    → Google ka alag format

const String fOpenAI    = 'openai';
const String fAnthropic = 'anthropic';
const String fGemini    = 'gemini';

// ─── All AI Providers ────────────────────────────────────────────
class AIProvider {
  final String name;
  final String flag;
  final String url;
  final String model;
  final String format;
  const AIProvider({
    required this.name,
    required this.flag,
    required this.url,
    required this.model,
    required this.format,
  });
}

const List<AIProvider> kAmericanAI = [
  AIProvider(name: 'xAI Grok',      flag: '🇺🇸', url: 'https://api.x.ai/v1/chat/completions',                                       model: 'grok-3',                  format: fOpenAI),
  AIProvider(name: 'Groq',           flag: '🇺🇸', url: 'https://api.groq.com/openai/v1/chat/completions',                             model: 'llama-3.3-70b-versatile', format: fOpenAI),
  AIProvider(name: 'OpenAI',         flag: '🇺🇸', url: 'https://api.openai.com/v1/chat/completions',                                  model: 'gpt-4o-mini',             format: fOpenAI),
  AIProvider(name: 'Anthropic Claude',flag: '🇺🇸', url: 'https://api.anthropic.com/v1/messages',                                      model: 'claude-3-5-haiku-20241022',format: fAnthropic),
  AIProvider(name: 'Google Gemini',  flag: '🇺🇸', url: 'https://generativelanguage.googleapis.com/v1beta/models',                    model: 'gemini-1.5-flash',        format: fGemini),
  AIProvider(name: 'Mistral AI',     flag: '🇪🇺', url: 'https://api.mistral.ai/v1/chat/completions',                                  model: 'mistral-small-latest',    format: fOpenAI),
  AIProvider(name: 'Perplexity',     flag: '🇺🇸', url: 'https://api.perplexity.ai/chat/completions',                                  model: 'llama-3.1-sonar-small-128k-online', format: fOpenAI),
  AIProvider(name: 'Together AI',    flag: '🇺🇸', url: 'https://api.together.xyz/v1/chat/completions',                                model: 'meta-llama/Llama-3-8b-chat-hf', format: fOpenAI),
  AIProvider(name: 'OpenRouter',     flag: '🇺🇸', url: 'https://openrouter.ai/api/v1/chat/completions',                               model: 'openai/gpt-4o-mini',      format: fOpenAI),
];

const List<AIProvider> kChineseAI = [
  AIProvider(name: 'DeepSeek',       flag: '🇨🇳', url: 'https://api.deepseek.com/v1/chat/completions',                                model: 'deepseek-chat',           format: fOpenAI),
  AIProvider(name: 'Alibaba Qwen',   flag: '🇨🇳', url: 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',          model: 'qwen-turbo',              format: fOpenAI),
  AIProvider(name: 'Zhipu AI (GLM)', flag: '🇨🇳', url: 'https://open.bigmodel.cn/api/paas/v4/chat/completions',                       model: 'glm-4-flash',             format: fOpenAI),
  AIProvider(name: 'Moonshot (Kimi)',flag: '🇨🇳', url: 'https://api.moonshot.cn/v1/chat/completions',                                 model: 'moonshot-v1-8k',          format: fOpenAI),
  AIProvider(name: 'ByteDance Doubao',flag:'🇨🇳', url: 'https://ark.cn-beijing.volces.com/api/v3/chat/completions',                   model: 'ep-your-endpoint-id',     format: fOpenAI),
  AIProvider(name: '01.AI (Yi)',     flag: '🇨🇳', url: 'https://api.01.ai/v1/chat/completions',                                       model: 'yi-lightning',            format: fOpenAI),
  AIProvider(name: 'Baichuan AI',    flag: '🇨🇳', url: 'https://api.baichuan-ai.com/v1/chat/completions',                             model: 'Baichuan4',               format: fOpenAI),
  AIProvider(name: 'MiniMax',        flag: '🇨🇳', url: 'https://api.minimax.chat/v1/text/chatcompletion_v2',                          model: 'abab6.5s-chat',           format: fOpenAI),
];

const AIProvider kCustomProvider = AIProvider(
  name: 'Custom', flag: '⚙️', url: '', model: '', format: fOpenAI,
);

// ─── App Root ────────────────────────────────────────────────────
class VirtualSpaceApp extends StatefulWidget {
  const VirtualSpaceApp({super.key});
  @override
  State<VirtualSpaceApp> createState() => _VirtualSpaceAppState();
}

class _VirtualSpaceAppState extends State<VirtualSpaceApp> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Space',
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
      home: MainScreen(isDark: _isDark, onToggle: () => setState(() => _isDark = !_isDark)),
    );
  }
}

// ─── Main Screen ─────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const MainScreen({super.key, required this.isDark, required this.onToggle});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tab == 0 ? AIChatScreen(isDark: widget.isDark) : const SettingsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.small(
          heroTag: 'theme',
          onPressed: widget.onToggle,
          backgroundColor: Colors.deepPurple,
          child: Icon(widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
    );
  }
}

// ─── Chat Screen ─────────────────────────────────────────────────
class AIChatScreen extends StatefulWidget {
  final bool isDark;
  const AIChatScreen({super.key, required this.isDark});
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _input  = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  String _apiKey      = '';
  String _apiUrl      = '';
  String _model       = '';
  String _format      = fOpenAI;
  String _providerName = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _apiKey       = p.getString('api_key')  ?? '';
      _apiUrl       = p.getString('api_url')  ?? '';
      _model        = p.getString('model')    ?? '';
      _format       = p.getString('format')   ?? fOpenAI;
      _providerName = p.getString('provider') ?? '';
    });
  }

  void _scrollBottom() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;

    if (_apiKey.isEmpty || _apiUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings mein API key daalo pehle!'), backgroundColor: Colors.deepPurple));
      return;
    }

    setState(() { _messages.add({'role': 'user', 'content': text}); _loading = true; });
    _input.clear();
    _scrollBottom();

    try {
      String reply;
      if (_format == fAnthropic) {
        reply = await _callAnthropic();
      } else if (_format == fGemini) {
        reply = await _callGemini(text);
      } else {
        reply = await _callOpenAI();
      }
      setState(() { _messages.add({'role': 'assistant', 'content': reply}); _loading = false; });
    } catch (e) {
      setState(() { _messages.add({'role': 'assistant', 'content': 'Error: $e'}); _loading = false; });
    }
    _scrollBottom();
  }

  // ── Format 1: OpenAI (sabse common, most AIs use this) ──
  Future<String> _callOpenAI() async {
    final res = await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
      body: jsonEncode({
        'model': _model,
        'messages': _messages.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
        'temperature': 0.7,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['choices'][0]['message']['content'] as String;
    }
    throw Exception('${res.statusCode}: ${_parseError(res.body)}');
  }

  // ── Format 2: Anthropic Claude (alag header + format) ──
  Future<String> _callAnthropic() async {
    final msgs = _messages.map((m) => {'role': m['role'], 'content': m['content']}).toList();
    final res = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'messages': msgs,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['content'][0]['text'] as String;
    }
    throw Exception('${res.statusCode}: ${_parseError(res.body)}');
  }

  // ── Format 3: Google Gemini (API key URL mein, alag structure) ──
  Future<String> _callGemini(String userText) async {
    final url = '$_apiUrl/$_model:generateContent?key=$_apiKey';
    final contents = _messages.map((m) => {
      'role': m['role'] == 'assistant' ? 'model' : 'user',
      'parts': [{'text': m['content']}],
    }).toList();

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': contents}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['candidates'][0]['content']['parts'][0]['text'] as String;
    }
    throw Exception('${res.statusCode}: ${_parseError(res.body)}');
  }

  String _parseError(String body) {
    try { return jsonDecode(body)['error']?['message'] ?? body; } catch (_) { return body; }
  }

  @override
  void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDark
              ? [const Color(0xFF0D1B2A), const Color(0xFF1B2A4A), const Color(0xFF0A1628)]
              : [const Color(0xFF4A90D9), const Color(0xFF87CEEB), const Color(0xFF6DB33F), const Color(0xFF4A8C2A)],
          stops: widget.isDark ? [0.0, 0.5, 1.0] : [0.0, 0.55, 0.75, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black38,
          title: Row(children: [
            const Icon(Icons.blur_on, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            const Text('Virtual Space', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (_providerName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                child: Text(_providerName, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ]),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white70), onPressed: _load),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.blur_on, size: 70, color: Colors.white54),
                    ),
                    const SizedBox(height: 16),
                    const Text('Virtual Space', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Settings mein koi bhi AI ki API key daalo', style: TextStyle(fontSize: 13, color: Colors.white60)),
                  ]))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.78),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.deepPurple.withOpacity(0.85) : Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12, width: 0.5),
                          ),
                          child: Text(msg['content']!, style: const TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      );
                    },
                  ),
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
                const SizedBox(width: 10),
                Text('${_providerName.isNotEmpty ? _providerName : "AI"} soch raha hai...', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
          Container(
            color: Colors.black26,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_loading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Message type karo...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                heroTag: 'send',
                onPressed: _loading ? null : _send,
                mini: true,
                backgroundColor: _loading ? Colors.grey : Colors.deepPurple,
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Settings Screen ──────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyCtrl    = TextEditingController();
  final _customUrlCtrl = TextEditingController();
  final _customModelCtrl = TextEditingController();
  String _selectedName = 'xAI Grok';
  bool _keyVisible = false;
  bool _saved = false;

  AIProvider get _selected {
    for (final p in [...kAmericanAI, ...kChineseAI]) {
      if (p.name == _selectedName) return p;
    }
    return kCustomProvider;
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedName      = prefs.getString('provider')     ?? 'xAI Grok';
      _apiKeyCtrl.text   = prefs.getString('api_key')      ?? '';
      _customUrlCtrl.text   = prefs.getString('custom_url')   ?? '';
      _customModelCtrl.text = prefs.getString('custom_model') ?? '';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = _selected;
    final url   = provider.name == 'Custom' ? _customUrlCtrl.text.trim() : provider.url;
    final model = provider.name == 'Custom' ? _customModelCtrl.text.trim() : provider.model;
    final format = provider.name == 'Custom' ? fOpenAI : provider.format;

    await prefs.setString('provider',     _selectedName);
    await prefs.setString('api_key',      _apiKeyCtrl.text.trim());
    await prefs.setString('api_url',      url);
    await prefs.setString('model',        model);
    await prefs.setString('format',       format);
    await prefs.setString('custom_url',   _customUrlCtrl.text.trim());
    await prefs.setString('custom_model', _customModelCtrl.text.trim());

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _saved = false); });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_selectedName connected!'), backgroundColor: Colors.deepPurple, duration: const Duration(seconds: 2)));
    }
  }

  Widget _providerTile(AIProvider p) {
    final selected = _selectedName == p.name;
    return GestureDetector(
      onTap: () => setState(() => _selectedName = p.name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: selected ? Colors.deepPurple : Colors.grey.withOpacity(0.3), width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Text(p.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(p.name, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? Colors.deepPurple : null))),
          Text(p.model, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 6),
          _formatBadge(p.format),
        ]),
      ),
    );
  }

  Widget _formatBadge(String format) {
    Color c;
    String label;
    switch (format) {
      case fAnthropic: c = Colors.orange; label = 'ANT'; break;
      case fGemini:    c = Colors.blue;   label = 'GEM'; break;
      default:         c = Colors.green;  label = 'OAI'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: c.withOpacity(0.5))),
      child: Text(label, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)),
    );
  }

  @override
  void dispose() { _apiKeyCtrl.dispose(); _customUrlCtrl.dispose(); _customModelCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── American AI ──
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Text('🇺🇸 🇪🇺  American / European AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 10),
              ...kAmericanAI.map(_providerTile),
            ]),
          )),

          const SizedBox(height: 12),

          // ── Chinese AI ──
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🇨🇳  Chinese AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              ...kChineseAI.map(_providerTile),
            ]),
          )),

          const SizedBox(height: 12),

          // ── Custom ──
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⚙️  Custom API', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _providerTile(kCustomProvider),
              if (_selectedName == 'Custom') ...[
                const SizedBox(height: 10),
                TextField(controller: _customUrlCtrl, decoration: const InputDecoration(labelText: 'API URL', border: OutlineInputBorder(), hintText: 'https://api.example.com/v1/chat/completions')),
                const SizedBox(height: 8),
                TextField(controller: _customModelCtrl, decoration: const InputDecoration(labelText: 'Model Name', border: OutlineInputBorder(), hintText: 'gpt-4o')),
              ],
            ]),
          )),

          const SizedBox(height: 12),

          // ── API Key ──
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.key_rounded, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyCtrl,
                obscureText: !_keyVisible,
                decoration: InputDecoration(
                  hintText: 'Apni API key yahan daalo...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _keyVisible = !_keyVisible),
                  ),
                ),
              ),
            ]),
          )),

          const SizedBox(height: 16),

          // ── Save ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(_saved ? Icons.check_rounded : Icons.save_rounded),
              label: Text(_saved ? 'Connected!' : 'Save & Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? Colors.green : Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Format legend ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('API Format kya hota hai?', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(children: [
                _Badge('OAI', Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('OpenAI format — sabse common (Grok, Groq, DeepSeek, Qwen...)', style: TextStyle(fontSize: 12))),
              ]),
              SizedBox(height: 6),
              Row(children: [
                _Badge('ANT', Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Anthropic format — sirf Claude ke liye', style: TextStyle(fontSize: 12))),
              ]),
              SizedBox(height: 6),
              Row(children: [
                _Badge('GEM', Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('Gemini format — sirf Google ke liye', style: TextStyle(fontSize: 12))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(5), border: Border.all(color: color.withOpacity(0.6))),
    child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
  );
}
