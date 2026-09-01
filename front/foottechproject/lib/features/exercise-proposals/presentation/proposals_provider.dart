import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/proposal_model.dart';
import '../data/proposals_repository.dart';

final proposalsRepositoryProvider = Provider<ProposalsRepository>((ref) {
  return ProposalsRepository(client: ref.watch(apiClientProvider));
});

final pendingProposalsProvider = FutureProvider.autoDispose<List<ExerciseProposal>>((ref) {
  return ref.watch(proposalsRepositoryProvider).list(status: 'PENDING');
});
