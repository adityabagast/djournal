import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Pustaka `excel` belum bisa filter, panel beku, dropdown, format bersyarat,
/// chart, dan sheet tersembunyi. File ini menyisipkannya ke XML hasil
/// `excel.encode()`. Tidak tahu apa-apa soal uang atau jurnal.

enum ChartType { column, bar, doughnut }

class ChartSeries {
  const ChartSeries({
    required this.name,
    required this.ref,
    required this.values,
    this.color,
    this.pointColors = const [],
  });

  final String name;

  /// Rentang nilai, mis. `'Dompet'!$E$2:$E$5`.
  final String ref;
  final List<num> values;

  /// Hex tanpa `#`.
  final String? color;
  final List<String> pointColors;
}

class ChartSpec {
  const ChartSpec({
    required this.type,
    required this.title,
    required this.categoryRef,
    required this.categories,
    required this.series,
    required this.column,
    required this.row,
    required this.width,
    required this.height,
    this.valueFormat = 'General',
    this.categoryFormat,
    this.majorUnit,
    this.legend = false,
  });

  final ChartType type;
  final String title;
  final String categoryRef;

  /// String, atau num (tanggal serial) kalau [categoryFormat] diisi.
  final List<Object> categories;
  final List<ChartSeries> series;

  /// Sel pojok kiri atas, mulai dari 0.
  final int column;
  final int row;

  /// Ukuran dalam point.
  final int width;
  final int height;
  final String valueFormat;
  final String? categoryFormat;
  final num? majorUnit;
  final bool legend;
}

class SheetExtras {
  const SheetExtras({
    this.freezeRows = 0,
    this.autoFilter,
    this.showGridLines = true,
    this.hidden = false,
    this.rowHeight,
    this.dropdowns = const {},
    this.highlights = const {},
    this.cached = const {},
    this.charts = const [],
  });

  final int freezeRows;

  /// Rentang filter, mis. `A3:K20`.
  final String? autoFilter;
  final bool showGridLines;
  final bool hidden;

  /// Tinggi semua baris (point), termasuk yang kosong, supaya posisi chart
  /// tetap.
  final double? rowHeight;

  /// Sel → rentang isi dropdown.
  final Map<String, String> dropdowns;

  /// Rentang → rumus; baris yang rumusnya benar ditandai merah.
  final Map<String, String> highlights;

  /// Sel rumus → hasilnya (num atau String), untuk pratinjau tanpa mesin
  /// hitung. Excel tetap menghitung ulang saat file dibuka.
  final Map<String, Object> cached;
  final List<ChartSpec> charts;
}

const _relNs = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _pkgRelNs = 'http://schemas.openxmlformats.org/package/2006/relationships';
const _mainNs = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _drawNs = 'http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing';
const _aNs = 'http://schemas.openxmlformats.org/drawingml/2006/main';
const _chartNs = 'http://schemas.openxmlformats.org/drawingml/2006/chart';
const _xmlHead = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
const _emuPerPoint = 12700;

/// Urutan wajib anak `<worksheet>`; salah urut = Excel minta perbaikan file.
const _sheetOrder = [
  'sheetPr', 'dimension', 'sheetViews', 'sheetFormatPr', 'cols', 'sheetData',
  'sheetCalcPr', 'sheetProtection', 'protectedRanges', 'scenarios',
  'autoFilter', 'sortState', 'dataConsolidate', 'customSheetViews',
  'mergeCells', 'phoneticPr', 'conditionalFormatting', 'dataValidations',
  'hyperlinks', 'printOptions', 'pageMargins', 'pageSetup', 'headerFooter',
  'rowBreaks', 'colBreaks', 'customProperties', 'cellWatches',
  'ignoredErrors', 'smartTags', 'drawing',
];

String _esc(String s) => const HtmlEscape(HtmlEscapeMode.attribute)
    .convert(s)
    .replaceAll('&#39;', "'");

