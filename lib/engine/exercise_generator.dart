import 'dart:math';

import '../models/vedic_models.dart';

class ExerciseGenerator {
  final Random _rng = Random.secure();
  final Map<String, Set<String>> _recentByItem = {};

  /// Generates [count] unique problems for [itemId] without repeats.
  List<MathProblem> generateSession(String itemId, {int count = 25}) {
    final sessionKeys = <String>{};
    final recentKeys = _recentByItem.putIfAbsent(itemId, () => <String>{});
    final List<MathProblem> problems = [];

    for (int i = 0; i < count; i++) {
      MathProblem? chosen;
      String? chosenKey;

      // Try up to 80 times to avoid both in-session AND recent-session repeats
      for (int attempt = 0; attempt < 80; attempt++) {
        final candidate = generate(itemId, i);
        final key = _canonicalKey(candidate.prompt);
        if (!sessionKeys.contains(key) && !recentKeys.contains(key)) {
          chosen = candidate;
          chosenKey = key;
          break;
        }
      }

      // Fallback: guarantee uniqueness within the current 25-question session
      if (chosen == null) {
        recentKeys.clear();
        for (int attempt = 0; attempt < 80; attempt++) {
          final candidate = generate(itemId, i);
          final key = _canonicalKey(candidate.prompt);
          if (!sessionKeys.contains(key)) {
            chosen = candidate;
            chosenKey = key;
            break;
          }
        }
      }

      chosen ??= generate(itemId, i);
      chosenKey ??= _canonicalKey(chosen.prompt);

      sessionKeys.add(chosenKey);
      recentKeys.add(chosenKey);
      if (recentKeys.length > 50) {
        recentKeys.remove(recentKeys.first);
      }

      problems.add(chosen);
    }

    return problems;
  }

  /// Normalizes commutative prompts (e.g. "94 × 97" == "97 × 94") so mirrored
  /// pairs aren't treated as different exercises.
  String _canonicalKey(String prompt) {
    final multMatch = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(prompt);
    if (multMatch != null) {
      final a = int.parse(multMatch.group(1)!);
      final b = int.parse(multMatch.group(2)!);
      final low = a < b ? a : b;
      final high = a < b ? b : a;
      return 'mul:$low:$high:${prompt.split('\n').first}';
    }
    return prompt;
  }

  MathProblem generate(String itemId, int questionIndex) {
    switch (itemId) {
      case 's1':
        return _genEkadhikena(questionIndex);
      case 's2':
        return _genNikhilamSub(questionIndex);
      case 's3':
        return _genUrdhva(questionIndex);
      case 's4':
        return _genParavartya();
      case 's5':
        return _genShunyam();
      case 's6':
        return _genAnurupye();
      case 's7':
        return _genSankalana();
      case 's8':
        return _genPuranapuranabhyam();
      case 's9':
        return _genChalana();
      case 's10':
        return _genYavadunamCube(questionIndex);
      case 's11':
        return _genVyashti();
      case 's12':
        return _genShesanyankena();
      case 's13':
        return _genTimes12();
      case 's14':
        return _genEkanyunena(questionIndex);
      case 's15':
        return _genGunitasamuccayah();
      case 's16':
        return _genGunakasamuccayah();
      case 'ss1':
        return _genAnurupyena();
      case 'ss2':
        return _genSisyate();
      case 'ss3':
        return _genAdyamadyena();
      case 'ss4':
        return _genKevalaih();
      case 'ss5':
        return _genVestanam();
      case 'ss6':
        return _genYavadunamMult(questionIndex);
      case 'ss7':
        return _genYavadunamSquare(questionIndex);
      case 'ss8':
        return _genAntyayordashake();
      case 'ss9':
        return _genAntyayoreva();
      case 'ss10':
        return _genSamuccayagunitah();
      case 'ss11':
        return _genLopana();
      case 'ss12':
        return _genVilokanam(questionIndex);
      case 'ss13':
      default:
        return _genDigitSum();
    }
  }

