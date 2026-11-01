import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const edition = String.fromEnvironment('ORLI_EDITION', defaultValue: 'pro');
const isLite = edition == 'lite';

const bg = Color(0xFF0B0E14);
const panel = Color(0xFF151B26);
const accent = Color(0xFF8B72FF);
const muted = Color(0xFF9AA6B8);
const green = Color(0xFF42D392);
const orange = Color(0xFFFFB454);
const red = Color(0xFFFF647C);

void main() => runApp(const OrliApp());

class OrliApp extends StatelessWidget {
  const OrliApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: isLite ? 'ORLI Lite' : 'ORLI Pro',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    ),
    home: const OrliHome(),
  );
}

class OrliItem {
  OrliItem({required this.id, required this.title, required this.detail, required this.category, required this.date, this.done = false});
  final String id, title, detail, category, date;
  bool done;
  Map<String, dynamic> toJson() => {'id':id,'title':title,'detail':detail,'category':category,'date':date,'done':done};
  factory OrliItem.fromJson(Map<String,dynamic> j) => OrliItem(
    id:j['id'] ?? '', title:j['title'] ?? '', detail:j['detail'] ?? '',
    category:j['category'] ?? 'Task', date:j['date'] ?? '', done:j['done'] ?? false);
}

class OrliHome extends StatefulWidget {
  const OrliHome({super.key});
  @override
  State<OrliHome> createState() => _OrliHomeState();
}

