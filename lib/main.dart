import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Hadis {
  final String kitab;
  final String id;
  final int available;

  Hadis({required this.kitab, required this.id, required this.available});

  factory Hadis.fromJson(Map<String, dynamic> json) {
    return Hadis(
      kitab: json['name'] as String,
      id: json['id'] as String,
      available: json['available'] as int,
    );
  }
}

class HadisDetail {
  final int number;
  final String arab;

  HadisDetail({required this.number, required this.arab});

  factory HadisDetail.fromJson(Map<String, dynamic> json) {
    return HadisDetail(
      number: json['number'] as int,
      arab: json['arab'] as String,
    );
  }
}

class HadisController extends GetxController {
  var isLoading = true.obs;
  var hadisList = <Hadis>[].obs;

  @override
  void onInit() {
    fetchHadis();
    super.onInit();
  }

  void fetchHadis() async {
    try {
      isLoading(true);
      var response = await http.get(Uri.parse('https://api.hadith.gading.dev/books'));
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['error'] == false) {
          var data = jsonData['data'] as List;
          hadisList.value = data.map((e) => Hadis.fromJson(e)).toList();
        } else {
          print('Kesalahan: ${jsonData['message']}');
        }
      } else {
        print('Kesalahan: ${response.statusCode}');
      }
    } catch (e) {
      print('Kesalahan: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<HadisDetail?> fetchHadisDetail(String id, int number) async {
    try {
      var response = await http.get(Uri.parse('https://api.hadith.gading.dev/books/$id/$number'));
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['error'] == false) {
          var data = jsonData['data']['contents'] as Map<String, dynamic>;
          return HadisDetail.fromJson(data);
        } else {
          print('Kesalahan: ${jsonData['message']}');
        }
      } else {
        print('Kesalahan: ${response.statusCode}');
      }
    } catch (e) {
      print('Kesalahan: $e');
    }
    return null;
  }
}

class DetailPage extends StatelessWidget {
  final Hadis hadis;
  final int hadisNumber;
  final HadisController hadisController = Get.find<HadisController>();
  final Rxn<HadisDetail> hadisDetail = Rxn<HadisDetail>();

  DetailPage({required this.hadis, required this.hadisNumber}) {
    fetchHadisDetail();
  }

  void fetchHadisDetail() async {
    var detail = await hadisController.fetchHadisDetail(hadis.id, hadisNumber);
    if (detail != null) {
      hadisDetail.value = detail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Hadis'),
      ),
      body: Obx(
        () => hadisDetail.value != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kitab: ${hadis.kitab}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Hadis No. $hadisNumber',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Isi Hadis:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      hadisDetail.value!.arab,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final HadisController hadisController = Get.put(HadisController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Buku Hadis'),
      ),
      body: Obx(
        () => hadisController.isLoading.value
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: hadisController.hadisList.length,
                itemBuilder: (context, index) {
                  var hadis = hadisController.hadisList[index];
                  return Card(
                    child: ListTile(
                      title: Text(hadis.kitab),
                      subtitle: Text('Tersedia: ${hadis.available} Hadis'),
                      onTap: () {
                        Get.to(
                          () => DetailPage(hadis: hadis, hadisNumber: 1),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

void main() {
  runApp(GetMaterialApp(
    home: HomePage(),
  ));
}