  int _randRange(int min, int max) => min + _rng.nextInt(max - min + 1);

  int _nonZeroDeviation(int maxAbs) {
    int d = 0;
    while (d == 0) {
      d = _randRange(-maxAbs, maxAbs);
    }
    return d;
  }

  int _digitSum(int n) {
    int x = n.abs();
    if (x == 0) return 0;
    int mod = x % 9;
    return mod == 0 ? 9 : mod;
  }

  MathProblem _genEkadhikena(int idx) {
    // 39 distinct prefixes (15² .. 395²)
    int prefix = idx < 10 ? _randRange(1, 14) : _randRange(10, 39);
    int n = prefix * 10 + 5;
    int ans = n * n;
    int left = prefix * (prefix + 1);
    return MathProblem(
      prompt: 'Compute $n²',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Multiply $prefix by ${prefix + 1}, then append 25.',
      solutionSteps:
          '1. Prefix = $prefix.\n'
          '2. Ekadhika (one more): $prefix × ${prefix + 1} = $left.\n'
          '3. Append 25 -> $ans.',
    );
  }

  MathProblem _genNikhilamSub(int idx) {
    int base = idx < 12 ? 1000 : 10000;
    int sub = _randRange(11, base - 11);
    int ans = base - sub;
    return MathProblem(
      prompt: 'Compute $base - $sub',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Subtract every digit from 9 and the last non-zero digit from 10.',
      solutionSteps:
          'Using Nikhilam (All from 9, last from 10) against $base:\n'
          '$base - $sub = $ans.',
    );
  }

  MathProblem _genUrdhva(int idx) {
    int a = idx < 15 ? _randRange(12, 98) : _randRange(112, 499);
    int b = _randRange(12, 98);
    int ans = a * b;
    return MathProblem(
      prompt: 'Multiply: $a × $b',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Apply Vertically & Crosswise right-to-left.',
      solutionSteps:
          'Multiply vertically & crosswise:\n'
          'Units -> Crosswise pairs -> Leftmost vertical product = $ans.',
    );
  }

  MathProblem _genParavartya() {
    int excess = _randRange(1, 5);
    int divisor = _rng.nextBool()
        ? 10 + excess
        : 100 + excess * 10 + _randRange(1, 4);
    int q = _randRange(11, 35);
    int r = _randRange(0, divisor - 1);
    int dividend = divisor * q + r;
    int base = divisor < 100 ? 10 : 100;
    int trans = -(divisor - base);
    return MathProblem(
      prompt: 'Divide: $dividend ÷ $divisor',
      answerType: AnswerType.quotientRemainder,
      primaryAnswer: '$q',
      secondaryAnswer: '$r',
      hint: 'Use Base $base and transpose excess to $trans.',
      solutionSteps:
          '1. Base = $base, transposed excess = $trans.\n'
          '2. Partition last ${base == 10 ? 1 : 2} digit(s) for remainder.\n'
          '3. Bring down, multiply by $trans, and add diagonally.\n'
          '4. Quotient = $q, Remainder = $r.',
    );
  }

  MathProblem _genShunyam() {
    int xAns = _randRange(2, 18);
    int d1 = _randRange(1, 6);
    int d2 = d1 + _randRange(1, 5);
    int a = xAns + d1;
    int b = xAns - d1;
    int c = xAns + d2;
    int d = xAns - d2;
    return MathProblem(
      prompt: 'Solve for x:\n1/(x - $a) + 1/(x - $b) = 1/(x - $c) + 1/(x - $d)',
      answerType: AnswerType.integer,
      primaryAnswer: '$xAns',
      hint: 'Sum the denominators on either side and set equal to 0.',
      solutionSteps:
          '1. LHS denominator sum = (x - $a) + (x - $b) = 2x - ${a + b}.\n'
          '2. RHS denominator sum = (x - $c) + (x - $d) = 2x - ${c + d}.\n'
          '3. Set 2x - ${a + b} = 0 -> x = $xAns.',
    );
  }

