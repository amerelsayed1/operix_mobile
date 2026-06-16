// General Ledger domain models — the offline mirror of the cloud's GL core
// (gl_accounts, journal_entries, journal_entry_lines). Kept free of Flutter /
// database imports. Monetary amounts use [Money] (decimal(15,2)), never double.

import 'value_objects/money.dart';

/// The five IFRS/GAAP account classifications.
enum GlAccountType { asset, liability, equity, revenue, expense }

extension GlAccountTypeX on GlAccountType {
  String get wire => name; // asset | liability | equity | revenue | expense

  /// The conventional normal balance for this type.
  NormalBalance get normalBalance {
    switch (this) {
      case GlAccountType.asset:
      case GlAccountType.expense:
        return NormalBalance.debit;
      case GlAccountType.liability:
      case GlAccountType.equity:
      case GlAccountType.revenue:
        return NormalBalance.credit;
    }
  }

  static GlAccountType fromWire(String value) => GlAccountType.values
      .firstWhere((t) => t.name == value, orElse: () => GlAccountType.asset);
}

/// Whether an account/line increases on the debit or the credit side.
enum NormalBalance { debit, credit }

extension NormalBalanceX on NormalBalance {
  String get wire => name; // debit | credit
  static NormalBalance fromWire(String value) => NormalBalance.values
      .firstWhere((b) => b.name == value, orElse: () => NormalBalance.debit);
}

/// A node in the chart of accounts.
class GlAccount {
  const GlAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.accountType,
    required this.normalBalance,
    this.nameAr,
    this.parentId,
    this.isActive = true,
    this.isSystem = false,
    this.isCogs = false,
    this.allowsManualPosting = true,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String? nameAr;
  final GlAccountType accountType;
  final NormalBalance normalBalance;
  final int? parentId;
  final bool isActive;
  final bool isSystem;
  final bool isCogs;
  final bool allowsManualPosting;
  final String? description;
}

/// Lifecycle of a journal entry. Posted entries are immutable; corrections are
/// made by posting a reversing entry, never by editing.
enum JournalEntryStatus { draft, posted, reversed }

extension JournalEntryStatusX on JournalEntryStatus {
  String get wire => name; // draft | posted | reversed
  static JournalEntryStatus fromWire(String value) =>
      JournalEntryStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => JournalEntryStatus.draft,
      );
}

/// One side of a journal entry: a debit or a credit to a GL account. The
/// [amount] is always positive; direction is carried by [lineType].
class JournalEntryLine {
  const JournalEntryLine({
    required this.glAccountId,
    required this.lineType,
    required this.amount,
    this.id,
    this.description,
  });

  final int? id;
  final int glAccountId;
  final NormalBalance lineType; // debit | credit
  final Money amount;
  final String? description;

  bool get isDebit => lineType == NormalBalance.debit;
  bool get isCredit => lineType == NormalBalance.credit;
}

/// A balanced set of debit/credit lines posted (or pending) to the ledger.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.referenceNo,
    required this.status,
    required this.transactionDate,
    required this.lines,
    this.sourceType,
    this.sourceId,
    this.entryType,
    this.description,
    this.postedAt,
    this.currencyCode,
    this.exchangeRate,
    this.createdBy,
    this.reversedEntryId,
    this.notes,
  });

  final int id;
  final String referenceNo;
  final String? sourceType;
  final int? sourceId;
  final String? entryType;
  final String? description;
  final DateTime transactionDate;
  final DateTime? postedAt;
  final JournalEntryStatus status;
  final String? currencyCode;
  final String? exchangeRate;
  final int? createdBy;
  final int? reversedEntryId;
  final String? notes;
  final List<JournalEntryLine> lines;

  bool get isPosted => status == JournalEntryStatus.posted;

  Money get totalDebit =>
      sumMoney(lines.where((l) => l.isDebit).map((l) => l.amount));

  Money get totalCredit =>
      sumMoney(lines.where((l) => l.isCredit).map((l) => l.amount));

  /// True when debits equal credits (the fundamental ledger invariant).
  bool get isBalanced => totalDebit.rounded() == totalCredit.rounded();
}

/// A single debit or credit instruction handed to the posting engine. Mirrors
/// the line shape `JournalService::post` accepts in the cloud.
class PostingLine {
  const PostingLine({
    required this.glAccountId,
    required this.lineType,
    required this.amount,
    this.description,
  });

  final int glAccountId;
  final NormalBalance lineType;
  final Money amount;
  final String? description;
}
