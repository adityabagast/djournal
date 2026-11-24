import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:djournal/features/backup/data/excel_ooxml.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

List<int> _base() {
  final excel = Excel.createExcel();
  final a = excel['A'];
  a.appendRow([TextCellValue('Nama'), TextCellValue('Nilai')]);
  a.appendRow([TextCellValue('x'), IntCellValue(3)]);
  a.appendRow([TextCellValue('y'), FormulaCellValue('SUM(B2:B2)&"<"')]);
  excel['Rahasia'].appendRow([TextCellValue('r')]);
  excel.delete('Sheet1');
  return excel.encode()!;
}

List<int> _built() => enrichXlsx(_base(), {
      'A': SheetExtras(
        freezeRows: 1,
        autoFilter: 'A1:B3',
        showGridLines: false,
        dropdowns: const {'B2': r'$A$2:$A$3'},
        highlights: const {'A2:B3': r'$B2>1'},
        cached: const {'B3': '3<'},
        charts: [
          for (final t in ChartType.values)
            ChartSpec(
              type: t,
              title: 'Judul & <${t.name}>',
              categoryRef: r"'A'!$A$2:$A$3",
              categories: const ['x', 'y'],
              series: const [
                ChartSeries(
                  name: 'S',
                  ref: r"'A'!$B$2:$B$3",
                  values: [3, 4],
                  color: '1F5F4E',
                ),
              ],
              column: 4,
              row: 2,
              width: 300,
              height: 200,
            ),
        ],
      ),
      'Rahasia': const SheetExtras(hidden: true),
    });

Map<String, XmlDocument> _parts(List<int> bytes) => {
      for (final f in ZipDecoder().decodeBytes(bytes).files)
        f.name: XmlDocument.parse(utf8.decode(f.content as List<int>)),
    };

XmlElement _sheet(Map<String, XmlDocument> p, String name) {
  final id = p['xl/workbook.xml']!
      .findAllElements('sheet')
      .firstWhere((s) => s.getAttribute('name') == name)
      .getAttribute('r:id');
  final target = p['xl/_rels/workbook.xml.rels']!
      .findAllElements('Relationship')
      .firstWhere((r) => r.getAttribute('Id') == id)
      .getAttribute('Target')!;
  return p['xl/${target.replaceFirst('/xl/', '')}']!.rootElement;
}

void main() {
  test('semua bagian XML sah dan tetap terbaca pustaka excel', () {
    final bytes = _built();
    expect(_parts(bytes), isNotEmpty);
    expect(Excel.decodeBytes(bytes).tables.keys, containsAll(['A', 'Rahasia']));
  });

  test('urutan elemen sheet sesuai skema Excel', () {
    final names =
        _sheet(_parts(_built()), 'A').childElements.map((e) => e.name.local);
    const order = [
      'sheetPr', 'dimension', 'sheetViews', 'sheetFormatPr', 'cols',
      'sheetData', 'autoFilter', 'mergeCells', 'conditionalFormatting',
      'dataValidations', 'hyperlinks', 'printOptions', 'pageMargins',
      'pageSetup', 'headerFooter', 'drawing',
    ];
    final idx = names.map(order.indexOf).toList();
    expect(idx, everyElement(greaterThanOrEqualTo(0)));
    expect(idx, [...idx]..sort());
    expect(names, containsAll(['autoFilter', 'dataValidations', 'drawing']));
  });

  test('nilai rumus tersimpan, teks diberi tipe str', () {
    final c = _sheet(_parts(_built()), 'A')
        .findAllElements('c')
        .firstWhere((c) => c.getAttribute('r') == 'B3');
    expect(c.getAttribute('t'), 'str');
    expect(c.getElement('v')!.innerText, '3<');
    expect(c.getElement('f')!.innerText, 'SUM(B2:B2)&"<"');
  });

  test('sheet tersembunyi, filter terdaftar, hitung ulang saat dibuka', () {
    final wb = _parts(_built())['xl/workbook.xml']!;
    String? state(String n) => wb
        .findAllElements('sheet')
        .firstWhere((s) => s.getAttribute('name') == n)
        .getAttribute('state');
    expect(state('A'), 'visible');
    expect(state('Rahasia'), 'hidden');
    expect(wb.findAllElements('calcPr').single.getAttribute('fullCalcOnLoad'),
        '1');
    expect(wb.findAllElements('definedName').single.innerText,
        r"'A'!$A$1:$B$3");
  });

  test('setiap chart punya relasi dan content type', () {
    final p = _parts(_built());
    final charts = p.keys.where((k) => k.startsWith('xl/charts/')).toList();
    expect(charts, hasLength(ChartType.values.length));
    final types = p['[Content_Types].xml']!
        .findAllElements('Override')
        .map((o) => o.getAttribute('PartName'));
    expect(types, containsAll(charts.map((c) => '/$c')));
    expect(types.toSet(), hasLength(types.length), reason: 'tidak dobel');
    for (final rels in p.keys.where((k) => k.endsWith('.rels'))) {
      final dir = rels.replaceFirst(RegExp(r'_rels/[^/]+$'), '');
      for (final r in p[rels]!.findAllElements('Relationship')) {
        final t = r.getAttribute('Target')!;
        final path = t.startsWith('/')
            ? t.substring(1)
            : Uri.parse('http://x/$dir').resolve(t).path.substring(1);
        expect(p.keys, contains(path), reason: '$rels -> $t');
      }
    }
  });

  test('tanpa tambahan apa pun, file tetap sah', () {
    expect(Excel.decodeBytes(enrichXlsx(_base(), const {})).tables, isNotEmpty);
  });
}