  MathProblem _genAnurupye() {
    int yAns = _randRange(1, 12);
    int k = _randRange(2, 6);
    int a = _randRange(2, 12);
    int d = a + _randRange(1, 7);
    int b = _randRange(2, 12);
    int c1 = b * yAns;
    int e = b * k;
    int c2 = c1 * k;
    return MathProblem(
      prompt: 'Solve:\n${a}x + ${b}y = $c1\n${d}x + ${e}y = $c2',
      answerType: AnswerType.pairXY,
      primaryAnswer: '0',
      secondaryAnswer: '$yAns',
      hint: 'Check the ratio of y-coefficients against the constants.',
      solutionSteps:
          '1. Ratio of y-terms ($b : $e) = Ratio of constants ($c1 : $c2) = 1 : $k.\n'
          '2. By Anurupye Shunyamanyat, x = 0.\n'
          '3. Then ${b}y = $c1 -> y = $yAns.',
    );
  }

  MathProblem _genSankalana() {
    int xAns = _randRange(1, 12);
    int yAns = _randRange(1, 12);
    int a = _randRange(11, 35);
    int b = a + _randRange(2, 15);
    int c1 = a * xAns + b * yAns;
    int c2 = b * xAns + a * yAns;
    return MathProblem(
      prompt: 'Solve:\n${a}x + ${b}y = $c1\n${b}x + ${a}y = $c2',
      answerType: AnswerType.pairXY,
      primaryAnswer: '$xAns',
      secondaryAnswer: '$yAns',
      hint: 'Add both equations to find (x + y), subtract to find (x - y).',
      solutionSteps:
          '1. Add: ${a + b}(x + y) = ${c1 + c2} -> x + y = ${xAns + yAns}.\n'
          '2. Subtract: ${a - b}(x - y) = ${c1 - c2} -> x - y = ${xAns - yAns}.\n'
          '3. Add & halve: x = $xAns, y = $yAns.',
    );
  }

  MathProblem _genPuranapuranabhyam() {
    int a = _randRange(12, 98);
    int comp = 10 - (a % 10);
    if (comp == 10) comp = 5;
    int b = _randRange(1, 9) * 10 + comp;
    int c = _randRange(11, 149);
    int ans = a + b + c;
    return MathProblem(
      prompt: 'Add mentally: $a + $b + $c',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Pair $a and $b first to complete a multiple of 10.',
      solutionSteps:
          '1. Complete tens: $a + $b = ${a + b}.\n'
          '2. Add remaining: ${a + b} + $c = $ans.',
    );
  }

  MathProblem _genChalana() {
    int a = _randRange(2, 9);
    int b = _randRange(1, 15);
    int c = _randRange(1, 25);
    int k = _randRange(1, 9);
    int ans = 2 * a * k + b;
    return MathProblem(
      prompt: 'Find f\'($k) for f(x) = ${a}x² + ${b}x + $c',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Derivative of ax² + bx + c is 2ax + b.',
      solutionSteps:
          '1. f\'(x) = 2($a)x + $b = ${2 * a}x + $b.\n'
          '2. At x = $k: ${2 * a}($k) + $b = $ans.',
    );
  }

  MathProblem _genYavadunamCube(int idx) {
    // 46+ distinct numbers across Base 100 and Base 1000
    int base = idx < 15 ? 100 : 1000;
    int d = base == 100 ? _nonZeroDeviation(14) : _nonZeroDeviation(9);
    int n = base + d;
    int ans = n * n * n;
    return MathProblem(
      prompt: 'Compute $n³',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Use (N + 2d) | 3d² | d³ around Base $base.',
      solutionSteps:
          '1. Base = $base, deviation d = $d.\n'
          '2. Left: $n + ${2 * d} = ${n + 2 * d}.\n'
          '3. Middle: 3(${d * d}) = ${3 * d * d}.\n'
          '4. Right: ($d)³ = ${d * d * d} (adjust negative borrow if d < 0).\n'
          '5. Result: $ans.',
    );
  }

