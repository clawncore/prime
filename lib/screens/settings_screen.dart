import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/prime_theme.dart';

/// PRIME Screens - Settings Screen
///
/// Configure providers, API keys, and voice settings.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = SettingsService();
    _settings.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimeTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: PrimeTheme.bgSurface,
        title: Text(
          'SETTINGS',
          style: TextStyle(
            color: PrimeTheme.primeCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: PrimeTheme.primeCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('LLM Provider', [
            _buildDropdown(
              'Provider',
              _settings.llmProvider,
              ['gemini', 'openai', 'local'],
              (v) => _settings.setLLMProvider(v),
            ),
            _buildDropdown(
              'Model',
              _settings.llmModel,
              ['gemini-2.0-flash', 'gemini-1.5-pro', 'gpt-4o'],
              (v) => _settings.setLLMModel(v),
            ),
            _buildApiKeyField(
              'Gemini API Key',
              _settings.geminiApiKey,
              (v) => _settings.setGeminiApiKey(v),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('Text-to-Speech', [
            _buildDropdown(
              'Provider',
              _settings.ttsProvider,
              ['auto', 'sapi', 'linux', 'elevenlabs'],
              (v) => _settings.setTTSProvider(v),
            ),
            _buildSlider(
              'Rate',
              _settings.ttsRate,
              0.5,
              2.0,
              (v) => _settings.setTTSRate(v),
            ),
            _buildSlider(
              'Volume',
              _settings.ttsVolume,
              0.0,
              1.0,
              (v) => _settings.setTTSVolume(v),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('Speech-to-Text', [
            _buildDropdown(
              'Provider',
              _settings.sttProvider,
              ['auto', 'sapi', 'vosk', 'whisper'],
              (v) => _settings.setSTTProvider(v),
            ),
            _buildDropdown(
              'Language',
              _settings.sttLanguage,
              ['en-US', 'en-GB', 'de-DE', 'fr-FR', 'es-ES'],
              (v) => _settings.setSTTLanguage(v),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('Audio', [
            _buildSlider(
              'System Sounds',
              _settings.systemSoundVolume,
              0.0,
              1.0,
              (v) => _settings.setSystemSoundVolume(v),
            ),
            _buildSwitch(
              'Auto Listen',
              _settings.autoListen,
              (v) => _settings.setAutoListen(v),
            ),
            _buildSwitch(
              'Barge-in',
              _settings.bargeInEnabled,
              (v) => _settings.setBargeIn(v),
            ),
          ]),

          const SizedBox(height: 32),

          // API Key security notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PrimeTheme.statusBusy.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PrimeTheme.statusBusy.withAlpha(100)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: PrimeTheme.statusBusy, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API keys are stored locally in .env and never committed to version control.',
                    style: TextStyle(color: PrimeTheme.statusBusy, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: PrimeTheme.primeCyan,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PrimeTheme.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PrimeTheme.borderDefault),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: PrimeTheme.textSecondary, fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: PrimeTheme.bgSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: PrimeTheme.borderDefault),
            ),
            child: DropdownButton<String>(
              value: value,
              dropdownColor: PrimeTheme.bgSurface,
              style: TextStyle(color: PrimeTheme.textPrimary, fontSize: 14),
              underline: const SizedBox(),
              items: options.map((o) => DropdownMenuItem(
                value: o,
                child: Text(o.toUpperCase()),
              )).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => onChanged(v));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: PrimeTheme.textSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: PrimeTheme.primeCyan,
                inactiveTrackColor: PrimeTheme.bgSurface,
                thumbColor: PrimeTheme.primeCyan,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(1),
              style: TextStyle(color: PrimeTheme.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: PrimeTheme.textSecondary, fontSize: 14),
          ),
          SwitchTheme(
            data: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? PrimeTheme.primeCyan
                      : PrimeTheme.textMuted),
            ),
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField(String label, String currentValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: PrimeTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          TextField(
            obscureText: true,
            style: TextStyle(color: PrimeTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: currentValue.isNotEmpty ? '••••••••' : 'Enter API key',
              hintStyle: TextStyle(color: PrimeTheme.textSecondary.withAlpha(128)),
              filled: true,
              fillColor: PrimeTheme.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: PrimeTheme.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: PrimeTheme.borderDefault),
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
