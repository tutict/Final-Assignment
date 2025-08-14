package bagu.juc.pool;

import org.openjdk.jmh.annotations.*;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

public class CachedThreadPool {
    private static final Logger logger = Logger.getGlobal();

    @Benchmark
    @Fork(value = 1)                // 启动一个独立的 JVM 进程运行测试
    @Warmup(iterations = 2)         // 预热5次（预热阶段不计入最终数据）
    @Measurement(iterations = 1)
    public static void main(String[] args) {

        // 创建一个缓存线程池
        ExecutorService executorService = Executors.newCachedThreadPool();

        for (int i = 0; i < 10; i++) {
            int taskId = i;
            executorService.submit(() -> {
                try {
                    logger.info("任务编号:" + taskId + "正在执行" + Thread.currentThread().getName());
                    // 暂停了一秒钟
                    TimeUnit.SECONDS.sleep(1);
                    logger.info("任务" + taskId + "完成了");
                } catch (InterruptedException e) {
                    logger.warning("任务" + taskId + "被中断" + "错误详情" + e.getMessage());
                    // 恢复中断状态
                    Thread.currentThread().interrupt();
                }
            });
        }

        // 等待所有任务完成,关闭线程池
        executorService.shutdown();

        try {
            if (!executorService.awaitTermination(10, TimeUnit.SECONDS)) {
                logger.info("线程池未在指定时间停止，强制关闭");
                executorService.shutdownNow();
            } else {
                logger.info("所有任务完成，线程已关闭");
            }
        } catch (InterruptedException e) {
            logger.warning("等待线程池被终止时被中断" + e.getMessage());
            executorService.shutdownNow();
            // 恢复中断状态
            Thread.currentThread().interrupt();
        }
    }
}