  MathProblem _genVyashti() {
    int base = [50, 100, 200][_rng.nextInt(3)];
    int offset = _randRange(-4, 4);
    int targetAvg = base + offset;
    List<int> devs = [
      _randRange(-8, 8),
      _randRange(-8, 8),
      _randRange(-8, 8),
      _randRange(-8, 8),
    ];
    int lastDev = 5 * offset - devs.reduce((a, b) => a + b);
    devs.add(lastDev);
    List<int> nums = devs.map((d) => base + d).toList();
    return MathProblem(
      prompt: 'Find the average of:\n${nums.join(', ')}',
      answerType: AnswerType.integer,
      primaryAnswer: '$targetAvg',
      hint: 'Measure deviations from $base, sum them, and divide by 5.',
      solutionSteps:
          '1. Assumed base = $base.\n'
          '2. Deviations: ${devs.join(', ')} (sum = ${5 * offset}).\n'
          '3. Average deviation = ${5 * offset} ÷ 5 = $offset.\n'
          '4. Average = $base + $offset = $targetAvg.',
    );
  }

  MathProblem _genShesanyankena() {
    int denom = [19, 29, 39, 49, 59, 69, 79, 89][_rng.nextInt(8)];
    int num = _randRange(1, denom - 1);
    int nth = _randRange(2, 5);
    int rem = num;
    int digit = 0;
    List<int> digits = [];
    for (int i = 0; i < nth; i++) {
      rem *= 10;
      digit = rem ~/ denom;
      rem = rem % denom;
      digits.add(digit);
    }
    return MathProblem(
      prompt:
          'What is decimal digit #$nth after the decimal point of $num / $denom?',
      answerType: AnswerType.integer,
      primaryAnswer: '$digit',
      hint: 'Use Ekadhika ${(denom ~/ 10) + 1} or trace the remainders.',
      solutionSteps:
          'First $nth decimal digits of $num / $denom: 0.${digits.join()}...\n'
          'Digit #$nth = $digit.',
    );
  }

  MathProblem _genTimes12() {
    int n = _randRange(112, 989);
    int ans = n * 12;
    return MathProblem(
      prompt: 'Multiply: $n × 12',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Double each digit and add its right-hand neighbor.',
      solutionSteps:
          'Apply Sopantyadvayamantyam (2 × digit + right neighbor, right-to-left):\n'
          '$n × 12 = $ans.',
    );
  }

  MathProblem _genEkanyunena(int idx) {
    int mult = idx < 12 ? 99 : 999;
    int n = mult == 99 ? _randRange(12, 98) : _randRange(102, 998);
    int ans = n * mult;
    int comp = (mult + 1) - n;
    int width = mult == 99 ? 2 : 3;
    return MathProblem(
      prompt: 'Multiply: $n × $mult',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Left = $n - 1; Right = Nikhilam complement of $n.',
      solutionSteps:
          '1. Left part: $n - 1 = ${n - 1}.\n'
          '2. Right part: Complement of $n = ${comp.toString().padLeft(width, '0')}.\n'
          '3. Answer = $ans.',
    );
  }

  MathProblem _genGunitasamuccayah() {
    int a = _randRange(1, 8);
    int b = _randRange(1, 10);
    int c = _randRange(1, 8);
    int d = _nonZeroDeviation(9);
    int ans = (a + b) * (c + d);
    String dStr = d >= 0 ? '+ $d' : '- ${d.abs()}';
    return MathProblem(
      prompt:
          'Find the sum of coefficients (P + Q + R) of:\n(${a}x + $b)(${c}x $dStr)',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Set x = 1 in both factors and multiply.',
      solutionSteps:
          'By Gunitasamuccayah, set x = 1:\n'
          '($a + $b) × ($c + $d) = ${a + b} × ${c + d} = $ans.',
    );
  }

