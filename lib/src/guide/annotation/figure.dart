import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:graphic/src/util/collection.dart';
import 'package:graphic/src/chart/view.dart';
import 'package:graphic/src/common/intrinsic_layers.dart';
import 'package:graphic/src/coord/coord.dart';
import 'package:graphic/src/dataflow/operator.dart';
import 'package:graphic/src/graffiti/figure.dart';
import 'package:graphic/src/scale/scale.dart';
import 'package:graphic/src/util/assert.dart';

import 'annotation.dart';

/// The Specification of a figure annotation.
abstract class FigureAnnotation extends Annotation {
  /// Creates a figure annotation.
  FigureAnnotation({
    this.variables,
    this.values,
    this.anchor,
    this.clip,
    int? layer,
  })  : assert(isSingle([variables, anchor], allowNone: true)),
        assert(isSingle([values, anchor])),
        super(
          layer: layer,
        );

  /// The variables in each dimension refered to for position.
  ///
  /// If null, the first variables assigned to each dimension are set by default.
  List<String>? variables;

  /// The values of [variables] for position.
  List? values;

  /// Indicates the anchor position of this annotation directly.
  ///
  /// This is a function with chart size as input that you may need to calculate
  /// the position.
  ///
  /// If set, this annotation's position will no longer determined by [variables]
  /// and [values].
  Offset Function(Size)? anchor;

  /// Whether this figure annotation should be cliped within the coordinate region.
  ///
  /// If null, a default false is set.
  bool? clip;

  @override
  bool operator ==(Object other) =>
      other is FigureAnnotation &&
      super == other &&
      deepCollectionEquals(variables, other.variables) &&
      deepCollectionEquals(values, values) &&
      clip == other.clip;
}

/// The operator to create figures of a figure annotation.
///
/// The figures value is nullable.
abstract class FigureAnnotOp extends Operator<List<Figure>?> {
  FigureAnnotOp(Map<String, dynamic> params) : super(params);
}

/// The operator to get figure annotation's anchor if it is set directly.
class FigureAnnotSetAnchorOp extends Operator<Offset> {
  FigureAnnotSetAnchorOp(Map<String, dynamic> params) : super(params);

  @override
  Offset evaluate() {
    final anchor = params['anchor'] as Offset Function(Size);
    final size = params['size'] as Size;

    return anchor(size);
  }
}

/// The operator to get figure annotation's anchor if it is calculated.
class FigureAnnotCalcAnchorOp extends Operator<Offset> {
  FigureAnnotCalcAnchorOp(Map<String, dynamic> params) : super(params);

  @override
  Offset evaluate() {
    final variables = params['variables'] as List<String>;
    final values = params['values'] as List;
    final scales = params['scales'] as Map<String, ScaleConv>;
    final coord = params['coord'] as CoordConv;

    final scaleX = scales[variables[0]]!;
    final scaleY = scales[variables[1]]!;
    return coord.convert(Offset(
      scaleX.normalize(scaleX.convert(values[0])),
      scaleY.normalize(scaleY.convert(values[1])),
    ));
  }
}

/// The figure annotation scene.
class FigureAnnotScene extends AnnotScene {
  FigureAnnotScene(int layer) : super(layer);

  @override
  int get intrinsicLayer => IntrinsicLayers.figureAnnot;
}

/// The figure annotation render operator.
class FigureAnnotRenderOp extends AnnotRenderOp<FigureAnnotScene> {
  FigureAnnotRenderOp(
    Map<String, dynamic> params,
    FigureAnnotScene scene,
    GraphicView view,
  ) : super(params, scene, view);

  @override
  void render() {
    final figures = params['figures'] as List<Figure>?;
    final clip = params['clip'] as bool;
    final coord = params['coord'] as CoordConv;

    if (clip) {
      scene.setRegionClip(coord.region);
    }

    scene.figures = figures;
  }
}
