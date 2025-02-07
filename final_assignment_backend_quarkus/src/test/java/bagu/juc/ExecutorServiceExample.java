package bagu.juc;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Fork;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Warmup;

import java.util.logging.Logger;

public class ExecutorServiceExample {
    private static Logger logger = Logger.getGlobal();

    @Benchmark
    @Fork(value = 1)                // 启动一个独立的 JVM 进程运行测试
    @Warmup(iterations = 2)         // 预热5次（预热阶段不计入最终数据）
    @Measurement(iterations = 1)
    public static void main(String[] args) {

    }
}
