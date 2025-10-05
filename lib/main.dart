import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Depo Yönetim Sistemi',
      theme: ThemeData(
        fontFamily: 'Consolas',
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Color(0xFFE0E0E0),
        appBarTheme: AppBarTheme(
          color: Color(0xFF333333),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.5),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: AnaSayfa(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AnaSayfa extends StatefulWidget {
  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _selectedIndex = 1;
  late List<Widget> _pages;

  File? foto;
  Map<String, dynamic>? guncellenecekUrun;

  @override
  void initState() {
    super.initState();
    _pages = [
      UstUrunlerPage(onUpdateSelected: onUpdateSelected),
      UrunEklePage(
          guncellenecekUrun: guncellenecekUrun,
          onUpdateCompleted: onUpdateCompleted),
      AltUrunlerPage(onUpdateSelected: onUpdateSelected),
    ];
  }

  void onUpdateSelected(Map<String, dynamic> urun) {
    setState(() {
      guncellenecekUrun = urun;
      _selectedIndex = 1;
      _pages[1] = UrunEklePage(
          guncellenecekUrun: guncellenecekUrun,
          onUpdateCompleted: onUpdateCompleted);
    });
  }

  void onUpdateCompleted() {
    setState(() {
      guncellenecekUrun = null;
      _selectedIndex = 1; // Güncelleme sonrası Ekle sayfasına dön
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        guncellenecekUrun = null; // Ürün Ekle sayfasına döndüğünde güncelleme modunu sıfırla
      }
      _pages[1] = UrunEklePage(
          guncellenecekUrun: guncellenecekUrun,
          onUpdateCompleted: onUpdateCompleted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Depo Yönetim Sistemi')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(0xFF424242),
        selectedItemColor: Color(0xFF007FFF),
        unselectedItemColor: Color(0xFFBDBDBD),
        elevation: 12,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list, size: 28),
            label: "ÜST",
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF007FFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white, size: 32),
            ),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt, size: 28),
            label: "ALT",
          ),
        ],
      ),
    );
  }
}

// -------------------- Ürün Ekleme/Güncelleme Sayfası -------------------
class UrunEklePage extends StatefulWidget {
  final Map<String, dynamic>? guncellenecekUrun;
  final VoidCallback onUpdateCompleted;

  UrunEklePage({
    this.guncellenecekUrun,
    required this.onUpdateCompleted,
  });

  @override
  _UrunEklePageState createState() => _UrunEklePageState();
}

class _UrunEklePageState extends State<UrunEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _markaController = TextEditingController();
  final _modelController = TextEditingController();
  final _seriNoController = TextEditingController();
  final _lokasyonController = TextEditingController();

  String? tip = 'ust';
    bool isPickingImage = false; // <-- Yeni değişken
  File? foto;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    if (widget.guncellenecekUrun != null) {
      isUpdating = true;
      _adController.text = widget.guncellenecekUrun!['ad'] ?? '';
      _markaController.text = widget.guncellenecekUrun!['marka'] ?? '';
      _modelController.text = widget.guncellenecekUrun!['model'] ?? '';
      _seriNoController.text = widget.guncellenecekUrun!['seri_no'] ?? '';
      _lokasyonController.text = widget.guncellenecekUrun!['lokasyon'] ?? '';
      tip = widget.guncellenecekUrun!['tip'] ?? 'ust';
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _markaController.dispose();
    _modelController.dispose();
    _seriNoController.dispose();
    _lokasyonController.dispose();
    super.dispose();
  }

