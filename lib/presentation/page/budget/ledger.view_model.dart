import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/domain/usecase/category_usecase.dart';
import 'package:sedae_budget/domain/usecase/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

// 장부: 로그인 세션에 묶인 가계부 서버 데이터(이달 거래·최근 6개월 추이·사용자 카테고리)와 그 변경.
// 여러 화면이 함께 읽는다.
//
// - 세션이 바뀌면(로그인·로그아웃) 모두 다시 읽는다. 로그인 전에는 서버를 부르지 않고 비어 있다.
// - 변경 뒤 무엇을 다시 읽을지는 여기서만 정한다. 화면은 변경 메서드만 부르고 invalidate하지 않는다.

/// 로그인 중이면 true. 이것을 부른 provider는 세션이 바뀌면 다시 만들어진다.
Future<bool> _signedIn(Ref ref) async => await ref.watch(authProvider.future) != null;

/// 보고 있는 달. 모든 탭이 함께 본다. 이번 달보다 뒤로는 가지 않는다.
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _thisMonth();

  static DateTime _thisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// 보고 있는 달이 이번 달인가.
  bool get isThisMonth => state == _thisMonth();

  /// 다음 달로 갈 수 있는가(보고 있는 달이 이번 달보다 앞이다).
  bool get canGoNext => state.isBefore(_thisMonth());

  void prev() => state = DateTime(state.year, state.month - 1);

  void next() {
    if (canGoNext) state = DateTime(state.year, state.month + 1);
  }
}

/// 장부가 보여줄 달.
final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

class MonthlyTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  TransactionUsecase get _usecase => ref.read(transactionUsecaseProvider);

  @override
  Future<List<Transaction>> build() async {
    final month = ref.watch(selectedMonthProvider);
    if (!await _signedIn(ref)) return const [];
    return (await _usecase.getMonth(month.year, month.month)).unwrap();
  }

  /// 변경 메서드는 서버 결과를 그대로 돌려준다. 실패를 호출부가 보고 문구를 띄운다.
  ///
  /// 입력한 거래를 저장한다(새 거래면 추가, 아니면 수정). 사용자 카테고리는 다 불러온 목록으로
  /// 판정한다 — 방금 만든 카테고리는 그대로, 지워진 카테고리는 기본 분류로.
  /// 목록을 읽지 못하면 저장을 막지 않고 고른 그대로 저장한다.
  Future<Result<Transaction>> save(TransactionDraft draft) async {
    CategoryCatalog? catalog;
    try {
      catalog = CategoryCatalog(await ref.read(customCategoriesProvider.future));
    } catch (_) {
      // catalog == null: 지워졌는지 판정하지 않는다.
    }
    return _apply(() => _usecase.save(draft.toTransaction(catalog)));
  }

  Future<Result<Transaction>> delete(Transaction tx) => _apply(() => _usecase.delete(tx));

  /// 불러오기에 실패한 화면의 '다시 시도'. 달 화면이 읽는 서버 데이터
  /// (이달 거래·추이·사용자 카테고리·또래 통계)를 모두 다시 읽는다.
  void reload() {
    ref.invalidateSelf();
    ref.invalidate(selfTrendProvider);
    ref.invalidate(customCategoriesProvider);
    ref.invalidate(peerStatsProvider);
    ref.invalidate(generationAvgProvider);
  }

  /// 거래가 바뀌면 이달 거래와 추이를 다시 읽는다.
  Future<Result<Transaction>> _apply(Future<Result<Transaction>> Function() run) async {
    final res = await run();
    if (res.failureOrNull == null) {
      ref.invalidateSelf();
      ref.invalidate(selfTrendProvider);
    }
    return res;
  }
}

final monthlyTransactionsProvider =
    AsyncNotifierProvider<MonthlyTransactionsNotifier, List<Transaction>>(
        MonthlyTransactionsNotifier.new);

