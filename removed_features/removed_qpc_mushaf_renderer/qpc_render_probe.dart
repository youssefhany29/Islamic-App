import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../data/qpc_reader_perf.dart';

class QpcLayoutPaintProbe extends SingleChildRenderObjectWidget {
  const QpcLayoutPaintProbe({
    super.key,
    required this.label,
    required super.child,
  });

  final String label;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _QpcRenderLayoutPaintProbe(label);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _QpcRenderLayoutPaintProbe).label = label;
  }
}

class _QpcRenderLayoutPaintProbe extends RenderProxyBox {
  _QpcRenderLayoutPaintProbe(this.label);

  String label;
  bool _didLogFirstLayout = false;
  bool _didLogFirstPaint = false;

  @override
  void performLayout() {
    final Stopwatch? stopwatch = QpcReaderPerf.start();
    super.performLayout();

    if (!_didLogFirstLayout) {
      _didLogFirstLayout = true;
      QpcReaderPerf.end('$label first layout', stopwatch);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Stopwatch? stopwatch = QpcReaderPerf.start();
    super.paint(context, offset);

    if (!_didLogFirstPaint) {
      _didLogFirstPaint = true;
      QpcReaderPerf.end('$label first paint', stopwatch);
    }
  }
}
