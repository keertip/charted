/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

abstract class CartesianRendererBase implements CartesianRenderer {
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  CartesianArea area;
  ChartSeries series;
  ChartTheme theme;
  ChartState state;
  Rect rect;

  Element host;
  Selection root;
  SelectionScope scope;

  StreamController<ChartEvent> mouseOverController;
  StreamController<ChartEvent> mouseOutController;
  StreamController<ChartEvent> mouseClickController;

  void _ensureAreaAndSeries(CartesianArea area, ChartSeries series) {
    assert(area != null && series != null);
    assert(this.area == null || this.area == area);
    if (this.area == null) {
      if (area.state != null) {
        this.state = area.state;
        _disposer.add(this.state.changes.listen(handleStateChanges));
      }
    }
    this.area = area;
    this.series = series;
  }

  void _ensureReadyToDraw(Element element) {
    assert(series != null && area != null);
    assert(element != null && element is GElement);

    if (scope == null) {
      host = element;
      scope = new SelectionScope.element(element);
      root = scope.selectElements([host]);
    }

    theme = area.theme;
    rect = area.layout.renderArea;
  }

  /// Override this method to handle state changes.
  void handleStateChanges(List<ChangeRecord> changes) {
    for (int i = 0; i < series.measures.length; ++i) {
      var column = series.measures.elementAt(i),
          selection = getSelectionForColumn(column),
          color = colorForKey(measure:column),
          filter = filterForKey(measure:column);

      selection.attr('filter', filter);
      selection.transition()
        ..style('fill', color)
        ..style('stroke', color)
        ..duration(50);
    }
  }

  Selection getSelectionForColumn(int column);

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.row-group').remove();
  }

  @override
  Extent get extent {
    assert(series != null && area != null);
    var rows = area.data.rows,
    max = rows.isEmpty ? 0 : rows[0][series.measures.first],
    min = max;

    rows.forEach((row) {
      series.measures.forEach((idx) {
        if (row[idx] > max) max = row[idx];
        if (row[idx] < min) min = row[idx];
      });
    });
    return new Extent(min, max);
  }

  @override
  Stream<ChartEvent> get onValueMouseOver {
    if (mouseOverController == null) {
      mouseOverController = new StreamController.broadcast(sync: true);
    }
    return mouseOverController.stream;
  }

  @override
  Stream<ChartEvent> get onValueMouseOut {
    if (mouseOutController == null) {
      mouseOutController = new StreamController.broadcast(sync: true);
    }
    return mouseOutController.stream;
  }

  @override
  Stream<ChartEvent> get onValueClick {
    if (mouseClickController == null) {
      mouseClickController = new StreamController.broadcast(sync: true);
    }
    return mouseClickController.stream;
  }

  double get bandInnerPadding => 1.0;
  double get bandOuterPadding => area.theme.dimensionAxisTheme.axisOuterPadding;

  /// Get a color using the theme's ordinal scale of colors
  String colorForKey({int index, int measure}) {
    int column = measure == null ? series.measures.elementAt(index) : measure;

    // Color state for legend hover and select.
    var colState = state.selection.isEmpty
        ? ChartTheme.STATE_NORMAL
        : state.selection.contains(column)
            ? ChartTheme.STATE_NORMAL
            : ChartTheme.STATE_DISABLED;

    // Preview color get's applied only when there is no selection
    return theme.getColorForKey(column,
        state.preview == column && state.selection.isEmpty
            ? ChartTheme.STATE_ACTIVE
            : colState);
  }

  String filterForKey({int index, int measure}) {
    int column = measure == null ? series.measures.elementAt(index) : measure;
    return theme.getFilterForKey(column,
        state.preview == column || state.selection.contains(column)
            ? ChartTheme.STATE_ACTIVE
            : ChartTheme.STATE_NORMAL);
  }
}