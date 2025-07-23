part of blackblizzard;

// Concrete leftout clues

class Gloves extends LeftoutClue {
  final String chineseName;
  Gloves({bool isExtra = false}) : chineseName = '手套', super('Gloves', 'Gloves', chineseName: '手套', isExtra: isExtra);
}

class Smartphone extends LeftoutClue {
  final String chineseName;
  Smartphone({bool isExtra = false}) : chineseName = '智能手机', super('Smartphone', 'Smartphone', chineseName: '智能手机', isExtra: isExtra);
}

class Snacks extends LeftoutClue {
  final String chineseName;
  Snacks({bool isExtra = false}) : chineseName = '零食', super('Snacks', 'Snacks', chineseName: '零食', isExtra: isExtra);
}

class Pendant extends LeftoutClue {
  final String chineseName;
  Pendant({bool isExtra = false}) : chineseName = '挂饰', super('Pendant', 'Pendant', chineseName: '挂饰', isExtra: isExtra);
}

class Watch extends LeftoutClue {
  final String chineseName;
  Watch({bool isExtra = false}) : chineseName = '手表', super('Watch', 'Watch', chineseName: '手表', isExtra: isExtra);
}

class Glasses extends LeftoutClue {
  final String chineseName;
  Glasses({bool isExtra = false}) : chineseName = '眼镜', super('Glasses', 'Glasses', chineseName: '眼镜', isExtra: isExtra);
}

class Hat extends LeftoutClue {
  final String chineseName;
  Hat({bool isExtra = false}) : chineseName = '帽子', super('Hat', 'Hat', chineseName: '帽子', isExtra: isExtra);
}

class Cloth extends LeftoutClue {
  final String chineseName;
  Cloth({bool isExtra = false}) : chineseName = '衣料', super('Cloth', 'Cloth', chineseName: '衣料', isExtra: isExtra);
}

class Earrings extends LeftoutClue {
  final String chineseName;
  Earrings({bool isExtra = false}) : chineseName = '耳环', super('Earrings', 'Earrings', chineseName: '耳环', isExtra: isExtra);
}

class Gun extends LeftoutClue {
  final String chineseName;
  Gun({bool isExtra = false}) : chineseName = '枪', super('Gun', 'Gun', chineseName: '枪', isExtra: isExtra);
} 