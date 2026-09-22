import 'package:flutter/material.dart';
import '../utils/sticker_loader.dart';
import '../theme/theme.dart';

class StickerPicker extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const StickerPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  late Future<List<String>> _stickers;

  @override
  void initState() {
    super.initState();
    _stickers = StickerLoader.loadStickers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _stickers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stickers = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stickers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (_, i) {
            final path = stickers[i];
            final isSelected = widget.selected == path;

            return GestureDetector(
              onTap: () => widget.onSelected(path),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? LutaliaTheme.rose : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Image.asset(path),
              ),
            );
          },
        );
      },
    );
  }
}