Future<void> fotoSec() async {
  // Eğer bir işlem zaten devam ediyorsa, yeni bir işlem başlatma.
  if (isPickingImage) return;

  setState(() {
    isPickingImage = true; // <-- İşlem başladı
  });

  try {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        foto = File(pickedFile.path);
      });
    }
  } finally {
    setState(() {
      isPickingImage = false; // <-- İşlem bitti
    });
  }
}

  Future<void> urunIslemi() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String endpoint = isUpdating ? 'urunguncelle.php' : 'urunekle.php';
      var uri = Uri.parse('https://www.cinetomi.com/depo/$endpoint');
      var request = http.MultipartRequest('POST', uri);

      request.fields['ad'] = _adController.text;
      request.fields['marka'] = _markaController.text;
      request.fields['model'] = _modelController.text;
      request.fields['seri_no'] = _seriNoController.text;
      request.fields['lokasyon'] = _lokasyonController.text;
      request.fields['tip'] = tip ?? 'ust';

      if (isUpdating) {
        request.fields['id'] = widget.guncellenecekUrun!['id'];
        if (foto != null) {
          request.files.add(await http.MultipartFile.fromPath('foto', foto!.path));
        } else {
          request.fields['mevcut_foto'] = widget.guncellenecekUrun!['foto'];
        }
      } else {
        if (foto == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lütfen fotoğraf seçin.')));
          return;
        }
        request.files.add(await http.MultipartFile.fromPath('foto', foto!.path));
      }

      try {
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          var jsonResp = jsonDecode(responseBody);
          if (jsonResp['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isUpdating
                    ? 'Ürün başarıyla güncellendi!'
                    : 'Ürün başarıyla kaydedildi!')));
            if (!isUpdating) {
              _formKey.currentState!.reset();
              _adController.clear();
              _markaController.clear();
              _modelController.clear();
              _seriNoController.clear();
              _lokasyonController.clear();
              setState(() {
                foto = null;
              });
            } else {
              widget.onUpdateCompleted();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Hata: ${jsonResp['error']}')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Sunucu hatası: ${response.statusCode}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İstek sırasında hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isUpdating ? 'Ürün Güncelle' : 'Yeni Ürün Kaydı',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              _buildTextFormField('Ad', controller: _adController),
              _buildTextFormField('Marka', controller: _markaController),
              _buildTextFormField('Model', controller: _modelController),
              _buildTextFormField('Seri No', controller: _seriNoController),
              _buildTextFormField('Lokasyon', controller: _lokasyonController),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tip,
                decoration: _inputDecoration('Ürün Tipi'),
                items: [
                  DropdownMenuItem(child: Text("Üst Ürün"), value: "ust"),
                  DropdownMenuItem(child: Text("Alt Ürün"), value: "alt"),
                ],
                onChanged: (val) {
                  setState(() {
                    tip = val;
                  });
                },
              ),
              SizedBox(height: 24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFBDBDBD)),
                ),
                child: foto != null
                    ? Image.file(foto!, fit: BoxFit.cover)
                    : (isUpdating && widget.guncellenecekUrun != null && widget.guncellenecekUrun!['foto'] != null && widget.guncellenecekUrun!['foto'].isNotEmpty)
                        ? Image.network("https://www.cinetomi.com/depo/${widget.guncellenecekUrun!['foto']}", fit: BoxFit.cover)
                        : Center(
                            child: Icon(Icons.image, size: 80, color: Color(0xFF9E9E9E)),
                          ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: fotoSec,
                icon: Icon(Icons.photo_library),
                label: Text('FOTOĞRAF SEÇ'),
                style: _buttonStyle(),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: urunIslemi,
                icon: Icon(isUpdating ? Icons.update : Icons.save),
                label: Text(isUpdating ? 'ÜRÜNÜ GÜNCELLE' : 'ÜRÜNÜ KAYDET'),
                style: _buttonStyle(backgroundColor: isUpdating ? Colors.orange : Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String labelText, {TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(labelText),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Color(0xFF616161)),
      filled: true,
      fillColor: Color(0xFFF5F5F5),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF007FFF), width: 2),
      ),
    );
  }

  ButtonStyle _buttonStyle({Color backgroundColor = const Color(0xFF007FFF)}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.4),
      textStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// -------------------- Üst Ürünler Sayfası --------------------
class UstUrunlerPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onUpdateSelected;

  const UstUrunlerPage({Key? key, required this.onUpdateSelected}) : super(key: key);

  @override
  _UstUrunlerPageState createState() => _UstUrunlerPageState();
}