  MathProblem _genGunakasamuccayah() {
    int p = _randRange(1, 6);
    int q = _randRange(1, 8);
    int r = _randRange(1, 6);
    int s = _randRange(1, 8);
    int a = p * r;
    int b = p * s + q * r;
    int c = q * s;
    int ans = a + b + c;
    return MathProblem(
      prompt:
          'If ${a}x² + ${b}x + $c factors into (px + q)(rx + s), find (p + q)(r + s).',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'The product of factor sums equals the sum of the quadratic coefficients.',
      solutionSteps:
          'By Gunakasamuccayah, (p + q)(r + s) = a + b + c:\n'
          '$a + $b + $c = $ans.',
    );
  }

  MathProblem _genAnurupyena() {
    int choice = _rng.nextInt(3);
    if (choice == 0) {
      int d1 = _nonZeroDeviation(9);
      int d2 = _nonZeroDeviation(9);
      int a = 50 + d1;
      int b = 50 + d2;
      int ans = a * b;
      return MathProblem(
        prompt: 'Multiply (Base 50): $a × $b',
        answerType: AnswerType.integer,
        primaryAnswer: '$ans',
        hint: 'Use Working Base 50 (half of 100). Halve the left side.',
        solutionSteps:
            '1. Deviations from 50: $d1 and $d2.\n'
            '2. Cross-add: $a + ($d2) = ${a + d2}.\n'
            '3. Halve left side (if odd, +50 to right side) and add (${d1 * d2}).\n'
            '4. Result = $ans.',
      );
    } else {
      int mult = choice == 1 ? 2 : 3;
      int base = 100 * mult;
      int d1 = _randRange(1, 12);
      int d2 = _randRange(1, 12);
      int a = base + d1;
      int b = base + d2;
      int ans = a * b;
      return MathProblem(
        prompt: 'Multiply (Base $base): $a × $b',
        answerType: AnswerType.integer,
        primaryAnswer: '$ans',
        hint:
            'Use Working Base $base ($mult × 100). Multiply left side by $mult.',
        solutionSteps:
            '1. Deviations from $base: +$d1 and +$d2.\n'
            '2. Left: ($a + $d2) × $mult = ${(a + d2) * mult}.\n'
            '3. Right: $d1 × $d2 = ${d1 * d2} (carry if ≥ 100).\n'
            '4. Result = $ans.',
      );
    }
  }

  MathProblem _genSisyate() {
    int a = _randRange(1, 7);
    int b = _randRange(1, 12);
    int c = _randRange(1, 18);
    int k = _randRange(1, 7);
    int ans = a * k * k + b * k + c;
    return MathProblem(
      prompt:
          'Find the remainder when (${a}x² + ${b}x + $c) is divided by (x - $k).',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Substitute x = $k into the quadratic.',
      solutionSteps:
          'P($k) = $a(${k * k}) + $b($k) + $c = ${a * k * k} + ${b * k} + $c = $ans.',
    );
  }

  MathProblem _genAdyamadyena() {
    int p = _randRange(2, 7);
    int q = _randRange(1, 9);
    int r = _randRange(2, 7);
    int kAns = _randRange(2, 12);
    int a = p * r;
    int b = p * kAns + q * r;
    int c = q * kAns;
    return MathProblem(
      prompt: 'If ${a}x² + ${b}x + $c = (${p}x + $q)(${r}x + k), find k.',
      answerType: AnswerType.integer,
      primaryAnswer: '$kAns',
      hint: 'Multiply the last terms: $q × k = $c.',
      solutionSteps:
          'By Adyamadyenantya-mantyena ("the last by the last"):\n'
          '$q × k = $c -> k = $c ÷ $q = $kAns.',
    );
  }

  MathProblem _genKevalaih() {
    int k = _randRange(2, 99);
    int m = 7 * k;
    int ans = 143 * m;
    return MathProblem(
      prompt: 'Multiply mentally: 143 × $m',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Write $m as 7 × $k, knowing 143 × 7 = 1001.',
      solutionSteps:
          '1. $m = 7 × $k.\n'
          '2. 143 × 7 × $k = 1001 × $k = $ans.',
    );
  }

