import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemoryView extends StatefulWidget {
  final List<int> data;

  const MemoryView({super.key, required this.data});

  @override
  State<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends State<MemoryView> {
  bool _showAscii = true;
  int? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${widget.data.length} bytes',
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('ASCII')),
                  ButtonSegment(value: false, label: Text('HEX')),
                ],
                selected: {_showAscii},
                onSelectionChanged: (value) {
                  setState(() => _showAscii = value.first);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyAll,
                tooltip: 'Copier tout',
              ),
            ],
          ),
        ),

        // Entêtes
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHigh,
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Addr',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (_showAscii)
                SizedBox(
                  width: 140,
                  child: Text(
                    'ASCII',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),

        // Données
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: (widget.data.length / 16).ceil(),
            itemBuilder: (context, index) => _buildRow(context, index),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, int rowIndex) {
    final theme = Theme.of(context);
    final startAddress = rowIndex * 16;
    final isSelected = _selectedAddress == startAddress;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAddress = isSelected ? null : startAddress;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : (rowIndex.isEven
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerLowest),
        child: Row(
          children: [
            // Adresse
            SizedBox(
              width: 60,
              child: Text(
                startAddress.toRadixString(16).padLeft(4, '0').toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'JetBrainsMono',
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            // Bytes hex
            Expanded(
              flex: 3,
              child: Text(
                _buildHexString(startAddress),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ),

            // ASCII
            if (_showAscii)
              Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Text(
                  _buildAsciiString(startAddress),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildHexString(int startAddress) {
    final buffer = StringBuffer();

    for (var i = 0; i < 16; i++) {
      final address = startAddress + i;
      if (address < widget.data.length) {
        buffer.write(
          widget.data[address].toRadixString(16).padLeft(2, '0').toUpperCase(),
        );
      } else {
        buffer.write('  ');
      }

      if (i < 15) {
        buffer.write(i == 7 ? '  ' : ' ');
      }
    }

    return buffer.toString();
  }

  String _buildAsciiString(int startAddress) {
    final buffer = StringBuffer();

    for (var i = 0; i < 16; i++) {
      final address = startAddress + i;
      if (address < widget.data.length) {
        final byte = widget.data[address];
        if (byte >= 32 && byte <= 126) {
          buffer.write(String.fromCharCode(byte));
        } else {
          buffer.write('.');
        }
      } else {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  void _copyAll() {
    final buffer = StringBuffer();

    for (var i = 0; i < widget.data.length; i += 16) {
      // Adresse
      buffer.write(i.toRadixString(16).padLeft(4, '0').toUpperCase());
      buffer.write(': ');

      // Hex
      for (var j = 0; j < 16; j++) {
        if (i + j < widget.data.length) {
          buffer.write(
            widget.data[i + j].toRadixString(16).padLeft(2, '0').toUpperCase(),
          );
          buffer.write(' ');
        } else {
          buffer.write('   ');
        }
        if (j == 7) buffer.write(' ');
      }

      buffer.write(' |');

      // ASCII
      for (var j = 0; j < 16; j++) {
        if (i + j < widget.data.length) {
          final byte = widget.data[i + j];
          if (byte >= 32 && byte <= 126) {
            buffer.write(String.fromCharCode(byte));
          } else {
            buffer.write('.');
          }
        }
      }

      buffer.writeln('|');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dump mémoire copié'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