List<int> enrichXlsx(List<int> bytes, Map<String, SheetExtras> extras) {
  final files = <String, List<int>>{
    for (final f in ZipDecoder().decodeBytes(bytes).files)
      if (f.isFile) f.name: f.content as List<int>,
  };
  XmlDocument read(String path) => XmlDocument.parse(utf8.decode(files[path]!));
  void write(String path, String xml) => files[path] = utf8.encode(xml);

  final workbook = read('xl/workbook.xml');
  final targets = {
    for (final r
        in read('xl/_rels/workbook.xml.rels').findAllElements('Relationship'))
      r.getAttribute('Id')!: r.getAttribute('Target')!,
  };
  final types = read('[Content_Types].xml');
  final styles = read('xl/styles.xml');

  final overrides = <String, String>{};
  final definedNames = <String>[];
  var dxfId = -1;
  var drawingNo = 0;
  var chartNo = 0;

  final sheets = workbook.findAllElements('sheet').toList();
  for (var i = 0; i < sheets.length; i++) {
    final name = sheets[i].getAttribute('name')!;
    final x = extras[name];
    if (x == null) continue;
    if (x.hidden) sheets[i].setAttribute('state', 'hidden');

    final rawTarget = targets[sheets[i].getAttribute('r:id')]!;
    final path = rawTarget.startsWith('/')
        ? rawTarget.substring(1)
        : 'xl/$rawTarget';
    final doc = read(path);
    final ws = doc.rootElement;

    _setView(ws, x);
    if (x.rowHeight case final h?) _setRowHeight(ws, h);
    _setCached(ws, x.cached);
    if (x.autoFilter case final ref?) {
      _insert(ws, '<autoFilter xmlns="$_mainNs" ref="$ref"/>');
      definedNames.add(
        '<definedName xmlns="$_mainNs" name="_xlnm._FilterDatabase" '
        'localSheetId="$i" hidden="1">'
        '${_esc(absoluteRef(name, ref))}</definedName>',
      );
    }
    var priority = 0;
    x.highlights.forEach((ref, formula) {
      if (dxfId < 0) dxfId = _addWarningStyle(styles);
      _insert(
        ws,
        '<conditionalFormatting xmlns="$_mainNs" sqref="$ref">'
        '<cfRule type="expression" dxfId="$dxfId" priority="${++priority}">'
        '<formula>${_esc(formula)}</formula></cfRule></conditionalFormatting>',
      );
    });
    if (x.dropdowns.isNotEmpty) {
      _insert(
        ws,
        '<dataValidations xmlns="$_mainNs" count="${x.dropdowns.length}">'
        '${x.dropdowns.entries.map((e) => '<dataValidation type="list" allowBlank="0" showErrorMessage="1" sqref="${e.key}"><formula1>${_esc(e.value)}</formula1></dataValidation>').join()}'
        '</dataValidations>',
      );
    }
    if (x.charts.isNotEmpty) {
      final drawing = 'laporan${++drawingNo}.xml';
      final rels = StringBuffer();
      final anchors = StringBuffer();
      for (var c = 0; c < x.charts.length; c++) {
        final chart = 'laporan${++chartNo}.xml';
        write('xl/charts/$chart', _chartXml(x.charts[c]));
        overrides['/xl/charts/$chart'] =
            'application/vnd.openxmlformats-officedocument.drawingml.chart+xml';
        rels.write(
          '<Relationship Id="rId${c + 1}" Type="$_relNs/chart" '
          'Target="../charts/$chart"/>',
        );
        anchors.write(_anchorXml(x.charts[c], c + 1));
      }
      write(
        'xl/drawings/$drawing',
        '$_xmlHead<xdr:wsDr xmlns:xdr="$_drawNs" xmlns:a="$_aNs">'
            '$anchors</xdr:wsDr>',
      );
      write(
        'xl/drawings/_rels/$drawing.rels',
        '$_xmlHead<Relationships xmlns="$_pkgRelNs">$rels</Relationships>',
      );
      overrides['/xl/drawings/$drawing'] =
          'application/vnd.openxmlformats-officedocument.drawing+xml';
      final sheetFile = path.split('/').last;
      write(
        'xl/worksheets/_rels/$sheetFile.rels',
        '$_xmlHead<Relationships xmlns="$_pkgRelNs"><Relationship Id="rId1" '
            'Type="$_relNs/drawing" Target="../drawings/$drawing"/>'
            '</Relationships>',
      );
      ws.childElements
          .where((e) => e.name.local == 'drawing')
          .toList()
          .forEach(ws.children.remove);
      _insert(
        ws,
        '<drawing xmlns="$_mainNs" xmlns:r="$_relNs" r:id="rId1"/>',
      );
    }
    write(path, doc.toXmlString());
  }

  _finishWorkbook(workbook, definedNames);
  write('xl/workbook.xml', workbook.toXmlString());
  _alignLeftByDefault(styles);
  write('xl/styles.xml', styles.toXmlString());
  for (final e in overrides.entries) {
    types.rootElement.children.add(
      XmlElement(XmlName('Override'), [
        XmlAttribute(XmlName('ContentType'), e.value),
        XmlAttribute(XmlName('PartName'), e.key),
      ]),
    );
  }
  write('[Content_Types].xml', types.toXmlString());

  final out = Archive();
  // [Content_Types].xml di depan, seperti file buatan Excel sendiri.
  final names = files.keys.toList()
    ..sort((a, b) => (a.startsWith('[') ? 0 : 1) - (b.startsWith('[') ? 0 : 1));
  for (final n in names) {
    out.addFile(ArchiveFile(n, files[n]!.length, files[n]!));
  }
  return ZipEncoder().encode(out)!;
}