  MathProblem _genVestanam() {
    int divisor = [7, 13, 19, 29][_rng.nextInt(4)];
    bool isDivisible = _rng.nextBool();
    int baseMult = divisor * _randRange(15, 120);
    int n = isDivisible ? baseMult : baseMult + _randRange(1, divisor - 1);
    String osc = divisor == 29
        ? '+3'
        : (divisor == 19 ? '+2' : (divisor == 13 ? '+4' : '-2'));
    return MathProblem(
      prompt: 'Is $n divisible by $divisor?',
      answerType: AnswerType.booleanYesNo,
      primaryAnswer: isDivisible ? 'Yes' : 'No',
      hint: 'Use the osculator ($osc) for $divisor.',
      solutionSteps:
          'Osculate $n repeatedly using $osc (for $divisor).\n'
          '$n % $divisor = ${n % divisor}, so the answer is ${isDivisible ? "Yes" : "No"}.',
    );
  }

  MathProblem _genYavadunamMult(int idx) {
    int base = idx < 13 ? 100 : 1000;
    int d1 = -_randRange(2, 15);
    int d2 = -_randRange(2, 15);
    int a = base + d1;
    int b = base + d2;
    int ans = a * b;
    int width = base == 100 ? 2 : 3;
    return MathProblem(
      prompt: 'Multiply: $a × $b',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Left = $a + ($d2); Right = ($d1) × ($d2) ($width digits).',
      solutionSteps:
          '1. Deficiencies from $base: $d1 and $d2.\n'
          '2. Left: $a + ($d2) = ${a + d2}.\n'
          '3. Right: ($d1) × ($d2) = ${d1 * d2} (carry if ≥ $base).\n'
          '4. Answer = $ans.',
    );
  }

  MathProblem _genYavadunamSquare(int idx) {
    // 76 distinct numbers across Base 100 and Base 1000
    int base = idx < 14 ? 100 : 1000;
    int d = _nonZeroDeviation(19);
    int n = base + d;
    int ans = n * n;
    int width = base == 100 ? 2 : 3;
    return MathProblem(
      prompt: 'Square: $n²',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Compute ($n + ($d)) | ($d)² padded to $width digits.',
      solutionSteps:
          '1. Base = $base, deviation d = $d.\n'
          '2. Left: $n + ($d) = ${n + d}.\n'
          '3. Right: ($d)² = ${d * d} (padded/carried for $width digits).\n'
          '4. Answer = $ans.',
    );
  }

  MathProblem _genAntyayordashake() {
    int prefix = _randRange(1, 25);
    int u1 = _randRange(1, 9);
    int u2 = 10 - u1;
    int a = prefix * 10 + u1;
    int b = prefix * 10 + u2;
    int ans = a * b;
    return MathProblem(
      prompt: 'Multiply: $a × $b',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Same prefix $prefix, last digits sum to 10.',
      solutionSteps:
          '1. Left: $prefix × ${prefix + 1} = ${prefix * (prefix + 1)}.\n'
          '2. Right: $u1 × $u2 = ${(u1 * u2).toString().padLeft(2, '0')}.\n'
          '3. Answer = $ans.',
    );
  }

  MathProblem _genAntyayoreva() {
    int xAns = _randRange(2, 16);
    int c = _randRange(2, 7);
    int d = c + _randRange(1, 5);
    int m = _randRange(2, 6);
    int num = m * c;
    int den = m * d;
    int a = num - xAns;
    int b = den - xAns;
    String aStr = a >= 0 ? '+ $a' : '- ${a.abs()}';
    String bStr = b >= 0 ? '+ $b' : '- ${b.abs()}';
    return MathProblem(
      prompt: 'Solve for x:\n(x $aStr) / (x $bStr) = $c / $d',
      answerType: AnswerType.integer,
      primaryAnswer: '$xAns',
      hint: 'Cross-multiply $d(x $aStr) = $c(x $bStr).',
      solutionSteps:
          '1. ${d}x + ${d * a} = ${c}x + ${c * b}.\n'
          '2. ${d - c}x = ${c * b - d * a}.\n'
          '3. x = $xAns.',
    );
  }

