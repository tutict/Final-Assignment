package bagu.design;


import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Fork;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Warmup;

import java.util.logging.Level;
import java.util.logging.Logger;

/*
 * 抽象工厂模式
 */
public class AbstractFactory {
    private static final Logger logger = Logger.getGlobal();

    public interface Box {
        void check();
    }

    public interface Desk {
        void check();
    }

    public static class boyBox implements Box {
        @Override
        public void check() {
            logger.log(Level.INFO, "This is boy's box.");
        }
    }

    public static class boyDesk implements Desk {
        @Override
        public void check() {
            logger.log(Level.INFO, "This is boy's desk.");
        }
    }

    public static class girlBox implements Box {
        @Override
        public void check() {
            logger.log(Level.INFO, "This is girl's box.");
        }
    }

    public static class girlDesk implements Desk {
        @Override
        public void check() {
            logger.log(Level.INFO, "This is girl's desk.");
        }
    }

    // 工厂接口
    public interface IFactory {
        Box getBox();

        Desk getDesk();
    }

    public static class boyFactory implements IFactory {
        @Override
        public Box getBox() {
            return new boyBox();
        }

        @Override
        public Desk getDesk() {
            return new boyDesk();
        }
    }

    public static class girlFactory implements IFactory {
        @Override
        public Box getBox() {
            return new girlBox();
        }

        @Override
        public Desk getDesk() {
            return new girlDesk();
        }
    }
   
    Box box;
    Desk desk;

    public AbstractFactory(IFactory factory) {
        box = factory.getBox();
        desk = factory.getDesk();
    }

    public void check() {
        box.check();
        desk.check();
    }

    @Benchmark
    @Fork(value = 1)                // 启动一个独立的 JVM 进程运行测试
    @Warmup(iterations = 2)         // 预热5次（预热阶段不计入最终数据）
    @Measurement(iterations = 1)
    public static void main(String[] args) {
        // 获取当前操作系统的名称
        String os = System.getProperty("os.name").toLowerCase();

        AbstractFactory abstractFactory = null;
        IFactory iFactory = null;

        if (os.startsWith("windows")) {
            iFactory = new boyFactory();
        } else if (os.startsWith("linux")) {
            iFactory = new girlFactory();
        } else {
            logger.log(Level.WARNING, "Your OS is not supported.");
        }

        if (iFactory != null) {
            abstractFactory = new AbstractFactory(iFactory);
        } else {
            logger.log(Level.WARNING, "IFactory with something warn");
        }

        if (abstractFactory != null) {
            abstractFactory.check();
        } else {
            logger.log(Level.WARNING, "AbstractFactory with something warn");
        }
    }
}