class _OrliHomeState extends State<OrliHome> {
  int tab = 0;
  bool loading = true;
  List<OrliItem> items = [];
  List<Map<String,String>> notes = [];
  double income = 0, expenses = 0, debts = 0;
  final moneyForm = GlobalKey<FormState>();
  final noteController = TextEditingController();

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('items');
    if (raw != null) {
      items = (jsonDecode(raw) as List).map((e)=>OrliItem.fromJson(e)).toList();
    } else {
      items = [
        OrliItem(id:'1',title:'Math lesson',detail:'Study lesson',category:'Lesson',date:'Today · 5:00 PM'),
        OrliItem(id:'2',title:'Study science',detail:'45 minutes',category:'Study',date:'Today · 7:00 PM'),
        OrliItem(id:'3',title:'Dinner',detail:'Daily routine',category:'Meal',date:'Today · 8:30 PM'),
      ];
    }
    final n = p.getString('notes');
    if (n != null) notes = (jsonDecode(n) as List).map((e)=>Map<String,String>.from(e)).toList();
    income = p.getDouble('income') ?? 0;
    expenses = p.getDouble('expenses') ?? 0;
    debts = p.getDouble('debts') ?? 0;
    if (mounted) setState(()=>loading=false);
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('items', jsonEncode(items.map((e)=>e.toJson()).toList()));
    await p.setString('notes', jsonEncode(notes));
    await p.setDouble('income', income);
    await p.setDouble('expenses', expenses);
    await p.setDouble('debts', debts);
  }

  @override
  void dispose() { noteController.dispose(); super.dispose(); }

  void addItem() {
    final title = TextEditingController(), detail = TextEditingController(), date = TextEditingController();
    String category = 'Task';
    showDialog(context:context,builder:(ctx)=>AlertDialog(
      title: const Text('Add to your day'),
      content: StatefulBuilder(builder:(ctx,setD)=>SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),
        const SizedBox(height:10),
        TextField(controller:detail,decoration:const InputDecoration(labelText:'Details')),
        const SizedBox(height:10),
        TextField(controller:date,decoration:const InputDecoration(labelText:'Date / time')),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Category'),
          items:['Task','Study','Lesson','Meal','Sleep','Medicine'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
          onChanged:(v)=>setD(()=>category=v ?? 'Task')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),
        FilledButton(onPressed:(){
          if(title.text.trim().isEmpty)return;
          setState(()=>items.insert(0,OrliItem(id:DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),detail:detail.text.trim(),category:category,date:date.text.trim())));
          save(); Navigator.pop(ctx);
        },child:const Text('Save'))],
    ));
  }

  void addNote() {
    noteController.clear();
    showDialog(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('New note'),
      content:TextField(controller:noteController,maxLines:5,decoration:const InputDecoration(hintText:'Write something...')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),
        FilledButton(onPressed:(){
          if(noteController.text.trim().isNotEmpty){
            setState(()=>notes.insert(0,{'text':noteController.text.trim(),'date':DateTime.now().toString().substring(0,16)}));
            save();
          } Navigator.pop(ctx);
        },child:const Text('Save'))],
    ));
  }

  void editMoney() {
    final i=TextEditingController(text:income.toStringAsFixed(0));
    final e=TextEditingController(text:expenses.toStringAsFixed(0));
    final d=TextEditingController(text:debts.toStringAsFixed(0));
    showDialog(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Update money overview'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:i,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Total income (EGP)')),
        const SizedBox(height:8),
        TextField(controller:e,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Expenses (EGP)')),
        const SizedBox(height:8),
        TextField(controller:d,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Outstanding debts (EGP)')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),
        FilledButton(onPressed:(){
          setState((){income=double.tryParse(i.text)??0;expenses=double.tryParse(e.text)??0;debts=double.tryParse(d.text)??0;});
          save();Navigator.pop(ctx);
        },child:const Text('Save'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [dashboard(), planner(), if (!isLite) moneyPage(), notesPage(), if (!isLite) healthPage()];
    final labels = ['Home','Planner', if (!isLite) 'Money','Notes', if (!isLite) 'Health'];
    final icons = [Icons.home_rounded,Icons.calendar_month_rounded,if(!isLite)Icons.account_balance_wallet_rounded,Icons.sticky_note_2_rounded,if(!isLite)Icons.health_and_safety_rounded];
    if (loading) return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if (tab >= pages.length) tab=0;
    return Scaffold(
      appBar:AppBar(
        title:Row(children:[const Text('OR',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.5)),Text('LI',style:TextStyle(color:accent,fontWeight:FontWeight.w900,letterSpacing:1.5)),const SizedBox(width:10),Text(isLite?'LITE':'PRO',style:TextStyle(fontSize:11,color:muted))]),
        actions:[IconButton(onPressed:addItem,icon:const Icon(Icons.add_circle_outline))],
      ),
      body:SafeArea(child:pages[tab]),
      bottomNavigationBar:NavigationBar(
        selectedIndex:tab,
        onDestinationSelected:(v)=>setState(()=>tab=v),
        destinations:List.generate(labels.length,(i)=>NavigationDestination(icon:Icon(icons[i]),label:labels[i])),
      ),
      floatingActionButton: tab==1 ? FloatingActionButton(onPressed:addItem,child:const Icon(Icons.add)) : null,
    );
  }

  Widget dashboard() {
    final done=items.where((x)=>x.done).length;
    return ListView(padding:const EdgeInsets.all(18),children:[
      Text('Your day, in control.',style:TextStyle(color:muted,fontSize:14)),
      const SizedBox(height:5),
      const Text('Good day!',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
      const SizedBox(height:18),
      Wrap(spacing:10,runSpacing:10,children:[
        metric('Tasks', '${items.length-done}', Icons.check_circle_outline, accent),
        metric('Completed', '$done', Icons.done_all, green),
        if(!isLite) metric('Balance', '${(income-expenses-debts).toStringAsFixed(0)} EGP', Icons.wallet, orange),
      ]),
      const SizedBox(height:24),
      sectionTitle('Today’s plan',onAdd:addItem),
      ...items.take(6).map(itemTile),
      if(!isLite)...[
        const SizedBox(height:18),sectionTitle('Health reminder'),
        Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18)),
          child:const Row(children:[Icon(Icons.medication_outlined,color:accent,size:28),SizedBox(width:12),Expanded(child:Text('Add your medicine schedule in Planner. ORLI records reminders; follow your clinician’s instructions.'))])),
      ],
    ]);
  }

  Widget planner() => ListView(padding:const EdgeInsets.all(18),children:[
    sectionTitle('Planner',onAdd:addItem),
    const Text('Add lessons, study sessions, meals, sleep and daily tasks.',style:TextStyle(color:muted)),
    const SizedBox(height:12),
    if(items.isEmpty) const Text('Nothing planned yet. Tap + to add an item.'),
    ...items.map(itemTile),
  ]);

  Widget moneyPage() => ListView(padding:const EdgeInsets.all(18),children:[
    sectionTitle('Money manager',onAdd:editMoney),
    const Text('Enter your own totals. Values are stored on this device.',style:TextStyle(color:muted)),
    const SizedBox(height:16),
    metric('Income','${income.toStringAsFixed(2)} EGP',Icons.trending_up,green),
    const SizedBox(height:10),metric('Expenses','${expenses.toStringAsFixed(2)} EGP',Icons.shopping_bag_outlined,red),
    const SizedBox(height:10),metric('Debts','${debts.toStringAsFixed(2)} EGP',Icons.receipt_long,orange),
    const SizedBox(height:10),metric('Available','${(income-expenses-debts).toStringAsFixed(2)} EGP',Icons.account_balance_wallet,accent),
    const SizedBox(height:16),FilledButton.icon(onPressed:editMoney,icon:const Icon(Icons.edit),label:const Text('Edit money totals')),
  ]);

  Widget notesPage() => ListView(padding:const EdgeInsets.all(18),children:[
    sectionTitle('Notes',onAdd:addNote),
    FilledButton.icon(onPressed:addNote,icon:const Icon(Icons.add),label:const Text('New note')),
    const SizedBox(height:12),
    if(notes.isEmpty) const Text('Your notes will appear here.',style:TextStyle(color:muted)),
    ...notes.map((n)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(n['text']??''),const SizedBox(height:8),Text(n['date']??'',style:TextStyle(color:muted,fontSize:11))]))),
  ]);

  Widget healthPage() => ListView(padding:const EdgeInsets.all(18),children:[
    sectionTitle('Health & routine'),
    const Text('Use this area to organize personal routines. Medicine reminders should match the instructions provided by your doctor or pharmacist.',style:TextStyle(color:muted)),
    const SizedBox(height:16),
    ...['Medicine schedule','Meals','Sleep routine'].map((x)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),child:Row(children:[const Icon(Icons.notifications_active_outlined,color:accent),const SizedBox(width:12),Expanded(child:Text(x)),const Icon(Icons.chevron_right,color:muted)]))),
    const SizedBox(height:8),
    const Text('Note: this initial build stores schedule entries but does not yet send operating-system notifications.',style:TextStyle(color:orange,fontSize:12)),
  ]);

  Widget metric(String title,String value,IconData icon,Color color)=>Container(width:MediaQuery.of(context).size.width>600?220:(MediaQuery.of(context).size.width-46)/2,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(icon,color:color),const SizedBox(height:12),Text(title,style:TextStyle(color:muted,fontSize:12)),const SizedBox(height:5),Text(value,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
  ]));

  Widget sectionTitle(String title,{VoidCallback? onAdd})=>Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
    Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    if(onAdd!=null) IconButton(onPressed:onAdd,icon:const Icon(Icons.add,color:accent)),
  ]);

  Widget itemTile(OrliItem x)=>Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),child:Row(children:[
    Checkbox(value:x.done,activeColor:green,onChanged:(v){setState(()=>x.done=v??false);save();}),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(x.title,style:TextStyle(fontWeight:FontWeight.w600,decoration:x.done?TextDecoration.lineThrough:null,color:x.done?muted:null)),
      if(x.detail.isNotEmpty) Text(x.detail,style:TextStyle(color:muted,fontSize:12)),
      if(x.date.isNotEmpty) Text(x.date,style:const TextStyle(color:accent,fontSize:11)),
    ])),
    PopupMenuButton<String>(onSelected:(v){if(v=='delete'){setState(()=>items.removeWhere((e)=>e.id==x.id));save();}},itemBuilder:(_)=>[const PopupMenuItem(value:'delete',child:Text('Delete'))]),
  ]));
}
