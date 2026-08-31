import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/scan/data/models/analysis_task_model.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';

void main() {
  group('AnalysisTaskModel.fromJson', () {
    test('parses completed task with camelCase', () {
      final json = {
        'taskId': 'task-abc',
        'status': 'completed',
        'progress': 100,
      };

      final model = AnalysisTaskModel.fromJson(json);

      expect(model.taskId, 'task-abc');
      expect(model.status, AnalysisTaskStatus.completed);
      expect(model.progress, 100);
      expect(model.isCompleted, true);
      expect(model.isFailed, false);
      expect(model.isProcessing, false);
    });

    test('parses task with snake_case task_id', () {
      final json = {
        'task_id': 'task-snake',
        'status': 'queued',
      };

      final model = AnalysisTaskModel.fromJson(json);

      expect(model.taskId, 'task-snake');
      expect(model.status, AnalysisTaskStatus.queued);
    });

    test('parses all status strings', () {
      final statuses = {
        'uploading': AnalysisTaskStatus.uploading,
        'queued': AnalysisTaskStatus.queued,
        'processing_text': AnalysisTaskStatus.processingText,
        'processingText': AnalysisTaskStatus.processingText,
        'processing_source': AnalysisTaskStatus.processingSource,
        'processingSource': AnalysisTaskStatus.processingSource,
        'processing_visual': AnalysisTaskStatus.processingVisual,
        'processingVisual': AnalysisTaskStatus.processingVisual,
        'completed': AnalysisTaskStatus.completed,
        'failed': AnalysisTaskStatus.failed,
        'timeout': AnalysisTaskStatus.timeout,
      };

      for (final entry in statuses.entries) {
        final model = AnalysisTaskModel.fromJson({
          'taskId': 'test',
          'status': entry.key,
        });
        expect(model.status, entry.value,
            reason: 'Status "${entry.key}" should map to ${entry.value}');
      }
    });

    test('defaults unknown status to queued', () {
      final model = AnalysisTaskModel.fromJson({
        'taskId': 'test',
        'status': 'unknown_status',
      });

      expect(model.status, AnalysisTaskStatus.queued);
    });

    test('defaults missing status to queued', () {
      final model = AnalysisTaskModel.fromJson({
        'taskId': 'test',
      });

      expect(model.status, AnalysisTaskStatus.queued);
    });

    test('defaults missing progress to 0', () {
      final model = AnalysisTaskModel.fromJson({
        'taskId': 'test',
        'status': 'queued',
      });

      expect(model.progress, 0);
    });

    test('defaults missing taskId to empty string', () {
      final model = AnalysisTaskModel.fromJson({
        'status': 'queued',
      });

      expect(model.taskId, '');
    });

    test('parses errorMessage', () {
      final model = AnalysisTaskModel.fromJson({
        'taskId': 'test',
        'status': 'failed',
        'errorMessage': 'Out of memory',
      });

      expect(model.errorMessage, 'Out of memory');
      expect(model.isFailed, true);
    });
  });

  group('AnalysisTask entity helpers', () {
    test('isCompleted returns true only for completed status', () {
      const task = AnalysisTask(
        taskId: 'a',
        status: AnalysisTaskStatus.completed,
      );
      expect(task.isCompleted, true);
      expect(task.isFailed, false);
      expect(task.isProcessing, false);
    });

    test('isFailed returns true for failed and timeout', () {
      const failed = AnalysisTask(
        taskId: 'a',
        status: AnalysisTaskStatus.failed,
      );
      const timeout = AnalysisTask(
        taskId: 'a',
        status: AnalysisTaskStatus.timeout,
      );

      expect(failed.isFailed, true);
      expect(timeout.isFailed, true);
    });

    test('isProcessing returns true for non-terminal states', () {
      const processing = AnalysisTask(
        taskId: 'a',
        status: AnalysisTaskStatus.processingText,
      );

      expect(processing.isProcessing, true);
      expect(processing.isCompleted, false);
      expect(processing.isFailed, false);
    });
  });

  group('AnalysisTask equality', () {
    test('equal tasks have same props', () {
      const a = AnalysisTask(taskId: 'a', status: AnalysisTaskStatus.queued);
      const b = AnalysisTask(taskId: 'a', status: AnalysisTaskStatus.queued);
      expect(a, equals(b));
    });

    test('different tasks are not equal', () {
      const a = AnalysisTask(taskId: 'a', status: AnalysisTaskStatus.queued);
      const b =
          AnalysisTask(taskId: 'a', status: AnalysisTaskStatus.completed);
      expect(a, isNot(equals(b)));
    });
  });
}