/// 최근 6개월 자기 지출 추이 (oldest → newest).
final selfTrendProvider =
    FutureProvider<List<({DateTime month, int expense})>>((ref) async {
  final anchor = ref.watch(selectedMonthProvider);
  final usecase = ref.watch(transactionUsecaseProvider);
  const n = 6;
  final start = DateTime(anchor.year, anchor.month - (n - 1));
  final end = DateTime(anchor.year, anchor.month + 1); // exclusive
  // 실패를 빈 목록으로 감추면 "지출 0"인 평탄한 추이로 보인다. 그대로 드러낸다.
  final txs = await _signedIn(ref)
      ? (await usecase.getRange(start, end)).unwrap()
      : const <Transaction>[];
  return List.generate(n, (i) {
    final m = DateTime(anchor.year, anchor.month - (n - 1) + i);
    final expense = ViewedMonth.expenseOf(
        txs.where((t) => t.date.year == m.year && t.date.month == m.month));
    return (month: m, expense: expense);
  });
});

/// 보고 있는 달의 장부(합계·분류·소득·저축률). 이달 거래를 못 읽으면 오류고,
/// 사용자 카테고리를 못 읽으면 기본 분류로만 판정한다(합계는 그대로).
final viewedMonthProvider = Provider<AsyncValue<ViewedMonth>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final txs = ref.watch(monthlyTransactionsProvider);
  final catalog = CategoryCatalog(ref.watch(customCategoriesProvider).value ?? const []);
  final profileIncome = ref.watch(userProfileProvider).value?.monthlyIncome;
  return txs.whenData((txs) => ViewedMonth(
        month: month,
        transactions: txs,
        catalog: catalog,
        profileIncome: profileIncome,
      ));
});

/// 보고 있는 달을 화면에서 부르는 이름: 이번 달이면 '이번 달', 아니면 'M월'.
final viewedMonthNameProvider = Provider<String>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.read(selectedMonthProvider.notifier).isThisMonth ? '이번 달' : '${month.month}월';
});

/// 사용자가 만든 카테고리 목록(서버). 기본 분류([BudgetCategory])는 계약 상수라 여기 없다.
///
/// 변경 메서드는 서버 결과를 그대로 돌려준다. 이름 중복·길이처럼 사용자가 바로 고칠 수 있는
/// 오류라 화면에서 문구를 보여주고, 성공하면 만들어진 카테고리를 호출부가 이어서 쓴다.
class CustomCategoriesNotifier extends AsyncNotifier<List<CustomCategory>> {
  CategoryUsecase get _usecase => ref.read(categoryUsecaseProvider);

  @override
  Future<List<CustomCategory>> build() async {
    if (!await _signedIn(ref)) return const [];
    return (await _usecase.getAll()).unwrap();
  }

  Future<Result<CustomCategory>> add({
    required String name,
    required BudgetCategory base,
  }) =>
      _apply(() => _usecase.add(name: name, base: base));

  Future<Result<CustomCategory>> edit(
    CustomCategory category, {
    required String name,
    required BudgetCategory base,
  }) =>
      _apply(() => _usecase.update(category, name: name, base: base));

  Future<Result<CustomCategory>> remove(CustomCategory category) =>
      _apply(() => _usecase.delete(category));

  /// 카테고리가 바뀌면 카테고리와 이달 거래를 다시 읽는다. 서버는 지운 카테고리의 거래를 기본 분류로
  /// 되돌리고, 상위 분류를 바꾸면 거래를 새 분류로 옮긴다. 추이는 금액만 보므로 그대로 둔다.
  Future<Result<CustomCategory>> _apply(
      Future<Result<CustomCategory>> Function() run) async {
    final res = await run();
    if (res.failureOrNull == null) {
      ref.invalidateSelf();
      ref.invalidate(monthlyTransactionsProvider);
    }
    return res;
  }
}

final customCategoriesProvider =
    AsyncNotifierProvider<CustomCategoriesNotifier, List<CustomCategory>>(
        CustomCategoriesNotifier.new);
