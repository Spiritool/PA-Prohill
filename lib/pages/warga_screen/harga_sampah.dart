import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HargaSampah extends StatefulWidget {
  const HargaSampah({super.key});

  @override
  State<HargaSampah> createState() => _HargaSampahState();
}

class SelectedItem {
  final Map<String, dynamic> item;
  int quantity;

  SelectedItem({required this.item, this.quantity = 1});
}

class _HargaSampahState extends State<HargaSampah> {
  final String baseUrl = 'https://prohildlhcilegon.id';
  List<dynamic> hargaSampahList = [];
  List<dynamic> filteredList = [];
  List<SelectedItem> selectedItems = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHargaSampah();
    searchController.addListener(() {
      filterSearchResults(searchController.text);
    });
  }

  Future<void> fetchHargaSampah() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/harga-barang'));
      if (response.statusCode == 200) {
        setState(() {
          hargaSampahList = jsonDecode(response.body);
          filteredList = hargaSampahList;
        });
      } else {
        throw Exception('Gagal koneksi ke API');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void filterSearchResults(String query) {
    setState(() {
      filteredList = hargaSampahList.where((item) {
        final namaBarang = (item['Nama_Barang'] ?? '').toLowerCase();
        return namaBarang.contains(query.toLowerCase());
      }).toList();
    });
  }

  String formatHarga(String harga) {
    double? hargaDouble = double.tryParse(harga);
    if (hargaDouble == null) return '0';
    return hargaDouble % 1 == 0
        ? hargaDouble.toInt().toString()
        : hargaDouble.toString();
  }

  void showItemDialog(Map<String, dynamic> item) {
    int tempQuantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Wrap(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      item['Nama_Barang'] ?? 'Barang',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            iconSize: 28,
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () {
                              if (tempQuantity > 1) {
                                setStateDialog(() => tempQuantity--);
                              }
                            },
                          ),
                          Text(
                            '$tempQuantity',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            iconSize: 28,
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.green),
                            onPressed: () {
                              setStateDialog(() => tempQuantity++);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: () {
                      print("Data item lengkap: $item");

                      print(
                          "Tambah item: ${item['id']} - ${item['Nama_Barang']}");
                      for (var s in selectedItems) {
                        print(
                            "Di keranjang: ${s.item['id']} - ${s.item['Nama_Barang']}");
                      }

                      final existingIndex = selectedItems.indexWhere(
                        (element) => element.item['ID'] == item['ID'],
                      );

                      setState(() {
                        if (existingIndex != -1) {
                          selectedItems[existingIndex].quantity += tempQuantity;
                        } else {
                          // SALINAN BARU DARI ITEM
                          selectedItems.add(
                            SelectedItem(
                                item: Map<String, dynamic>.from(item),
                                quantity: tempQuantity),
                          );
                        }
                      });

                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: const Text('Simpan ke Keranjang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showCartDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double totalHarga = 0;
        for (var selected in selectedItems) {
          final harga =
              double.tryParse(selected.item['Harga_Beli'] ?? '0') ?? 0;
          totalHarga += harga * selected.quantity;
        }
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Keranjang',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: selectedItems.isEmpty
                      ? const Center(child: Text('Keranjang kosong'))
                      : ListView.builder(
                          itemCount: selectedItems.length,
                          itemBuilder: (context, index) {
                            final selected = selectedItems[index];
                            final item = selected.item;
                            final harga =
                                double.tryParse(item['Harga_Beli'] ?? '0') ?? 0;

                            return ListTile(
                              title: Text(item['Nama_Barang'] ?? ''),
                              subtitle: Text(
                                  '${selected.quantity} x Rp${formatHarga(harga.toString())}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    selectedItems.removeAt(index);
                                  });
                                  Navigator.pop(context);
                                  showCartDialog();
                                },
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Rp${formatHarga(totalHarga.toString())},-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ElevatedButton(
                //   onPressed: () {
                //     Navigator.pop(context);
                //     // bisa lanjut ke halaman checkout atau apapun
                //   },
                //   child: const Text('Lanjutkan'),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Harga Sampah',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF0F5E8),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama barang...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index] as Map<String, dynamic>;
                final namaBarang = item['Nama_Barang'] ?? 'Tidak tersedia';
                final hargaBeli = item['Harga_Beli'] ?? '0';
                String gambarUrl = item['gambar'] ?? '';

                if (gambarUrl.isNotEmpty) {
                  gambarUrl = '$baseUrl$gambarUrl'.replaceAll(r'\', '');
                } else {
                  gambarUrl = 'https://via.placeholder.com/150';
                }

                return GestureDetector(
                  onTap: () => showItemDialog(item),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: Image.network(
                              gambarUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image,
                                    size: 100);
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            namaBarang,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Rp.${formatHarga(hargaBeli)},-',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: selectedItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: showCartDialog,
              icon: const Icon(Icons.shopping_cart),
              label: Text('${selectedItems.length} item'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
}
