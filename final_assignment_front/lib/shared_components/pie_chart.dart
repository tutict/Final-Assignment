import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';

/// 基于 flutter_chart_plus 包的饼图组件。
/// 该小部件用于以饼图的形式展示数据，饼图是一种常见的表示比例的方式。
class PieChart extends StatelessWidget {
  /// PieChart 的构造函数。
  /// 继承自 StatelessWidget 的 key 参数，用于小部件的自定义。
  const PieChart({super.key});

  /// 构建并返回给定小部件的 widget 树。
  ///
  /// [BuildContext context]: 当前构建上下文。
  /// 返回一个显示饼图的 Widget。
  @override
  Widget build(BuildContext context) {
    return SizedBox(

        /// 设置饼图容器的高度。
        height: 200,
        child: ChartWidget(
          /// 配置图表坐标的渲染方式。
          coordinateRender: ChartCircularCoordinateRender(
            /// 定义饼图的具体配置。
            charts: [
              /// 配置饼图的数据和样式。
              Pie(
                /// 饼图的数据源。
                data: dataList,

                /// 计算饼图位置的方法，基于数据项中的 'value1' 值。
                position: (item) => (double.parse(item['value1'].toString())),

                /// 设置饼图中心孔的半径。
                holeRadius: 40,

                /// 设置饼图中值文本的偏移量。
                valueTextOffset: 20,

                /// 设置饼图中心文本的样式。
                centerTextStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),

                /// 格式化饼图中显示的值。
                valueFormatter: (item) => item['value1'].toString(),
              ),
            ],
          ),
        ));
  }
}
