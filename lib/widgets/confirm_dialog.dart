import 'package:flutter/material.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 공용 확인 다이얼로그 헬퍼. 파괴적 액션(연결 해제, 데이터 삭제 등) 앞에서 사용.
///
/// [isDestructive] true 이면 확정 버튼이 [ColorScheme.error] 색으로 강조되고,
/// Cancel 버튼에 `autofocus` 가 걸려 기본 포커스가 안전한 쪽에 놓인다.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = true,
  IconData? icon,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        icon: icon != null
            ? Icon(
                icon,
                color:
                    isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
              )
            : null,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel ?? l10n.cancel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel ?? l10n.commonOk),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