/// `A3:K20` di sheet [sheet] → `'sheet'!$A$3:$K$20`.
String absoluteRef(String sheet, String ref) =>
    "'$sheet'!${ref.replaceAllMapped(RegExp(r'([A-Z]+)(\d+)'), (m) => '\$${m[1]}\$${m[2]}')}";

XmlElement _element(String xml) =>
    XmlDocument.parse(xml).rootElement.copy();

void _insert(XmlElement ws, String xml) {
  final e = _element(xml);
  final rank = _sheetOrder.indexOf(e.name.local);
  final kids = ws.children;
  var at = kids.length;
  for (var i = 0; i < kids.length; i++) {
    final k = kids[i];
    if (k is XmlElement && _sheetOrder.indexOf(k.name.local) > rank) {
      at = i;
      break;
    }
  }
  kids.insert(at, e);
}

void _setView(XmlElement ws, SheetExtras x) {
  if (x.freezeRows == 0 && x.showGridLines) return;
  ws.childElements
      .where((e) => e.name.local == 'sheetViews')
      .toList()
      .forEach(ws.children.remove);
  final pane = x.freezeRows == 0
      ? ''
      : '<pane ySplit="${x.freezeRows}" topLeftCell="A${x.freezeRows + 1}" '
          'activePane="bottomLeft" state="frozen"/>'
          '<selection pane="bottomLeft"/>';
  _insert(
    ws,
    '<sheetViews xmlns="$_mainNs"><sheetView workbookViewId="0"'
    '${x.showGridLines ? '' : ' showGridLines="0"'}>$pane</sheetView>'
    '</sheetViews>',
  );
}

void _setRowHeight(XmlElement ws, double height) {
  ws.childElements
      .where((e) => e.name.local == 'sheetFormatPr')
      .toList()
      .forEach(ws.children.remove);
  _insert(
    ws,
    '<sheetFormatPr xmlns="$_mainNs" defaultRowHeight="$height" '
    'customHeight="1"/>',
  );
  for (final row in ws.findAllElements('row')) {
    row.setAttribute('ht', '$height');
    row.setAttribute('customHeight', '1');
  }
}

/// `excel` tidak menulis perataan kiri, jadi tanggal ikut rata kanan.
void _alignLeftByDefault(XmlDocument styles) {
  final xfs = styles.rootElement.getElement('cellXfs');
  if (xfs == null) return;
  for (final xf in xfs.findElements('xf').skip(1)) {
    var a = xf.getElement('alignment');
    if (a == null) {
      a = XmlElement(XmlName('alignment'));
      xf.children.insert(0, a);
      xf.setAttribute('applyAlignment', '1');
    }
    if (a.getAttribute('horizontal') == null) {
      a.setAttribute('horizontal', 'left');
      xf.setAttribute('applyAlignment', '1');
    }
  }
}

void _setCached(XmlElement ws, Map<String, Object> cached) {
  if (cached.isEmpty) return;
  for (final c in ws.findAllElements('c')) {
    final value = cached[c.getAttribute('r')];
    final v = c.getElement('v');
    if (value == null || v == null || c.getElement('f') == null) continue;
    if (value is String) c.setAttribute('t', 'str');
    v.innerText = '$value';
  }
}

