import 'package:flutter/widgets.dart';

typedef RouteHandler =
    Widget Function(BuildContext context, {Map<String, dynamic>? args});

RouteSettings mergeUriToRouteSettings(RouteSettings settings) {
  final name = settings.name ?? '/';
  final uri = Uri.tryParse(name);
  if (uri == null || uri.queryParameters.isEmpty) {
    return settings;
  }

  final args = <String, dynamic>{};
  final rawArgs = settings.arguments;
  if (rawArgs is Map<String, dynamic>) {
    args.addAll(rawArgs);
  }
  args.addAll(uri.queryParameters);

  return RouteSettings(
    name: uri.path.isEmpty ? '/' : uri.path,
    arguments: args,
  );
}
