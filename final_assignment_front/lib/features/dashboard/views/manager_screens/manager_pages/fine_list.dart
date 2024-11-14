import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FineList extends StatefulWidget {
  const FineList({super.key});

  @override
  State<FineList> createState() => _FineListPage();
}

class _FineListPage extends State<FineList> with AddFinePage, FineDetailPage {
  late Future<List<Fine>> _finesFuture;

  @override
  void initState() {
    super.initState();
    _finesFuture = _fetchFines();
  }

  Future<List<Fine>> _fetchFines() async {
    final url =
    Uri.parse('\${AppConfig.baseUrl}\${AppConfig.fineInformationEndpoint}');
    try {
      final response = await http.get(url);
      if (!mounted) return [];
      if (response.statusCode == 200) {
        List<dynamic> finesJson = jsonDecode(response.body);
        return finesJson.map((json) => Fine.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fines');
      }
    } catch (e) {
      throw Exception('Failed to load fines: \$e');
    }
  }

  Future<void> _deleteFine(int fineId) async {
    final url = Uri.parse(
        '\${AppConfig.baseUrl}\${AppConfig.fineInformationEndpoint}/\$fineId');
    try {
      final response = await http.delete(url);
      if (!mounted) return;
      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除罚款信息成功！')),
        );
        setState(() {
          _finesFuture = _fetchFines(); // 刷新罚款信息列表
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除罚款信息失败，请稍后重试。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发生错误，请检查网络连接。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('罚款信息列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => buildAddFinePage(context)),
              ).then((value) {
                if (value == true) {
                  setState(() {
                    _finesFuture = _fetchFines();
                  });
                }
              });
            },
            tooltip: '添加新罚款',
          ),
        ],
      ),
      body: FutureBuilder<List<Fine>>(
        future: _finesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
                child: Text('加载罚款信息时发生错误: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('没有找到罚款信息'));
          } else {
            final fines = snapshot.data!;
            return ListView.builder(
              itemCount: fines.length,
              itemBuilder: (context, index) {
                final fine = fines[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: const Text('罚款金额: \$\${fine.fineAmount}'),
                    subtitle: const Text(
                        '缴款人: \${fine.payee}\n罚款时间: \${fine.fineTime}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteFine(fine.fineId),
                      tooltip: '删除此罚款',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                buildFineDetailPage(context, fine)),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

mixin AddFinePage {
  Widget buildAddFinePage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加新罚款'),
      ),
      body: const Center(
        child: Text('此页面用于添加新罚款信息（尚未实现）'),
      ),
    );
  }
}

mixin FineDetailPage {
  Widget buildFineDetailPage(BuildContext context, Fine fine) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('罚款详细信息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('罚款金额: \$\${fine.fineAmount}',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge),
            const SizedBox(height: 8.0),
            Text('缴款人: \${fine.payee}',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyLarge),
            const SizedBox(height: 8.0),
            Text('罚款时间: \${fine.fineTime}',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyLarge),
          ],
        ),
      ),
    );
  }
}

class Fine {
  final int fineId;
  final double fineAmount;
  final String fineTime;
  final String payee;

  Fine({
    required this.fineId,
    required this.fineAmount,
    required this.fineTime,
    required this.payee,
  });

  factory Fine.fromJson(Map<String, dynamic> json) {
    return Fine(
      fineId: json['fineId'],
      fineAmount: json['fineAmount'].toDouble(),
      fineTime: json['fineTime'],
      payee: json['payee'],
    );
  }
}
