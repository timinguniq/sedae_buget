import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/domain/domain.dart';
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

/// 변경 뒤 서버의 장부가 바뀌었을 수 있는가: 성공했거나, 시간 초과라 서버에서 바뀌었는지 모를 때.
/// 연결이 안 됐거나 서버가 거절했으면 바뀐 것이 없다(다시 읽어도 같고, 연결이 안 되면 뒤 화면까지 실패로 바뀐다).
bool _mayHaveChanged(Result<Object?> res) {
  final reason = res.failureOrNull?.reason;
  return reason == null || reason == FailureReason.timeout;
}

/// 보고 있는 달. 모든 탭이 함께 본다. 이번 달보다 뒤로, 2020년 1월보다 앞으로는 가지 않는다(규칙은 [YearMonth]).
class SelectedMonthNotifier extends Notifier<YearMonth> {
  @override
  YearMonth build() => YearMonth.of(today);

  /// 오늘. 이 viewmodel은 시계를 여기서만 읽는다. 화면은 시계를 직접 읽지 않고, 오늘이 필요한 규칙에 이 값을 넘긴다.
  /// 부를 때마다 읽으므로 자정을 넘겨도 새 오늘이다. 다만 보고 있는 달은 처음 만들 때 한 번 정하므로,
  /// 앱을 켜 둔 채 달이 바뀌면 보고 있는 달과 그 이름은 새 달로 바뀌지 않는다.
  DateTime get today => DateTime.now();

  /// 다음 달로 갈 수 있는가(보고 있는 달이 이번 달보다 앞이다).
  bool get canGoNext => state.canGoNext(today);

  /// 이전 달로 갈 수 있는가(보고 있는 달이 하한보다 뒤다).
  bool get canGoPrevious => state.canGoPrevious;

  void prev() {
    if (canGoPrevious) state = state.previous;
  }

  void next() {
    if (canGoNext) state = state.next;
  }
}

/// 장부가 보여줄 달.
final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, YearMonth>(SelectedMonthNotifier.new);

class MonthlyTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  TransactionRepository get _transactions => ref.read(transactionRepositoryProvider);

  @override
  Future<List<Transaction>> build() async {
    final month = ref.watch(selectedMonthProvider);
    if (!await _signedIn(ref)) return const [];
    return (await _transactions.getRange(month.start, month.end)).unwrap();
  }

  /// 새 거래의 초안. 보고 있는 달에 적는다(지난 달을 보며 추가하면 그 달의 거래다. 날짜는 [YearMonth.draftDate]).
  TransactionDraft newDraft() {
    final today = ref.read(selectedMonthProvider.notifier).today;
    return TransactionDraft.create(ref.read(selectedMonthProvider).draftDate(today));
  }

  /// [tx]를 고치는 초안. 카테고리는 지금 아는 사용자 카테고리([categoryCatalogProvider])로 판정한다.
  TransactionDraft editDraft(Transaction tx) => TransactionDraft.edit(tx, ref.read(categoryCatalogProvider));

  /// 변경 메서드는 서버 결과를 그대로 돌려준다. 실패를 호출부가 보고 문구를 띄운다.
  ///
  /// 입력한 거래를 저장한다(새 거래면 추가, 아니면 수정). 사용자 카테고리는 다 불러온 목록으로
  /// 판정한다 — 방금 만든 카테고리는 그대로, 지워진 카테고리는 기본 분류로.
  /// 목록을 읽지 못하면 저장을 막지 않고 고른 그대로 저장한다.
  Future<Result<Transaction>> save(TransactionDraft draft) async {
    final catalog = await _catalogToSave();
    return _apply(() => _transactions.upsert(draft.toTransaction(catalog)));
  }

  /// 저장할 때의 카탈로그. 목록을 읽는 중이면 다 읽을 때까지 기다리고, 읽지 못하면 모른다.
  Future<CategoryCatalog> _catalogToSave() async {
    try {
      return CategoryCatalog(await ref.read(customCategoriesProvider.future));
    } catch (_) {
      return const CategoryCatalog.unknown();
    }
  }

  Future<Result<Transaction>> delete(Transaction tx) => _apply(() => _transactions.delete(tx));

  /// 불러오기에 실패한 달 화면의 '다시 시도'(`LoadErrorView`). 달 화면이 읽는 서버 데이터
  /// (이달 거래·추이·사용자 카테고리·또래 통계·세대별 평균)를 모두 다시 읽는다.
  void reload() {
    ref.invalidateSelf();
    ref.invalidate(selfTrendProvider);
    ref.invalidate(customCategoriesProvider);
    ref.invalidate(peerStatsProvider);
    ref.invalidate(generationAvgProvider);
  }

  /// 거래가 바뀌었을 수 있으면 이달 거래와 추이를 다시 읽는다.
  Future<Result<Transaction>> _apply(Future<Result<Transaction>> Function() run) async {
    final res = await run();
    if (_mayHaveChanged(res)) {
      ref.invalidateSelf();
      ref.invalidate(selfTrendProvider);
    }
    return res;
  }
}

