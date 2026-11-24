import 'dart:convert';

import 'sync_plan_model.dart';
import 'sync_snapshot_model.dart';

/// What the client sends to the host at the end of a sync: its data and the plan both agreed on.
final class SyncEnvelopeModel {
  static const String _snapshotField = 'snapshot';
  static const String _planField = 'plan';

  /// The data of the client.
  final SyncSnapshotModel snapshot;

  /// What to delete and update on the host.
  final SyncPlanModel plan;

  /// Creates a [SyncEnvelopeModel].
  const SyncEnvelopeModel({required this.snapshot, required this.plan});

  /// Reads the JSON text the client sent.
  factory SyncEnvelopeModel.fromJsonText(String text) {
    final Map<String, dynamic> json = jsonDecode(text) as Map<String, dynamic>;
    return SyncEnvelopeModel(
      snapshot: SyncSnapshotModel.fromJson(json[_snapshotField] as Map<String, dynamic>),
      plan: SyncPlanModel.fromJson(json[_planField] as Map<String, dynamic>),
    );
  }

  /// The JSON text to send.
  String toJsonText() => jsonEncode(<String, dynamic>{_snapshotField: snapshot.toJson(), _planField: plan.toJson()});
}
