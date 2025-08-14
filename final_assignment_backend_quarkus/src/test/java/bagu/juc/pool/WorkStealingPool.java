package bagu.juc.pool;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Fork;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Warmup;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;
import java.util.stream.IntStream;

public class WorkStealingPool {
    private static final Logger logger = Logger.getGlobal();

    @Benchmark
    @Fork(value = 1)                // 启动一个独立的 JVM 进程运行测试
    @Warmup(iterations = 2)         // 预热5次（预热阶段不计入最终数据）
    @Measurement(iterations = 1)
    public static void main(String[] args) {

        ExecutorService executorService = Executors.newWorkStealingPool();

        // 提交20个任务到线程池，模拟计算任务
        IntStream.range(1, 21).forEach(i -> executorService.submit(() -> {
            try {
                // 模拟任务执行，计算斐波那契数列并休眠随机时间
                logger.info("任务 " + i + " 开始执行，线程: " + Thread.currentThread().getName());
                // 计算斐波那契数列（较耗时的任务）
                long result = fibonacci(30);
                TimeUnit.MILLISECONDS.sleep((long) (Math.random() * 500));
                logger.info("任务 " + i + " 完成，结果: " + result);
            } catch (InterruptedException e) {
                logger.severe("任务 " + i + " 被中断: " + e.getMessage());
                // 恢复中断状态
                Thread.currentThread().interrupt();
            }
        }));

        // 关闭线程池，不接受新任务
        executorService.shutdown();

        try {
            // 等待所有任务完成，最多等待30秒
            if (!executorService.awaitTermination(30, TimeUnit.SECONDS)) {
                logger.warning("线程池未在指定时间内终止，强制关闭");
                // 强制终止所有任务
                executorService.shutdownNow();
            } else {
                logger.info("所有任务已完成，线程池已关闭");
            }
        } catch (InterruptedException e) {
            logger.severe("等待线程池终止时被中断: " + e.getMessage());
            // 强制终止线程池
            executorService.shutdownNow();
            // 恢复中断状态
            Thread.currentThread().interrupt();
        }
    }

    // 简单的递归斐波那契数列计算，用于模拟耗时任务
    private static long fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }
}
