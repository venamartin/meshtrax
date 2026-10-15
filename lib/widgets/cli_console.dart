import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import 'debug_frame_viewer.dart';

class CliQuickCommand {
  final String label;
  final String command;

  const CliQuickCommand(this.label, this.command);
}

class CliHelpEntry {
  final String command;
  final String description;

  const CliHelpEntry({required this.command, required this.description});
}

class CliHelpSection {
  final String title;
  final List<CliHelpEntry> entries;
  final String? note;

  const CliHelpSection(this.title, this.entries, {this.note});
}

/// A terminal-style console: quick commands, scrolling history, input with
/// up/down recall, a command list and a frame debugger. Delivery is the
/// caller's: [onSend] returns the reply, or throws to show an error.
class CliConsole extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<String> Function(String command) onSend;
  final List<CliQuickCommand> quickCommands;
  final List<CliHelpSection> Function(BuildContext context) helpSections;
  final String helpNote;
  final Uint8List Function(String command)? debugFrameFor;
  final List<Widget> actions;

  const CliConsole({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSend,
    required this.quickCommands,
    required this.helpSections,
    required this.helpNote,
    this.debugFrameFor,
    this.actions = const [],
  });

  @override
  State<CliConsole> createState() => _CliConsoleState();
}

class _CliConsoleState extends State<CliConsole> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<({bool isCommand, String text})> _history = [];
  int _historyIndex = -1;

  @override
  void dispose() {
    _commandController.dispose();
    _commandFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendCommand({bool showDebug = false}) async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    setState(() => _history.add((isCommand: true, text: command)));

    if (showDebug && widget.debugFrameFor != null) {
      DebugFrameViewer.showFrameDebug(
        context,
        widget.debugFrameFor!(command),
        context.l10n.repeater_cliCommandFrameTitle,
      );
    }

    String response;
    try {
      response = await widget.onSend(command);
    } catch (e) {
      if (!mounted) return;
      response = context.l10n.repeater_cliCommandError(e.toString());
    }
    if (!mounted) return;
    setState(() => _history.add((isCommand: false, text: response)));

    _commandController.clear();
    _historyIndex = -1;
    _commandFocusNode.requestFocus();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _useQuickCommand(String command) {
    _commandController.text = command;
    _sendCommand();
  }

  void _navigateHistory(bool up) {
    final commands = _history
        .where((entry) => entry.isCommand)
        .toList()
        .reversed
        .toList();

    if (commands.isEmpty) return;

    if (up) {
      if (_historyIndex < commands.length - 1) {
        _historyIndex++;
      }
    } else {
      if (_historyIndex > 0) {
        _historyIndex--;
      } else {
        _historyIndex = -1;
        _commandController.clear();
        return;
      }
    }

    if (_historyIndex >= 0 && _historyIndex < commands.length) {
      _commandController.text = commands[_historyIndex].text;
      _commandController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commandController.text.length),
      );
    }
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
      _historyIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          ...widget.actions,
          if (widget.debugFrameFor != null)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: l10n.repeater_debugNextCommand,
              onPressed: () {
                if (_commandController.text.trim().isNotEmpty) {
                  _sendCommand(showDebug: true);
                } else {
                  showDismissibleSnackBar(
                    context,
                    content: Text(l10n.repeater_enterCommandFirst),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.repeater_commandHelp,
            onPressed: () => _showCommandHelp(context),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: l10n.repeater_clearHistory,
            onPressed: _history.isEmpty ? null : _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickCommandsBar(),
          const Divider(height: 1),
          Expanded(
            child: _history.isEmpty
                ? _buildEmptyState()
                : _buildCommandHistory(),
          ),
          const Divider(height: 1),
          _buildCommandInput(),
        ],
      ),
    );
  }

  Widget _buildQuickCommandsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.quickCommands.map((cmd) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(cmd.label),
                onPressed: () => _useQuickCommand(cmd.command),
                avatar: const Icon(Icons.play_arrow, size: 16),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.repeater_noCommandsSent,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.repeater_typeCommandOrUseQuick,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandHistory() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        final isCommand = entry.isCommand;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCommand
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isCommand ? Icons.chevron_right : Icons.arrow_back,
                  size: 16,
                  color: isCommand
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  entry.text,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: isCommand
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandInput() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 20),
              tooltip: l10n.repeater_previousCommand,
              onPressed: () => _navigateHistory(true),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward, size: 20),
              tooltip: l10n.repeater_nextCommand,
              onPressed: () => _navigateHistory(false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _commandController,
                focusNode: _commandFocusNode,
                decoration: InputDecoration(
                  hintText: l10n.repeater_enterCommandHint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixText: '> ',
                ),
                style: const TextStyle(fontFamily: 'monospace'),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendCommand(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: _sendCommand,
            ),
          ],
        ),
      ),
    );
  }

  void _applyHelpCommand(String command) {
    _commandController.text = command;
    _commandController.selection = TextSelection.fromPosition(
      TextPosition(offset: command.length),
    );
    Navigator.pop(context);
    Future.microtask(() {
      if (mounted) {
        _commandFocusNode.requestFocus();
      }
    });
  }

  void _showCommandHelp(BuildContext context) {
    final l10n = context.l10n;
    final sections = widget.helpSections(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.repeater_commandsListTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.helpNote, style: const TextStyle(fontSize: 13)),
              for (final section in sections) ...[
                const SizedBox(height: 16),
                _buildHelpSection(context, section),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, CliHelpSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (section.note != null) ...[
          const SizedBox(height: 6),
          Text(section.note!, style: const TextStyle(fontSize: 12)),
        ],
        const SizedBox(height: 8),
        ...section.entries.map(
          (entry) => _buildHelpCommandCard(context, entry),
        ),
      ],
    );
  }

  Widget _buildHelpCommandCard(BuildContext context, CliHelpEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _applyHelpCommand(entry.command),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.command,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.description,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