class _UstUrunlerPageState extends State<UstUrunlerPage> {
  List<dynamic> urunler = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    urunleriGetir();
  }

  Future<void> urunleriGetir() async {
    setState(() {
      isLoading = true;
    });
    var uri = Uri.parse('https://www.cinetomi.com/depo/urungetir.php?tip=ust');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      setState(() {
        urunler = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> urunSil(String productId) async {
    var uri = Uri.parse('https://www.cinetomi.com/depo/urunsil.php');
    try {
      var response = await http.post(
        uri,
        body: {'id': productId},
      );

      if (response.statusCode == 200) {
        var jsonResp = jsonDecode(response.body);
        if (jsonResp['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ürün başarıyla silindi!')));
          urunleriGetir();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata: ${jsonResp['error']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sunucu hatası: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstek sırasında hata: $e')));
    }
  }

  Future<void> _showDeleteConfirmationDialog(String productId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ürünü Sil?'),
          content: const SingleChildScrollView(
            child: Text('Bu ürünü kalıcı olarak silmek istediğinizden emin misiniz?'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sil'),
              onPressed: () {
                Navigator.of(context).pop();
                urunSil(productId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: product['foto'] != null && product['foto'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "https://www.cinetomi.com/depo/${product['foto']}",
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.broken_image, size: 80, color: Color(0xFF9E9E9E)),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image, size: 100, color: Color(0xFF9E9E9E)),
                    ),
            ),
            SizedBox(height: 16),
            _buildInfoRow("Ad", product['ad']),
            _buildInfoRow("Marka", product['marka']),
            _buildInfoRow("Model", product['model']),
            _buildInfoRow("Seri No", product['seri_no']),
            _buildInfoRow("Lokasyon", product['lokasyon']),
            _buildInfoRow("Tip", product['tip']),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => widget.onUpdateSelected(product),
                  icon: Icon(Icons.edit),
                  label: Text("GÜNCELLE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(product['id']),
                  icon: Icon(Icons.delete),
                  label: Text("SİL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 16, color: Color(0xFF424242)),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value ?? '',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (urunler.isEmpty) {
      return Center(
        child: Text(
          "Henüz ürün yok.",
          style: TextStyle(fontSize: 18, color: Color(0xFF616161)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: urunleriGetir,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: urunler.length,
        itemBuilder: (context, index) {
          var u = urunler[index];
          return _buildProductCard(u);
        },
      ),
    );
  }
}

// -------------------- Alt Ürünler Sayfası --------------------
class AltUrunlerPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onUpdateSelected;

  const AltUrunlerPage({Key? key, required this.onUpdateSelected}) : super(key: key);

  @override
  _AltUrunlerPageState createState() => _AltUrunlerPageState();
}

class _AltUrunlerPageState extends State<AltUrunlerPage> {
  List<dynamic> urunler = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    urunleriGetir();
  }

  Future<void> urunleriGetir() async {
    setState(() {
      isLoading = true;
    });
    var uri = Uri.parse('https://www.cinetomi.com/depo/urungetir.php?tip=alt');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      setState(() {
        urunler = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> urunSil(String productId) async {
    var uri = Uri.parse('https://www.cinetomi.com/depo/urunsil.php');
    try {
      var response = await http.post(
        uri,
        body: {'id': productId},
      );

      if (response.statusCode == 200) {
        var jsonResp = jsonDecode(response.body);
        if (jsonResp['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ürün başarıyla silindi!')));
          urunleriGetir();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata: ${jsonResp['error']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sunucu hatası: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstek sırasında hata: $e')));
    }
  }

  Future<void> _showDeleteConfirmationDialog(String productId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ürünü Sil?'),
          content: const SingleChildScrollView(
            child: Text('Bu ürünü kalıcı olarak silmek istediğinizden emin misiniz?'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sil'),
              onPressed: () {
                Navigator.of(context).pop();
                urunSil(productId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: product['foto'] != null && product['foto'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "https://www.cinetomi.com/depo/${product['foto']}",
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.broken_image, size: 80, color: Color(0xFF9E9E9E)),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image, size: 100, color: Color(0xFF9E9E9E)),
                    ),
            ),
            SizedBox(height: 16),
            _buildInfoRow("Ad", product['ad']),
            _buildInfoRow("Marka", product['marka']),
            _buildInfoRow("Model", product['model']),
            _buildInfoRow("Seri No", product['seri_no']),
            _buildInfoRow("Lokasyon", product['lokasyon']),
            _buildInfoRow("Tip", product['tip']),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => widget.onUpdateSelected(product),
                  icon: Icon(Icons.edit),
                  label: Text("GÜNCELLE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(product['id']),
                  icon: Icon(Icons.delete),
                  label: Text("SİL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 16, color: Color(0xFF424242)),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value ?? '',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (urunler.isEmpty) {
      return Center(
        child: Text(
          "Henüz ürün yok.",
          style: TextStyle(fontSize: 18, color: Color(0xFF616161)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: urunleriGetir,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: urunler.length,
        itemBuilder: (context, index) {
          var u = urunler[index];
          return _buildProductCard(u);
        },
      ),
    );
  }
}