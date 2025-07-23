part of blackblizzard;

// Concrete trace clues

class FootprintsF extends TraceClue {
  final String chineseName;
  FootprintsF({bool isExtra = false}) : chineseName = '女人的脚印', super('FootprintsF', "Woman's footprints", chineseName: '女人的脚印', isExtra: isExtra);
}

class FootprintsM extends TraceClue {
  final String chineseName;
  FootprintsM({bool isExtra = false}) : chineseName = '男人的脚印', super('FootprintsM', "Man's footprints", chineseName: '男人的脚印', isExtra: isExtra);
}

class HandprintsF extends TraceClue {
  final String chineseName;
  HandprintsF({bool isExtra = false}) : chineseName = '女人的手掌印', super('HandprintsF', "Woman's handprints", chineseName: '女人的手掌印', isExtra: isExtra);
}

class HandprintsM extends TraceClue {
  final String chineseName;
  HandprintsM({bool isExtra = false}) : chineseName = '男人的手掌印', super('HandprintsM', "Man's handprints", chineseName: '男人的手掌印', isExtra: isExtra);
}

class Smells extends TraceClue {
  final String chineseName;
  Smells({bool isExtra = false}) : chineseName = '气味', super('Smells', 'Smells', chineseName: '气味', isExtra: isExtra);
}

class Dirt extends TraceClue {
  final String chineseName;
  Dirt({bool isExtra = false}) : chineseName = '泥土', super('Dirt', 'Dirt', chineseName: '泥土', isExtra: isExtra);
}

class Watermark extends TraceClue {
  final String chineseName;
  Watermark({bool isExtra = false}) : chineseName = '水痕', super('Watermark', 'Watermark', chineseName: '水痕', isExtra: isExtra);
}