int _addWarningStyle(XmlDocument styles) {
  var dxfs = styles.rootElement.getElement('dxfs');
  if (dxfs == null) {
    dxfs = XmlElement(XmlName('dxfs'));
    final kids = styles.rootElement.children;
    final at = kids.indexWhere(
      (k) => k is XmlElement && k.name.local == 'cellStyles',
    );
    kids.insert(at + 1, dxfs);
  }
  dxfs.children.add(
    _element(
      '<dxf xmlns="$_mainNs"><font><color rgb="FFB42318"/></font><fill>'
      '<patternFill><bgColor rgb="FFFDECEA"/></patternFill></fill></dxf>',
    ),
  );
  final n = dxfs.childElements.length;
  dxfs.setAttribute('count', '$n');
  return n - 1;
}

void _finishWorkbook(XmlDocument workbook, List<String> definedNames) {
  final root = workbook.rootElement;
  root.childElements
      .where((e) => const {'definedNames', 'calcPr'}.contains(e.name.local))
      .toList()
      .forEach(root.children.remove);
  final at = root.children.indexWhere(
    (k) => k is XmlElement && k.name.local == 'sheets',
  );
  root.children.insert(
    at + 1,
    _element('<calcPr xmlns="$_mainNs" fullCalcOnLoad="1"/>'),
  );
  if (definedNames.isNotEmpty) {
    root.children.insert(
      at + 1,
      _element(
        '<definedNames xmlns="$_mainNs">${definedNames.join()}</definedNames>',
      ),
    );
  }
}

String _anchorXml(ChartSpec c, int id) =>
    '<xdr:oneCellAnchor><xdr:from><xdr:col>${c.column}</xdr:col>'
    '<xdr:colOff>0</xdr:colOff><xdr:row>${c.row}</xdr:row>'
    '<xdr:rowOff>0</xdr:rowOff></xdr:from>'
    '<xdr:ext cx="${c.width * _emuPerPoint}" cy="${c.height * _emuPerPoint}"/>'
    '<xdr:graphicFrame macro=""><xdr:nvGraphicFramePr>'
    '<xdr:cNvPr id="${id + 1}" name="Chart $id" descr="${_esc(c.title)}"/>'
    '<xdr:cNvGraphicFramePr/></xdr:nvGraphicFramePr>'
    '<xdr:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/></xdr:xfrm>'
    '<a:graphic><a:graphicData uri="$_chartNs">'
    '<c:chart xmlns:c="$_chartNs" xmlns:r="$_relNs" r:id="rId$id"/>'
    '</a:graphicData></a:graphic></xdr:graphicFrame><xdr:clientData/>'
    '</xdr:oneCellAnchor>';

String _line(String hex) =>
    '<a:ln w="9525"><a:solidFill><a:srgbClr val="$hex"/></a:solidFill></a:ln>';

String _fill(String hex) =>
    '<c:spPr><a:solidFill><a:srgbClr val="$hex"/></a:solidFill></c:spPr>';

String _chartXml(ChartSpec c) {
  final bar = c.type != ChartType.doughnut;
  final horizontal = c.type == ChartType.bar;
  final series = StringBuffer();
  for (var i = 0; i < c.series.length; i++) {
    final s = c.series[i];
    series.write(
      '<c:ser><c:idx val="$i"/><c:order val="$i"/>'
      '<c:tx><c:v>${_esc(s.name)}</c:v></c:tx>'
      '${s.color == null ? '' : _fill(s.color!)}'
      '${bar ? '<c:invertIfNegative val="0"/>' : ''}',
    );
    for (var p = 0; p < s.pointColors.length; p++) {
      series.write(
        '<c:dPt><c:idx val="$p"/><c:bubble3D val="0"/>'
        '${_fill(s.pointColors[p])}</c:dPt>',
      );
    }
    series.write(
      '<c:cat>${_categoryXml(c)}</c:cat><c:val>'
      '${_numRef(s.ref, s.values, c.valueFormat)}</c:val></c:ser>',
    );
  }

  final plot = bar
      ? '<c:barChart><c:barDir val="${horizontal ? 'bar' : 'col'}"/>'
          '<c:grouping val="clustered"/><c:varyColors val="0"/>$series'
          '<c:gapWidth val="70"/><c:axId val="111"/><c:axId val="222"/>'
          '</c:barChart>${_axesXml(c, horizontal)}'
      : '<c:doughnutChart><c:varyColors val="1"/>$series'
          '<c:firstSliceAng val="0"/><c:holeSize val="58"/>'
          '</c:doughnutChart>';

  return '$_xmlHead<c:chartSpace xmlns:c="$_chartNs" xmlns:a="$_aNs" '
      'xmlns:r="$_relNs"><c:roundedCorners val="0"/><c:chart><c:title><c:tx>'
      '<c:rich><a:bodyPr/><a:p><a:pPr><a:defRPr sz="1200" b="1"/></a:pPr>'
      '<a:r><a:rPr sz="1200" b="1"/><a:t>${_esc(c.title)}</a:t></a:r></a:p>'
      '</c:rich></c:tx><c:overlay val="0"/></c:title>'
      '<c:autoTitleDeleted val="0"/><c:plotArea><c:layout/>$plot</c:plotArea>'
      '${c.legend ? '<c:legend><c:legendPos val="${bar ? 'b' : 'r'}"/><c:overlay val="0"/></c:legend>' : ''}'
      '<c:plotVisOnly val="1"/><c:dispBlanksAs val="gap"/></c:chart>'
      '<c:spPr><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>'
      '${_line('D9D9D9')}</c:spPr>'
      '</c:chartSpace>';
}

