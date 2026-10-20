import 'package:flutter/material.dart';

void main() => runApp(const IzerApp());

class IzerLayer {
  IzerLayer(this.name, this.kind, {this.icon = Icons.text_fields});
  final String name;
  final String kind;
  final IconData icon;
  bool visible = true;
  bool locked = false;
  bool keyframed = false;
}

class IzerApp extends StatelessWidget {
  const IzerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Izer Motion Editor',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff9b6cff), brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xff0e0d14),
        ),
        home: const EditorPage(),
      );
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final layers = <IzerLayer>[
    IzerLayer('عنوان المشروع', 'نص', icon: Icons.title),
    IzerLayer('خلفية', 'لون', icon: Icons.palette),
  ];
  int selected = 0;
  double position = 0.35;
  double scale = 1;
  double rotation = 0;
  double opacity = 1;
  bool playing = false;

  IzerLayer get active => layers[selected];

  void addLayer() async {
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('إضافة طبقة'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.text_fields), title: const Text('نص'), onTap: () => Navigator.pop(context, 'نص جديد')),
        ListTile(leading: const Icon(Icons.image), title: const Text('صورة / فيديو'), onTap: () => Navigator.pop(context, 'وسائط جديدة')),
        ListTile(leading: const Icon(Icons.graphic_eq), title: const Text('صوت'), onTap: () => Navigator.pop(context, 'صوت جديد')),
        ListTile(leading: const Icon(Icons.shape_line), title: const Text('شكل'), onTap: () => Navigator.pop(context, 'شكل جديد')),
      ]),
    ));
    if (name == null) return;
    setState(() { layers.insert(0, IzerLayer(name, name.contains('نص') ? 'نص' : 'وسائط', icon: name.contains('نص') ? Icons.text_fields : Icons.image)); selected = 0; });
  }

  void exportProject() => showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: const Text('التصدير'),
    content: const Text('هذه نسخة الواجهة الأولى. سيتم إضافة تصدير MP4 الحقيقي بعد إضافة محرك الوسائط.', textDirection: TextDirection.rtl),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))],
  ));

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(
      title: const Text('Izer', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [IconButton(onPressed: exportProject, icon: const Icon(Icons.ios_share), tooltip: 'تصدير'), IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))],
    ),
    body: Column(children: [
      Expanded(flex: 5, child: _preview()),
      _timelineToolbar(),
      Expanded(flex: 4, child: _layersAndControls()),
    ]),
    floatingActionButton: FloatingActionButton(onPressed: addLayer, child: const Icon(Icons.add)),
  ));

  Widget _preview() => Container(
    margin: const EdgeInsets.fromLTRB(18, 12, 18, 8),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xff281b55), Color(0xff111c3e)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Stack(alignment: Alignment.center, children: [
      CustomPaint(size: Size.infinite, painter: GridPainter()),
      Transform.rotate(angle: rotation, child: Opacity(opacity: opacity, child: Transform.scale(scale: scale, child: active.kind == 'نص' ? const Text('Izer', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)) : const Icon(Icons.movie_creation_outlined, size: 80, color: Color(0xffc7b5ff))))),
      Positioned(bottom: 12, left: 12, child: Text('00:${(position * 10).toStringAsFixed(1).padLeft(4, '0')} / 00:10.0', style: const TextStyle(color: Colors.white70))),
    ]),
  );

  Widget _timelineToolbar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    color: const Color(0xff17151f),
    child: Row(children: [
      IconButton(onPressed: () => setState(() => playing = !playing), icon: Icon(playing ? Icons.pause : Icons.play_arrow)),
      IconButton(onPressed: () => setState(() => position = 0), icon: const Icon(Icons.skip_previous)),
      Expanded(child: Slider(value: position, onChanged: (v) => setState(() => position = v))),
      Text('${(position * 10).toStringAsFixed(1)}s', style: const TextStyle(color: Colors.white70)),
    ]),
  );

  Widget _layersAndControls() => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    SizedBox(width: 155, child: Container(color: const Color(0xff14121b), child: Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: Row(children: [const Expanded(child: Text('الطبقات', style: TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: addLayer, icon: const Icon(Icons.add, size: 19))])),
      Expanded(child: ReorderableListView.builder(padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: layers.length, onReorder: (oldIndex, newIndex) { setState(() { if (newIndex > oldIndex) newIndex--; final item = layers.removeAt(oldIndex); layers.insert(newIndex, item); selected = newIndex; }); }, itemBuilder: (context, index) => _layerTile(index))),
    ]))),
    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 80), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(active.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _control('الحجم', scale, 0.3, 2, (v) => setState(() => scale = v)),
      _control('الدوران', rotation, -3.14, 3.14, (v) => setState(() => rotation = v)),
      _control('الشفافية', opacity, 0, 1, (v) => setState(() => opacity = v)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Keyframe لهذه الطبقة'), subtitle: const Text('تحريك الخصائص عبر الزمن'), value: active.keyframed, onChanged: (v) => setState(() => active.keyframed = v)),
      Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.crop), label: const Text('قص')), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.blur_on), label: const Text('مؤثر')), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.color_lens), label: const Text('لون'))]),
    ]))),
  ]);

  Widget _layerTile(int index) { final layer = layers[index]; return Card(key: ValueKey(layer), color: index == selected ? const Color(0xff382b5b) : const Color(0xff211e2c), child: ListTile(dense: true, onTap: () => setState(() => selected = index), leading: Icon(layer.icon, size: 19), title: Text(layer.name, overflow: TextOverflow.ellipsis), trailing: Icon(layer.visible ? Icons.visibility : Icons.visibility_off, size: 17, color: Colors.white60))); }

  Widget _control(String label, double value, double min, double max, ValueChanged<double> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text(label)), Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white60))]), Slider(value: value, min: min, max: max, onChanged: onChanged)]);
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) { final paint = Paint()..color = Colors.white.withOpacity(.045)..strokeWidth = 1; for (double x = 0; x < size.width; x += 24) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); for (double y = 0; y < size.height; y += 24) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}