  MathProblem _genSamuccayagunitah() {
    int a = _randRange(1, 7);
    int b = _randRange(1, 9);
    int c = _randRange(1, 7);
    int d = _randRange(1, 9);
    int p = a * c;
    int q = a * d + b * c;
    int r = b * d;
    return MathProblem(
      prompt: 'If (${a}x + $b)(${c}x + $d) = ${p}x² + Qx + $r, find Q.',
      answerType: AnswerType.integer,
      primaryAnswer: '$q',
      hint: 'Total sum is (${a + b})(${c + d}). Subtract P and R.',
      solutionSteps:
          '1. Sum of factors at x=1: (${a + b}) × (${c + d}) = ${(a + b) * (c + d)}.\n'
          '2. Q = ${(a + b) * (c + d)} - $p - $r = $q.',
    );
  }

  MathProblem _genLopana() {
    int xAns = _randRange(1, 12);
    int yAns = _randRange(1, 12);
    int a1 = _randRange(2, 7);
    int b1 = _randRange(1, 6);
    int a2 = _randRange(2, 7);
    int b2 = -b1;
    int c1 = a1 * xAns + b1 * yAns;
    int c2 = a2 * xAns + b2 * yAns;
    return MathProblem(
      prompt: 'Solve:\n${a1}x + ${b1}y = $c1\n${a2}x - ${b1}y = $c2',
      answerType: AnswerType.pairXY,
      primaryAnswer: '$xAns',
      secondaryAnswer: '$yAns',
      hint: 'Add both equations to eliminate y immediately.',
      solutionSteps:
          '1. Add equations: ${a1 + a2}x = ${c1 + c2} -> x = $xAns.\n'
          '2. Substitute back: ${a1 * xAns} + ${b1}y = $c1 -> y = $yAns.',
    );
  }

  MathProblem _genVilokanam(int idx) {
    if (idx.isEven) {
      int root = _randRange(22, 99);
      int sq = root * root;
      int prefix = root ~/ 10;
      return MathProblem(
        prompt: 'Find √$sq by observation',
        answerType: AnswerType.integer,
        primaryAnswer: '$root',
        hint:
            'Group last 2 digits, find tens digit, compare against $prefix×${prefix + 1}.',
        solutionSteps:
            '1. Group: ${sq ~/ 100} | ${(sq % 100).toString().padLeft(2, '0')}.\n'
            '2. Largest square ≤ ${sq ~/ 100} is $prefix².\n'
            '3. Match ending digit ${sq % 10} against Ekadhika midpoint ($prefix×${prefix + 1}) -> $root.',
      );
    } else {
      int root = _randRange(12, 99);
      int cube = root * root * root;
      return MathProblem(
        prompt: 'Find ∛$cube by observation',
        answerType: AnswerType.integer,
        primaryAnswer: '$root',
        hint: 'Read units digit from last digit (2↔8, 3↔7), cross out 3 digits, floor-cube prefix.',
        solutionSteps:
            '1. Last digit ${cube % 10} -> units digit ${root % 10}.\n'
            '2. Cross out last 3 digits -> left with ${cube ~/ 1000}.\n'
            '3. Largest cube ≤ ${cube ~/ 1000} is ${root ~/ 10}³ -> $root.',
      );
    }
  }

  MathProblem _genDigitSum() {
    int a = _randRange(123, 9876);
    int b = _randRange(123, 9876);
    int dsA = _digitSum(a);
    int dsB = _digitSum(b);
    int ans = _digitSum(dsA * dsB);
    return MathProblem(
      prompt: 'Find the single-digit Digit Sum (Beejank) of:\n$a × $b',
      answerType: AnswerType.integer,
      primaryAnswer: '$ans',
      hint: 'Find DS($a) and DS($b) first, multiply them, and reduce.',
      solutionSteps:
          '1. DS($a) = $dsA, DS($b) = $dsB.\n'
          '2. $dsA × $dsB = ${dsA * dsB} -> Digit Sum = $ans.',
    );
  }
}