String _categoryXml(ChartSpec c) {
  if (c.categoryFormat case final format?) {
    return _numRef(c.categoryRef, c.categories.cast<num>(), format);
  }
  final points = StringBuffer();
  for (var i = 0; i < c.categories.length; i++) {
    points.write('<c:pt idx="$i"><c:v>${_esc('${c.categories[i]}')}</c:v></c:pt>');
  }
  return '<c:strRef><c:f>${_esc(c.categoryRef)}</c:f><c:strCache>'
      '<c:ptCount val="${c.categories.length}"/>$points</c:strCache></c:strRef>';
}

String _numRef(String ref, List<num> values, String format) {
  final points = StringBuffer();
  for (var i = 0; i < values.length; i++) {
    points.write('<c:pt idx="$i"><c:v>${values[i]}</c:v></c:pt>');
  }
  return '<c:numRef><c:f>${_esc(ref)}</c:f><c:numCache>'
      '<c:formatCode>${_esc(format)}</c:formatCode>'
      '<c:ptCount val="${values.length}"/>$points</c:numCache></c:numRef>';
}

/// Batang mendatar: urutan dibalik supaya baris pertama tabel ada di atas,
/// dan sumbu angka tetap di bawah (`crosses="max"`).
String _axesXml(ChartSpec c, bool horizontal) =>
    '<c:catAx><c:axId val="111"/><c:scaling><c:orientation '
    'val="${horizontal ? 'maxMin' : 'minMax'}"/></c:scaling>'
    '<c:delete val="0"/><c:axPos val="${horizontal ? 'l' : 'b'}"/>'
    '<c:numFmt formatCode="${_esc(c.categoryFormat ?? 'General')}" '
    'sourceLinked="0"/><c:majorTickMark val="none"/>'
    '<c:minorTickMark val="none"/><c:tickLblPos val="low"/>'
    '<c:spPr>${_line('D9D9D9')}</c:spPr>'
    '<c:crossAx val="222"/><c:crosses val="autoZero"/><c:auto val="0"/>'
    '<c:lblAlgn val="ctr"/><c:lblOffset val="100"/>'
    '<c:noMultiLvlLbl val="1"/></c:catAx>'
    '<c:valAx><c:axId val="222"/><c:scaling><c:orientation val="minMax"/>'
    '</c:scaling><c:delete val="0"/>'
    '<c:axPos val="${horizontal ? 'b' : 'l'}"/><c:majorGridlines><c:spPr>'
    '<a:ln><a:solidFill><a:srgbClr val="E5E7EB"/></a:solidFill></a:ln>'
    '</c:spPr></c:majorGridlines>'
    '<c:numFmt formatCode="${_esc(c.valueFormat)}" sourceLinked="0"/>'
    '<c:majorTickMark val="none"/><c:minorTickMark val="none"/>'
    '<c:tickLblPos val="nextTo"/><c:spPr><a:ln><a:noFill/></a:ln></c:spPr>'
    '<c:crossAx val="111"/>'
    '<c:crosses val="${horizontal ? 'max' : 'autoZero'}"/>'
    '<c:crossBetween val="between"/>'
    '${c.majorUnit == null ? '' : '<c:majorUnit val="${c.majorUnit}"/>'}'
    '</c:valAx>';
