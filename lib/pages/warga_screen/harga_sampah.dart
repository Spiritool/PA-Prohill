import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

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
  final String baseipapi = 'https://prohildlhcilegon.id';
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
      final response = await http.get(Uri.parse('$baseipapi/api/harga-barang'));
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                left: 24,
                right: 24,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Item image
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        item['gambar'] != null && item['gambar'].isNotEmpty
                            ? '$baseipapi${item['gambar']}'.replaceAll(r'\', '')
                            : 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.recycling,
                                size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Item name
                  Text(
                    item['Nama_Barang'] ?? 'Barang',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rp. ${formatHarga(item['Harga_Beli'] ?? '0')},- /kg',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Quantity selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade50, Colors.grey.shade100],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (tempQuantity > 1) {
                              setStateDialog(() => tempQuantity--);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tempQuantity > 1
                                  ? Colors.red.shade100
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.remove,
                              color: tempQuantity > 1
                                  ? Colors.red.shade700
                                  : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '$tempQuantity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setStateDialog(() => tempQuantity++);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Add to cart button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final existingIndex = selectedItems.indexWhere(
                          (element) => element.item['ID'] == item['ID'],
                        );

                        setState(() {
                          if (existingIndex != -1) {
                            selectedItems[existingIndex].quantity +=
                                tempQuantity;
                          } else {
                            selectedItems.add(
                              SelectedItem(
                                  item: Map<String, dynamic>.from(item),
                                  quantity: tempQuantity),
                            );
                          }
                        });

                        Navigator.pop(context);

                        // Show success snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                    '${item['Nama_Barang']} ditambahkan ke keranjang'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white),
                      label: const Text(
                        'Tambah ke Keranjang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        double totalHarga = 0;
        for (var selected in selectedItems) {
          final harga =
              double.tryParse(selected.item['Harga_Beli'] ?? '0') ?? 0;
          totalHarga += harga * selected.quantity;
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.shopping_cart,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keranjang Belanja',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${selectedItems.length} item dipilih',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Cart items
              Expanded(
                child: selectedItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Keranjang masih kosong',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pilih barang yang ingin Anda jual',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: selectedItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final selected = selectedItems[index];
                          final item = selected.item;
                          final harga =
                              double.tryParse(item['Harga_Beli'] ?? '0') ?? 0;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Item image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      item['gambar'] != null &&
                                              item['gambar'].isNotEmpty
                                          ? '$baseipapi${item['gambar']}'
                                              .replaceAll(r'\', '')
                                          : 'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.recycling,
                                            size: 30, color: Colors.grey[400]);
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Item details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['Nama_Barang'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${selected.quantity} kg × Rp. ${formatHarga(harga.toString())},-',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rp. ${formatHarga((harga * selected.quantity).toString())},-',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Delete button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedItems.removeAt(index);
                                    });
                                    Navigator.pop(context);
                                    if (selectedItems.isNotEmpty) {
                                      showCartDialog();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade400,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom section with total and button
              if (selectedItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Estimasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Rp. ${formatHarga(totalHarga.toString())},-',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Container(
                      //   width: double.infinity,
                      //   height: 56,
                      //   decoration: BoxDecoration(
                      //     gradient: LinearGradient(
                      //       colors: [
                      //         Colors.green.shade400,
                      //         Colors.green.shade600
                      //       ],
                      //     ),
                      //     borderRadius: BorderRadius.circular(28),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.green.withOpacity(0.3),
                      //         blurRadius: 10,
                      //         offset: const Offset(0, 5),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Katalog Harga Sampah',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100), // Space for app bar

            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Cari jenis sampah...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey[400], size: 22),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey[400], size: 20),
                          onPressed: () {
                            searchController.clear();
                            // Add filter logic here
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

            // Grid view
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index] as Map<String, dynamic>;
                  final namaBarang = item['Nama_Barang'] ?? 'Tidak tersedia';
                  final hargaBeli = item['Harga_Beli'] ?? '0';
                  String gambarUrl = item['gambar'] ?? '';

                  if (gambarUrl.isNotEmpty) {
                    gambarUrl = '$baseipapi$gambarUrl'.replaceAll(r'\', '');
                  } else {
                    gambarUrl = 'https://via.placeholder.com/150';
                  }

                  return GestureDetector(
                    onTap: () => showItemDialog(item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image section
                          Expanded(
                            flex: 3,
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade50,
                                    Colors.grey.shade100
                                  ],
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  gambarUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.recycling,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Content section
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    namaBarang,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400,
                                          Colors.green.shade600
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      'Rp. ${formatHarga(hargaBeli)},- /kg',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
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
      ),
      floatingActionButton: selectedItems.isNotEmpty
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: showCartDialog,
                backgroundColor: Colors.green.shade600,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white),
                    if (selectedItems.length > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${selectedItems.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: Text(
                  '${selectedItems.length} Item',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
