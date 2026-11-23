import '../models/vedic_models.dart';

const List<VedicItem> vedicCatalog = [
  // ========================
  // THE 16 MAIN SUTRAS
  // ========================
  VedicItem(
    id: 's1',
    number: 1,
    sanskritName: 'Ekadhikena Purvena',
    translation: 'By one more than the previous one',
    category: VedicCategory.sutra,
    summary:
        'Squaring numbers ending in 5 and computing special unit fractions.',
    theory: 'To square any number ending in 5 (written as A5), multiply the prefix A by (A + 1), then append 25 to the right. Algebraically: (10A + 5)² = 100·A(A + 1) + 25.',
    examples: [
      VedicExample(
        problem: '75²',
        steps: 'Prefix is 7. Multiply 7 × (7 + 1) = 7 × 8 = 56. Append 25.',
        answer: '5625',
      ),
      VedicExample(
        problem: '115²',
        steps: 'Prefix is 11. Multiply 11 × 12 = 132. Append 25.',
        answer: '13225',
      ),
    ],
  ),
  VedicItem(
    id: 's2',
    number: 2,
    sanskritName: 'Nikhilam Navatashcaramam Dashatah',
    translation: 'All from 9 and the last from 10',
    category: VedicCategory.sutra,
    summary: 'Instant subtraction from powers of 10 and finding complements.',
    theory: 'When subtracting any number from a power of 10 (100, 1000, 10000...), subtract every digit from 9 and the final non-zero digit from 10, working left to right without borrowing.',
    examples: [
      VedicExample(
        problem: '1000 - 467',
        steps: '(9 - 4) | (9 - 6) | (10 - 7) = 5 | 3 | 3',
        answer: '533',
      ),
      VedicExample(
        problem: '10000 - 384',
        steps: 'Pad as 0384: (9 - 0)(9 - 3)(9 - 8)(10 - 4)',
        answer: '9616',
      ),
    ],
  ),
  VedicItem(
    id: 's3',
    number: 3,
    sanskritName: 'Urdhva-Tiryagbhyam',
    translation: 'Vertically and crosswise',
    category: VedicCategory.sutra,
    summary: 'Universal one-line multiplication for any pair of numbers.',
    theory: 'For 2-digit numbers (ab × cd), compute three compartments right-to-left: (b×d), then crosswise (a×d + b×c), then (a×c), carrying tens leftward. The pattern scales symmetrically to 3-digit numbers (1, 2, 3, 2, 1 products).',
    examples: [
      VedicExample(
        problem: '43 × 26',
        steps: 'Units: 3×6=18 (8, c1). Cross: 4×6 + 3×2 + 1 = 31 (1, c3). Left: 4×2 + 3 = 11.',
        answer: '1118',
      ),
    ],
  ),
  VedicItem(
    id: 's4',
    number: 4,
    sanskritName: 'Paravartya Yojayet',
    translation: 'Transpose and adjust',
    category: VedicCategory.sutra,
    summary: 'Fast division when the divisor is just above a power of 10.',
    theory: 'For divisors slightly above 10 or 100 (like 12 or 113), negate (transpose) the excess digits. Partition the dividend on the right by the number of base zeros, bring down the first digit, multiply by the transposed digits, and add diagonally.',
    examples: [
      VedicExample(
        problem: '1358 ÷ 113',
        steps: 'Base 100, excess +13 -> transpose (-1, -3). Bring down 1 -> -1, -3. Col 2: 3-1=2 -> -2, -6. Rem: (5-3-2)(8-6) = 02.',
        answer: 'Q = 12, R = 2',
      ),
    ],
  ),
  VedicItem(
    id: 's5',
    number: 5,
    sanskritName: 'Shunyam Samyasamuccaye',
    translation: 'When the sum is the same, that sum is zero',
    category: VedicCategory.sutra,
    summary: 'Solving special fractional and linear equations by inspection.',
    theory: 'In equations of the form 1/(x - a) + 1/(x - b) = 1/(x - c) + 1/(x - d), if the sum of the denominators on both sides is identical (i.e., a + b = c + d), then setting that common sum (2x - a - b) = 0 immediately yields x = (a + b) / 2.',
    examples: [
      VedicExample(
        problem: '1/(x - 2) + 1/(x - 8) = 1/(x - 3) + 1/(x - 7)',
        steps: 'Sum on both sides is 2x - 10. Set 2x - 10 = 0.',
        answer: 'x = 5',
      ),
    ],
  ),
  VedicItem(
    id: 's6',
    number: 6,
    sanskritName: 'Anurupye Shunyamanyat',
    translation: 'If one is in ratio, the other is zero',
    category: VedicCategory.sutra,
    summary: 'Instant solution to simultaneous equations with proportional coefficients.',
    theory: 'In a system ax + by = c₁ and dx + ey = c₂, if the coefficients of y are in the exact same ratio as the constants (b/e = c₁/c₂), then x = 0 and y = c₁/b immediately.',
    examples: [
      VedicExample(
        problem: '3x + 7y = 14 and 9x + 14y = 28',
        steps: 'Ratio of y-terms (7:14 = 1:2) equals ratio of constants (14:28 = 1:2). Thus x = 0, and 7y = 14.',
        answer: 'x = 0, y = 2',
      ),
    ],
  ),
  VedicItem(
    id: 's7',
    number: 7,
    sanskritName: 'Sankalana-Vyavakalanabhyam',
    translation: 'By addition and by subtraction',
    category: VedicCategory.sutra,
    summary:
        'Solving simultaneous equations with swapped x and y coefficients.',
    theory: 'When equations have the form ax + by = c₁ and bx + ay = c₂, add them to find (x + y) and subtract them to find (x - y). Adding and halving those two simple results yields x and y mentally.',
    examples: [
      VedicExample(
        problem: '27x + 19y = 111 and 19x + 27y = 119',
        steps: 'Add: 46(x+y)=230 -> x+y=5. Subtract: 8(x-y)=-8 -> x-y=-1. Thus 2x=4.',
        answer: 'x = 2, y = 3',
      ),
    ],
  ),
  VedicItem(
    id: 's8',
    number: 8,
    sanskritName: 'Puranapuranabhyam',
    translation: 'By the completion or non-completion',
    category: VedicCategory.sutra,
    summary: 'Mental addition by spotting pairs that complete multiples of 10.',
    theory: 'Instead of adding strictly left-to-right in order, group numbers whose units digits complete a multiple of 10 (e.g., 37 + 23 = 60), then add the remaining numbers cleanly.',
    examples: [
      VedicExample(
        problem: '48 + 37 + 22',
        steps: 'Group (48 + 22) = 70. Then 70 + 37 = 107.',
        answer: '107',
      ),
    ],
  ),
  VedicItem(
    id: 's9',
    number: 9,
    sanskritName: 'Chalana-Kalanabhyam',
    translation: 'Differences and similarities',
    category: VedicCategory.sutra,
    summary: 'Calculus-style rate of change and evaluating derivatives of quadratics.',
    theory: 'Used in Swami Tirtha’s text to connect algebraic differences with derivatives. For f(x) = ax² + bx + c, the first derivative (instantaneous rate of change) is f\'(x) = 2ax + b.',
    examples: [
      VedicExample(
        problem: 'Find f\'(3) for f(x) = 4x² + 5x + 7',
        steps: 'f\'(x) = 2(4)x + 5 = 8x + 5. At x = 3: 8(3) + 5 = 29.',
        answer: '29',
      ),
    ],
  ),
  VedicItem(
    id: 's10',
    number: 10,
    sanskritName: 'Yavadunam',
    translation: 'Whatever the extent of its deficiency',
    category: VedicCategory.sutra,
    summary: 'Rapid squaring and cubing of numbers close to a base.',
    theory: 'For a number N = B + d near base B: N² = (N + d) | d², and N³ = (N + 2d) | 3d² | d³. Each right-hand compartment holds as many digits as zeros in base B.',
    examples: [
      VedicExample(
        problem: '103³',
        steps:
            'Base 100, d = +3. Left: 103 + 6 = 109. Mid: 3(9) = 27. Right: 27.',
        answer: '1092727',
      ),
    ],
  ),
  VedicItem(
    id: 's11',
    number: 11,
    sanskritName: 'Vyashtisamashtih',
    translation: 'Part and whole',
    category: VedicCategory.sutra,
    summary:
        'Computing averages mentally using deviations from an assumed base.',
    theory: 'To average numbers clustered near a clean number B (the whole), sum their positive and negative deviations (the parts), divide the net deviation by the count, and add to B.',
    examples: [
      VedicExample(
        problem: 'Average of 98, 103, 97, 105, 102',
        steps: 'Assume B = 100. Deviations: -2 + 3 - 3 + 5 + 2 = +5. 5 ÷ 5 = +1. 100 + 1 = 101.',
        answer: '101',
      ),
    ],
  ),
  VedicItem(
    id: 's12',
    number: 12,
    sanskritName: 'Shesanyankena Charamena',
    translation: 'The remainders by the last digit',
    category: VedicCategory.sutra,
    summary: 'Generating decimal digits of fractions ending in 9 (e.g., 1/19, 1/29).',
    theory: 'To convert a/19 or a/29 into decimal digits, use the Ekadhika multiplier (2 for 19, 3 for 29). Working left-to-right: divide numerator by the Ekadhika to get the digit and remainder, then prepend the remainder to the next digit.',
    examples: [
      VedicExample(
        problem: '3rd decimal digit of 1/19',
        steps: '1/19 = 0.05263... (Using multiplier 2: 0.0 -> 5 -> 2).',
        answer: '2',
      ),
    ],
  ),
  VedicItem(
    id: 's13',
    number: 13,
    sanskritName: 'Sopantyadvayamantyam',
    translation: 'The ultimate and twice the penultimate',
    category: VedicCategory.sutra,
    summary: 'Multiplying any number by 12 mentally in one pass.',
    theory: 'Imagine a 0 at both ends of the number. Working right to left, take twice each digit and add its right-hand neighbor ("twice the penultimate plus the ultimate"), carrying tens forward.',
    examples: [
      VedicExample(
        problem: '324 × 12',
        steps: '0 3 2 4 0 -> 2(4)+0=8 | 2(2)+4=8 | 2(3)+2=8 | 2(0)+3=3',
        answer: '3888',
      ),
    ],
  ),
  VedicItem(
    id: 's14',
    number: 14,
    sanskritName: 'Ekanyunena Purvena',
    translation: 'By one less than the previous one',
    category: VedicCategory.sutra,
    summary: 'Instant multiplication by 9, 99, 999, or 9999.',
    theory: 'When multiplying N by an equal (or greater) string of 9s: Left side = N - 1. Right side = Nikhilam complement of N (padded with leading zeros if the multiplier has more 9s).',
    examples: [
      VedicExample(
        problem: '674 × 999',
        steps: 'Left: 674 - 1 = 673. Right: Complement of 674 = 326.',
        answer: '673326',
      ),
    ],
  ),
  VedicItem(
    id: 's15',
    number: 15,
    sanskritName: 'Gunitasamuccayah',
    translation: 'The product of the sum equals the sum of the products',
    category: VedicCategory.sutra,
    summary:
        'Checking polynomial products by summing coefficients (setting x = 1).',
    theory: 'In any polynomial product (ax + b)(cx + d) = Px² + Qx + R, substituting x = 1 proves that (a + b)(c + d) = P + Q + R.',
    examples: [
      VedicExample(
        problem: 'Sum of coefficients of (2x + 3)(4x - 1)',
        steps: '(2 + 3) × (4 - 1) = 5 × 3 = 15.',
        answer: '15',
      ),
    ],
  ),
  VedicItem(
    id: 's16',
    number: 16,
    sanskritName: 'Gunakasamuccayah',
    translation: 'The factors of the sum equal the sum of the factors',
    category: VedicCategory.sutra,
    summary: 'Verifying algebraic factorizations via factor sums.',
    theory: 'If ax² + bx + c factors into (px + q)(rx + s), then the sum of the coefficients (a + b + c) must equal (p + q)(r + s).',
    examples: [
      VedicExample(
        problem: 'If 2x² + 7x + 3 = (2x + 1)(x + k), find (2 + 1)(1 + k)',
        steps: 'Sum of quadratic coefficients = 2 + 7 + 3 = 12.',
        answer: '12',
      ),
    ],
  ),

  // ========================
  // THE 13 SUB-SUTRAS
  // ========================
  VedicItem(
    id: 'ss1',
    number: 1,
    sanskritName: 'Anurupyena',
    translation: 'Proportionately',
    category: VedicCategory.subSutra,
    summary: 'Working-base multiplication near 50, 200, or 300.',
    theory: 'When numbers are near 50 (100 ÷ 2) or 200 (100 × 2), perform Nikhilam base multiplication using deviations from the working base, then scale the left compartment by the same ratio (÷ 2 or × 2).',
    examples: [
      VedicExample(
        problem: '204 × 207',
        steps:
            'Working base 200 (2×100). Left: (204+7)×2 = 422. Right: 4×7 = 28.',
        answer: '42228',
      ),
    ],
  ),
  VedicItem(
    id: 'ss2',
    number: 2,
    sanskritName: 'Sisyate Sesasamjnah',
    translation: 'The remainder remains constant',
    category: VedicCategory.subSutra,
    summary: 'Evaluating polynomial remainders upon division by (x - k).',
    theory: 'By the Remainder Theorem, when a polynomial P(x) = ax² + bx + c is divided by (x - k), the remainder is simply P(k) = ak² + bk + c.',
    examples: [
      VedicExample(
        problem: 'Remainder of (2x² + 3x + 5) ÷ (x - 2)',
        steps: 'Evaluate at x = 2: 2(4) + 3(2) + 5 = 8 + 6 + 5 = 19.',
        answer: '19',
      ),
    ],
  ),
  VedicItem(
    id: 'ss3',
    number: 3,
    sanskritName: 'Adyamadyenantya-mantyena',
    translation: 'The first by the first and the last by the last',
    category: VedicCategory.subSutra,
    summary: 'Deducing missing terms in quadratic factorizations.',
    theory: 'In (px + q)(rx + s) = ax² + bx + c, the first term comes purely from p·r = a and the constant term purely from q·s = c.',
    examples: [
      VedicExample(
        problem: 'If 6x² + 19x + 15 = (2x + 3)(3x + k), find k',
        steps: 'Last by last: 3 × k = 15 -> k = 5.',
        answer: '5',
      ),
    ],
  ),
  VedicItem(
    id: 'ss4',
    number: 4,
    sanskritName: 'Kevalaih Saptakam Gunyat',
    translation: 'For 7, the multiplicand is 143',
    category: VedicCategory.subSutra,
    summary: 'Exploiting 143 × 7 = 1001 for instant mental multiplication.',
    theory: 'Because 143 × 7 = 1001, multiplying 143 by any multiple of 7 (7 × k) gives 1001 × k—which simply writes k twice side-by-side (for 2- or 3-digit k)!',
    examples: [
      VedicExample(
        problem: '143 × 35',
        steps: '35 = 7 × 5. Thus 143 × (7 × 5) = 1001 × 5 = 5005.',
        answer: '5005',
      ),
    ],
  ),
  VedicItem(
    id: 'ss5',
    number: 5,
    sanskritName: 'Vestanam',
    translation: 'By osculation',
    category: VedicCategory.subSutra,
    summary: 'Testing divisibility by 7, 13, and 19 without dividing.',
    theory: 'Use the osculator (+2 for 19, +4 for 13, -2 for 7). Repeatedly peel off the last digit, multiply it by the osculator, and add/subtract from the remaining prefix.',
    examples: [
      VedicExample(
        problem: 'Is 437 divisible by 19?',
        steps: 'Osculator +2: 43 + 2(7) = 57 -> 5 + 2(7) = 19. Yes!',
        answer: 'Yes',
      ),
    ],
  ),
  VedicItem(
    id: 'ss6',
    number: 6,
    sanskritName: 'Yavadunam Tavadunam',
    translation: 'Lessen by the deficiency',
    category: VedicCategory.subSutra,
    summary: 'Multiplying two numbers slightly below a base (e.g., 91–99).',
    theory: 'Cross-subtract one number’s deficiency from the other number for the left side, and multiply the two deficiencies for the right side.',
    examples: [
      VedicExample(
        problem: '94 × 97',
        steps:
            'Deficiencies -6 and -3. Left: 94 - 3 = 91. Right: (-6)(-3) = 18.',
        answer: '9118',
      ),
    ],
  ),
  VedicItem(
    id: 'ss7',
    number: 7,
    sanskritName: 'Yavadunam Tavadunikritya Varganca Yojayet',
    translation: 'Lessen further by the deficiency and set up its square',
    category: VedicCategory.subSutra,
    summary: 'Squaring any number close to 100 or 1000.',
    theory: 'Add the deviation d (positive or negative) to N for the left part, and append d² padded to the number of zeros in the base.',
    examples: [
      VedicExample(
        problem: '93²',
        steps: 'Base 100, d = -7. Left: 93 - 7 = 86. Right: (-7)² = 49.',
        answer: '8649',
      ),
    ],
  ),
  VedicItem(
    id: 'ss8',
    number: 8,
    sanskritName: 'Antyayordashake\'pi',
    translation: 'Last digits totaling 10',
    category: VedicCategory.subSutra,
    summary: 'Multiplying numbers with identical prefixes whose units digits sum to 10.',
    theory: 'Multiply the common prefix P by (P + 1) for the left side, and multiply the two last digits for the 2-digit right side.',
    examples: [
      VedicExample(
        problem: '64 × 66',
        steps: '6 × 7 = 42 | 4 × 6 = 24.',
        answer: '4224',
      ),
    ],
  ),
  VedicItem(
    id: 'ss9',
    number: 9,
    sanskritName: 'Antyayoreva',
    translation: 'Only the last terms',
    category: VedicCategory.subSutra,
    summary: 'Solving proportion equations by cross-balancing terms.',
    theory: 'For equations of the form (x + a) / (x + b) = c / d, cross-multiplying isolates x = (bc - ad) / (d - c).',
    examples: [
      VedicExample(
        problem: '(x + 2) / (x + 5) = 3 / 4',
        steps: '4x + 8 = 3x + 15 -> x = 7.',
        answer: '7',
      ),
    ],
  ),
  VedicItem(
    id: 'ss10',
    number: 10,
    sanskritName: 'Samuccayagunitah',
    translation: 'The sum of the products',
    category: VedicCategory.subSutra,
    summary:
        'Deducing the middle coefficient of a quadratic from coefficient sums.',
    theory: 'Given (ax + b)(cx + d) = Px² + Qx + R, you can find Q without full expansion: Q = (a + b)(c + d) - P - R.',
    examples: [
      VedicExample(
        problem: 'Find Q if (2x + 3)(4x + 5) = 8x² + Qx + 15',
        steps: 'Total sum = (2+3)(4+5) = 45. Q = 45 - 8 - 15 = 22.',
        answer: '22',
      ),
    ],
  ),
  VedicItem(
    id: 'ss11',
    number: 11,
    sanskritName: 'Lopanasthapanabhyam',
    translation: 'By alternate elimination and retention',
    category: VedicCategory.subSutra,
    summary: 'Solving general 2-variable linear systems by eliminating one variable.',
    theory: 'Eliminate y by scaling and subtracting the equations to retain x, then substitute back to find y.',
    examples: [
      VedicExample(
        problem: '2x + y = 7 and 3x - y = 8',
        steps: 'Add to eliminate y: 5x = 15 -> x = 3, y = 1.',
        answer: 'x = 3, y = 1',
      ),
    ],
  ),
  VedicItem(
    id: 'ss12',
    number: 12,
    sanskritName: 'Vilokanam',
    translation: 'By mere observation',
    category: VedicCategory.subSutra,
    summary: 'Mental extraction of exact square roots and cube roots.',
    theory: 'For 6-digit exact cubes: look at the last digit (2↔8, 3↔7, others stay same), cross out the last 3 digits, and take the floor cube root of the prefix. For 4-digit exact squares, narrow down by tens square and compare against the midpoint (Ekadhikena).',
    examples: [
      VedicExample(
        problem: '∛389017',
        steps: 'Ends in 7 -> units 3. Cross out 017 -> 389. 7³=343 ≤ 389 < 8³. Tens 7.',
        answer: '73',
      ),
    ],
  ),
  VedicItem(
    id: 'ss13',
    number: 13,
    sanskritName: 'Gunitasamuccayah Samuccayagunitah',
    translation: 'Product of sums equals sum of products (Digit Sums)',
    category: VedicCategory.subSutra,
    summary:
        'Finding the Digit Sum (Beejank) of a product without multiplying.',
    theory: 'Reduce each factor to its 1-digit Beejank (1–9, casting out 9s), multiply the two single digits, and reduce again to a single digit.',
    examples: [
      VedicExample(
        problem: 'Digit sum of 347 × 86',
        steps: 'DS(347) = 5, DS(86) = 5. 5 × 5 = 25 -> 2 + 5 = 7.',
        answer: '7',
      ),
    ],
  ),
];