final monthlyTransactionsProvider =
    AsyncNotifierProvider<MonthlyTransactionsNotifier, List<Transaction>>(
        MonthlyTransactionsNotifier.new);

/// 보고 있는 달까지 최근 6개월 지출 추이(오래된 달 → 보고 있는 달). 규칙은 [SpendingTrend].
final selfTrendProvider = FutureProvider<List<MonthExpense>>((ref) async {
  final trend = SpendingTrend.ending(ref.watch(selectedMonthProvider));
  final transactions = ref.watch(transactionRepositoryProvider);
  // 실패를 빈 목록으로 감추면 "지출 0"인 평탄한 추이로 보인다. 그대로 드러낸다.
  final txs = await _signedIn(ref)
      ? (await transactions.getRange(trend.start, trend.end)).unwrap()
      : const <Transaction>[];
  return trend.of(txs);
});

/// 보고 있는 달의 장부(합계·분류·소득·저축률). 이달 거래를 못 읽으면 오류고,
/// 사용자 카테고리를 못 읽으면 기본 분류로만 판정한다(합계는 그대로).
final viewedMonthProvider = Provider<AsyncValue<ViewedMonth>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final txs = ref.watch(monthlyTransactionsProvider);
  final catalog = ref.watch(categoryCatalogProvider);
  final profileIncome = ref.watch(userProfileProvider).value?.monthlyIncome;
  return txs.whenData((txs) => ViewedMonth(
        month: month,
        transactions: txs,
        catalog: catalog,
        profileIncome: profileIncome,
      ));
});

/// 보고 있는 달을 화면에서 부르는 이름([YearMonth.name]). 오늘은 [SelectedMonthNotifier.today]로 읽어 화면이 시계를 모르게 한다.
final viewedMonthNameProvider = Provider<String>((ref) =>
    ref.watch(selectedMonthProvider).name(ref.read(selectedMonthProvider.notifier).today));

/// 사용자가 만든 카테고리 목록(서버). 기본 분류([BudgetCategory])는 계약 상수라 여기 없다.
///
/// 변경 메서드는 서버 결과를 그대로 돌려준다. 이름 중복·길이처럼 사용자가 바로 고칠 수 있는
/// 오류라 화면에서 문구를 보여주고, 성공하면 만들어진 카테고리를 호출부가 이어서 쓴다.
class CustomCategoriesNotifier extends AsyncNotifier<List<CustomCategory>> {
  CategoryRepository get _categories => ref.read(categoryRepositoryProvider);

  @override
  Future<List<CustomCategory>> build() async {
    if (!await _signedIn(ref)) return const [];
    return (await _categories.getAll()).unwrap();
  }

  /// 입력한 카테고리를 저장한다(새 카테고리면 추가, 아니면 수정). 같은 초안은 몇 번 저장해도 카테고리 하나다.
  Future<Result<CustomCategory>> save(CategoryDraft draft) =>
      _apply(() => _categories.upsert(draft.toCategory()));

  Future<Result<CustomCategory>> remove(CustomCategory category) =>
      _apply(() => _categories.delete(category));

  /// 카테고리가 바뀌었을 수 있으면 카테고리와 이달 거래를 다시 읽는다. 서버는 지운 카테고리의 거래를
  /// 기본 분류로 되돌리고, 상위 분류를 바꾸면 거래를 새 분류로 옮긴다. 추이는 금액만 보므로 그대로 둔다.
  Future<Result<CustomCategory>> _apply(
      Future<Result<CustomCategory>> Function() run) async {
    final res = await run();
    if (_mayHaveChanged(res)) {
      ref.invalidateSelf();
      ref.invalidate(monthlyTransactionsProvider);
    }
    return res;
  }
}

final customCategoriesProvider =
    AsyncNotifierProvider<CustomCategoriesNotifier, List<CustomCategory>>(
        CustomCategoriesNotifier.new);

/// 화면이 거래의 카테고리를 판정할 카탈로그. 사용자 카테고리 목록을 아직 읽지 못했으면(읽는 중·실패)
/// 모른다([CategoryCatalog.unknown]). 다시 읽는 동안에는 앞서 읽은 목록을 쓴다.
final categoryCatalogProvider = Provider<CategoryCatalog>((ref) {
  final customs = ref.watch(customCategoriesProvider).value;
  return customs == null ? const CategoryCatalog.unknown() : CategoryCatalog(customs);
});
