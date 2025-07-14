package finalassignmentbackend.config.ai.chat;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Value;

import java.io.File;

// Quarkus作用域注解，用于定义应用级别的单例Bean
@ApplicationScoped
public class GraalPyContext {

    // GraalVM Python上下文对象
    private final Context context;

    // 构造函数，初始化GraalVM Python上下文
    @Inject
    public GraalPyContext() {
        try {
            String sitePackagesPath;
            String executablePath;
            // 获取项目根目录
            String projectRoot = System.getProperty("user.dir");
            // 获取target目录路径
            File targetDir = new File(projectRoot, "finalAssignmentBackend/target");
            // 获取venv目录路径
            File venvDir = new File(targetDir, "classes/org.graalvm.python.vfs/venv");
            String os = System.getProperty("os.name").toLowerCase();

            // 验证venv目录是否存在
            if (!venvDir.exists()) {
                throw new RuntimeException("venv目录不存在: " + venvDir.getAbsolutePath());
            }

            // 根据操作系统设置site-packages路径
            if (os.startsWith("windows")) {
                sitePackagesPath = new File(venvDir, "Lib/site-packages").getAbsolutePath();
            } else if (os.startsWith("linux")) {
                sitePackagesPath = new File(venvDir, "lib/python3.11/site-packages").getAbsolutePath();
            } else {
                throw new RuntimeException("不支持的操作系统: " + os);
            }

            // 获取包含baidu_crawler.py的目录
            File pythonScriptDir = new File(projectRoot, "finalAssignmentBackend/src/main/resources/python/");
            if (!pythonScriptDir.exists()) {
                throw new RuntimeException("Python脚本目录不存在: " + pythonScriptDir.getAbsolutePath());
            }
            String pythonScriptPath = pythonScriptDir.getAbsolutePath();

            // 合并site-packages和脚本目录路径
            String pythonPath = sitePackagesPath + File.pathSeparator + pythonScriptPath;

            // 根据操作系统设置可执行文件路径
            if (os.startsWith("windows")) {
                executablePath = new File(venvDir, "Scripts/graalpy.exe").getAbsolutePath();
            } else if (os.startsWith("linux")) {
                executablePath = new File(venvDir, "Scripts/graalpy.sh").getAbsolutePath();
            } else {
                throw new RuntimeException("不支持的操作系统: " + os);
            }

            // 配置GraalPy上下文
            context = Context.newBuilder("python")
                    .option("python.PythonPath", pythonPath)
                    .option("python.Executable", executablePath)
                    .allowAllAccess(true)
                    .build();
        } catch (Exception e) {
            throw new RuntimeException("初始化GraalPy上下文失败: " + e.getMessage(), e);
        }
    }

    // 执行Python代码并返回结果
    public Value eval(String source) {
        return context.eval("python", source);
    }
}