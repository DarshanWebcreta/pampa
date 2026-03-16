import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum NavAction {
  push,
  go,
  replace,
  pop,
  popUntilRoot,
  clearStack,
}

class NavService {
  static void navigate({
    required BuildContext context,
    required String routeName,
    NavAction action = NavAction.push,
    dynamic extra,
  }) {
    switch (action) {
      case NavAction.push:
        context.pushNamed(routeName, extra: extra);
        break;

      case NavAction.go:
        context.goNamed(routeName, extra: extra);
        break;

      case NavAction.replace:
        context.pushReplacementNamed(routeName, extra: extra);
        break;

      case NavAction.pop:
        context.pop();
        break;

      case NavAction.popUntilRoot:
        while (context.canPop()) context.pop();
        break;

      case NavAction.clearStack:
        context.goNamed(routeName, extra: extra);
        break;
    }
  }
}

