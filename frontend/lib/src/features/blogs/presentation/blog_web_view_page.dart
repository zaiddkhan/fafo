import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:fafu/src/core/config/app_config.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/blogs/domain/blog.dart';

/// In-app reader for a City Read. Loads the public web article
/// (`/read/:city/:id`) in a WebView so the app reuses the site's rendering and
/// styling rather than duplicating a native Markdown view.
class BlogWebViewPage extends StatefulWidget {
  const BlogWebViewPage({super.key, required this.blog});

  final BlogResponse blog;

  /// Public permalink for [blog] on the marketing site. `embed=1` tells the
  /// web reader to hide the site header/footer for a clean in-app surface.
  static Uri urlFor(BlogResponse blog) {
    final base = AppConfig.publicWebBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse(
      '$base/read/${Uri.encodeComponent(blog.city)}/${blog.id}?embed=1',
    );
  }

  @override
  State<BlogWebViewPage> createState() => _BlogWebViewPageState();
}

class _BlogWebViewPageState extends State<BlogWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bgPrimary)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _failed = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            // Only surface main-frame failures; sub-resource errors (a missing
            // image, an analytics beacon) shouldn't blank the whole page.
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
        ),
      )
      ..loadRequest(BlogWebViewPage.urlFor(widget.blog));
  }

  void _reload() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _controller.loadRequest(BlogWebViewPage.urlFor(widget.blog));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          widget.blog.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          if (!_failed)
            WebViewWidget(
              controller: _controller,
              // Give the WebView an eager vertical-drag recognizer so it owns
              // vertical scroll directly instead of routing every drag/fling
              // through Flutter's gesture arena. Under Android Hybrid
              // Composition the arena round-trip adds per-frame latency, which
              // is what made this reader feel choppy versus native Flutter
              // scroll views elsewhere in the app.
              gestureRecognizers: {
                Factory<VerticalDragGestureRecognizer>(
                  VerticalDragGestureRecognizer.new,
                ),
              },
            ),
          if (_loading && !_failed)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary),
            ),
          if (_failed) _BlogWebViewError(onRetry: _reload),
        ],
      ),
    );
  }
}

class _BlogWebViewError extends StatelessWidget {
  const _BlogWebViewError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load this read",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
